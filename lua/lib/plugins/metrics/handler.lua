--
-- User: Tietang Wang 铁汤 
-- Date: 16/8/24 14:00
-- Blog: http://tietang.wang
--
local utils = require "utils.utils"
local strings = require("utils.strings")

metricsTimer = require "plugins.metrics.metrics_timer"

local _M = {
    name = "metrics",
    _VERSION = "1.0",
}


function _M:init()
end

function _M:initWorker()
    metricsTimer:init(ngx.shared.metrics, globalConfig[self.name])
    metricsTimer:start()
end


--在指定共享缓存shared中对指定key，累积总请求时间req_time和后端响应时间res_time
local function sumTime(shared, key, req_time, res_time)
    local req_time_key = "REQ:" .. key
    utils:incr(shared, req_time_key, req_time or 0)

    local res_time_key = "RES:" .. key
    utils:incr(shared, res_time_key, res_time or 0)
end

function _M:log()

    --- app统计
    local apps_count = ngx.shared.apps_count
    local apps_res_time = ngx.shared.apps_res_time
    local appName = ngx.ctx.appName or "NULL"
    --- count

    --- API 操作
    local api_res_time = ngx.shared.api_res_time
    local api_count = ngx.shared.api_count


    local uri = ngx.var.uri
    local allRequest = "AllRequest"
    --- count
    utils:incr(apps_count, appName, 1)
    utils:incr(api_count, uri, 1)
    utils:incr(api_count, allRequest, 1)


    --- response time
    local request_time = tonumber(ngx.var.request_time) or 0
    local res_time = tonumber(ngx.var.upstream_response_time) or 0
    -- ngx.log(ngx.ERR,"^^^^^^^^^  ", request_time,",  ",res_time)

    sumTime(apps_res_time, appName, request_time, res_time)
    sumTime(api_res_time, uri, request_time, res_time)
    sumTime(api_res_time, allRequest, request_time, res_time)

    --- 2xx 4xx 5xx

    local status_code = tonumber(ngx.var.status) or 0
    local statusKey = status_code .. ""
    utils:incr(api_count, statusKey)
    sumTime(api_res_time, statusKey, request_time, res_time)

    -- metrics
    local now = ngx.time()
    local windowSeconds = globalConfig.metrics.timeWindowInSeconds
    local time_key = windowSeconds * math.floor(now / windowSeconds)

    utils:incr(ngx.shared.metrics, time_key, 1)
    sumTime(ngx.shared.metrics_time, time_key, request_time, res_time)

    -- ngx.log(ngx.ERR,"^^^^^^^^^  ", ngx.var.upstream_connect_time,",  ",ngx.var.upstream_response_time)
end

function _M:report()
    return showAll()
end

function _M:reportHtml()
    sayHtml()
end



local function show(shared, shared_time)
    local kv = {}

    local keys = shared:get_keys()
    for i, key in pairs(keys) do
        local value = shared:get(key)
        local reqtime = shared_time:get("REQ:" .. key) or 0
        local restime = shared_time:get("RES:" .. key) or 0
        local avg = restime / value
        local avg2 = reqtime / value
        table.insert(kv, { key = key, value = value, resValue = restime, reqValue = reqtime })
    end

    return kv
end


local function showAll()
    local kvapp = show(ngx.shared.apps_count, ngx.shared.apps_res_time)
    local kvapi = show(ngx.shared.api_count, ngx.shared.api_res_time)
    local metrics = show(ngx.shared.metrics, ngx.shared.metrics_time)

    return {
        apps = kvapp,
        apis = kvapi,
        metrics = metrics
    }
end



local function showH5(shared, shared_time)

    ngx.say('<table style=" border:solid # cccccc 1 px; collapse:border - collapse:collapse; " border=" 1 " cellspacing=" 0 " cellpadding=" 0 ">')
    ngx.say("   <tr>")
    ngx.say("       <th>name</th>")
    ngx.say("       <th>count</th>")
    ngx.say("       <th>avg time (s)</th>")
    ngx.say("       <th>request time (s)</th>")
    ngx.say("       <th>response time (s)</th>")
    ngx.say("   </tr>")
    local keys = shared:get_keys()
    for k, key in pairs(keys) do
        local value = shared:get(key)
        local reqtime = shared_time:get("REQ:" .. key) or 0
        local restime = shared_time:get("RES:" .. key) or 0
        local avg = restime / value
        local avg2 = reqtime / value
        --        ngx.say(key .. "= count: " .. value .. "," .. avg2 .. ", req_time: " .. reqtime .. ", res_time: " .. restime .. "")
        ngx.say("   <tr>")
        ngx.say("       <td>" .. key .. "</td>")
        ngx.say("       <td>" .. value .. "</td>")
        ngx.say("       <td>" .. avg2 .. "</td>")
        ngx.say("       <td>" .. reqtime .. "</td>")
        ngx.say("       <td>" .. restime .. "</td>")
        ngx.say("   </tr>")
    end
    ngx.say("</table>\n")
end

local function sayHtml()
    ngx.say("<pre>")
    ngx.say("<div>apps</div>")

    showH5(ngx.shared.apps_count, ngx.shared.apps_res_time)
    ngx.say("<div>api</div>")
    showH5(ngx.shared.api_count, ngx.shared.api_res_time)
    ngx.say("<div>metrics</div>")
    showH5(ngx.shared.metrics, ngx.shared.metrics_time)
    ngx.say("</pre>")
end



return _M