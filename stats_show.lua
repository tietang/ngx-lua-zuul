local json=require "cjson"


-- local kv = {
-- 	{
-- 		key="",
-- 		value=0
-- 	}
-- }

function show(shared,shared_time)
 

    local keys = shared:get_keys()
    for k,key in pairs(keys) do
        local  value= shared:get(key)
        local reqtime = shared_time:get("REQ:"..key) or 0
        local restime = shared_time:get("RES:"..key) or 0
        local avg = restime/value
        local avg2 = reqtime/value
      

        ngx.say(key .. "= count: " .. value .. ","..avg2..", req_time: "..reqtime..", res_time: "..restime.. "")
    end
    ngx.say("\n")
   
end

ngx.say("<pre>")
show(ngx.shared.apps_count,ngx.shared.apps_res_time)
show(ngx.shared.api_count, ngx.shared.api_res_time )




show(ngx.shared.metrics, ngx.shared.metrics_time )

ngx.say("</pre>")

