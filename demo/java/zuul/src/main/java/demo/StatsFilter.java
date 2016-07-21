package demo;

import com.google.common.util.concurrent.AtomicDouble;

import javax.servlet.*;
import javax.servlet.annotation.WebFilter;
import java.io.IOException;
import java.util.concurrent.atomic.AtomicLong;

/**
 * @author Tietang Wang 铁汤
 * @Date: 16/7/12 17:07
 * @blog http://tietang.wang
 */
@WebFilter
public class StatsFilter implements Filter {

    public static AtomicLong count = new AtomicLong();
    public static AtomicDouble time = new AtomicDouble();

    @Override
    public void init(FilterConfig filterConfig) throws ServletException {

    }

    @Override
    public void doFilter(
            ServletRequest request, ServletResponse response, FilterChain chain) throws IOException, ServletException {
        count.incrementAndGet();
        long start = System.currentTimeMillis();
        chain.doFilter(request, response);
        long end = System.currentTimeMillis();
        time.addAndGet(end - start);
    }

    @Override
    public void destroy() {

    }
}
