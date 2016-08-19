--
-- User: Tietang Wang 铁汤 
-- Date: 16/8/18 13:59
-- Blog: http://tietang.wang
--
metricsTimer:init(ngx.shared.metrics,globalConfig.metrics)
metricsTimer:start()

rateLimiter:init(ngx.shared.limiter, globalConfig.limiter)
rateLimiter:start()

discovery:init(globalConfig.eureka.serverUrl)
discovery:schedule()

