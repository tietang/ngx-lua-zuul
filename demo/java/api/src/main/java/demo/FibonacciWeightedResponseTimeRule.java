package demo;

import com.netflix.loadbalancer.ILoadBalancer;
import com.netflix.loadbalancer.Server;
import com.netflix.loadbalancer.WeightedResponseTimeRule;

import java.util.ArrayList;
import java.util.List;

/**
 * @author Tietang Wang 铁汤
 * @Date: 2016/12/23 16:12
 * @blog http://tietang.wang
 */
public class FibonacciWeightedResponseTimeRule extends WeightedResponseTimeRule {

    private volatile List<Double> accumulatedWeights = new ArrayList<Double>();

    public Server choose(ILoadBalancer lb, Object key) {
        if (lb == null) {
            return null;
        }
        Server server = null;

        while (server == null) {
            // get hold of the current reference in case it is changed from the other thread
            List<Double> currentWeights = accumulatedWeights;
            if (Thread.interrupted()) {
                return null;
            }
            List<Server> allList = lb.getAllServers();

            int serverCount = allList.size();

            if (serverCount == 0) {
                return null;
            }

            int serverIndex = 0;

            // last one in the list is the sum of all weights
            double maxTotalWeight = currentWeights.size() == 0 ? 0 : currentWeights.get(currentWeights.size() - 1);
            // No server has been hit yet and total weight is not initialized
            // fallback to use round robin
            if (maxTotalWeight < 0.001d) {
                server = super.choose(getLoadBalancer(), key);
                if (server == null) {
                    return server;
                }
            } else {
                // generate a random weight between 0 (inclusive) to maxTotalWeight (exclusive)
                double randomWeight = maxTotalWeight;
                // pick the server index based on the randomIndex
                int n = 0;
                for (Double d : currentWeights) {
                    if (d >= randomWeight) {
                        serverIndex = n;
                        break;
                    } else {
                        n++;
                    }
                }

                server = allList.get(serverIndex);
            }

            if (server == null) {
                /* Transient. */
                Thread.yield();
                continue;
            }

            if (server.isAlive()) {
                return (server);
            }

            // Next.
            server = null;
        }
        return server;
    }

}
