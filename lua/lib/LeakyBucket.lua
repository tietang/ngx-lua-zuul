--
-- User: Tietang Wang 铁汤 
-- Date: 16/8/5 11:05
-- Blog: http://tietang.wang
--




local LeakyBucket = {
    maxRequests = 10000, -- 单位时间窗口的最大请求数,默认10k
    windowSeconds = 1, -- 时间窗口,单位s 1~60s
    maxSaveSize = 60
}

function LeakyBucket:new(o, share, maxRequests, windowSeconds, maxSaveSize)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    self.share = share
    self.maxRequests = maxRequests or self.maxRequests
    if windowSeconds and windowSeconds < 1 then
        windowSeconds = 1
    end
    if windowSeconds and windowSeconds > 60 then
        windowSeconds = 60
    end
    self.windowSeconds = windowSeconds or self.windowSeconds
    self.maxSaveSize = maxSaveSize or self.maxSaveSize
    return o
end


function LeakyBucket:incr(share, key, value)
    return share:incr(self:genCurrentKey(key, 0), value,0)
end

function LeakyBucket:delete(share, key)
    return share:delete(self:genCurrentKey(key, self.maxSaveSize))
end

function LeakyBucket:genCurrentKey(key, prevUnit)
    local now = os.time() --  ngx.time()
    local time_key = self.windowSeconds * (math.floor(now / self.windowSeconds) - (prevUnit or 0))
    local finalKey = key .. ":" .. time_key
    print(finalKey)
    return finalKey
end

function LeakyBucket:acquire(key, permits)
    self:delete(self.share, key)
--    print(self.maxRequests)
    local newval, err, forcible = self:incr(self.share, key, permits or 1)
    local s=(newval or 0) >= self.maxRequests
    print( newval .. " " .. self.maxRequests .. " " )
    if (newval or 0) >= self.maxRequests then
        return false
    end
    return true
end

function LeakyBucket:release(key, permits)
    self:incr(self.share, key, -(permits or 1))
end

return LeakyBucket