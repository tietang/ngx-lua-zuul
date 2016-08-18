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

return _M