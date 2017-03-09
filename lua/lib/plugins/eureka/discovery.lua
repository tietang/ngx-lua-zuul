local _M = {
    _VERSION = "1.0",
    requestTimes = 0,
    loadTime = os.date(),
    apps = {},
    hosts = {},
}


local http = require "resty.http"
local eureka = require "plugins.eureka.eureka"
-- https://github.com/pintsized/lua-resty-http



--[[

启动定时任务，获取在线服务器列表

--]]
local KEY_LAST_EXECUTED_PID = "last_executed_pid"
local KEY_LAST_EXECUTED_PID_TIME = "last_executed_pid_time"
local KEY_LAST_EXECUTED_TIME = "last_executed_time"
local KEY_ROUTERS = "__ROUTERS"


local function readRoute(routeStr)


    ngx.log(ngx.ERR, "route", routeStr)
    local lines = string.split(routeStr, "\n")

    for i, line in ipairs(lines) do

        if not (line == "") then
            ngx.log(ngx.ERR, "routes", line)
            local words = string.split(line, "=")
            if table.maxn(words) == 2 then

                local sourcePath = words[1]
                local appPath = string.split(words[2], ",")
                if table.maxn(appPath) == 2 then
                    local appName, targetPath = appPath[1], appPath[2]
                    local route = { sourcePath = sourcePath, app = appName, targetPath = targetPath, stripPrefix = false }
                    router:addRoute(route)
                    ngx.log(ngx.ERR, "add route: ", line)
                end
            end
        end
    end
end

local function readRoutes()
    for k, v in pairs(globalConfig.routes) do
        local route = require(v)
        readRoute(route)
    end
end

string.split = function(s, p)
    local rt = {}
    string.gsub(s, '[^' .. p .. ']+', function(w) table.insert(rt, w) end)
    return rt
end


function _M:init(...)
    self.router = router or {}
--    ngx.log(ngx.ERR, "arg type","    ", type(...))
    local arg = { ... }
--    ngx.log(ngx.ERR, "arg type","    ", type(arg))
    ngx.log(ngx.ERR, "arg", arg[1])
--    eureka:setDiscoveryServers(arg)
    eureka:setDiscoveryServers(unpack(arg))

    readRoutes()
end

function _M:schedule()

    local shared = ngx.shared.discovery
    local interval = 10

    function getAndSet(premature, shared)


        local c = ngx.worker.count()
        local id = ngx.worker.id()
        local currentWorkerPid = ngx.worker.pid() --ngx.var.pid --

        local last_executed_pid = shared:get(KEY_LAST_EXECUTED_PID)
        local last_executed_time = shared:get(KEY_LAST_EXECUTED_TIME)
        local keyPidTime = KEY_LAST_EXECUTED_PID_TIME .. "-" .. currentWorkerPid
        local last_executed_pid_time = shared:get(keyPidTime)




        local now = ngx.now()
        local rt = shared:get("requestTimes")
        -- ngx.log(ngx.ERR," ",currentWorkerPid," ",currentWorkerPid%c,",",ngx.time()%c,",",rt)

        -- if last_executed_pid_time == nil then
        -- last_executed_pid_time=now
        -- end
        -- ngx.log(ngx.ERR,"worker count:",c,", PID:",currentWorkerPid,",",last_executed_time,",",now-last_executed_time,",",interval-0.1)
        -- <=NGINX 1.9.1+ 旨在同一时间只有一个worker执行定时任务，并且不一致在同一个worker执行，需要运行一段时间调整近似
        -- if last_executed_pid ==nil or last_executed_time == nil or last_executed_pid_time==nil
        --     or (
        --             (now-last_executed_time) >= interval-0.1 --如果最后执行时间>=设定间隔-0.1，-0.1是纠正偶尔存在的执行时间偏差
        --         and last_executed_pid ~= currentWorkerPid -- 如果当前worker pid != 最后一次worker pid
        --         and (now-last_executed_pid_time) >= interval*c-0.1 --如果当前worker最后执行时间 >= 设定间隔*worker数量 - 0.1
        --     ) then
        -- if  id % c==0 then -->=NGINX 1.9.1+
        if true then -->=NGINX 1.9.1+
            -- getApps()
            local content, hosts, apps = _M:getAllApps()
            self:dealApps()



            shared:set(KEY_LAST_EXECUTED_TIME, now)
            shared:set(KEY_LAST_EXECUTED_PID, currentWorkerPid)
            shared:set(keyPidTime, now)
            --

            -- ngx.log(ngx.ERR, "getAllApps", json.encode(hosts))
        end

        local ok, err = ngx.timer.at(interval, getAndSet, shared)
        -- local last=shared:get("lastRenewalTimestamp")
        -- ngx.log(ngx.DEBUG, "ok:", ok, " err:", err)
    end

    local ok, err = ngx.timer.at(1, getAndSet, shared)
    -- ngx.log(ngx.DEBUG, "ok:", ok, " err:", err)
end

function _M:say()
    ngx.say(json.encode(self.hosts or {}) .. "<br/>")
end

function _M:dealApps()



    if self.hosts ~= nil then
        for k, v in pairs(self.hosts) do

            local appName = string.lower(k)
            --- 默认以serviceId名称匹配
            local route = { sourcePath = "/" .. appName .. "/**", app = appName, stripPrefix = true }
            router:addRoute(route)
        end

    else
        ngx.log(ngx.ERR, "hosts is nil")
    end

    -- ngx.log(ngx.ERR, "routes:", json.encode(router.routingTable))
end



function isUP(url)

    local httpc = http.new()
    httpc:set_timeout(1000)
    local res, err = httpc:request_uri(url, {
        method = "GET",
    })

    if not res or res.status == ngx.HTTP_OK then
        ngx.log(ngx.ERR, "failed to request :", err)
        return false
    end
end



function _M:getHttpEndpont(path)
    local shared = ngx.shared.apps
    local apps = shared:get("apps")
    local uri = ngx.var.uri
    local first, last = string.find(uri, "/", 2)
    local appName = string.upper(string.sub(s, 0, first - 1))
    -- local hosts=self.hosts[appName]
    local hostsStr = shared:get(string.upper(appName))
    local hosts = json.decode(hostsStr)
    local x = self:getAndSetCountByAppName(appName) % table.nums(hosts) + 1
    return hosts[x]
end

function _M:getAndSetCountByAppName(appName)
    local shared = ngx.shared.apps_count
    return getAndSetCountByAppName(shared, appName)
end

function getAndSetCountByAppName(shared, appName)

    local v, e = shared:incr(appName, 1)
    if v == nil then
        shared:set(appName, 1)
        return 1
    end
    return v
end


function _M:getAllApps()

    --- 从Eureka server获取注册的apps
    local hosts, apps = eureka:getAllAppHosts()


    self.apps = apps
    self.hosts = hosts
    -- ngx.log(ngx.ERR, "content=",content,", requestTimes: ",self.requestTimes)
    return hosts, apps
end

function _M:getHosts()

    -- ngx.log(ngx.ERR, json.encode(self.hosts))
    return self.hosts
end


-- function _M.getHostByName(shared,name,balance)
--     local apps=shared:get("apps")
--     self.apps=

-- end

-- apps={
--     ["CALM_EDGE"]={
--         {
--             name="CALM_EDGE",
--             id= "192.168.99.1:calm_edge",
--             hostName="192.168.99.1",
--             ip="192.168.99.1",
--             port=8080,
--             sport=null,
--             status="UP",
--             lastRenewalTimestamp=1451030859398

--         }
--     }
-- }




return _M



-- {
--     "apps": [
--         {
--             "name": "CALM_EDGE",
--             "hosts": [
--                 {
--                     "name": "CALM_EDGE",
--                     "id": "192.168.99.1:calm_edge",
--                     "hostName": "192.168.99.1",
--                     "ip": "192.168.99.1",
--                     "port": 8080,
--                     "sport": null,
--                     "status": "UP",
--                     "lastRenewalTimestamp": 1451030859398
--                 }
--             ]
--         }
--     ],
--     "timestamp": 1451030794105
-- }
-- local http=require "resty.http"
-- local httpc=http.new()
-- httpc:set_timeout(1000)
-- local res,err=httpc:request_uri("http://127.0.0.1:8761/v1/apps",{
--     method ="GET"
-- })

-- if not res then
--     ngx.say("failed to request :",err)
--     return
-- end
-- local content=res.body
-- ngx.log(ngx.ERR,content)



