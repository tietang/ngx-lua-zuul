local robin = require "robin"


local _M = robin:new(nil, {})

-- local servers={
--  {["weight"]=1,["name"]="a",["cweight"]=0},
--  {["weight"]=2,["name"]="b",["cweight"]=0},
--  {["weight"]=4,["name"]="c",["cweight"]=0}
-- }
--Weighted Response Time Rule


function _M:new(o, servers)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    self.servers = servers
    return o
end

function _M:reWeight()
    local totalResTime = 0;
    local shared = globalConfig.robin.shared
    local now = ngx.time()
    local windowSeconds = globalConfig.robin.timeWindowInSeconds
    local time_key = windowSeconds * math.floor(now / windowSeconds)

    local hosts = {}

    for i, server in pairs(self.servers) do
        local key = server.id .. ":RES:" .. time_key
        local value = shared:get(key) or 0
        hosts[server.id] = tonumber(value)
        totalResTime = totalResTime + tonumber(value)
    end


    for i, server in pairs(self.hosts) do
        local key = server.id .. ":RES:" .. time_key
        local value = shared:get(key) or 0
    end
end

return _M






