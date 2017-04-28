package demo;

/**
 * @author Tietang Wang 铁汤
 * @Date: 2017/1/9 14:12
 * @blog http://tietang.wang
 */
public class FibonacciHelper {

    public static long ceilingGet(long[][] tables, long key, boolean smoothness, boolean isTenMillisecond) {
        int index = isTenMillisecond ? 0 : 1;

        for (int i = 0; i < tables.length; i++) {
            long[] kv = tables[i];
            long k = kv[index];
            long v = kv[2];

            if (key <= k) {
                if (i == 0 || !smoothness) {
                    return v;
                }
                long[] kv0 = tables[i - 1];
                long k0 = kv0[index];
                long v0 = kv0[2];
                long diffk = k - k0;
                long diffv = v - v0;
                //                long r = v0 + diffv * ((key - k0) / diffk);
                long r = Math.round(v0 + ((double) diffv) * ((double) (key - k0) / (double) diffk));
                //                System.out.println(v0 + ((double)diffv) * ((double) (key - k0) / (double)diffk));
                //                System.out.printf("%d,%d,%d,%d,%d,%d \n", key, k0, k, v0, v, r);
                return r;
            }
        }
        return 1l;
    }
}
