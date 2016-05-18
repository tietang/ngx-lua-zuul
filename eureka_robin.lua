
local robinMeta=require "robin"
local apps = ngx.shared.apps

local robins={}
--local robins={
--    app1={
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
--    }
--}

for k, app in pairs(apps.apps) do
    local robin =robinMeta:new(nil,app.hosts)
    robins[app.name]=robin
end

return robins

