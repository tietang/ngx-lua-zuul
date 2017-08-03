package star;

import java.lang.instrument.Instrumentation;

/**
 * @author Tietang Wang 铁汤
 * @Date: 2017/6/5 17:25
 * @blog http://tietang.wang
 */
public class PStar {

    public static void premain(String agentOps, Instrumentation inst) {
        System.out.println(agentOps);
        inst.addTransformer(new MonitorTransformer());
    }
}
