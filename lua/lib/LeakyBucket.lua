--
-- User: Tietang Wang 铁汤 
-- Date: 16/8/5 11:05
-- Blog: http://tietang.wang
--


local LeakyBucket = {
    limitLevel = "global",
    config = {
        default = {
            maxRequests = 10000, -- 单位时间窗口的最大请求数,默认10k
            windowSeconds = 1, -- 时间窗口,单位s 1~60s
            maxSaveSize = 60 --最大保留的时间窗口size,
        }
    }
}

--[

params = {
    default = { [1] = 100, [2] = 1, [3] = 60 },
    ["UserService"] = { [1] = 100, [2] = 1, [3] = 60 },
    ["/api/v1/users"] = { [1] = 100, [2] = 1, [3] = 60 },
    ["/api/v2/users"] = {
        maxRequests = 10000,
        windowSeconds = 1,
        maxSaveSize = 60
    }
}

--]


function LeakyBucket:init(share, config)
    self.share = share
    --    if not config then
    --        return
    --    end
    self:updateConfig(config.params)
    self:updateLimitLevel(config.limitLevel)
end

function LeakyBucket:updateLimitLevel(limitLevel)
    self.limitLevel = limitLevel or self.limitLevel
end

function LeakyBucket:updateConfig(config)
    if not config then
        return
    end

    if config.default then
        self.config.default.maxRequests = config.default[1] or config.default.maxRequests or self.config.default.maxRequests
        self.config.default.windowSeconds = dealWindowSeconds(config.default[2] or config.default.windowSeconds or self.config.default.windowSeconds)
        self.config.default.maxSaveSize = config.default[3] or config.default.maxSaveSize or self.config.default.maxSaveSize
    end

    for k, v in pairs(config) do
        self.config[k] = self.config[k] or {}
        self.config[k].maxRequests = v[1] or v.maxRequests or self.config.default.maxRequests
        self.config[k].windowSeconds = dealWindowSeconds(v[2] or v.windowSeconds or self.config.default.windowSeconds)
        self.config[k].maxSaveSize = v[3] or v.maxSaveSize or self.config.default.maxSaveSize
    end
end

function dealWindowSeconds(windowSeconds)
    if windowSeconds and windowSeconds < 1 then
        windowSeconds = 1
    end
    if windowSeconds and windowSeconds > 60 then
        windowSeconds = 60
    end
    return windowSeconds
end

-- for lua-nginx-module version >= v0.10.6
function LeakyBucket:incr2(share, key, value)

    local v, e, f = share:incr(self:genCurrentKey(key, 0), value, 0)
--    ngx.log(ngx.ERR, "-----------", key, " ", value, "v=", v, " e=", e, "f=", f)
    return v, e, f
end

function LeakyBucket:incr(shared, key, value)
    local x = value or 1
    key=self:genCurrentKey(key, 0)
    local v, e, f = shared:incr(key, x)
    if v == nil then
        local succ, err, forcible = shared:set(key, x)
        if forcible then
            return 0, err, forcible
        else
            return x, err, forcible
        end
    end
    return v, e, f
end



function LeakyBucket:delete(share, key)
    local maxSaveSize = self.config[key].maxSaveSize or self.config.default.maxSaveSize
    return share:delete(self:genCurrentKey(key, maxSaveSize))
end

function LeakyBucket:genCurrentKey(key, prevUnit)
    local now = os.time() --  ngx.time()
    local windowSeconds = self.config[key].windowSeconds or self.config.default.windowSeconds
    local time_key = windowSeconds * (math.floor(now / windowSeconds) - (prevUnit or 0))
    local finalKey = key .. ":" .. time_key
    --    print(finalKey)
        ngx.log(ngx.ERR,"-----------",now," ", finalKey," ",prevUnit)
    return finalKey
end

function LeakyBucket:acquire(key, permits)
    key = key or "default"
    self:delete(self.share, key)
    --    print(self.maxRequests)
    local maxRequests = self.config[key].maxRequests or self.config.default.maxRequests
    local newval, err, forcible = self:incr(self.share, key, permits or 1)
    --    local newval, flags = self.share:get(key) or 1

    newval = newval or 0
    --    local s = (newval or 0) >= maxRequests
    --    print(newval .. " " .. maxRequests .. " ")
    ngx.log(ngx.ERR, "-----------", newval, " ", maxRequests, " ", dump(self.share))
    if (newval or 0) >= maxRequests then
        return false
    end
    return true
end

function LeakyBucket:release(key, permits)
    --    self:incr(self.share, key, -(permits or 1))
    --Nothing
end

return LeakyBucket