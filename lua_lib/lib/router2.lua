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
_M.stripPrefix=false


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


function initRoute(route)
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

   if route.stripPrefix == nil  then
      route.stripPrefix = false
   end

   return true
  
end

function _M:getMatchSourcePathKey(path,keys )
   for i,v in pairs(keys) do

      if  isMatch(path,v) then
         return v
      end
   end

   -- print(path)
    -- print(dump(keys))

   return nil
end

function _M:getMatchRoute(path,keys,shareRoutes )
   local key = self:getMatchSourcePathKey(path,keys)
   -- print(key)
   if key== nil then
      return nil
   end
   --[
   --   {sourcePath="/app1/v1/user",app="app1",targetPath="/v1/user",stripPrefix=false}
   --]
   local targetJson = shareRoutes:get(key)
   if targetJson==nil then
      return nil
   end

   

   local route = json.decode(targetJson)

   initRoute(route)

   if route.targetPath then
      local targetFuzzyMatchIndex=string.find(route.targetPath,"/**",1)
      route.targetFuzzyMatchIndex=targetFuzzyMatchIndex
      if targetFuzzyMatchIndex and targetFuzzyMatchIndex>0 then
         route.targetIsFuzzyMatch = true
         route.targetPrefix=string.sub(route.targetPath,1,targetFuzzyMatchIndex)
      end   
   end

   if route.stripPrefix == nil and routingTable.stripPrefix ~= nil then
      route.stripPrefix = routingTable.stripPrefix
   end

   return route
end



function _M:getRouteTargetPath(route,path )
   return getRouteTargetPath(route,path )
end

 

function _M:getMatchRouteTargetPath(path,keys,shareRoutes )
   local route = self:getMatchRoute(path,keys,shareRoutes)

   if not route then
      return ""
   end
 
   return self:getRouteTargetPath(route,path) 
end

function getRouteTargetPath(route,path )

   local tpath = path
   local isStrip= false
-- print(dump(route))
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



function isMatch(path,sourcePath)

   local sourceFuzzyMatchIndex=string.find(sourcePath,"/**",1)
   local sourceIsFuzzyMatch= false
   local sourcePrefix=sourcePath
   if sourceFuzzyMatchIndex and sourceFuzzyMatchIndex>0 then
      sourceIsFuzzyMatch= true
      sourcePrefix=string.sub(sourcePath,1,sourceFuzzyMatchIndex)
   end
   -- print(path,sourcePath,sourceFuzzyMatchIndex,sourceIsFuzzyMatch,sourcePrefix)

   if sourceIsFuzzyMatch then
      local foundSub = string.find(path, sourcePrefix,1)
      if foundSub and foundSub==1 then
         return true
      else
         return false
      end

   else 
      if path==sourcePath then
         return true
      else
         return false
      end
   end

end

return _M
 