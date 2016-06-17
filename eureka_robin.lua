
local robinMeta=require "robin"
local apps = ngx.shared.apps

local json=require "cjson"

local appHostsJson = apps["appHosts"]

local robins={}
ngx.log(ngx.ERR, "1 ^^^^^^^^^",  appHostsJson )

if appHostsJson == nil then
	ngx.log(ngx.ERR, "^^^^^^^^^",  "appHostsJson is nil" )
 	return robins
end

local appHosts = json.decode(appHostsJson)


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

for name, app in pairs(appHosts) do
	ngx.log(ngx.ERR, "2 ^^^^^^^^^",  name )
    local robin =robinMeta:new(nil,app.hosts)
    robins[name]=robin
    -- table.insert(robins, name, robin)
end

return robins

