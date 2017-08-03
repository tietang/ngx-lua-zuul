package demo.zuul;

import com.netflix.loadbalancer.*;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.util.ArrayList;
import java.util.List;
import java.util.stream.Collectors;

/**
 * @author Tietang Wang 铁汤
 * @Date: 2017/4/24 13:09
 * @blog http://tietang.wang
 */


public class BestAvailableRule extends ClientConfigEnabledRoundRobinRule {


    private LoadBalancerStats loadBalancerStats;
    private static Logger stats = LoggerFactory.getLogger("STATS");
    private List<ServerSource> serverSources = new ArrayList<>();

    @Override
    public Server choose(Object key) {
        List<Server> serverList = getLoadBalancer().getAllServers();
        if (loadBalancerStats == null) {

            return next(key);
        }

        int minimalConcurrentConnections = Integer.MAX_VALUE;
        long currentTime = System.currentTimeMillis();
        Server chosen = null;

        if (chosen == null) {
            chosen = next(key);
        }

        RouterStats.set(chosen);

        return chosen;
    }

    private Server next(Object key) {
        List<Server> serverList = getLoadBalancer().getAllServers();
        serverSources = toSources(serverList);
        ServerSource source = RobinRound.next(serverSources);
        return source.getServer();
    }

    public List<ServerSource> getServerSources() {
        return serverSources;
    }

    private List<ServerSource> toSources(List<Server> serverList) {
        return serverList.stream().map(s -> {
            ServerSource source = source(s);
            return source;
        }).collect(Collectors.toList());
    }

    private ServerSource source(Server server) {
        ServerSource[] ss = new ServerSource[1];
        serverSources.stream().forEach(s -> {
            if (s.getServer().equals(server)) {
                ss[0] = s;
            }
        });
        if (ss[0] == null) {
            ss[0] = new ServerSource(server.getHostPort());
            ss[0].setServer(server);
        }
        return ss[0];
    }


    @Override
    public void setLoadBalancer(ILoadBalancer lb) {
        super.setLoadBalancer(lb);
        if (lb instanceof AbstractLoadBalancer) {
            loadBalancerStats = ((AbstractLoadBalancer) lb).getLoadBalancerStats();
        }
    }


}