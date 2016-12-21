package demo;

/**
 * @author Tietang Wang 铁汤
 * @Date: 2016/10/27 18:12
 * @blog http://tietang.wang
 */
public class Re {

    public static void main3(String[] args) {
        hash("fdss",4);
        hash("fdss2",4);
    }

    static final int hash(Object key, int n) {
        int h;
        h = key.hashCode();
        System.out.println(Integer.toBinaryString(h));
        int x = h >>> 16;

        System.out.println(Integer.toBinaryString(x));
        h = h ^ x;

        System.out.println(Integer.toBinaryString(h));

        h = (n - 1) & h;
        System.out.println(Integer.toBinaryString(h));

        return h;
    }
}
