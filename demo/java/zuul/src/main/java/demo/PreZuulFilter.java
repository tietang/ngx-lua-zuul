package demo;

import com.netflix.zuul.ZuulFilter;
import com.netflix.zuul.context.RequestContext;
import org.springframework.stereotype.Component;

/**
 * @author Tietang Wang 铁汤
 * @Date: 2016/12/14 14:37
 * @blog http://tietang.wang
 */
@Component
public class PreZuulFilter extends ZuulFilter {

    @Override
    public String filterType() {
        return "pre";
    }

    @Override
    public int filterOrder() {
        return 0;
    }

    @Override
    public boolean shouldFilter() {
        return true;
    }

    @Override
    public Object run() {
        RequestContext ctx = RequestContext.getCurrentContext();

        System.out.println(ctx.getRouteHost());
        System.out.println(ctx.getRequest().getRequestURL());
        return null;
    }
}
