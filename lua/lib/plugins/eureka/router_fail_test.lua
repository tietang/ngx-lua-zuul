local router = require "router"

local unit = require "luaunit"
--  /app1/v1/user=app1,/v1/user
--  /app1/v1/user=app1,/app1/v1/user
--  app1, /app1/**=app1,/app1/**
--  /app1x/**=app1,/app1/**
print("默认group测试-正常：")
router:addRoute({ sourcePath = "/app1/v1/user", app = "app1", targetPath = "/v1/user", stripPrefix = false })
router:addRoute({ sourcePath = "/app1/v2/user", app = "app1", targetPath = "/app1/v2/user", stripPrefix = false })
router:addRoute({ sourcePath = "/app2/*", app = "app2", targetPath = "/app20/*", stripPrefix = true })
router:addRoute({ sourcePath = "/app3/*", app = "app3", stripPrefix = false })
router:addRoute({ sourcePath = "/app4/*", app = "app4", stripPrefix = true })
router:addRoute({ sourcePath = "/baidu/*", app = "baidu", targetPath = "http://baidu.com/**", stripPrefix = true })


--/baidu/**=baidu,http://baidu.com/**

-- print(dump(router))
function test1_fail()
    print("默认group测试-异常【显示为nil】：")

    unit.assertNil(router:getMatchRouteTargetPath("/app02/v3/cc"))
    route = router:getMatchRoute("/app20/v3/cc")
    unit.assertNil(route)
    -- print( dump( router ) )


    unit.assertNil(router:getMatchRouteTargetPath("/app02/v3/cc"))
    route = router:getMatchRoute("/app20/v3/cc")
    unit.assertNil(route)
end





os.exit(unit.LuaUnit.run())

--local runner = unit.LuaUnit.new()
--runner:setOutputType("tap")
--os.exit(runner:runSuite())






















































