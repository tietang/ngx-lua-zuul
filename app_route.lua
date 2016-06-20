
local json=require "cjson"
local shared = ngx.shared.apps
local routes = ngx.shared.routes

 

function newRobin( appName )
	-- body
	local robinMeta=require "robin"
	 
	local appHostJson = shared:get(string.upper(appName))

 
	ngx.log(ngx.ERR, "1 ^^^^^^^^^",  appHostJson )

	if appHostJson == nil then
		ngx.log(ngx.ERR, "^^^^^^^^^",  "appHostsJson is nil" )
	 	return robins
	end

	local appHost = json.decode(appHostJson)


	--local robin={
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
	--}

	 
 
	local robin =robinMeta:new(nil,appHost)
 
	return robin
end

function getTarget( )
	
	local uri = ngx.var.uri
	-- ngx.log(ngx.ERR,"^^^^^^^^^", uri," ",ngx.var.request_uri)
	 
	local router = require "router2"
	local routingKeysStr = routes:get("ROUTERS")
	ngx.log(ngx.ERR,"^^^^^^^^^", routingKeysStr)
	local routingKeys = json.decode(routingKeysStr)
	local route=router:getMatchRoute(uri,routingKeys,routes)
	if route == nil then
		ngx.status=ngx.HTTP_NOT_FOUND
		ngx.say(" not found available target route for uri ", ngx.req.get_method() ," ", uri)
		return
	end

	targetAppName=route.app
	targetPath=router:getRouteTargetPath(route,uri)
	return targetAppName,targetPath
end


local targetAppName, targetPath=getTarget()
local appName = string.upper(targetAppName)
local hosts =shared:get(appName)

 
ngx.log(ngx.ERR,"$$$$$$: targetAppName=", targetAppName,",targetPath=",targetPath)

 
ngx.log(ngx.ERR, "^^^^^^^^^",  targetAppName )
local robin = newRobin(targetAppName)

ngx.log(ngx.ERR, "^^^^^^^^^",  json.encode(robin) )



if robin==nil then
	ngx.status=ngx.HTTP_NOT_FOUND
	ngx.say(" not found available target instance for uri ", ngx.req.get_method() ," ", uri)
	return
end
 
host=robin:next()

ngx.log(ngx.ERR,"^^^^^^^^^", host.hostStr)
 -- ngx.req.set_uri(targetPath, true) 
-- ngx.var.targetUri=targetPath

ngx.var.bk_host= host.ip .. ":" .. host.port..targetPath

 


