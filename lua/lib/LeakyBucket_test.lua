--
-- User: Tietang Wang 铁汤 
-- Date: 16/8/5 11:05
-- Blog: http://tietang.wang
--






local config = {
    default = { [1] = 3, [2] = 1, [3] = 60 },
    ["UserService"] = { [1] = 3, [2] = 1, [3] = 60 },
    ["/api/v1/users"] = { [1] = 3, [2] = 1, [3] = 60 },
    ["/api/v2/users"] = {
        maxRequests = 3,
        windowSeconds = 1,
        maxSaveSize = 60
    }
}

local ShareTest = {}


function ShareTest:incr(key, value, initValue)
    self[key] = (self[key] or 0) + value + (initValue or 0);
    return self[key]
end
function ShareTest:delete(key)
    self[key] = nil
--    table.remove(self,key)
end


function ShareTest:size()
    return table.maxn(share)
end

local leakyBucket = require "LeakyBucket"
leakyBucket:init(ShareTest,config)

for i = 1, 10 do
    print(leakyBucket:acquire())
end