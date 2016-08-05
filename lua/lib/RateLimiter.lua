--
-- User: Tietang Wang 铁汤 
-- Date: 16/8/5 10:41
-- Blog: http://tietang.wang
--



local LeakyBucket = require "LeakyBucket"


local _M = {
    default = {}
}

local defaultMaxRequests = 10000 -- 最大请求数,默认10k
local defaultWindowSeconds = 1 -- 最大请求数,默认10k
local defaultMaxSaveSize = 60 -- 最大请求数,默认10k


function _M:init(config, share)
    self.share = share
    self.default = LeakyBucket:new({}, share, defaultMaxRequests, defaultWindowSeconds, defaultMaxSaveSize)
    for k, v in pairs(config) do
        self[k] = LeakyBucket:new({}, share, v[1] or defaultMaxRequests, v[2] or defaultWindowSeconds, v[3] or defaultMaxSaveSize)
    end
end


function _M:acquire(key)
    local lb = self[key] or self.default
    if lb:acquire(key) then
        return true
    end
    return false
end

return _M

