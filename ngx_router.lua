-- local balancer = require "ngx.balancer"
local _M = {}
 
-- local routingTable = {
--    stripPrefix=false,
--    routes={

--       {sourcePath="/app1/v1/user",app="app1",targetPath="/v1/user",stripPrefix=false},
--       {sourcePath="/app1/v2/user",app="app1",targetPath="/app1/v2/user",stripPrefix=false},
--       {sourcePath="/app2/*",app="app2",targetPath="/app20/*",stripPrefix=true},
--       {sourcePath="/app3/*",app="app3",stripPrefix=false},
--       {sourcePath="/app4/*",app="app4",stripPrefix=true}
--    }
   
-- }
local json=require "cjson"
_M.routingTable={
   stripPrefix=false,
   routes={}
}

function _M:addRoute(route)
   if not route then
      return
   end
-- print(dump(route))
   local isInit=initRoute(self.routingTable,route)
   if isInit then 
      table.insert(self.routingTable.routes,route)
   end
   -- print(dump(route))


end
 
function _M:setRoutingTable(routingTable)
   if not routingTable then
      return
   end
  
   for k,v in pairs(routingTable.routes) do
    -- print(dump(v))
      self:addRoute(v)
   end 
  -- print(dump(self.routingTable))
end

function dump(o)
   if type(o) == 'table' then
      local s = '{ '
      for k,v in pairs(o) do
         if type(k) ~= 'number' then k = '"'..k..'"' end
         s = s .. '['..k..'] = ' .. dump(v) .. ','
      end
      return s .. '} '
   else
      return tostring(o)
   end
end


function initRoute(routingTable,route)
   if not route or not route.sourcePath then 
      return false
   end

   local sourceFuzzyMatchIndex=string.find(route.sourcePath,"/**",1)
   if sourceFuzzyMatchIndex and sourceFuzzyMatchIndex>0 then
      route.sourceIsFuzzyMatch= true
      route.sourcePrefix=string.sub(route.sourcePath,1,sourceFuzzyMatchIndex)
   end

   if route.targetPath then
      local targetFuzzyMatchIndex=string.find(route.targetPath,"/**",1)
      if targetFuzzyMatchIndex and targetFuzzyMatchIndex>0 then
         route.targetIsFuzzyMatch = true
         route.targetPrefix=string.sub(route.targetPath,1,targetFuzzyMatchIndex)
      end   
   end

   if route.stripPrefix == nil and routingTable.stripPrefix ~= nil then
      route.stripPrefix = routingTable.stripPrefix
   end

   return true
  
end

function _M:getMatchRouteTargetPath( path )
   
   return getMatchRouteTargetPath(self.routingTable,path)
end

 

function _M:getMatchRoute(path) 
    -- ngx.log(ngx.ERR, "$$$$$$:", json.encode(self.routingTable))
   -- print( "$$$$$$:", json.encode(self.routingTable))
   return getMatchRoute(self.routingTable,path)
end

function _M:getRouteTargetPath(route,path )

   return getRouteTargetPath(route,path )
end

function getMatchRouteTargetPath( routingTable, path )
   local route = getMatchRoute(routingTable,path)
   if not route then
      return nil
   end
 
   return getRouteTargetPath(route,path)
end

function getMatchRoute(routingTable, path)

   for k,v in pairs(routingTable.routes) do
      if  isMatch(path,v) then
         return v
      end
   end
   return nil
end


function getRouteTargetPath(route,path )

   local tpath = path
   local isStrip= false

   if route.targetPath then
  
      if route.targetFuzzyMatchIndex and route.targetFuzzyMatchIndex>0 then
         if route.targetPath  then
            route.targetPrefix=string.sub(route.targetPath,1,route.targetFuzzyMatchIndex)
         end
         tpath=  path
         isStrip=true
      else
         return route.targetPath
      end
   else
      isStrip=true
   end

   if isStrip and route.stripPrefix then
      if route.targetPrefix then
         return route.targetPrefix..string.sub(tpath,string.len(route.sourcePrefix)+1)
      else
         return  string.sub(tpath,string.len(route.sourcePrefix))
      end
   else
      if route.targetPrefix then
         return route.targetPrefix..string.sub(tpath,2)
      else
          return tpath
      end
   end
end



function isMatch(path,route)

   if route.sourceIsFuzzyMatch then
    
      local foundSub = string.find(path, route.sourcePrefix,1)
      if foundSub and foundSub==1 then
         return true
      else
         return false
      end

   else 
      if path==route.sourcePath then
         return true
      else
         return false
      end
   end

end

return _M
 