--
-- User: Tietang Wang 铁汤 
-- Date: 16/8/25 09:26
-- Blog: http://tietang.wang
--



local accept = ngx.req.get_headers()["Accept"]

local default_type = ngx.var.default_type

if default_type == "application/json" or string.match(accept, "application/json") then
    local metrics = middlewares.report("metrics")
    ngx.say(json.encode(metrics))
    return
end

middlewares.reportHtml("metrics")