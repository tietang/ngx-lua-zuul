--
-- User: Tietang Wang 铁汤
-- Date: 16/8/24 17:14
-- Blog: http://tietang.wang
--


discovery = require "plugins.eureka.discovery"
--json = require "cjson"
balancer = require "plugins.eureka.robin"
router = require "plugins.eureka.router"
rateLimiter = require "plugins.eureka.LeakyBucket"
weight = require "plugins.eureka.weight"
strings = require "utils.strings"
utils = require "utils.utils"
fibonacci = require "plugins.eureka.fibonacci"
url = require "utils.url"
local _M = {
    name = "eureka",
    upstream_name = "_eureka_route",
    version = "1.0"
}



local function newRobin(appName)

    local hosts = discovery.hosts[string.upper(appName)]
    --     ngx.log(ngx.ERR,"^^^^^^^^^", json.encode(discovery.hosts))

    if hosts == nil then
        ngx.log(ngx.ERR, "^^^^^^^^^", "hosts is nil", appName)
        return nil
    end


    --local robin={
    --        {
    --            "lastRenewalTimestamp": 1452042964223,
    --            "hostName": "192.168.99.1",
    --            "ip": "192.168.99.1",
    --            "id": "192.168.99.1:gateaway",
    --            "status": "UP",
    --            "sport": null,
    --            "name": "GATEAWAY",
    --            "port": 8080
    --        }
    --}

    local robin = balancer:new(nil, hosts)

    return robin
end

local function getTarget()

    local uri = ngx.var.uri
    -- ngx.log(ngx.ERR,"^^^^^^^^^", uri," ",ngx.var.request_uri)


    --     ngx.log(ngx.ERR,"^^^^^^^^^", json.encode(router.routingTable))

    route = router:getMatchRoute(uri)


    if route == nil then
        ngx.status = ngx.HTTP_NOT_FOUND
        ngx.say(" not found available target route for uri ", ngx.req.get_method(), " ", uri)
        return
    end
    ngx.log(ngx.ERR, "^^^^^^^^^", uri, " ", route.targetPath, " ", strings:isHttpUrl(route.targetPath))
    if route.targetPath and strings:isHttpUrl(route.targetPath) then
        ngx.ctx.by_upstream = "false"
        ngx.ctx.by_bk_host = "true"
        ngx.var.by_upstream = "false"
        ngx.var.by_bk_host = "true"
    else
        ngx.ctx.by_upstream = "true"
        ngx.ctx.by_bk_host = "false"
        ngx.var.by_upstream = "true"
        ngx.var.by_bk_host = "false"
    end
    ngx.log(ngx.ERR, "^^^^^^^^^", ngx.ctx.by_bk_host, " ", ngx.ctx.by_upstream)
    ngx.log(ngx.ERR, "^^^^^^^^^", json.encode(route))

    targetAppName = route.app
    targetPath = router:getRouteTargetPath(route, uri)
    ngx.log(ngx.ERR, "$$$$$$: targetAppName=", targetAppName, ",targetPath=", targetPath)
    return targetAppName, targetPath
end

local function limit(limitLevel, givenlimitLevel, key)

    -- 流量全局限制
    if limitLevel == givenlimitLevel and not rateLimiter:acquire(key) then
        ngx.status = ngx.HTTP_SERVICE_UNAVAILABLE
        --    ngx.log(ngx.ERR,"-----------", "can't acquire ")
        ngx.say(" not available for ", limitLevel, " ", key or "", ", ", ngx.req.get_method(), " ", ngx.var.uri)
        return true
    end
    return false
end

function _M:init()
end

function _M:initWorker()

    rateLimiter:init(ngx.shared.limiter, globalConfig.limiter)
    rateLimiter:start()

    discovery:init(unpack(globalConfig.eureka.serverUrl))
    discovery:schedule()

    weight:init(ngx.shared.lb)
    weight:start()
end

function _M:rewrite()
    self:access1()


    if ngx.ctx.by_upstream == "true" then
        -- rewrite  the current request's (parsed) URI
        ngx.req.set_uri(ngx.ctx.targetPath)
    end
end

function _M:access1()

    local limitLevel = "global"
    if globalConfig and globalConfig.limiter and globalConfig.limiter.limitLevel then
        limitLevel = globalConfig.limiter.limitLevel
    end

    --local auth_jwt = require "auth_jwt"
    --if config.auth.type == "jwt" and not auth_jwt.jwt_verify() then
    --    ngx.status = ngx.HTTP_UNAUTHORIZED
    --    ngx.say(" not available ", ngx.req.get_method(), " ", uri)
    --    return true
    --end


    --    if limit(limitLevel, "global", nil) then return end
    --    if limit(limitLevel, "api", ngx.var.uri) then return end

    local targetAppName, targetPath = getTarget()
    ngx.log(ngx.ERR, "$$$$$$: targetAppName=", targetAppName, ",targetPath=", targetPath)
    if targetAppName == nil then
        ngx.log(ngx.ERR, "Not found target app name for uri:  ", ngx.var.request_uri)
        ngx.say("targetAppName is nil for uri:  " .. ngx.var.request_uri)
        return
    end



    if limit(limitLevel, "service", targetAppName) then return end

    local appName = string.upper(targetAppName)
    --         ngx.log(ngx.ERR,"$$$$$$: targetAppName=", targetAppName,",targetPath=",targetPath)
    ngx.log(ngx.ERR, "^^^^^^^^^", ngx.ctx.by_bk_host, "", ngx.ctx.by_upstream)

    -- 通过域名代理
    if ngx.ctx.by_bk_host == "true" then
        ngx.ctx.pass = true --是否能正确代理
        ngx.ctx.appName = appName
        ngx.ctx.uri = ngx.var.uri
        u = url.parse(targetPath)
        ngx.log(ngx.ERR, "^^^^^^^^^", targetAppName, " ", targetPath)
        -- direct
        --         ngx.var.bk_host = u.host .. ":" .. (u.port or '') .. targetPath
        -- by upstream & balancer

--        if strings.startswith(targetPath, "https://") then
--            ngx.var.bk_host = string.sub(targetPath, 9)
--        end
--        if strings.startswith(targetPath, "http://") then
--            ngx.var.bk_host = string.sub(targetPath, 8)
--        end
        ngx.var.bk_host =targetPath
        ngx.ctx.targetPath = ngx.var.uri
        ngx.ctx.b_host = u.host
        ngx.ctx.b_port = u.port or 80
        ngx.var.by_bk_host = ngx.ctx.by_bk_host
        ngx.var.by_upstream = ngx.ctx.by_upstream

        ngx.log(ngx.ERR, "^^^^^^^^^", ngx.ctx.b_host, " ", ngx.ctx.b_port)
        ngx.log(ngx.ERR, "^^^^^^^^^", ngx.ctx.by_bk_host, " ", ngx.ctx.by_upstream)
        return
    end

    local robin = newRobin(targetAppName)

    --    ngx.log(ngx.ERR, "^^^^^^^^^", json.encode(robin))

    if robin == nil then
        ngx.status = ngx.HTTP_NOT_FOUND
        ngx.say(" not found available target instance for uri ", ngx.req.get_method(), " ", uri)
        return
    end

    host = robin:next()

    if not host then
        ngx.say(" not found available target instance for uri ", ngx.req.get_method(), " ", uri)
        return
    end

    -- ngx.log(ngx.ERR,"^^^^^^^^^", host.hostStr)
    -- ngx.req.set_uri(targetPath, true)
    -- ngx.var.targetUri=targetPath
    -- local newval,err=apps_count:incr(appName, 1)
    -- if newval==nil then
    -- 	apps_count:set(appName,1)
    -- end
    -- local newval,err=api_count:incr(ngx.var.uri, 1)
    -- if newval==nil then
    -- 	api_count:set(ngx.var.uri,1)
    -- end
    ngx.ctx.pass = true
    ngx.ctx.appName = appName
    ngx.ctx.uri = ngx.var.uri



    -- direct
    -- ngx.var.bk_host = host.ip .. ":" .. host.port .. targetPath
    -- by upstream & balancer
    ngx.var.bk_host = "http://"..self.upstream_name .. targetPath
    ngx.ctx.targetPath = targetPath
    ngx.ctx.b_host = host.ip
    ngx.ctx.b_port = host.port
    ngx.var.by_bk_host = ngx.ctx.by_bk_host
    ngx.var.by_upstream = ngx.ctx.by_upstream

    --    ngx.log(ngx.ERR, "host: ", ngx.ctx.b_host, " ", ngx.ctx.b_port)
    ngx.log(ngx.ERR, "$$$$$$: by_bk_host=", ngx.var.by_bk_host, ", by_upstream=", ngx.var.by_upstream)
end


function _M:balance()
    ngx.log(ngx.ERR, "$$$$$$: balancer: ", ngx.ctx.b_host, ":", ngx.ctx.b_port, ", by_upstream=", ngx.var.by_upstream)
    if ngx.ctx.by_upstream == "true" then
        local balancer = require "ngx.balancer"

        -- well, usually we calculate the peer's host and port
        -- according to some balancing policies instead of using
        -- hard-coded values like below

        --    ngx.log(ngx.ERR, "^^^^^^^^^： ", ngx.ctx.b_host, ngx.ctx.b_port)

        local ok, err = balancer.set_current_peer(ngx.ctx.b_host, ngx.ctx.b_port)
        --    ok, err = balancer.set_more_tries(2)
        --    state_name, status_code = balancer.get_last_failure()
        --    ok, err = balancer.set_timeouts(connect_timeout, send_timeout, read_timeout)


        if not ok then
            ngx.log(ngx.ERR, "failed to set the current peer: ", err)
            return ngx.exit(500)
        end
    end
end


function _M:log()

    weight:onLog()
end



return _M