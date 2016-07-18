 -- local json=require "cjson"


-- local kv = {
-- 	{
-- 		key="",
-- 		value=0
-- 	}
-- }

 
function show(shared,shared_time)
	local kv = {}


	local keys = shared:get_keys()
	for i,key in pairs(keys) do
	 	 local  value= shared:get(key)
	 	 local reqtime = shared_time:get("REQ:"..key) or 0
	 	 local restime = shared_time:get("RES:"..key) or 0
	 	 local avg = restime/value
	 	 local avg2 = reqtime/value
	 	table.insert(kv,{key=key,value=value,resValue=restime,reqValue=reqtime})

	end
 
	
	return kv
	

end



local kvapp=show(ngx.shared.apps_count,ngx.shared.apps_res_time)
local kvapi=show(ngx.shared.api_count, ngx.shared.api_res_time) 
local metrics=show(ngx.shared.metrics, ngx.shared.metrics_time )

local kv = {
	apps=kvapp,
	apis=kvapi,
	metrics=metrics
}
ngx.say(json.encode(kv))

