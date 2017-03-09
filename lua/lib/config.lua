--
-- User: Tietang Wang 铁汤 
-- Date: 16/8/8 14:26
-- Blog: http://tietang.wang
--

local _M = {}
-- 指定eureka server url，多个用数组表示
_M.eureka = {
    serverUrl ={"http://172.16.2.248:8761/eureka/","http://172.16.1.248:8761/eureka/"}
--    serverUrl ="http://172.16.1.248:8761/eureka/"
}
-- 定义route table lua 文件名称：
-- key为任意能区分业务的，值为route table lua文件名，该文件路径为当前文件同文件夹
_M.routes = {
    demoRoute="routes"
}
--
_M.metrics = {
    -- 收集计算时间窗口
    timeWindowInSeconds = 1,
    -- 最大保留size
    maxSaveSize = 10,
    -- 是否启用微服务收集
    enabledService = true,
    -- 是否启用请求收集
    enabledRequest = false,
    -- 展示最新的条目数
    showTopNum = 100
}
-- 服务限流
_M.limiter = {
    --global,service,api
    limitLevel = "global",
    -- 时间窗口,单位s 1~60s
    windowSeconds = 10,
    --最大保留size
    maxSaveSize = 10,
    -- 单位时间窗口的最大请求数,默认10k
    maxRequests = 10000,
    -- 不同微服务使用不同的限流策略，默认使用全局配置
    params = {
        ["UserService"] = { [1] = 100, [2] = 1, [3] = 60 },
    }
}

_M.robin = {
    timeWindowInSeconds = 5,
    --负载均衡共享缓存
    shared=ngx.shared.robin,

}
-- # 预先提供,调用方和服务方共同持有同样的
_M.auth = {
    type = "jwt", --none,jwt,
    loginUrl = "/_admin/login",
    logoutUrl = "/_admin/logout",
    homeUrl = "/home",
}

_M.jwt = {
    secret = {
        default = "your-own-jwt-secret",
        ["userService"] = "7c4c8d455df311e6811590b11c1a55bf"
    }
}

--_M.urlGroup[]

return _M



