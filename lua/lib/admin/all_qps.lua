local json = require "cjson"
local now = ngx.time()
local windowSeconds = globalConfig.metrics.timeWindowInSeconds
local time_key = windowSeconds * math.floor(now / windowSeconds)
local size = globalConfig.metrics.maxSaveSize or 1
--size = 1
local function get(givenKey)
    local v = {}
    for i = 1, size do
        local key = time_key - i * windowSeconds
        local saved_key = givenKey .. ":" .. key
        local value = ngx.shared.metrics:get(saved_key)
        if value then

            table.insert(v, {
                --            key = givenKey,
                date = key * 1000,
                close = tonumber(value)/windowSeconds
            })
        end
    end

    return v;
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