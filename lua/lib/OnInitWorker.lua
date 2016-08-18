--
-- User: Tietang Wang 铁汤 
-- Date: 16/8/18 13:59
-- Blog: http://tietang.wang
--

rateLimiter:init(ngx.shared.metrics, globalConfig.limiter)
rateLimiter:start()

discovery:init("http://172.16.1.248:8761/eureka/")
discovery:schedule()

