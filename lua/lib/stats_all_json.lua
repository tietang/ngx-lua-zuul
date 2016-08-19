local json = require "cjson"


local now = ngx.time()
local windowSeconds = globalConfig.metrics.timeWindowInSeconds
local time_key = windowSeconds * math.floor(now / windowSeconds)
local value = ngx.shared.metrics:get(time_key) or 0
local v = {
    key = time_key,
    date = time_key * 1000,
    close = tonumber(value) / 100
}
ngx.say(json.encode(v))

