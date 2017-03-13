local _M = {}


-- local servers={
--  {["weight"]=1,["name"]="a",["cweight"]=0},
--  {["weight"]=2,["name"]="b",["cweight"]=0},
--  {["weight"]=4,["name"]="c",["cweight"]=0}
-- }
local weight = require "weight"

_M.servers = {}

function _M:new(o, servers)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    self.servers = servers
    return o
end

--function _M:setServers(servers )
--  self.servers=servers
--end

function _M:addServer(server)
    table.insert(self.servers, server)
end

function _M:down(server)
    for k, v in pairs(self.servers) do
        if server.name == v.name then
            v.status = "DOWN"
        end
    end
end

function _M:up(server)
    for k, v in pairs(self.servers) do
        if server.name == v.name then
            v.status = "UP"
        end
    end
end



function _M:next()
    local servers = self.servers
    rweights = weight:weights(servers)
    local totalWeight = totalWeight(servers)
    for k, v in pairs(servers) do

        --        v.cweight = v.weight + v.cweight
        rweight = rweights[k]
        v.cweight = rweight + v.cweight
    end

    table.sort(servers,
        function(a, b)
            return a.cweight > b.cweight
        end)
    selected = servers[1]

    selected.cweight = selected.cweight - totalWeight

    return selected
end

function totalWeight(servers)
    local totalWeight = 0
    for i, v in ipairs(servers) do
        totalWeight = totalWeight + v.weight
    end
    return totalWeight
end

return _M






