package demo;

import java.util.Map;
import java.util.TreeMap;

/**
 * @author Tietang Wang 铁汤
 * @Date: 2016/10/10 15:59
 * @blog http://tietang.wang
 */
public class CavesMain {

    static TreeMap<Long, Long> map = new TreeMap<>();

    static {
        map.put(1l, 999l);
        map.put(10l, 996l);
        map.put(20l, 992l);
        map.put(30l, 988l);
        map.put(50l, 981l);
        map.put(80l, 970l);
        map.put(130l, 951l);
        map.put(210l, 922l);
        map.put(340l, 874l);
        map.put(550l, 798l);
        map.put(890l, 680l);
        map.put(1440l, 508l);
        map.put(2330l, 285l);
        map.put(3770l, 48l);
        map.put(6100l, 10l);
        map.put(9870l, 6l);
        map.put(15970l, 1l);
    }

    public static void main(String[] args) {

        int size = 3;
        int weight = 1000 / size;

        int end = 1000;
        System.out.println(Math.max(-1, 0));

        for (int i = 0; i < 1000; i++) {

            int rt = i * 10;
            System.out.print(rt);
            System.out.print(",");
            //            System.out.print(weight * (0.39 - Math.atan(i*0.1-2)/3.9 ));
            cu3(weight, size, rt);
            System.out.println();
        }


    }

    private static void cu3(int weight, int size, long rt) {
        Long key=map.ceilingKey(rt);

        Long value = map.get(key);
        if (value == null) value = 1l;

        long v = value.longValue() / size;

        if (v <= 1l) {
            v = 1l;
        }
        System.out.print(v);
    }

    private static void cu2(int weight, int rt) {
        System.out.print(weight * Math.max((1 - (Math.atan(0.000618 * rt))), 0.001d));
    }

    private static void cu(int weight, int rt) {
        System.out.print(weight * Math.max((1 - (Math.atan(rt * 0.1 * 0.01) / 1.372)), 0.001d));
    }
}
