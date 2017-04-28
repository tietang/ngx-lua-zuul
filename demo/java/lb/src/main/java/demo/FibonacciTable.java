package demo;

/**
 * @author Tietang Wang 铁汤
 * @Date: 2017/1/4 15:42
 * @blog http://tietang.wang
 */
public class FibonacciTable {

    final static double GoldenSelection = (Math.sqrt(5) - 1) / 2;

    static long[][] FibonacciTable = {
            {0l, 1l, 1000l},
            {1l, 10l, 996l},
            {2l, 20l, 992l},
            {3l, 30l, 988l},
            {5l, 50l, 981l},
            {8l, 80l, 970l},
            {13l, 130l, 951l},
            {21l, 210l, 922l},
            {34l, 340l, 874l},
            {55l, 550l, 798l},
            {89l, 890l, 680l},
            {144l, 1440l, 508l},
            {233l, 2330l, 285l},
            {377l, 3770l, 48l},
            {610l, 6100l, 10l},
            {987l, 9870l, 6l},
            {1597l, 15970l, 1l}
    };


    public static void main(String[] args) {

        System.out.println(getCeiling(-1));
        System.out.println(getCeiling(0));
        System.out.println(getCeiling(1));
        System.out.println(getCeiling(2));
        System.out.println(getCeiling(3));
        System.out.println(getCeiling(30));
        for (int i = 0; i < 100; i++) {
            long v = getCeiling(i * 10 + 1);
            System.out.println(v);
        }
    }


    public static long getCeiling(long key) {
        long value = FibonacciHelper.ceilingGet(FibonacciTable, key, true, false);
        return value;
    }

    public static Long getCeilingByTenMillisecond(long key) {
        long value = FibonacciHelper.ceilingGet(FibonacciTable, key, true, true);
        return value;
    }
}
