package demo.zuul;

import com.google.common.util.concurrent.AtomicDoubleArray;
import com.netflix.loadbalancer.Server;

import java.util.*;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.ConcurrentMap;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.atomic.AtomicLongArray;
import java.util.concurrent.locks.ReentrantLock;
import java.util.stream.Collectors;

/**
 * @author Tietang Wang 铁汤
 * @Date: 2017/4/24 13:38
 * @blog http://tietang.wang
 */
public class RouterStats extends TimerTask {

    public static ThreadLocal<Server> serverThreadLocal = new ThreadLocal<>();

    public static void set(Server server) {
        serverThreadLocal.remove();
        serverThreadLocal.set(server);
    }

    public static Server get() {
        return serverThreadLocal.get();
    }


    public static final int WINDOW_IN_SECONDS = 3;
    public static final int NUMBER_OF_WINDOW = 3;
    public static final long START_YEAR;
    private ConcurrentMap<String, RollingNumbers> metrics = new ConcurrentHashMap<>();

    static {
        Calendar calendar = Calendar.getInstance();
        calendar.set(2017, 1, 1, 0, 0, 0);
        calendar.set(Calendar.MILLISECOND, 0);
        START_YEAR = calendar.getTimeInMillis();
    }

    //    private ConcurrentMap<String, Metric> metrics;
    final int windowInSeconds;
    final int numberOfWindow;
    final Timer timer;

    public RouterStats() {
        this(WINDOW_IN_SECONDS, NUMBER_OF_WINDOW);
    }


    public RouterStats(int windowInSeconds, int numberOfWindow) {
        this.windowInSeconds = windowInSeconds;
        this.numberOfWindow = numberOfWindow;
        this.timer = new Timer("RollingNumbers-Timer");
        this.timer.scheduleAtFixedRate(this, windowInSeconds * 1000, windowInSeconds * 1000);
    }

    public RollingNumbers getCuttentRollingNumbers(String name) {
        RollingNumbers numbers = metrics.get(name);
        if (numbers == null) {
            numbers = new RollingNumbers(name);
            metrics.put(name, numbers);
        }
        return numbers;
    }

    public long getAndIncrement(String name, RollingNumberEvent event, double value) {
        return getCuttentRollingNumbers(name).getAndIncrement(event, value);
    }

    @Override
    public void run() {

        long key = getCuttentTimeKey();
        long cleanMaxKey = key - windowInSeconds * numberOfWindow;
        for (Map.Entry<String, RollingNumbers> entry : metrics.entrySet()) {
            RollingNumbers rn = entry.getValue();
            for (Long k : rn.getMetrics().keySet()) {
                if (k <= cleanMaxKey) {
                    rn.getMetrics().remove(k);
                }
            }
        }

        for (Map.Entry<String, RollingNumbers> entry : metrics.entrySet()) {
            RollingNumbers rn = entry.getValue();
            //            RollingNumber n = rn.getCuttentRollingNumber();
            RollingNumber n = rn.getRollingNumber(1);
            System.out.println(rn.getName() + " " + n.toString() + " " + rn.getFailedercent());
            //            n = rn.getCuttentRollingNumber();
            //            System.out.println("------");
            //            System.out.println(rn.getName() + " " + n.toString() + " " + rn.getFailedercent());
        }
        System.out.println();
    }

    private long getCuttentTimeKey() {
        long c = System.currentTimeMillis();
        long cu = c / 1000;
        long key = windowInSeconds * new Double(Math.floor(cu / windowInSeconds)).intValue();
        return key;
    }


    public List<ISource> getSources(List<Server> serverList) {
        //        List<ISource> sources = new ArrayList<>();
        long key = getCuttentTimeKey();
        //        for (Server server : serverList) {
        //            RollingNumbers numbers = metrics.get(server.getHostPort());
        //            RollingNumber rn = numbers.getRollingNumber(key);
        //            ServerSource source = new ServerSource();
        //            sources.add(source);
        //        }
        return serverList.stream().map(s -> {
            RollingNumbers numbers = metrics.get(s.getHostPort());
            RollingNumber rn = numbers.getRollingNumber(key);
            ServerSource source = new ServerSource(s.getHostPort());
            source.setServer(s);
            source.setCurrentFailedNumbers(rn.getCount(RollingNumberEvent.FAILURE));
            source.setCurrentSuccessNumbers(rn.getCount(RollingNumberEvent.SUCCESS));
            source.setCurrentFailedResTime(rn.getDouble(RollingNumberEvent.SUCCESS));
            source.setCurrentSuccessResTime(rn.getDouble(RollingNumberEvent.SUCCESS));
            return source;
        }).collect(Collectors.toList());
        //        return sources;
    }


    class RollingNumbers {

        private String name;
        private ReentrantLock lock = new ReentrantLock();
        private ConcurrentMap<Long, RollingNumber> metrics = new ConcurrentHashMap<>();

        public RollingNumbers(String name) {
            this.name = name;
        }

        public String getName() {
            return name;
        }

        public ConcurrentMap<Long, RollingNumber> getMetrics() {
            return metrics;
        }

        public RollingNumber getCuttentRollingNumber() {
            long key = getCuttentTimeKey();
            RollingNumber numbers = metrics.get(key);
            if (numbers == null) {
                numbers = new RollingNumber(RollingNumberEvent.getSize());
                metrics.put(key, numbers);
            }
            return numbers;
        }

        public RollingNumber getRollingNumber(long key) {
            RollingNumber numbers = metrics.get(key);
            if (numbers == null) {
                numbers = new RollingNumber(RollingNumberEvent.getSize());
                metrics.put(key, numbers);
            }
            return numbers;
        }

        public RollingNumber getRollingNumber(int forward) {
            long key = getCuttentTimeKey() - forward * windowInSeconds;
            RollingNumber numbers = metrics.get(key);
            if (numbers == null) {
                numbers = new RollingNumber(RollingNumberEvent.getSize());
                metrics.put(key, numbers);
            }
            return numbers;
        }

        public double getFailedercent() {
            RollingNumber rn = getCuttentRollingNumber();
            long sucess = rn.getCount(RollingNumberEvent.SUCCESS);
            long failure = rn.getCount(RollingNumberEvent.FAILURE);
            double total = sucess + failure;
            return total == 0 ? 0 : failure / total;

        }


        public AtomicLongArray getCurrentAtomicLongArray() {
            long key = getCuttentTimeKey();
            if (lock.tryLock()) {
                try {
                    RollingNumber rn = getCuttentRollingNumber();
                    return rn.countArrays;
                } finally {
                    lock.unlock();
                }

            }
            return null;
        }

        public AtomicDoubleArray getCurrentAtomicDoubleArray() {
            long key = getCuttentTimeKey();
            if (lock.tryLock()) {
                try {
                    RollingNumber rn = getCuttentRollingNumber();
                    return rn.arrays;
                } finally {
                    lock.unlock();
                }

            }
            return null;
        }

        public long getAndIncrement(RollingNumberEvent i, double value) {

            return getCuttentRollingNumber().getAndIncrement(i, value);

        }

    }

    class RollingNumber {

        private AtomicLongArray countArrays;
        private AtomicDoubleArray arrays;

        public RollingNumber(int size) {
            countArrays = new AtomicLongArray(size);
            arrays = new AtomicDoubleArray(size);
        }

        public long getAndIncrement(RollingNumberEvent event, double value) {
            int i = event.ordinal();
            arrays.getAndAdd(i, value);
            return countArrays.getAndIncrement(i);
        }

        public long getCount(RollingNumberEvent event) {
            int i = event.ordinal();
            return countArrays.get(i);
        }

        public double getDouble(RollingNumberEvent event) {
            int i = event.ordinal();
            return arrays.get(i);
        }

        @Override
        public String toString() {
            List<Long> longs = new ArrayList<>();
            for (int i = 0; i < countArrays.length(); i++) {
                longs.add(countArrays.get(i));
            }
            List<Double> doubles = new ArrayList<>();
            for (int i = 0; i < arrays.length(); i++) {
                doubles.add(arrays.get(i));
            }
            return "RollingNumber{" +
                    "countArrays=" + longs +
                    ", arrays=" + doubles +
                    '}';
        }
    }

    enum RollingNumberEvent {

        SUCCESS,
        FAILURE;


        private static int size;

        static {
            Set<Integer> integers = new HashSet<>();
            for (RollingNumberEvent rollingNumberEvent : RollingNumberEvent.values()) {
                integers.add(rollingNumberEvent.ordinal());
            }
            size = integers.size();
        }


        public static int getSize() {
            return size;
        }
    }

    public static void main(String[] args) {
        int size = 10;
        String[] names = {"c1", "c2", "c3", "c4"};
        RouterStats routerStats = new RouterStats();

        Thread[] threads = new Thread[size];
        for (int i = 0; i < threads.length; i++) {
            threads[i] = new Thread(() -> {
                Random random = new Random();
                while (true) {
                    int rd = Math.abs(random.nextInt());
                    int fs = Math.abs(random.nextInt(50));
                    double rt = Math.abs(random.nextDouble() % 1000);
                    String name = names[rd % names.length];
                    boolean isFailed = fs % 18 == 0 && fs % 12 == 0;

                    routerStats.getAndIncrement(name,
                                                isFailed ? RollingNumberEvent.FAILURE : RollingNumberEvent.SUCCESS,
                                                rt);
                    try {
                        TimeUnit.MILLISECONDS.sleep(50);
                    } catch (InterruptedException e) {
                        e.printStackTrace();

                    }
                }

            });

        }
        for (int i = 0; i < threads.length; i++) {
            threads[i].start();
        }

    }
}
