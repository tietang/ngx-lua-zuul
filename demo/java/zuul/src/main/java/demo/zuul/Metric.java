package demo.zuul;

import lombok.Data;

import java.util.Date;

/**
 * @author Tietang Wang 铁汤
 * @Date: 2017/4/25 11:07
 * @blog http://tietang.wang
 */
@Data
public class Metric<T extends Number> {

    private final String name;
    private T value;
    private Date timestamp;

    public Metric(String name) {
        this.name = name;
    }

    public String toString() {
        return "Metric [name=" + this.name + ", value=" + this.value + ", timestamp=" + this.timestamp + "]";
    }

}