package demo;

import com.netflix.appinfo.InstanceInfo;
import lombok.extern.slf4j.Slf4j;
import org.springframework.cloud.netflix.eureka.server.event.EurekaInstanceRegisteredEvent;
import org.springframework.context.ApplicationListener;
import org.springframework.stereotype.Component;

import java.util.Objects;

/**
 * @author Tietang Wang 铁汤
 * @Date: 2017/2/16 14:05
 * @blog http://tietang.wang
 */
@Slf4j
@Component
public class EurekaInstanceRegisteredListener implements ApplicationListener<EurekaInstanceRegisteredEvent> {

    @Override
    public void onApplicationEvent(EurekaInstanceRegisteredEvent event) {
        InstanceInfo info = event.getInstanceInfo();
        if(!event.isReplication()){
            //TODO notify micro service
        }
        log.info(Objects.toString(info));
    }
}
