package demo.zuul;

import com.netflix.loadbalancer.Server;
import lombok.Data;

/**
 * @author Tietang Wang 铁汤
 * @Date: 2017/1/9 16:29
 * @blog http://tietang.wang
 */
@Data
public class ServerSource implements ISource {

    private String name;
    private long weight = 1;//权重
    private long currentWeight;//当前权重
    private long effectiveWeight;
    private long maxFails;//在一段时间内的最大失败次数,固定值
    private long failedTimeout;//"一段时间"的值，固定值
    private boolean isBackup;
    private boolean isDown;
    private Server server;

    //
    private long currentFailedNumbers;
    private long currentSuccessNumbers;
    private double currentFailedResTime;
    private double currentSuccessResTime;

    public ServerSource(String name) {
        this(name, 1);
    }

    public ServerSource(String name, long weight) {
        this.name = name;
        this.weight = weight;
        this.effectiveWeight = weight;
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
        return "ServerSource{" +
                "weight=" + weight +
                ", currentWeight=" + currentWeight +
                ", effectiveWeight=" + effectiveWeight +
                ", maxFails=" + maxFails +
                ", failedTimeout=" + failedTimeout +
                ", isBackup=" + isBackup +
                ", isDown=" + isDown +
                ", server=" + server.toString() +
                '}';
    }
}
