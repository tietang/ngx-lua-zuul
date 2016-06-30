
local metrics = require "metrics"


local json=require "cjson"

--在指定共享缓存shared中对指定key做incr操作
local function incr(shared, key)
   local v,e = shared:incr(key, 1)
   if v ==nil then
       shared:set(key,1)
       return 1
   end
   return v
end



--在指定共享缓存shared中对指定key，累积总请求时间req_time和后端响应时间res_time
local function sumTime(shared,key,req_time,res_time )
 -- body

 local req_time_key = "REQ:"..key

 local sum = shared:get(req_time_key) or 0
 sum = sum + req_time
 shared:set(req_time_key, sum)


 local res_time_key = "RES:"..key
 local sum = shared:get(res_time_key) or 0
 sum = sum + res_time
 shared:set(res_time_key, sum)

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
incr(apps_count,appName)
incr(api_count,uri)
incr(api_count,allRequest)


--- response time
local request_time = tonumber(ngx.var.request_time) or 0
local res_time = tonumber(ngx.var.upstream_response_time) or 0
sumTime(apps_res_time,appName,request_time,res_time)
sumTime(api_res_time,uri,request_time,res_time)
sumTime(api_res_time,allRequest,request_time,res_time)

--- 2xx 4xx 5xx

local status_code = tonumber(ngx.var.status) or 0
local statusKey = status_code..""
incr(api_count,statusKey)
sumTime(api_res_time,statusKey,request_time,res_time)


-- if status_code>=200 and status_code<300 then
-- 	incr(api_count,"2xx")
-- 	sumTime(api_res_time,"2xx",request_time,res_time)
-- end

-- if status_code>=400 and status_code<500 then
-- 	incr(api_count,"4xx")
-- 	sumTime(api_res_time,"4xx",request_time,res_time)
-- end

-- if status_code>=500 then
-- 	incr(api_count,"5xx")
-- 	sumTime(api_res_time,"5xx",request_time,res_time)
-- end
