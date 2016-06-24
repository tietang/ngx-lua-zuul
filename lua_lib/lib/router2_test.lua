local router = require "router2"
 
local json=require "cjson"

--  /app1/v1/user=app1,/v1/user
--  /app1/v1/user=app1,/app1/v1/user
--  app1, /app1/**=app1,/app1/**
--  /app1x/**=app1,/app1/**
local keys = {}
local routes = {}
function routes:get( key )
  return self[key]
end


local routingTable = {
   stripPrefix=false,
   routes={

      {sourcePath="/app1/v1/user",app="app1",targetPath="/v1/user",stripPrefix=false},
      {sourcePath="/app1/v2/user",app="app1",targetPath="/app1/v2/user",stripPrefix=false},
      {sourcePath="/app2/**",app="app2",targetPath="/app20/**",stripPrefix=true},
      {sourcePath="/app3/**",app="app3",stripPrefix=false},
      {sourcePath="/app4/**",app="app4",stripPrefix=true}
   }
   
}
-- router:setRoutingTable(routingTable)
for k,v in pairs(routingTable.routes) do
    table.insert(keys,v.sourcePath)
    routes[v.sourcePath]=json.encode(v)
end

 
 
 
print(router:getMatchRouteTargetPath("/app2/v3/cc",keys,routes).."") -- /app20/v2/cc
print(router:getMatchRouteTargetPath("/app4/v3/cc",keys,routes).."") -- /v3/cc
print(router:getMatchRouteTargetPath("/app4/v3/e",keys,routes).."") -- /v3/e
print(router:getMatchRouteTargetPath("/app1/v1/user",keys,routes).."") -- /v1/user
print(router:getMatchRouteTargetPath("/app1/v2/user",keys,routes).."") -- /app1/v2/user
print(router:getMatchRouteTargetPath("/app2/v3/f",keys,routes).."") -- /app20/v3/f
print(router:getMatchRouteTargetPath("/app3/v3/f",keys,routes).."") -- /app3/v3/f

route=router:getMatchRoute("/app2/v3/cc",keys,routes)
print(route.app,route.targetPath)

 
 