--
-- User: Tietang Wang 铁汤 
-- Date: 2017/3/13 16:52
-- Blog: http://tietang.wang
--
local _M = {}


_M.FibonacciTable = {
    { 0, 1, 1000 },
    { 1, 10, 996 },
    { 2, 20, 992 },
    { 3, 30, 988 },
    { 5, 50, 981 },
    { 8, 80, 970 },
    { 13, 130, 951 },
    { 21, 210, 922 },
    { 34, 340, 874 },
    { 55, 550, 798 },
    { 89, 890, 680 },
    { 144, 1440, 508 },
    { 233, 2330, 285 },
    { 377, 3770, 48 },
    { 610, 6100, 10 },
    { 987, 9870, 6 },
    { 1597, 15970, 1 },
}

local function ceilingGet(tables, key, smoothness, isTenMillisecond)
    index = 2
    if isTenMillisecond then
        index = 1
    end

    for i, v in pairs(tables) do
        k = v[index]
        v = v[3]
        if key <= k then
            if i == 1 or not smoothness then
                return v
            end
            kv0 = tables[i - 1]
            k0 = kv0[index]
            v0 = kv0[3]
            diffk = k - k0
            diffv = v - v0
            dv = diffv * (key - k0) / diffk
            r = math.ceil(v0 + dv)
            return r
        end
    end
    return 1
end

function _M:getCeiling(key)
    value = ceilingGet(self.FibonacciTable, key, true, false)
    return value
end

function _M:weight(key)
    value = ceilingGet(self.FibonacciTable, key, true, false)
    return value
end

function _M:getCeilingByTenMillisecond(key)
    value = ceilingGet(self.FibonacciTable, key, true, true);
    return value;
end

return _M