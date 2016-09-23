local json = require "cjson"
local now = ngx.time()
local windowSeconds = globalConfig.metrics.timeWindowInSeconds
local time_key = windowSeconds * math.floor(now / windowSeconds)
local function get(givenKey)
    local key = time_key
    local saved_key = givenKey .. ":" .. key
    local value = ngx.shared.metrics:get(saved_key) or 0
    return {
        --        seconds = key,
        date = key * 1000,
        close = tonumber(value) / windowSeconds
    }
end

local apps_count = ngx.shared.apps_count
local keys = apps_count:get_keys()
local v = {}
local allRequest = "AllRequest"
v[allRequest] = get(allRequest)
for i, key in pairs(keys) do
    v[key] = get(key)
    --    ngx.log(ngx.ERR, i, key)
end

ngx.say(json.encode(v))