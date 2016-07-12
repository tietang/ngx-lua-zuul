 local json=require "cjson"

--在指定共享缓存shared中对指定key做incr操作,增加 
local function incr(shared, key, value)
    local x = value or 1
    local v,e = shared:incr(key, x)
    if v ==nil then
        local succ,err,forcible=shared:set(key,x)
        if forcible then
          return 0,err
        else
          return x,err
        end
    end
    return v,e
end

--在指定共享缓存shared中对指定key，累积总请求时间req_time和后端响应时间res_time
local function sumTime(shared,key,req_time,res_time )


	local req_time_key = "REQ:"..key
  incr(shared,req_time_key,req_time or 0)

	local res_time_key = "RES:"..key
  incr(shared,res_time_key,res_time or 0)

end



--- app统计
local apps_count = ngx.shared.apps_count
local apps_res_time = ngx.shared.apps_res_time
local appName=ngx.ctx.appName or "NULL"
--- count




---API 操作
local api_res_time= ngx.shared.api_res_time
local api_count = ngx.shared.api_count



local uri = ngx.var.uri
local allRequest = "AllRequest"
--- count
incr(apps_count,appName,1)
incr(api_count,uri,1)
incr(api_count,allRequest,1)


--- response time
local request_time = tonumber(ngx.var.request_time) or 0
local res_time = tonumber(ngx.var.upstream_response_time) or 0
-- ngx.log(ngx.ERR,"^^^^^^^^^  ", request_time,",  ",res_time)

sumTime(apps_res_time,appName,request_time,res_time)
sumTime(api_res_time,uri,request_time,res_time)
sumTime(api_res_time,allRequest,request_time,res_time)

--- 2xx 4xx 5xx

local status_code = tonumber(ngx.var.status) or 0
local statusKey = status_code..""
incr(api_count,statusKey)
sumTime(api_res_time,statusKey,request_time,res_time)

-- metrics
local now =ngx.time()
local time_window = 60 --seconds
local time_key = time_window*math.floor(now/60)

incr(ngx.shared.metrics,time_key,1) 
sumTime(ngx.shared.metrics_time,time_key,request_time,res_time)

ngx.log(ngx.ERR,"^^^^^^^^^  ", ngx.var.upstream_connect_time,",  ",ngx.var.upstream_response_time)

