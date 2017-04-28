package demo;

/**
 * @author Tietang Wang 铁汤
 * @Date: 2017/1/4 13:57
 * @blog http://tietang.wang
 */
public class FibaonacciMain {

    final static double GoldenSelection = (Math.sqrt(5) - 1) / 2;

    //（√5-1）：2，
    public static void main(String[] args) {
        int size = 1;
        int weight = 1000 / size;

        //        System.out.println((Math.sqrt(5) - 1) / 2);
        //        double j = 1;
        //        for (int i = 1; i <= 37; i++) {
        //            j = goldenSelect(j);
        //            int v = Double.valueOf(j).intValue();
        //            System.out.print(v + "    ");
        //            int ms = Double.valueOf(j * 10).intValue();
        //            System.out.print(ms + "    ");
        //            cu3(weight, ms);
        //
        //            System.out.println();
        //        }
        int m = 0, n = 1;
        for (int i = 0; i < 37; i++) {

            int ms = m + n;
            //            System.out.print(ms + "    ");
            //            System.out.print(ms * 10 + "    ");
            double w = weight * Math.max((1 - (Math.atan(ms * GoldenSelection * 0.01) / (2 - GoldenSelection))),
                                         0.001d);
            //                        double w = weight * (0.39 - Math.atan(i*0.1-2)/3.9 );
//                        double w = weight * Math.max((1 - (Math.atan(0.000618 * 10*ms))), 0.001d);
//            double w = weight * Math.max((1 - (Math.atan(ms  * 0.00618) / 1.372)), 0.001d);
            long v = Math.round(w);

            System.out.printf("{%d,%d,%d},\n", ms, ms * 10, v);
            m = n;
            n = ms;

        }
    }

    private static void cu2(int weight, int rt) {
        System.out.print(weight * Math.max((1 - (Math.atan(0.000618 * rt))), 0.001d));
    }

    private static void cu(int weight, int rt) {
        System.out.print(weight * Math.max((1 - (Math.atan(rt * 0.1 * 0.01) / 1.372)), 0.001d));
    }

    private static void cu3(int weight, int rt) {
        System.out.print(weight * Math.max((1 - (Math.atan(rt * 0.1 * 0.01) / 1.372)), 0.001d));
    }

    private static double goldenSelect(double v) {
        return v / GoldenSelection;
    }

}
