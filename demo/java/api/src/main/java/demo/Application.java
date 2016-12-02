package demo;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.boot.context.embedded.FilterRegistrationBean;
import org.springframework.cloud.client.discovery.EnableDiscoveryClient;
import org.springframework.context.annotation.Bean;
import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.ResponseBody;

import java.util.Date;
import java.util.HashMap;
import java.util.Map;
import java.util.Random;

/**
 * @author Tietang Wang 铁汤
 * @Date: 16/7/12 15:05
 * @blog http://tietang.wang
 */
@SpringBootApplication
@EnableDiscoveryClient
@Controller
public class Application {

    static long Test1Sleep = 0;

    @ResponseBody
    @RequestMapping("/")
    public String home() {
        return "Hello world";
    }

    @ResponseBody
    @RequestMapping("/stats")
    public String stats() {
        return "count: " + StatsFilter.count.get() + ", time:" + StatsFilter.time.get() + " ns";
    }

    @ResponseBody
    @RequestMapping("/stats/reset")
    public String statsReset() {
        StatsFilter.count.set(0);
        StatsFilter.time.set(0);
        return "count: " + StatsFilter.count.get() + ", time:" + StatsFilter.time.get() + " ns";
    }

    @ResponseBody
    @RequestMapping("/set/{sleep}")
    public String statsReset(@PathVariable long sleep) {
        Test1Sleep = sleep;
        return "ok";
    }

    @RequestMapping({"/test1/{index}", "/test1"})
    @ResponseBody
    public Map<String, Object> testAction(@PathVariable int index) throws Exception {

        Map<String, Object> attrs = new HashMap<>();

        if (Test1Sleep > 0) {
            Thread.sleep(Test1Sleep);
        }
        if (index < 0) {
            index = 0;
        }
        if (index >= base.length) {
            index = base.length - 1;
        }
        attrs.put("content", strs[index]);

        return attrs;
    }


    @RequestMapping({"/test/{sleep}/{index}", "/test"})
    @ResponseBody
    public Map<String, Object> test(@PathVariable long sleep, @PathVariable int index) throws Exception {

        Map<String, Object> attrs = new HashMap<>();

        if (sleep > 0) {
            Thread.sleep(sleep);
        }
        if (index < 0) {
            index = 0;
        }
        if (index >= base.length) {
            index = base.length - 1;
        }
        attrs.put("content", strs[index]);

        return attrs;
    }

    @RequestMapping({"/test/g1/{size}"})
    @ResponseBody
    public Map<Object, Object> testG1(@PathVariable long size) throws Exception {

        size = size <= 0 ? 1000 : size;

        Map<Object, Object> attrs = new HashMap<>();
        int c = 0;
        double d = 0;

        for (int i = 0; i < size; i++) {
            c += random.nextInt(20);
            d += new Double(random.nextInt(100)).doubleValue() / 13;
            User user = new User();
            user.setAge(c);
            user.setDate(new Date());
            user.setName("name+" + i);
            user.setMoney(d);
            user.setDesc(getRandomString(random.nextInt(128)) + "--" + d + "--" + c);

            attrs.put(i, user);
        }

        return attrs;
    }


    @Bean
    public FilterRegistrationBean filterRegistrationBean() {
        FilterRegistrationBean bean = new FilterRegistrationBean();
        bean.setFilter(new StatsFilter());
        bean.addUrlPatterns(new String[]{"/*"});

        return bean;
    }

    static class User {

        private String name;
        private int age;
        private double money;
        private Date date;
        private String desc;

        public String getDesc() {
            return desc;
        }

        public void setDesc(String desc) {
            this.desc = desc;
        }

        public String getName() {
            return name;
        }

        public void setName(String name) {
            this.name = name;
        }

        public int getAge() {
            return age;
        }

        public void setAge(int age) {
            this.age = age;
        }

        public double getMoney() {
            return money;
        }

        public void setMoney(double money) {
            this.money = money;
        }

        public Date getDate() {
            return date;
        }

        public void setDate(Date date) {
            this.date = date;
        }
    }

    public static void main(String[] args) {
        SpringApplication.run(Application.class, args);
    }

    static String chars = "abcdefghijklmnopqrstuvwxyz0123456789";
    static Random random = new Random();
    static int base[] = {128, 256, 512, 1024, 2048, 16 * 1024, 64 * 1024, 128 * 1024};
    static String[] strs;

    static {
        strs = new String[base.length];
        for (int i = 0; i < base.length; i++) {
            strs[i] = getRandomString(base[i]);
        }

    }

    public static String getRandomString(int length) {

        StringBuffer sb = new StringBuffer();
        for (int i = 0; i < length; i++) {
            int number = random.nextInt(chars.length());
            sb.append(chars.charAt(number));
        }
        return sb.toString();
    }
}