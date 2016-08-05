

local metrics = ngx.shared.metrics

lastCleanSeconds=0
local time_window = 60 --seconds
local delay = 10 

local handler=function(premature)
	if premature then
         return
    end
    local now = ngx.time()
	local time_key = time_window* math.floor(now/60)

    local keys = metrics:get_keys()
    local len =table.maxn( keys )

    if len>= 60 then
    	local size = len-60 + 1
    	for i = 1, size do
    		local key = time_key-60-i
    		metrics:delete(key)
    		metrics:delete("REQ:"..key)
    		metrics:delete("RES:"..key)
    	end

    end

    for i, v in ipairs( keys ) do
    	 
    end

    local ok, err = ngx.timer.at(delay, handler)
     if not ok then
         ngx.log(ngx.ERR, "failed to create the timer: ", err)
         return
     end
end


local ok, err = ngx.timer.at(delay, handler)
 if not ok then
     ngx.log(ngx.ERR, "failed to create the timer: ", err)
     return
 end








