--
-- User: Tietang Wang 铁汤 
-- Date: 16/8/5 11:11
-- Blog: http://tietang.wang
--

local _M = {}

function _M:incrByTimeKey(share, key, value)
    local now = ngx.time()
    local time_window = 60 --seconds
    local time_key = key .. ":" .. time_window * math.floor(now / 60)
    return share:incr(time_key, value)
end

function _M.dump(o)
    if type(o) == 'table' then
        local s = '{ '
        for k, v in pairs(o) do
            if type(k) ~= 'number' then k = '"' .. k .. '"' end
            s = s .. '[' .. k .. '] = ' .. _M.dump(v) .. ','
        end
        return s .. '} '
    else
        return tostring(o)
    end
end

--在指定共享缓存shared中对指定key做incr操作,增加
function _M:incr(shared, key, value)
    local x = value or 1
    local v, e = shared:incr(key, x)
    if v == nil then
        local succ, err, forcible = shared:set(key, x)
        if forcible then
            return 0, err
        else
            return x, err
        end
    end
    return v, e
end



-- for lua-nginx-module version >= v0.10.6
function _M:incr2(shared, key, value)
    local v, e, f = shared:incr(key, value or 1, 0)
    return v, e
end


return _M