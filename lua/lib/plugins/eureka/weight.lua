--
-- User: Tietang Wang 铁汤 
-- Date: 2017/3/13 17:28
-- Blog: http://tietang.wang
--

local _M = {}
local KEY_RES = "RES"
local KEY_COUNT = "CT"

local function key(time_key, flag)
    local instance = ngx.ctx.b_host .. ":" .. ngx.ctx.b_port
    return time_key .. ":" .. flag .. "@" .. instance
end

local function keyByServer(server, time_key, flag)
    local instance = server.hostStr --server.host .. ":" .. server.port
    return time_key .. ":" .. flag .. "@" .. instance
end

local function delete(share, key)
    local s, e, f = share:delete(key)
    --    ngx.log(ngx.ERR, "deleted: ", key, "=", s, " ", e, " ", f)
end

local function timeKey()
    local now = ngx.time()
    local windowSeconds = globalConfig.lb.windowInSeconds
    local time_key = windowSeconds * math.floor(now / windowSeconds)
    return time_key;
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

function _M:weights(servers)
    -- 默认
    local ws = {}
    local len = table.getn(servers)
    for k, v in pairs(servers) do
        ws[k] = self:weight(len, v)
    end

    return ws
end

function _M:weight(len, server)
    -- 默认
    local time_key = timeKey()
    local req_time_key = keyByServer(server, time_key, KEY_RES) -- time_key .. ":RES@" .. instance
    local ct_time_key = keyByServer(server, time_key, KEY_COUNT) -- time_key .. ":CT@" .. instance
    local total_res_time = self.share:get(req_time_key)
    local total_ct = self.share:get(ct_time_key)
    local res_time = tonumber(total_res_time) or 0
    local ct = tonumber(total_ct) or 0
    local avg = math.ceil(res_time / ct - 0.5)

    local weight = (fibonacci:getCeiling(avg) or 1 / len) or 1

    return weight --server.weight
end


function _M:init(share)
    self.share = share
end

function _M:onLog()
    -- 能正确代理
    if ngx.ctx.pass then
        ngx.log(ngx.ERR, "host: ", ngx.ctx.b_host, " ", ngx.ctx.b_port)
        local req_time = tonumber(ngx.var.request_time) or 0
        --    local res_time = tonumber(ngx.var.upstream_response_time) or 0
        local time_key = timeKey()
        local req_time_key = key(time_key, KEY_RES) -- time_key .. ":RES@" .. instance
        local ct_time_key = key(time_key, KEY_COUNT) -- time_key .. ":CT@" .. instance
        utils:incr(self.share, ct_time_key, 1)
        utils:incr(self.share, req_time_key, req_time)
    end
end



-- timer
function _M:start()
    local ok, err = ngx.timer.at(globalConfig.lb.windowInSeconds, _M.timerHandler)
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
    local windowSeconds = globalConfig.lb.windowInSeconds
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
