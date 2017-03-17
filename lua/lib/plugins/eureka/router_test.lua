local router = require "router"

local unit = require "luaunit"
--  /app1/v1/user=app1,/v1/user
--  /app1/v1/user=app1,/app1/v1/user
--  app1, /app1/**=app1,/app1/**
--  /app1x/**=app1,/app1/**
--print("默认group测试-正常：")
router:addRoute({ sourcePath = "/app1/v1/user", app = "app1", targetPath = "/v1/user", stripPrefix = false })
router:addRoute({ sourcePath = "/app1/v2/user", app = "app1", targetPath = "/app1/v2/user", stripPrefix = true })
router:addRoute({ sourcePath = "/app2/*", app = "app2", targetPath = "/app20/*", stripPrefix = true })
router:addRoute({ sourcePath = "/app3/*", app = "app3", stripPrefix = false })
router:addRoute({ sourcePath = "/app4/*", app = "app4", stripPrefix = true })
router:addRoute({ sourcePath = "/baidu/*", app = "baidu", targetPath = "http://baidu.com/**", stripPrefix = true })
---
--print("")
local groupName = "blog.tietang.wang"
--print("自定义group测试【" .. groupName .. "】：")

router:addRoute({ sourcePath = "/blog1/v1/user", app = "blog1", targetPath = "/v1/user", stripPrefix = false }, groupName)
router:addRoute({ sourcePath = "/blog1/v2/user", app = "blog2", targetPath = "/blog1/v2/user", stripPrefix = false }, groupName)
router:addRoute({ sourcePath = "/blog2/*", app = "blog2", targetPath = "/blog20/*", stripPrefix = true }, groupName)
router:addRoute({ sourcePath = "/blog3/*", app = "blog3", stripPrefix = false }, groupName)
router:addRoute({ sourcePath = "/blog4/*", app = "blog4", stripPrefix = true }, groupName)

function test1_Nomal()
    unit.assertEquals(router:getMatchRouteTargetPath("/app2/v3/cc"), "/app20/v3/cc")
    unit.assertEquals(router:getMatchRouteTargetPath("/app4/v3/cc"), "/v3/cc")
    unit.assertEquals(router:getMatchRouteTargetPath("/app4/v3/e"), "/v3/e")
    unit.assertEquals(router:getMatchRouteTargetPath("/app1/v1/user"), "/v1/user")
    unit.assertEquals(router:getMatchRouteTargetPath("/app1/v2/user"), "/app1/v2/user")
    unit.assertEquals(router:getMatchRouteTargetPath("/app2/v3/f"), "/app20/v3/f")
    unit.assertEquals(router:getMatchRouteTargetPath("/app3/v3/f"), "/app3/v3/f")
end
function test1_group()
    unit.assertEquals((router:getMatchRouteTargetPath("/blog2/v3/cc", groupName)),"/blog20/v3/cc")
    unit.assertEquals((router:getMatchRouteTargetPath("/blog4/v3/cc", groupName)),"/v3/cc")
    unit.assertEquals((router:getMatchRouteTargetPath("/blog4/v3/e", groupName)),"/v3/e")
    unit.assertEquals((router:getMatchRouteTargetPath("/blog1/v1/user", groupName)),"/v1/user")
    unit.assertEquals((router:getMatchRouteTargetPath("/blog1/v2/user", groupName)),"/blog1/v2/user")
    unit.assertEquals((router:getMatchRouteTargetPath("/blog2/v3/f", groupName)),"/blog20/v3/f")
    unit.assertEquals((router:getMatchRouteTargetPath("/blog3/v3/f", groupName)),"/blog3/v3/f")
    local blogRoute = router:getMatchRoute("/blog2/v3/cc", groupName)
    print(blogRoute.app, blogRoute.targetPath)
    unit.assertEquals(blogRoute.targetPath,"/blog20/*")

end




os.exit(unit.LuaUnit.run())

--local runner = unit.LuaUnit.new()
--runner:setOutputType("tap")
--os.exit(runner:runSuite())






















































