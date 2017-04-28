package demo;

/**
 * @author Tietang Wang 铁汤
 * @Date: 2017/1/4 15:42
 * @blog http://tietang.wang
 */
public class GoldenMeanTable {

    final static double GoldenSelection = (Math.sqrt(5) - 1) / 2;

    static long[][] GoldenMeanTable = null;

    static {
        double j = 1;
        long m = 0, n = 1;
        GoldenMeanTable = new long[31][];
        GoldenMeanTable[0] = new long[]{0l, 0l, 1000l};
        for (int i = 1; i <= 30; i++) {
            long ms = Math.round(j);
            long hms = Math.round(j * 10);
            double w = weightGolden(ms);
            long weight = Math.round(w);

            GoldenMeanTable[i] = new long[]{ms, hms, weight};
            //            System.out.printf("%d,%d,%d            \n ", ms, hms, weight);
            j = goldenSelect(j);

        }


    }

    private static double weightGolden(long value) {
        double w = 1000 * Math.max((1 - (Math.atan(value * GoldenSelection * 0.01) / (2 - GoldenSelection))),
                                   0.001d);
        return w;
    }

    private static double weight(long value) {
        return 1000 * Math.max((1 - (Math.atan(value * 0.1 * 0.01) / 1.372)), 0.001d);
    }


    private static double goldenSelect(double v) {
        return v / GoldenSelection;
    }

    public static void main(String[] args) {


        System.out.println(getCeiling(-1));
        System.out.println(getCeiling(0));
        System.out.println(getCeiling(1));
        System.out.println(getCeiling(2));
        System.out.println(getCeiling(3));
        System.out.println(getCeiling(30));
    }

    public static long getCeiling(long key) {
        long value = FibonacciHelper.ceilingGet(GoldenMeanTable, key, true, false);
        return value;
    }

    public static Long getCeilingByTenMillisecond(long key) {
        long value = FibonacciHelper.ceilingGet(GoldenMeanTable, key, true, true);
        return value;
    }
}
