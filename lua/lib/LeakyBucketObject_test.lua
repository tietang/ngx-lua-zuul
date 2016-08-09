--
-- User: Tietang Wang 铁汤 
-- Date: 16/8/5 11:05
-- Blog: http://tietang.wang
--




local LeakyBucket = require "LeakyBucketObject"

local ShareTest = {}

function ShareTest:incr(key, value, initValue)
    self[key] = (self[key] or 0) + value + (initValue or 0);
    return self[key]
end

function ShareTest:delete(key)
    self[key] = nil
    table.remove(self,key)
end


function ShareTest:size()
    return table.maxn(ShareTest)
end

function sleep(n)
    os.execute("sleep " .. n)
end

local lb = LeakyBucket:new({}, ShareTest, 3, 60, 10)
local key = "/api/v1/users"
--
--timer = function(time)
--    local init = os.time()
--    local diff = os.difftime(os.time(), init)
--    while diff < time do
--        coroutine.yield(diff)
--        diff = os.difftime(os.time(), init)
--    end
--    print('Timer timed out at ' .. time .. ' seconds!')
--end
--co = coroutine.create(timer)
--coroutine.resume(co, 10) -- timer starts here!
--while coroutine.status(co) ~= "dead" do
--    select(2, coroutine.resume(co))
--- -    print("time passed",)
---- print('', coroutine.status(co))
-- print(share:size())
-- if lb:acquire(key) then
-- print("get continue"..share:size())
-- else
-- print("can't get pasue"..share:size())
-- end
-- lb:release(key)
-- sleep(.100)
-- end

co = coroutine.create(function(i)
    for i = 1, 100 do
        local has=lb:acquire(key)
        print(has)
        if has then
            print("get continue " .. share:size())
        else
            print("can't get pasue " .. share:size())
        end
        sleep(math.random(1000)/1000)
--        lb:release(key)

    end
end)

co2 = coroutine.create(function(i)
    for i = 1, 100 do
        sleep(math.random(1000)/1000)
        lb:release(key)
    end
end)

coroutine.resume(co, 1) -- 1
--coroutine.resume(co2, 1) -- 1
--coroutine.resume(co, 1) -- 1
--coroutine.resume(co2, 1) -- 1
--coroutine.resume(co, 1) -- 1
--coroutine.resume(co2, 1) -- 1
--coroutine.resume(co, 1) -- 1
--coroutine.resume(co2, 1) -- 1


