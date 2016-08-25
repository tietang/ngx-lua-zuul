local json = require "cjson"


-- local kv = {
-- 	{
-- 		key="",
-- 		value=0
-- 	}
-- }

function show(shared, shared_time)


    local keys = shared:get_keys()
    for k, key in pairs(keys) do
        local value = shared:get(key)
        local reqtime = shared_time:get("REQ:" .. key) or 0
        local restime = shared_time:get("RES:" .. key) or 0
        local avg = restime / value
        local avg2 = reqtime / value


        ngx.say(key .. "= count: " .. value .. "," .. avg2 .. ", req_time: " .. reqtime .. ", res_time: " .. restime .. "")
    end
    ngx.say("\n")
end

--ngx.say("<pre>")
--show(ngx.shared.apps_count, ngx.shared.apps_res_time)
--show(ngx.shared.api_count, ngx.shared.api_res_time)
--
--
--
--
--show(ngx.shared.metrics, ngx.shared.metrics_time)
--
--ngx.say("</pre>")
--


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

--ngx.say('<meta http-equiv="refresh" content="5">')

sayHtml()