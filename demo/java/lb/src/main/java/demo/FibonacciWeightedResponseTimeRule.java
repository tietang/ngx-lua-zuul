package demo;

import com.netflix.client.config.IClientConfig;
import com.netflix.client.config.IClientConfigKey;
import com.netflix.loadbalancer.*;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.util.*;
import java.util.concurrent.atomic.AtomicBoolean;

/**
 * @author Tietang Wang 铁汤
 * @Date: 2016/12/23 16:12
 * @blog http://tietang.wang
 */
public class FibonacciWeightedResponseTimeRule extends RoundRobinRule {

    public static final IClientConfigKey<Integer> WEIGHT_TASK_TIMER_INTERVAL_CONFIG_KEY = new IClientConfigKey<Integer>() {
        @Override
        public String key() {
            return "ServerWeightTaskTimerInterval";
        }

        @Override
        public String toString() {
            return key();
        }

        @Override
        public Class<Integer> type() {
            return Integer.class;
        }
    };

    public static final int DEFAULT_TIMER_INTERVAL = 30 * 1000;

    private int serverWeightTaskTimerInterval = DEFAULT_TIMER_INTERVAL;

    private static final Logger logger = LoggerFactory.getLogger(WeightedResponseTimeRule.class);

    // holds the accumulated weight from index 0 to current index
    // for example, element at index 2 holds the sum of weight of servers from 0 to 2
    private volatile List<ServerSource> accumulatedWeights = new ArrayList<>();


    private final Random random = new Random();

    protected Timer serverWeightTimer = null;

    protected AtomicBoolean serverWeightAssignmentInProgress = new AtomicBoolean(
            false);

    String name = "unknown";

    public FibonacciWeightedResponseTimeRule() {
        super();
    }

    public FibonacciWeightedResponseTimeRule(ILoadBalancer lb) {
        super(lb);
    }

    @Override
    public void setLoadBalancer(ILoadBalancer lb) {
        super.setLoadBalancer(lb);
        if (lb instanceof BaseLoadBalancer) {
            name = ((BaseLoadBalancer) lb).getName();
        }
        initialize(lb);
    }

    void initialize(ILoadBalancer lb) {
        if (serverWeightTimer != null) {
            serverWeightTimer.cancel();
        }
        serverWeightTimer = new Timer("NFLoadBalancer-serverWeightTimer-"
                                              + name, true);
        serverWeightTimer.schedule(new FibonacciWeightedResponseTimeRule.DynamicServerWeightTask(), 0,
                                   serverWeightTaskTimerInterval);
        // do a initial run
        FibonacciWeightedResponseTimeRule.ServerWeight sw = new FibonacciWeightedResponseTimeRule.ServerWeight();
        sw.maintainWeights();

        Runtime.getRuntime().addShutdownHook(new Thread(new Runnable() {
            public void run() {
                logger
                        .info("Stopping NFLoadBalancer-serverWeightTimer-"
                                      + name);
                serverWeightTimer.cancel();
            }
        }));
    }

    public void shutdown() {
        if (serverWeightTimer != null) {
            logger.info("Stopping NFLoadBalancer-serverWeightTimer-" + name);
            serverWeightTimer.cancel();
        }
    }

    private long totalWeight(List<ServerSource> currentWeights) {
        long w = 0;
        for (ServerSource currentWeight : currentWeights) {
            w += currentWeight.getCurrentWeight();
        }
        return w;

    }

    @Override
    public Server choose(ILoadBalancer lb, Object key) {
        if (lb == null) {
            return null;
        }
        Server server = null;

        while (server == null) {
            // get hold of the current reference in case it is changed from the other thread
            List<ServerSource> currentWeights = accumulatedWeights;
            if (Thread.interrupted()) {
                return null;
            }
            List<Server> allList = lb.getAllServers();

            int serverCount = allList.size();

            if (serverCount == 0) {
                return null;
            }


            long totalWeight = totalWeight(currentWeights);


            if (totalWeight <= 0) {
                server = super.choose(getLoadBalancer(), key);
            } else {
                ServerSource ss = RobinRound.next(currentWeights);
                server = ss.getServer();
                System.out.println(ss);
            }


            if (server == null) {
                /* Transient. */
                Thread.yield();
                continue;
            }
            if (server.isAlive()) {
                return (server);
            }

            // Next.
            server = null;
        }
        return server;
    }

    class DynamicServerWeightTask extends TimerTask {

        public void run() {
            FibonacciWeightedResponseTimeRule.ServerWeight serverWeight = new FibonacciWeightedResponseTimeRule.ServerWeight();
            try {
                serverWeight.maintainWeights();
            } catch (Throwable t) {
                logger.error(
                        "Throwable caught while running DynamicServerWeightTask for "
                                + name, t);
            }
        }
    }

    class ServerWeight {

        public void maintainWeights() {
            ILoadBalancer lb = getLoadBalancer();
            if (lb == null) {
                return;
            }
            if (serverWeightAssignmentInProgress.get()) {
                return; // Ping in progress - nothing to do
            } else {
                serverWeightAssignmentInProgress.set(true);
            }
            try {
                logger.info("Weight adjusting job started");
                AbstractLoadBalancer nlb = (AbstractLoadBalancer) lb;
                LoadBalancerStats stats = nlb.getLoadBalancerStats();
                if (stats == null) {
                    // no statistics, nothing to do
                    return;
                }

                List<ServerSource> finalWeights = new ArrayList<ServerSource>();
                for (Server server : nlb.getAllServers()) {
                    ServerStats ss = stats.getSingleServerStat(server);
                    double responseTime = ss.getResponseTimeAvg();
                    long value = FibonacciTable.getCeiling(Math.round(responseTime));

                    ServerSource serverSource = new ServerSource();
                    serverSource.setServer(server);
                    serverSource.setEffectiveWeight(value);
                    serverSource.setWeight(value);
                    finalWeights.add(serverSource);

                }
                setWeights(finalWeights);
                //
                //
                //                double totalResponseTime = 0;
                //                // find maximal 95% response time
                //                for (Server server : nlb.getAllServers()) {
                //                    // this will automatically load the stats if not in cache
                //                    ServerStats ss = stats.getSingleServerStat(server);
                //                    totalResponseTime += ss.getResponseTimeAvg();
                //                }
                //                // weight for each server is (sum of responseTime of all servers - responseTime)
                //                // so that the longer the response time, the less the weight and the less likely to be chosen
                //                Double weightSoFar = 0.0;
                //
                //                // create new list and hot swap the reference
                //                List<Double> finalWeights = new ArrayList<Double>();
                //                for (Server server : nlb.getAllServers()) {
                //                    ServerStats ss = stats.getSingleServerStat(server);
                //                    double weight = totalResponseTime - ss.getResponseTimeAvg();
                //                    weightSoFar += weight;
                //                    finalWeights.add(weightSoFar);
                //                }
                //                setWeights(finalWeights);
            } catch (Throwable t) {
                logger.error("Exception while dynamically calculating server weights", t);
            } finally {
                serverWeightAssignmentInProgress.set(false);
            }

        }
    }

    void setWeights(List<ServerSource> weights) {
        this.accumulatedWeights = weights;
    }

    @Override
    public void initWithNiwsConfig(IClientConfig clientConfig) {
        super.initWithNiwsConfig(clientConfig);
        serverWeightTaskTimerInterval = clientConfig.get(WEIGHT_TASK_TIMER_INTERVAL_CONFIG_KEY, DEFAULT_TIMER_INTERVAL);
    }

}
