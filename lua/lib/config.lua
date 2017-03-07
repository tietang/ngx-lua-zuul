--
-- User: Tietang Wang 铁汤 
-- Date: 16/8/8 14:26
-- Blog: http://tietang.wang
--

local _M = {}
-- 指定eureka server url，多个用数组表示
_M.eureka = {
    serverUrl ={"http://172.16.2.248:8761/eureka/","http://172.16.1.248:8761/eureka/"}
}
-- 定义route table lua 文件名称：
-- key为任意能区分业务的，值为route table lua文件名，该文件路径为当前文件同文件夹
_M.routes = {
    demoRoute="routes"
}
_M.metrics = {
    timeWindowInSeconds = 1,
    maxSaveSize = 10,
    enabledService = true,
    enabledRequest = false,
    showTopNum = 100
}

_M.limiter = {
    limitLevel = "global", --global,service,api
    windowSeconds = 10, -- 时间窗口,单位s 1~60s
    maxSaveSize = 10, --最大保留size
    maxRequests = 10000, -- 单位时间窗口的最大请求数,默认10k
    params = {
        ["UserService"] = { [1] = 100, [2] = 1, [3] = 60 },
    }
}

_M.robin = {
    timeWindowInSeconds = 5,
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



