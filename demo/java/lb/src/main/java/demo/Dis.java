package demo;

import com.netflix.loadbalancer.*;
import com.netflix.niws.loadbalancer.DiscoveryEnabledNIWSServerList;
import com.netflix.niws.loadbalancer.DiscoveryEnabledServer;

/**
 * @author Tietang Wang 铁汤
 * @Date: 2017/3/31 14:35
 * @blog http://tietang.wang
 */
public class Dis {

    public static void main(String[] args) {
        IRule rule = new BestAvailableRule();
        ServerList<DiscoveryEnabledServer> list = new DiscoveryEnabledNIWSServerList("172.16.1.248:8761");
        ServerListFilter<DiscoveryEnabledServer> filter = new ZoneAffinityServerListFilter<DiscoveryEnabledServer>();
        ZoneAwareLoadBalancer<DiscoveryEnabledServer> lb = LoadBalancerBuilder.<DiscoveryEnabledServer>newBuilder()
                .withDynamicServerList(list)
                .withRule(rule)
                .withServerListFilter(filter)
                .buildDynamicServerListLoadBalancer();
        DiscoveryEnabledServer server = (DiscoveryEnabledServer) lb.chooseServer();
        System.out.println(server);



    }
}
