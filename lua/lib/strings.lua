--
-- User: Tietang Wang 铁汤 
-- Date: 16/8/18 13:48
-- Blog: http://tietang.wang
--



local _M = { _VERSION = '0.1' }

function _M:split(str, delimiter)
--    if (delimiter == '') then return false end
--    local pos, arr = 0, {}
--
--    for st, sp in function() return string.find(str, delimiter, pos, true) end do
--        table.insert(arr, string.sub(str, pos, st - 1))
--        pos = sp + 1
--    end
--    table.insert(arr, string.sub(str, pos))
--    return arr
    return string.split(str,delimiter)
end

string.split = function(s, p)
    local rt= {}
    string.gsub(s, '[^'..p..']+', function(w) table.insert(rt, w) end )
    return rt
end


function _M:ltrim(str)
    if str then
        return string.gsub(str, '^[ \t\n\r]+', '')
    end
    return nil
end

function _M:rtrim(str)
    if str then
        return string.gsub(str, '[ \t\n\r]+$', '')
    end
    return nil
end

function _M:trim(str)
    if str then
        str = string.gsub(str, '^[ \t\n\r]+', '')
        return string.gsub(str, '[ \t\n\r]+$', '')
    end
    return nil
end

function _M:capitaliz(str)
    if str == nil then
        return nil, 'string is nil'
    end
    local ch = string.sub(str, 1, 1)
    local len = string.len(str)
    if ch < 'a' or ch > 'z' then
        return str
    end
    ch = string.char(string.byte(ch) - 32)
    if len == 1 then
        return ch
    else
        return ch .. string.sub(str, 2, len)
    end
end

function _M:count(str, substr, from, to)
    if str == nil or substr == nil then
        return nil, 'string or sub-string is nil'
    end
    from = from or 1
    if to == nil or to > string.len(str) then
        to = string.len(str)
    end
    local str_tmp = string.sub(str, from, to)
    local _, n = string.gsub(str, substr, '')
    return n
end


function _M:startswith(str, substr)
    if str == nil or substr == nil then
        return nil, 'string or sub-stirng is nil'
    end
    if string.find(str, substr) ~= 1 then
        return false
    else
        return true
    end
end

function _M:endswith(str, substr)
    if str == nil or substr == nil then
        return nil, 'string or sub-string is nil'
    end
    local str_tmp = string.reverse(str)
    local substr_tmp = string.reverse(substr)
    if string.find(str_tmp, substr_tmp) ~= 1 then
        return false
    else
        return true
    end
end

function _M:expendtabs(str, n)
    if str == nil then
        return nil, 'string is nil'
    end
    n = n or 8
    str = string.gsub(str, '\t', string.rep(' ', n))
    return str
end

function _M:isalnum(str)
    if str == nil then
        return nil, 'string is nil'
    end
    local len = string.len(str)
    for i = 1, len do
        local ch = string.sub(str, i, i)
        if not ((ch >= 'a' and ch <= 'z') or (ch >= 'A' and ch <= 'Z') or (ch >= '0' and ch <= '9')) then
            return false
        end
    end
    return true
end

function _M:isalpha(str)
    if str == nil then
        return nil, 'string is nil'
    end
    local len = string.len(str)
    for i = 1, len do
        local ch = string.sub(str, i, i)
        if not ((ch >= 'a' and ch <= 'z') or (ch >= 'A' and ch <= 'Z')) then
            return false
        end
    end
    return true
end

function _M:isdigit(str)
    if str == nil then
        return nil, 'string is nil'
    end
    local len = string.len(str)
    for i = 1, len do
        local ch = string.sub(str, i, i)
        if ch < '0' or ch > '9' then
            return false
        end
    end
    return true
end

function _M:islower(str)
    if str == nil then
        return nil, 'string is nil'
    end
    local len = string.len(str)
    for i = 1, len do
        local ch = string.sub(str, i, i)
        if ch < 'a' or ch > 'z' then
            return false
        end
    end
    return true
end

function _M:isupper(str)
    if str == nil then
        return nil, 'string is nil'
    end
    local len = string.len(str)
    for i = 1, len do
        local ch = string.sub(str, i, i)
        if ch < 'A' or ch > 'Z' then
            return false
        end
    end
    return true
end

function _M:join(str, substr)
    if str == nil or substr == nil then
        return nil, 'string or sub-string is nil'
    end
    local xlen = string.len(str) - 1
    if xlen == 0 then
        return str
    end
    local str_tmp = ''
    for i = 1, xlen do
        str_tmp = str_tmp .. string.sub(str, i, i) .. substr
    end
    str_tmp = str_tmp .. string.sub(str, xlen + 1, xlen + 1)
    return str_tmp
end

function _M:lower(str)
    if str == nil then
        return nil, 'string is nil'
    end
    local len = string.len(str)
    local str_tmp = ''
    for i = 1, len do
        local ch = string.sub(str, i, i)
        if ch >= 'A' and ch <= 'Z' then
            ch = string.char(string.byte(ch) + 32)
        end
        str_tmp = str_tmp .. ch
    end
    return str_tmp
end

function _M:upper(str)
    if str == nil then
        return nil, 'string is nil'
    end
    local len = string.len(str)
    local str_tmp = ''
    for i = 1, len do
        local ch = string.sub(str, i, i)
        if ch >= 'a' and ch <= 'z' then
            ch = string.char(string.byte(ch) - 32)
        end
        str_tmp = str_tmp .. ch
    end
    return str_tmp
end

function _M:partition(str, substr)
    if str == nil or substr == nil then
        return nil, 'string or sub-string is nil'
    end
    local len = string.len(str)
    local start_idx, end_idx = string.find(str, substr)
    if start_idx == nil or end_idx == len then
        return str, '', ''
    end
    return string.sub(str, 1, start_idx - 1), string.sub(str, start_idx, end_idx), string.sub(str, end_idx + 1, len)
end

function _M:zfill(str, n)
    if str == nil then
        return nil, 'string is nil'
    end
    if n == nil then
        return str
    end
    local format_str = '%0' .. n .. 's'
    return string.format(format_str, str)
end

function _M:ljust(str, n, ch)
    if str == nil then
        return nil, 'string is nil'
    end
    ch = ch or ' '
    n = tonumber(n) or 0
    local len = string.len(str)
    return string.rep(ch, n - len) .. str
end

function _M:rjust(str, n, ch)
    if str == nil then
        return nil, 'string is nil'
    end
    ch = ch or ' '
    n = tonumber(n) or 0
    local len = string.len(str)
    return str .. string.rep(ch, n - len)
end

function _M:center(str, n, ch)
    if str == nil then
        return nil, 'string is nil'
    end
    ch = ch or ' '
    n = tonumber(n) or 0
    local len = string.len(str)
    local rn_tmp = math.floor((n - len) / 2)
    local ln_tmp = n - rn_tmp - len
    return string.rep(ch, rn_tmp) .. str .. string.rep(ch, ln_tmp)
end

function _M:abbreviate(str, size)
    if str == nil then
        return nil, 'string is nil'
    end
    if string.len(str) <= size then
        return str
    end
    return string.sub(str, 0, size) .. '...'
end

function _M:eval(str)
    if type(str) ~= "string" then return end
    local s = string.format("return %s", str)
    return loadstring(str)()
end

return _M