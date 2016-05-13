local router = require "router"
 

--  /app1/v1/user=app1,/v1/user
--  /app1/v1/user=app1,/app1/v1/user
--  app1, /app1/**=app1,/app1/**
--  /app1x/**=app1,/app1/**
local routingTable = {
   stripPrefix=false,
   routes={

      {sourcePath="/app1/v1/user",app="app1",targetPath="/v1/user",stripPrefix=false},
      {sourcePath="/app1/v2/user",app="app1",targetPath="/app1/v2/user",stripPrefix=false},
      {sourcePath="/app2/*",app="app2",targetPath="/app20/*",stripPrefix=true},
      {sourcePath="/app3/*",app="app3",stripPrefix=false},
      {sourcePath="/app4/*",app="app4",stripPrefix=true}
   }
   
}
router:setRoutingTable(routingTable)
 


print(router:getMatchRouteTargetPath("/app2/v3/cc").."\n")
print(router:getMatchRouteTargetPath("/app4/v3/cc").."\n")
print(router:getMatchRouteTargetPath("/app4/v3/e").."\n")
print(router:getMatchRouteTargetPath("/app1/v1/user").."\n")
print(router:getMatchRouteTargetPath("/app1/v2/user").."\n")
print(router:getMatchRouteTargetPath("/app2/v3/f").."\n")
print(router:getMatchRouteTargetPath("/app3/v3/f").."\n")

