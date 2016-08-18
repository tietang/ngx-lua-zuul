--
-- User: Tietang Wang 铁汤 
-- Date: 16/8/18 17:33
-- Blog: http://tietang.wang
--



--
local _M = {}


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

function _M:init(config)
    self.timeWindowInSeconds = config.timeWindowInSeconds or 60
    self.maxSaveSize = config.maxSaveSize or 60
end

function _M:start()
    local ok, err = ngx.timer.at(self.timeWindowInSeconds, _M.timerHandler)
    if not ok then
        ngx.log(ngx.ERR, "failed to create the timer: ", err)
        return
    end
end

function _M.timerHandler(premature)
    _M:handler(premature)
end

function _M:handler()
    if premature then
        return
    end
    local now = ngx.time()
    local windowSeconds = self.timeWindowInSeconds
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
            delete(self.share, "REQ:" .. key)
            delete(self.share, "RES:" .. key)
            deleteKey(self.share, key)
        end
    end
    local lastDeleteKey = time_key - maxSaveSize
    delete(self.share, lastDeleteKey)
    delete(self.share, "REQ:" .. lastDeleteKey)
    delete(self.share, "RES:" .. lastDeleteKey)
    deleteKey(self.share, lastDeleteKey)

    local ok, err = ngx.timer.at(windowSeconds, _M.timerHandler)
    if not ok then
        ngx.log(ngx.ERR, "failed to create the timer: ", err)
        return
    end
end

return _M