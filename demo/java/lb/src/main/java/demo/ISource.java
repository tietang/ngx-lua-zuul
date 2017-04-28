package demo;

/**
 * @author Tietang Wang 铁汤
 * @Date: 2016/9/21 15:58
 * @blog http://tietang.wang
 */
public interface ISource extends Comparable<ISource> {

    long getWeight();

    long getCurrentWeight();

    long getEffectiveWeight();

    long getMaxFails();

    boolean isBackup();

    boolean isDown();

    void setCurrentWeight(long currentWeight);
}
