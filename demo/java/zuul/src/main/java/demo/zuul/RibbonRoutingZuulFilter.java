package demo.zuul;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.netflix.hystrix.exception.HystrixRuntimeException;
import com.netflix.loadbalancer.Server;
import com.netflix.zuul.exception.ZuulException;
import lombok.extern.slf4j.Slf4j;
import org.apache.commons.lang.StringUtils;
import org.springframework.cloud.netflix.ribbon.support.RibbonRequestCustomizer;
import org.springframework.cloud.netflix.zuul.filters.ProxyRequestHelper;
import org.springframework.cloud.netflix.zuul.filters.route.RibbonCommand;
import org.springframework.cloud.netflix.zuul.filters.route.RibbonCommandContext;
import org.springframework.cloud.netflix.zuul.filters.route.RibbonCommandFactory;
import org.springframework.cloud.netflix.zuul.filters.route.RibbonRoutingFilter;
import org.springframework.http.client.ClientHttpResponse;

import java.io.InterruptedIOException;
import java.net.SocketTimeoutException;
import java.util.List;
import java.util.Map;

/**
 * @author Tietang Wang 铁汤
 * @Date: 2017/4/24 13:36
 * @blog http://tietang.wang
 */
@Slf4j
public class RibbonRoutingZuulFilter extends RibbonRoutingFilter {

    private RouterStats routerStats = new RouterStats();

    public RibbonRoutingZuulFilter(
            ProxyRequestHelper helper,
            RibbonCommandFactory<?> ribbonCommandFactory,
            List<RibbonRequestCustomizer> requestCustomizers) {
        super(helper, ribbonCommandFactory, requestCustomizers);
    }


    public RibbonRoutingZuulFilter(RibbonCommandFactory<?> ribbonCommandFactory) {
        super(ribbonCommandFactory);
    }


    protected ClientHttpResponse forward(RibbonCommandContext context) throws Exception {
        Map<String, Object> info = this.helper.debug(context.getMethod(),
                                                     context.getUri(), context.getHeaders(), context.getParams(),
                                                     context.getRequestEntity());

        RibbonCommand command = this.ribbonCommandFactory.create(context);
        Mark serviceMark = new Mark(routerStats);
        try {
            ClientHttpResponse response = command.execute();
            this.helper.appendDebug(info, response.getStatusCode().value(),
                                    response.getHeaders());
            Server server = RouterStats.get();

            if (server == null) {
                log.info("not found server");
            } else {
                serviceMark.setName(server.getHostPort());
                serviceMark.end(RouterStats.RollingNumberEvent.SUCCESS);
            }


            return response;
        } catch (HystrixRuntimeException ex) {
            return handleExceptionInner(info, serviceMark, ex);
        }finally {

        }

    }

    protected ClientHttpResponse handleExceptionInner(
            Map<String, Object> info, Mark serviceMark,
            HystrixRuntimeException ex) throws ZuulException {
        try {
            return super.handleException(info, ex);
        } catch (ZuulException e) {
            Throwable cause = e.getCause();
            if (cause instanceof SocketTimeoutException
                    || cause instanceof InterruptedIOException
                    || cause.getClass().getName().equals("org.apache.http.conn.ConnectTimeoutException")
                    || cause.getClass().getName().equals("org.apache.http.conn.ConnectTimeoutException")) {
                serviceMark.end(RouterStats.RollingNumberEvent.FAILURE);
            }
            throw e;
        }
    }

    static class Mark {

        private long start;
        private String name;
        private RouterStats routerStats;

        public Mark(RouterStats routerStats) {
            this.routerStats = routerStats;
        }

        public Mark(String name, RouterStats routerStats) {
            this.name = StringUtils.isEmpty(name) ? "/" : name;
            this.routerStats = routerStats;
            this.start();
        }

        private void start() {
            start = System.nanoTime();
        }

        public void setName(String name) {
            this.name = name;
        }

        public long end(RouterStats.RollingNumberEvent event) {
            if (name == null) throw new NullPointerException("name is null");
            long end = System.nanoTime();
            long s = (end - start) / 1000000;
            routerStats.getAndIncrement(name, event, s);
            return s;
        }
    }

}
