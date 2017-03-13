--
-- User: Tietang Wang 铁汤 
-- Date: 2017/3/13 17:28
-- Blog: http://tietang.wang
--

local _M = {}

function _M:weights(servers)
    -- 默认
    local ws = {}
    for k, v in pairs(servers) do
        ws[k] = self:weight(v)
    end

    return ws
end

function _M:weight(server)
    -- 默认
    return server.weight
end

function _M:onLog()
    local req_time = tonumber(ngx.var.request_time) or 0
    local res_time = tonumber(ngx.var.upstream_response_time) or 0
    key = ngx.ctx.b_host .. ":" .. ngx.ctx.b_port
    local now = ngx.time()
    local windowSeconds = globalConfig.lb.windowInSeconds
    local time_key = windowSeconds * math.floor(now / windowSeconds)
end


-- timer
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
    local maxSaveSize = 3
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



    local ok, err = ngx.timer.at(windowSeconds, _M.timerHandler)
    if not ok then
        ngx.log(ngx.ERR, "failed to create the timer: ", err)
        return
    end
end

return _M
