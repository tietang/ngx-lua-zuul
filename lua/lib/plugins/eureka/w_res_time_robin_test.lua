
local r = require "w_res_time_robin"


for i = 1, 1000, 30 do
    print(i,r.getCeiling(123))
end
