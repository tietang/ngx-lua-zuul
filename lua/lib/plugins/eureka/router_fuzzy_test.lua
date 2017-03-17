local router = require "router"
local unit = require "luaunit"
--  /app1/v1/user=app1,/v1/user
--  /app1/v1/user=app1,/app1/v1/user
--  app1, /app1/**=app1,/app1/**
--  /app1x/**=app1,/app1/**
--router:addRoute({ sourcePath = "/app2/*", app = "app2", targetPath = "/app20/*", stripPrefix = true })
--router:addRoute({ sourcePath = "/app3/*", app = "app3", stripPrefix = false })
--router:addRoute({ sourcePath = "/app4/*", app = "app4", stripPrefix = true })
router:addRoute({ sourcePath = "/baidu/*", app = "baidu", targetPath = "http://baidu.com/**", stripPrefix = true })

--/baidu/**=baidu,http://baidu.com/**

-- print(dump(router))

function test1_Nomal()
    unit.assertEquals(router:getMatchRouteTargetPath("/baidu/v3/cc"), "http://baidu.com/v3/cc")
end


os.exit(unit.LuaUnit.run())





--local runner = unit.LuaUnit.new()
--runner:setOutputType("tap")
--os.exit(runner:runSuite())






















































