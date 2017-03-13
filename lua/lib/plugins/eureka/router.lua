

local _M = {
    stripPrefix=false,
    defaultGroupName="DefaultGroup"
}
local json=require "cjson"


_M.groups={}


--[[
local routingTable = {
    stripPrefix=false,
    enableGroup=false,
    defaultGroupName="DefaultGroup",
    groups = {


        ["DefaultGroup"] = {

            stripPrefix = false,
            routes={
                {sourcePath="/app1/v1/user",app="app1",targetPath="/v1/user",stripPrefix=false},
                {sourcePath="/app1/v2/user",app="app1",targetPath="/app1/v2/user",stripPrefix=false},
                {sourcePath="/app2/*",app="app2",targetPath="/app20/*",stripPrefix=true},
                {sourcePath="/app3/*",aForpp="app3",stripPrefix=false},
                {sourcePath="/app4/*",app="app4",stripPrefix=true}
            }
        },
        ["blog.tietang.wang"] = {
            stripPrefix = false,
            routes={}
        }
    }

}
--]]


function _M:setGroupStripPrefix(name,stripPrefix)
    if not self.groups[groupName] then
        self.groups[groupName]={}
    end
    self.groups[groupName].stripPrefix=stripPrefix
end


function _M:addRoute(route,groupName)
    --
   
    if not route then
        return
    end

    local name = self:dealGroupName(groupName) 
  

    if not self.groups[name] then
        self.groups[name]={stripPrefix=self.stripPrefix,routes={}}
    end

    -- print(dump(route))
    local isInit=initRoute(self.groups[name],route)
    if isInit then
        local updated = false
        for i,v in ipairs(self.groups[name].routes) do
            if v.app==route.app and v.sourcePath==route.sourcePath then
                self.groups[name].routes[i]=route
                updated=true
            end
        end
        if not updated then
            table.insert(self.groups[name].routes,route)
        end
    end
    

end


function initRoute(group,route)
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

    if route.stripPrefix == nil and group.stripPrefix ~= nil  then
        route.stripPrefix = group.stripPrefix
    end

    return true

end

---

function _M:getMatchRouteTargetPath(path,groupName)
    local name = self:dealGroupName(groupName)

    -- print( name )


    return getMatchRouteTargetPath(self.groups[name],path)
end

function _M:dealGroupName(groupName)
    if not groupName then
        return self.defaultGroupName
    else
        return groupName
    end
end



function _M:getMatchRoute(path,groupName)
    -- ngx.log(ngx.ERR, "$$$$$$:", json.encode(self.routingTable))
    -- print( "$$$$$$:", json.encode(self.routingTable))
    local name = self:dealGroupName(groupName)
    return getMatchRoute(self.groups[name],path)
end

function _M:getRouteTargetPath(route,path )

    return getRouteTargetPath(route,path )
end

function getMatchRouteTargetPath( group, path )

    local route = getMatchRoute(group,path)

    if not route then
        return nil
    end

    return getRouteTargetPath(route,path)
end

function getMatchRoute(group, path)
     -- print( dump(group) )
     -- print( path )
    if not group then return nil end

    for k,v in pairs(group.routes) do
         -- print( dump(k),dump(v) )
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
 












