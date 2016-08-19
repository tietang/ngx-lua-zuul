--
-- User: Tietang Wang 铁汤 
-- Date: 16/8/5 11:05
-- Blog: http://tietang.wang
--

local strings = require("strings")
local utils = require("utils")

local LeakyBucket = {
    limitLevel = "global",
    maxRequests = 10000, -- 单位时间窗口的最大请求数,默认10k
    windowSeconds = 10, -- 时间窗口,单位s 1~60s
    maxSaveSize = 60, --最大保留的时间窗口size,
    allKeys = {},
    config = {
        default = {
            maxRequests = 10000, -- 单位时间窗口的最大请求数,默认10k
            windowSeconds = 10, -- 时间窗口,单位s 1~60s
            maxSaveSize = 60 --最大保留的时间窗口size,
        }
    }
}

--[

params = {
    default = { [1] = 100 },
    ["UserService"] = { [1] = 100 },
    ["/api/v1/users"] = { [1] = 100 },
    ["/api/v2/users"] = {
        maxRequests = 10000,
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
        self.maxRequests = config.default[1] or config.default.maxRequests or self.maxRequests
        self.windowSeconds = dealWindowSeconds(config.default[2] or config.default.windowSeconds or self.windowSeconds)
        self.maxSaveSize = config.default[3] or config.default.maxSaveSize or self.maxSaveSize
    end

    for k, v in pairs(config) do
        self.config[k] = self.config[k] or {}
        self.config[k].maxRequests = v[1] or v.maxRequests or self.maxRequests
    end
end

local function dealWindowSeconds(windowSeconds)
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
    key = self:genCurrentKey(key, 0)
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
    local maxSaveSize = self.maxSaveSize
    return share:delete(self:genCurrentKey(key, maxSaveSize))
end

function LeakyBucket:genCurrentKey(key, prevUnit)
    local now = os.time() --  ngx.time()
    local windowSeconds = self.windowSeconds
    local time_key = windowSeconds * (math.floor(now / windowSeconds) - (prevUnit or 0))
    local finalKey = key .. ":" .. time_key
    --    print(finalKey)
    --    ngx.log(ngx.ERR, "-----------", now, " ", finalKey, " ", prevUnit)
    return finalKey
end

function LeakyBucket:acquire(key, permits)
    key = key or "default"
    self:delete(self.share, key)
    --    print(self.maxRequests)
    local maxRequests = self.config[key].maxRequests or self.maxRequests
    local newval, err, forcible = self:incr(self.share, key, permits or 1)
    --    local newval, flags = self.share:get(key) or 1

    newval = newval or 0
    --    local s = (newval or 0) >= maxRequests
    --    print(newval .. " " .. maxRequests .. " ")
    --    ngx.log(ngx.ERR, "-----------", newval, " ", maxRequests, " ", utils.dump(self.share))
    if (newval or 0) >= maxRequests then
        return false
    end
    return true
end

function LeakyBucket:release(key, permits)
    --    self:incr(self.share, key, -(permits or 1))
    --Nothing
end

function LeakyBucket:report()
    local r = {
        metrics = {},
        limitLevel = self.limitLevel,
        maxRequests = self.maxRequests,
        windowSeconds = self.windowSeconds,
        maxSaveSize = self.maxRequests,
        allKeys = self.allKeys,
        config = self.config
    }

    local keys = self.share:get_keys()
    for i, key in pairs(keys) do
        local value = self.share:get(key)
        r.metrics[key] = value
    end
    return r
end


--

local function delete(share, key)
    local s, e, f = share:delete(key)
    --    ngx.log(ngx.ERR, "deleted: ", key, "=", s, " ", e, " ", f)
end

local function deleteKey(share, timeKey)
    local keys = share:get_keys()

    for k, v in pairs(keys) do
        --        ngx.log(ngx.ERR, "keys: ", k, "=", v)
        --print(dump(string.split("1,2|3-4 5_6 7:8#9@10",",|_::---#@ ")))

        local kk = strings:split(v, "_ - : @");
        for tk, tv in pairs(kk) do
            --            ngx.log(ngx.ERR, "split: ", tk, "=", tv, "   ", type(tv))
            local time = tonumber(tv)
            if time and time <= timeKey then
                delete(share, v)
            end
        end

        --        if strings.startswith(v, timeKey) or strings.endswith(v, timeKey) then
        --            deteteByCache(v)
        --        end
    end
end

function LeakyBucket:start()
    local ok, err = ngx.timer.at(self.windowSeconds, LeakyBucket.timerHandler)
    if not ok then
        ngx.log(ngx.ERR, "failed to create the timer: ", err)
        return
    end
end

function LeakyBucket.timerHandler(premature)
    LeakyBucket:handler(premature)
end

function LeakyBucket:handler()
    if premature then
        return
    end
    local now = ngx.time()
    local windowSeconds = self.windowSeconds
    local maxSaveSize = self.maxSaveSize
    local time_key = windowSeconds * math.floor(now / windowSeconds)

    local keys = self.share:get_keys()
    local len = table.maxn(keys)
    --    ngx.log(ngx.ERR, len, "  ", maxSaveSize, "  ", time_key) --, "   ", utils.dump(keys))
    if len >= maxSaveSize then
        local size = len - maxSaveSize + 1
        for i = 1, size do
            local key = time_key - maxSaveSize - i
            delete(self.share, key)
            deleteKey(self.share, key)
        end
    end
    local lastDeleteKey = time_key - maxSaveSize
    delete(self.share, lastDeleteKey)
    deleteKey(self.share, lastDeleteKey)

    local ok, err = ngx.timer.at(windowSeconds, LeakyBucket.timerHandler)
    if not ok then
        ngx.log(ngx.ERR, "failed to create the timer: ", err)
        return
    end
end







return LeakyBucket