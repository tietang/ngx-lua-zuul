package demo;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.netflix.appinfo.InstanceInfo;
import com.netflix.discovery.EurekaClient;
import com.netflix.discovery.shared.Applications;
import demo.zuul.RibbonRoutingZuulFilter;
import lombok.extern.slf4j.Slf4j;
import org.springframework.aop.framework.Advised;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.boot.context.properties.EnableConfigurationProperties;
import org.springframework.boot.web.servlet.FilterRegistrationBean;
import org.springframework.cloud.client.discovery.EnableDiscoveryClient;
import org.springframework.cloud.netflix.hystrix.EnableHystrix;
import org.springframework.cloud.netflix.ribbon.support.RibbonRequestCustomizer;
import org.springframework.cloud.netflix.zuul.EnableZuulProxy;
import org.springframework.cloud.netflix.zuul.filters.ProxyRequestHelper;
import org.springframework.cloud.netflix.zuul.filters.route.RibbonCommandFactory;
import org.springframework.context.annotation.Bean;
import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.ResponseBody;

import java.lang.reflect.Method;
import java.util.Collections;
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
@EnableConfigurationProperties
public class Application {

    @SuppressWarnings("rawtypes")
    @Autowired(required = false)
    private List<RibbonRequestCustomizer> requestCustomizers = Collections.emptyList();

    @Autowired
    EurekaClient eurekaClient;

    @Bean
    public RibbonRoutingZuulFilter ribbonRoutingFilter(
            ProxyRequestHelper helper,
            RibbonCommandFactory<?> ribbonCommandFactory) {
        RibbonRoutingZuulFilter filter = new RibbonRoutingZuulFilter(helper,
                                                                     ribbonCommandFactory,
                                                                     this.requestCustomizers);
        return filter;
    }

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