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



local _M = {
    name = "eureka",
    upstream_name="_eureka_route",
    version = "1.0"
}




local function newRobin(appName)

    local hosts = discovery.hosts[string.upper(appName)]
    -- ngx.log(ngx.ERR,"^^^^^^^^^", json.encode(discovery.hosts))

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


    -- ngx.log(ngx.ERR,"^^^^^^^^^", json.encode(router.routingTable))

    route = router:getMatchRoute(uri)


    if route == nil then
        ngx.status = ngx.HTTP_NOT_FOUND
        ngx.say(" not found available target route for uri ", ngx.req.get_method(), " ", uri)
        return
    end

    targetAppName = route.app
    targetPath = router:getRouteTargetPath(route, uri)
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

    discovery:init(globalConfig.eureka.serverUrl)
    discovery:schedule()
end

function _M:rewrite()
    self:access1()
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

    if targetAppName == nil then
        --         ngx.log(ngx.ERR,"^^^^^^^^^", "targetAppName is nil for uri:  ",ngx.var.request_uri)
        ngx.say("targetAppName is nil for uri:  " .. ngx.var.request_uri)
        return
    end

    if limit(limitLevel, "service", targetAppName) then return end

    local appName = string.upper(targetAppName)
    --         ngx.log(ngx.ERR,"$$$$$$: targetAppName=", targetAppName,",targetPath=",targetPath)
    --         ngx.log(ngx.ERR, "^^^^^^^^^",  targetAppName )
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

    ngx.ctx.appName = appName
    ngx.ctx.uri = ngx.var.uri



    -- direct
    -- ngx.var.bk_host = host.ip .. ":" .. host.port .. targetPath
    -- by upstream & balancer
    ngx.var.bk_host = self.upstream_name .. targetPath
    ngx.ctx.b_host = host.ip
    ngx.ctx.b_port = host.port
end


function _M:balance()

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

return _M