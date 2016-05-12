-- local balancer = require "ngx.balancer"
local _M = {}

_M.routingTable={
   stripPrefix=false,
   routes={}
}

function _M.addRoute(route)
   table.insert(self.routingTable,route)
end
 
function _M:setRoutingTable(routingTable)
  self.routingTable=routingTable
end

function _M:getMatchRouteTargetPath( routingTable, path )
   local route = self.getMatchRoute(routingTable,path)
   if route.stripPrefix == nil and routingTable.stripPrefix ~= nil then
      route.stripPrefix = routingTable.stripPrefix
   end
   return getRouteTargetPath(route,path)
end

function _M.getMatchRoute(routingTable, path)

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
 
      if not route.targetFuzzyMatchIndex then
         route.targetFuzzyMatchIndex=string.find(route.targetPath,"/**",1)
     
      end
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

      if not route.fuzzyMatchIndex then
         route.fuzzyMatchIndex= string.find(route.sourcePath,"/**",1)
      end 

      if not route.prefix then
         route.prefix=string.sub(route.sourcePath,1,route.fuzzyMatchIndex)
      end   
    
    

      --print(string.format("%s %d %d",tpath,index,string.len(route.prefix)))
      if route.targetPrefix then

         return route.targetPrefix..string.sub(tpath,string.len(route.prefix)+1)

      else
         return  string.sub(tpath,string.len(route.prefix))

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
 
   if not route.fuzzyMatchIndex then
      route.fuzzyMatchIndex= string.find(route.sourcePath,"/**",1)
   end

   if route.fuzzyMatchIndex and route.fuzzyMatchIndex>0 then
      if not route.prefix then
         route.prefix=string.sub(route.sourcePath,1,route.fuzzyMatchIndex)
      end
      local foundSub = string.find(path, route.prefix,1)
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
 