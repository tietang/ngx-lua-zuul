package demo;

/**
 * @author Tietang Wang 铁汤
 * @Date: 2017/1/4 15:42
 * @blog http://tietang.wang
 */
public class FibonacciGoldenTable {

    final static double GoldenSelection = (Math.sqrt(5) - 1) / 2;

    static long[][] FibonacciGoldenTable = null;


    static {
        double j = 1;
        long m = 0, n = 1;
        FibonacciGoldenTable = new long[31][];
        FibonacciGoldenTable[0] = new long[]{0l, 0l, 1000l};
        for (int i = 1; i <= 30; i++) {

            //
            long fms = m + n;
            double fw = weight(fms * 10);
            long fweight = Math.round(fw);
            FibonacciGoldenTable[i] = new long[]{fms, fms * 10, fweight};
            System.out.printf("%d,%d,%d \n", fms, fms * 10, fweight);
            m = n;
            n = fms;

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


        System.out.println(ceilingGet(-1));
        System.out.println(ceilingGet(0));
        System.out.println(ceilingGet(1));
        System.out.println(ceilingGet(2));
        System.out.println(ceilingGet(3));
        System.out.println(ceilingGet(30));
    }

    public static Long ceilingGet(long key) {
        for (long[] kv : FibonacciGoldenTable) {
            long k = kv[0];
            long v = kv[2];
            if (key <= k) {
                return v;
            }
        }
        return 1l;
    }

    public static Long get(long key) {
        for (long[] kv : FibonacciGoldenTable) {
            long k = kv[0];
            long v = kv[2];
            if (key <= k) {
                return v;
            }
        }
        return 1l;
    }

}
