 local json=require "cjson"


function incr(shared, key)
    local v,e = shared:incr(key, 1)
    if v ==nil then
        shared:set(key,1)
        return 1
    end
    return v
end



local apps_count = ngx.shared.apps_count
local apps_res_time = ngx.shared.apps_res_time
local api_res_time= ngx.shared.api_res_time
local api_count = ngx.shared.api_count

 
-- count:{key}
-- sum:{key}
-- max:{key}
-- min:{key}

-- count_60:{key}
-- sum_60:{key}
-- max_60:{key}
-- min_60:{key}

local appName=ngx.ctx.appName

local newval,err=apps_count:incr(appName, 1)
if newval==nil then
	apps_count:set(appName,1)
end
local newval,err=api_count:incr(ngx.var.uri, 1)
if newval==nil then
	api_count:set(ngx.var.uri,1)
end 
 
 -- req:
local request_time = tonumber(ngx.var.request_time)

local request_time_var = "REQ:"..appName
local sum = apps_res_time:get(request_time_var) or 0
sum = sum + request_time
apps_res_time:set(request_time_var, sum)

local request_time_var_url = "REQ:"..ngx.var.uri
local sum1 = api_res_time:get(request_time_var_url) or 0
sum1 = sum1 + request_time
api_res_time:set(request_time_var_url, sum1)


--RES:
local res_time = tonumber(ngx.var.upstream_response_time)

local res_time_var = "RES:"..appName
local sum = apps_res_time:get(res_time_var) or 0
sum = sum + res_time
apps_res_time:set(res_time_var, sum)

local res_time_var_url = "RES:"..ngx.var.uri
local sum = api_res_time:get(res_time_var_url) or 0
sum = sum + res_time
api_res_time:set(res_time_var_url, sum)       


  