--
-- User: Tietang Wang 铁汤 
-- Date: 16/8/18 13:58
-- Blog: http://tietang.wang
--

globalConfig = require "config"
middlewares = require "middleware"
json = require "cjson"


middlewares:useByName("metrics")
middlewares:useByName("eureka")


middlewares:init()

