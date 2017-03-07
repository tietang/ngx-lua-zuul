package demo;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.netflix.appinfo.InstanceInfo;
import com.netflix.discovery.EurekaClient;
import com.netflix.discovery.shared.Applications;
import lombok.extern.slf4j.Slf4j;
import org.springframework.aop.framework.Advised;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.boot.web.servlet.FilterRegistrationBean;
import org.springframework.cloud.client.discovery.EnableDiscoveryClient;
import org.springframework.cloud.netflix.hystrix.EnableHystrix;
import org.springframework.cloud.netflix.zuul.EnableZuulProxy;
import org.springframework.context.annotation.Bean;
import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.ResponseBody;

import java.lang.reflect.Method;
import java.util.List;

/**
 * @author Tietang Wang 铁汤
 * @Date: 16/7/12 15:05
 * @blog http://tietang.wang
 */
@SpringBootApplication
@EnableDiscoveryClient
@EnableZuulProxy
@EnableHystrix
@Controller
@Slf4j
public class Application {

    @Autowired
    EurekaClient eurekaClient;


    @RequestMapping("/test")
    @ResponseBody
    public String test() throws Exception {

        Object bean = null;
        if (eurekaClient instanceof Advised) {
            bean = ((Advised) eurekaClient).getTargetSource().getTarget();
        }
        if (bean instanceof Advised) {
            bean = ((Advised) bean).getTargetSource().getTarget();
        }

        Method method =
                ReflectUtils.getMethod(bean.getClass(), "fetchRegistry", boolean.class);
        log.debug("target method is {}", method);
        method.setAccessible(true);
        method.invoke(bean, true);


        Applications apps = eurekaClient.getApplications();
        com.netflix.discovery.shared.Application app = apps.getRegisteredApplications("zuul");
        System.out.println(new ObjectMapper().writeValueAsString(eurekaClient.getApplications()));


        List<InstanceInfo> infos = app.getInstances();
        for (InstanceInfo info : infos) {
            if (info.getMetadata() != null) {
                info.setActionType(InstanceInfo.ActionType.MODIFIED);
                info.setStatus(InstanceInfo.InstanceStatus.DOWN);
            }
        }


        System.out.println(new ObjectMapper().writeValueAsString(eurekaClient.getApplications()));


        return "test";
    }


    @Bean
    public FilterRegistrationBean filterRegistrationBean() {
        FilterRegistrationBean bean = new FilterRegistrationBean();
        bean.setFilter(new StatsFilter());
        bean.addUrlPatterns(new String[]{"/*"});


        return bean;
    }

    public static void main(String[] args) {
        SpringApplication.run(Application.class, args);
    }

}