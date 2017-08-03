package demo.zuul;

import com.netflix.client.config.IClientConfig;
import com.netflix.client.config.IClientConfigKey;
import com.netflix.loadbalancer.*;
import lombok.extern.slf4j.Slf4j;

import java.util.ArrayList;
import java.util.List;
import java.util.Timer;
import java.util.TimerTask;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.ConcurrentMap;
import java.util.concurrent.atomic.AtomicBoolean;

/**
 * @author Tietang Wang 铁汤
 * @Date: 2017/5/3 15:15
 * @blog http://tietang.wang
 */
@Slf4j
public class BestResTimeAvailableRule extends ClientConfigEnabledRoundRobinRule {

    public static final IClientConfigKey<Integer> WEIGHT_TASK_TIMER_INTERVAL_CONFIG_KEY = WeightedResponseTimeRule.WEIGHT_TASK_TIMER_INTERVAL_CONFIG_KEY;

    public static final int DEFAULT_TIMER_INTERVAL = 5 * 1000;

    private int serverWeightTaskTimerInterval = DEFAULT_TIMER_INTERVAL;
    private volatile List<Double> accumulatedWeights = new ArrayList<Double>();


    protected AtomicBoolean serverWeightAssignmentInProgress = new AtomicBoolean(false);
    private LoadBalancerStats loadBalancerStats;
    protected Timer serverWeightTimer = null;
    String name = "unknown";

    @Override
    public Server choose(Object key) {
        if (loadBalancerStats == null) {
            return super.choose(key);
        }
        List<Server> serverList = getLoadBalancer().getAllServers();
        int minimalConcurrentConnections = Integer.MAX_VALUE;
        long currentTime = System.currentTimeMillis();
        Server chosen = null;
        for (Server server : serverList) {
            ServerStats serverStats = loadBalancerStats.getSingleServerStat(server);
            if (!serverStats.isCircuitBreakerTripped(currentTime)) {
                int concurrentConnections = serverStats.getActiveRequestsCount(currentTime);
                if (concurrentConnections < minimalConcurrentConnections) {
                    minimalConcurrentConnections = concurrentConnections;
                    chosen = server;
                }
            }
        }
        if (chosen == null) {
            return super.choose(key);
        } else {
            return chosen;
        }
    }

    @Override
    public void setLoadBalancer(ILoadBalancer lb) {
        super.setLoadBalancer(lb);
        if (lb instanceof AbstractLoadBalancer) {
            loadBalancerStats = ((AbstractLoadBalancer) lb).getLoadBalancerStats();
            name = ((BaseLoadBalancer) lb).getName();
        }
        initialize(lb);
    }


    void initialize(ILoadBalancer lb) {
        if (serverWeightTimer != null) {
            serverWeightTimer.cancel();
        }
        serverWeightTimer = new Timer("NFLoadBalancer-serverWeightTimer-"
                                              + name, true);
        serverWeightTimer.schedule(new DynamicServerWeightTask(), 0,
                                   serverWeightTaskTimerInterval);
        // do a initial run
        ServerWeight sw = new ServerWeight();
        sw.maintainWeights();

        Runtime.getRuntime().addShutdownHook(new Thread(new Runnable() {
            public void run() {
                log.info("Stopping NFLoadBalancer-serverWeightTimer-{}", name);
                serverWeightTimer.cancel();
            }
        }));
    }


    class DynamicServerWeightTask extends TimerTask {

        public void run() {
            ServerWeight serverWeight = new ServerWeight();
            try {
                serverWeight.maintainWeights();
            } catch (Exception e) {
                log.error("Error running DynamicServerWeightTask for {}", name, e);
            }
        }
    }

    class ServerWeight {

        public void maintainWeights() {
            ILoadBalancer lb = getLoadBalancer();
            if (lb == null) {
                return;
            }

            if (!serverWeightAssignmentInProgress.compareAndSet(false, true)) {
                return;
            }

            try {
                log.info("Weight adjusting job started");
                AbstractLoadBalancer nlb = (AbstractLoadBalancer) lb;
                LoadBalancerStats stats = nlb.getLoadBalancerStats();
                if (stats == null) {
                    // no statistics, nothing to do
                    return;
                }
                double totalResponseTime = 0;
                // find maximal 95% response time
                for (Server server : nlb.getAllServers()) {
                    // this will automatically load the stats if not in cache
                    ServerStats ss = stats.getSingleServerStat(server);
                    totalResponseTime += ss.getResponseTimeAvg();
                }
                // weight for each server is (sum of responseTime of all servers - responseTime)
                // so that the longer the response time, the less the weight and the less likely to be chosen
                Double weightSoFar = 0.0;

                // create new list and hot swap the reference
                List<Double> finalWeights = new ArrayList<Double>();
                for (Server server : nlb.getAllServers()) {
                    ServerStats ss = stats.getSingleServerStat(server);
                    double weight = totalResponseTime - ss.getResponseTimeAvg();
                    weightSoFar += weight;
                    finalWeights.add(weightSoFar);
                }
                setWeights(finalWeights);
            } catch (Exception e) {
                log.error("Error calculating server weights", e);
            } finally {
                serverWeightAssignmentInProgress.set(false);
            }

        }
    }

    void setWeights(List<Double> weights) {
        this.accumulatedWeights = weights;
    }

    @Override
    public void initWithNiwsConfig(IClientConfig clientConfig) {
        super.initWithNiwsConfig(clientConfig);
        serverWeightTaskTimerInterval = clientConfig.get(WEIGHT_TASK_TIMER_INTERVAL_CONFIG_KEY, DEFAULT_TIMER_INTERVAL);
    }


    private ConcurrentMap<String, RouterStats.RollingNumbers> metrics = new ConcurrentHashMap<>();


    public static class  LastResponseStats{
    }

}
