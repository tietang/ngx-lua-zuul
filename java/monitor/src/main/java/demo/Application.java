package demo;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.boot.context.embedded.FilterRegistrationBean;
import org.springframework.cloud.client.discovery.EnableDiscoveryClient;
import org.springframework.cloud.netflix.turbine.EnableTurbine;
import org.springframework.cloud.netflix.turbine.stream.EnableTurbineStream;
import org.springframework.cloud.netflix.zuul.EnableZuulProxy;
import org.springframework.context.annotation.Bean;
import org.springframework.stereotype.Controller;

/**
 * @author Tietang Wang 铁汤
 * @Date: 16/7/12 15:05
 * @blog http://tietang.wang
 */
@SpringBootApplication
@EnableDiscoveryClient
@EnableTurbineStream
@EnableTurbine
@Controller
public class Application {


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