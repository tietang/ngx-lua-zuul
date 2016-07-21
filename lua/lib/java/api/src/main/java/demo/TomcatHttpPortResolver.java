package demo;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.InitializingBean;
import org.springframework.beans.factory.annotation.Autowired;
import org.apache.catalina.core.*;
import org.springframework.core.env.ConfigurableEnvironment;
import org.springframework.stereotype.Component;

import javax.management.MBeanServer;
import javax.management.MBeanServerFactory;
import javax.management.ObjectName;
import java.util.Iterator;
import java.util.Set;


/**
 * 如果是war包部署,通过此代码来获取容器http port
 *
 * @author Tietang Wang 铁汤
 * @Date: 16/7/19 09:27
 * @blog http://tietang.wang
 */

@Component
public class TomcatHttpPortResolver implements InitializingBean {

    public static final Logger LOGGER = LoggerFactory.getLogger(TomcatHttpPortResolver.class);
    @Autowired
    private ConfigurableEnvironment environment;

    @Override
    public void afterPropertiesSet() throws Exception {
        String serverPortKey = "server.port";
        int port = getHttpPort();
        if (port > 0) {
            environment.getSystemProperties().put(serverPortKey, port);
        }
    }

    public static int getHttpPort() {
        try {
            MBeanServer server = null;
            if (MBeanServerFactory.findMBeanServer(null).size() > 0) {
                server = MBeanServerFactory.findMBeanServer(null).get(0);
            }

            Set names = server.queryNames(new ObjectName("Catalina:type=Connector,*"), null);

            Iterator iterator = names.iterator();
            ObjectName name = null;
            while (iterator.hasNext()) {
                name = (ObjectName) iterator.next();

                String protocol = server.getAttribute(name, "protocol").toString();
                //                String scheme = server.getAttribute(name, "scheme").toString();
                String port = server.getAttribute(name, "port").toString();
                //                System.out.println(protocol + " : " + scheme + " : " + port);
                if (protocol.toUpperCase().contains("HTTP")) {
                    return Integer.parseInt(port);
                }

            }
        } catch (Exception e) {
            LOGGER.error("get http port ", e);
        }
        return 0;

    }

}