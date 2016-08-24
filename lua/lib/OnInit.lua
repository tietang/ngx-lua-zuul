--
-- User: Tietang Wang 铁汤 
-- Date: 16/8/18 13:58
-- Blog: http://tietang.wang
--

globalConfig = require "config"
discovery = require "discovery"
json = require "cjson"
balancer = require "robin"
router = require "router"
rateLimiter = require "LeakyBucket"
--middlewares = require "middlewares"

metricsTimer=require "metrics_timer"


--middlewares.useByName("metrics")
--middlewares.useByName("eureka")

