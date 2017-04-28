package demo.zuul;

import lombok.Data;

import java.util.ArrayList;
import java.util.Collections;
import java.util.List;

/**
 * @author Tietang Wang 铁汤
 * @Date: 2016/9/21 15:49
 * @blog http://tietang.wang
 */

public class RobinRound {

    @Data
    static class AvailableSources {

        private long totalWeight;
        private List<ISource> availableSources = new ArrayList<>(10);

        public void add(ISource source) {
            availableSources.add(source);
        }

    }


    public static <T extends ISource> T next(List<T> list) {
        if (list == null || list.isEmpty()) {
            return null;
        }
        AvailableSources sources = totalWeight(list);
        if (sources == null || sources.getAvailableSources() == null || sources.getAvailableSources().size() == 0)
            return null;
        for (ISource source : sources.getAvailableSources()) {
            source.setCurrentWeight(source.getWeight() + source.getCurrentWeight());
        }
        T selected = Collections.max(list);

        if (selected == null) {
            return null;
        }
        selected.setCurrentWeight(selected.getCurrentWeight() - sources.getTotalWeight());
        return selected;
    }

    public static AvailableSources totalWeight(List<? extends ISource> list) {
        AvailableSources sources = new AvailableSources();
        for (ISource source : list) {
            if (!source.isDown() && !source.isBackup()) {
                sources.setTotalWeight(sources.getTotalWeight() + source.getWeight());
                sources.add(source);
            }
        }
        return sources;
    }


    public static void main2(String[] args) {
        List<TestSource> list = new ArrayList<>();

        list.add(new TestSource("a", 3, 0));
        list.add(new TestSource("b", 2, 0));
        list.add(new TestSource("c", 0, 0));
        //        list.add(new Source("d", 1, 0));
        //        list.add(new Source("e", 1, 0));

        for (int i = 0; i < 24; i++) {
            //            System.out.println(list);
            //            next(list);
            System.out.println(next(list));
        }
    }

    @Data
    //    @ToString
    static class TestSource implements ISource {

        private String name;
        private String ip;
        private long port;
        private Integer sport;
        //
        private long weight;//权重
        private long currentWeight;//当前权重
        private long effectiveWeight;
        private long maxFails;//在一段时间内的最大失败次数,固定值
        private long failimeout;//"一段时间"的值，固定值
        private boolean isBackup;
        private boolean isDown;


        public TestSource(String name, int weight, int currentWeight) {
            this.name = name;
            this.weight = weight;
            this.currentWeight = currentWeight;
        }


        @Override
        public int compareTo(ISource o) {
            long cc = this.getCurrentWeight() - o.getCurrentWeight();
            if (cc > 0) {
                return 1;
            } else if (cc < 0) {
                return -1;
            }
            return 0;
        }


        @Override
        public String toString() {
            return "Source{" +
                    "name='" + name + '\'' +
                    ", weight=" + weight +
                    ", currentWeight=" + currentWeight +
                    '}';
        }


        //        @Override
        //        public String toString() {
        //            return "" + currentWeight;
        //        }
    }
}