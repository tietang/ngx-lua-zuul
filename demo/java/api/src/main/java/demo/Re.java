package demo;

import com.google.common.collect.Lists;
import com.netflix.loadbalancer.BaseLoadBalancer;
import com.netflix.loadbalancer.LoadBalancerBuilder;
import com.netflix.loadbalancer.Server;
import com.netflix.loadbalancer.ServerList;
import com.netflix.loadbalancer.reactive.LoadBalancerCommand;
import com.netflix.loadbalancer.reactive.ServerOperation;
import com.netflix.ribbon.RibbonRequest;
import com.netflix.ribbon.proxy.annotation.Http;
import com.netflix.ribbon.proxy.annotation.Var;
import rx.Observable;

import java.net.HttpURLConnection;
import java.net.URL;
import java.util.List;

/**
 * @author Tietang Wang 铁汤
 * @Date: 2016/10/27 18:12
 * @blog http://tietang.wang
 */
public class Re {

    public static void main(String[] args) {
        //        Api movieService = Ribbon.from(Api.class);
        //        Observable<String> result = movieService.recommendationsByUserId("user1").observe();

        ServerList<Server> serverList = new ServerList<Server>() {
            @Override
            public List<Server> getInitialListOfServers() {
                return Lists.newArrayList(
                        new Server("www.baidu.com", 80),
                        new Server("www.qq.com", 80),
                        new Server("www.163.com", 80));
            }

            @Override
            public List<Server> getUpdatedListOfServers() {
                return Lists.newArrayList(
                        new Server("www.baidu.com", 80),
                        new Server("www.qq.com", 80),
                        new Server("www.163.com", 80));
            }
        };

        BaseLoadBalancer loadBalancer = LoadBalancerBuilder.<Server>newBuilder()
                .withRule(new FibonacciWeightedResponseTimeRule())
                .buildFixedServerListLoadBalancer(
                        serverList.getInitialListOfServers());


        for (int i = 0; i < 1000; i++) {
            LoadBalancerCommand.<String>builder()
                    .withLoadBalancer(loadBalancer)
                    .build()
                    .submit(new ServerOperation<String>() {
                        @Override
                        public Observable<String> call(Server server) {

                            URL url;
                            try {
                                url = new URL("http://" + server.getHost() + ":" + server.getPort());
                                HttpURLConnection conn = (HttpURLConnection) url.openConnection();
                                return Observable.just(conn.getResponseMessage());
                            } catch (Exception e) {
                                return Observable.error(e);
                            }
                        }
                    }).toBlocking().single();

            if (i % 100 == 0) {
                System.out.println(loadBalancer.getLoadBalancerStats());
            }
        }
        System.out.println("=== Load balancer stats ===");
        System.out.println(loadBalancer.getLoadBalancerStats());
    }


}

interface Api {

    @Http(
            method = Http.HttpMethod.GET,
            uri = "/users/{userId}/recommendations"
    )
    RibbonRequest<String> recommendationsByUserId(@Var("userId") String userId);
}