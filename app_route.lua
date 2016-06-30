
local json=require "cjson"
local shared = ngx.shared.discovery
local routes = ngx.shared.routes

 

function newRobin( appName )
  
	local hosts = discovery.hosts[string.upper(appName)]
 	-- ngx.log(ngx.ERR,"^^^^^^^^^", json.encode(discovery.hosts))
	
	 
	if hosts == nil then
		ngx.log(ngx.ERR, "^^^^^^^^^",  "hosts is nil", appName )
	 	return nil
	end

	

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

	 
 
	local robin =balancer:new(nil,hosts)
 
	return robin
end

function getTarget( )
	
	local uri = ngx.var.uri
	-- ngx.log(ngx.ERR,"^^^^^^^^^", uri," ",ngx.var.request_uri)
	 

 	-- ngx.log(ngx.ERR,"^^^^^^^^^", json.encode(router.routingTable))
	
	route=router:getMatchRoute(uri)

	 
	if route == nil then
		ngx.status=ngx.HTTP_NOT_FOUND
		ngx.say(" not found available target route for uri ", ngx.req.get_method() ," ", uri)
		return
	end

	targetAppName=route.app
	targetPath=router:getRouteTargetPath(route,uri)
	return targetAppName,targetPath
end

local apps_count = ngx.shared.apps_count
local api_count = ngx.shared.api_count

local targetAppName, targetPath=getTarget()

if targetAppName==nil then
	ngx.log(ngx.ERR,"^^^^^^^^^", "targetAppName is nil for uri:  ",ngx.var.request_uri)

	return
end

local appName = string.upper(targetAppName)
local hosts =discovery.hosts[targetAppName]

 
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
-- local newval,err=apps_count:incr(appName, 1)
-- if newval==nil then
-- 	apps_count:set(appName,1)
-- end
-- local newval,err=api_count:incr(ngx.var.uri, 1)
-- if newval==nil then
-- 	api_count:set(ngx.var.uri,1)
-- end 
 
ngx.ctx.appName=appName
ngx.ctx.uri=ngx.var.uri

ngx.var.bk_host= host.ip .. ":" .. host.port..targetPath




