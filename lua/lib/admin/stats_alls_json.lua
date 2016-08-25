local json = require "cjson"


local now = ngx.time()
local windowSeconds = globalConfig.metrics.timeWindowInSeconds
local time_key = windowSeconds * math.floor(now / windowSeconds)

local v = {}
for i = 0, 60 do
    local key = time_key - 0 * windowSeconds
    local value = ngx.shared.metrics:get(key) or 0

    table.insert(v, {
        key = key,
        date = key * 1000,
        close = tonumber(value) / 100
    })
end


ngx.say(json.encode(v))