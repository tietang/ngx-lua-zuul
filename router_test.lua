local router = require "router"


--  /app1/v1/user=app1,/v1/user
--  /app1/v1/user=app1,/app1/v1/user
--  app1, /app1/**=app1,/app1/**
--  /app1x/**=app1,/app1/**

print( "默认group测试-正常：" )
router:addRoute( {sourcePath="/app1/v1/user",app="app1",targetPath="/v1/user",stripPrefix=false})
router:addRoute( {sourcePath="/app1/v2/user",app="app1",targetPath="/app1/v2/user",stripPrefix=false})
router:addRoute( {sourcePath="/app2/*",app="app2",targetPath="/app20/*",stripPrefix=true})
router:addRoute( {sourcePath="/app3/*",app="app3",stripPrefix=false})
router:addRoute( {sourcePath="/app4/*",app="app4",stripPrefix=true})

-- print(dump(router))


print(router:getMatchRouteTargetPath("/app2/v3/cc"))
print(router:getMatchRouteTargetPath("/app4/v3/cc"))
print(router:getMatchRouteTargetPath("/app4/v3/e"))
print(router:getMatchRouteTargetPath("/app1/v1/user"))
print(router:getMatchRouteTargetPath("/app1/v2/user"))
print(router:getMatchRouteTargetPath("/app2/v3/f"))
print(router:getMatchRouteTargetPath("/app3/v3/f"))

route=router:getMatchRoute("/app2/v3/cc")
print(route.app,route.targetPath)

print( "默认group测试-异常【显示为nil】：" )

print(router:getMatchRouteTargetPath("/app02/v3/cc"))
route=router:getMatchRoute("/app20/v3/cc")
print(route or "nil,不能匹配的路由规则")


print( "")
local groupName = "blog.tietang.wang"
print( "自定义group测试【" .. groupName .. "】：")

router:addRoute( {sourcePath="/blog1/v1/user",app="blog1",targetPath="/v1/user",stripPrefix=false},groupName)
router:addRoute( {sourcePath="/blog1/v2/user",app="blog2",targetPath="/blog1/v2/user",stripPrefix=false},groupName)
router:addRoute( {sourcePath="/blog2/*",app="blog2",targetPath="/blog20/*",stripPrefix=true},groupName)
router:addRoute( {sourcePath="/blog3/*",app="blog3",stripPrefix=false},groupName)
router:addRoute( {sourcePath="/blog4/*",app="blog4",stripPrefix=true},groupName)

-- print( dump( router ) )

print(router:getMatchRouteTargetPath("/blog2/v3/cc",groupName))
print(router:getMatchRouteTargetPath("/blog4/v3/cc",groupName))
print(router:getMatchRouteTargetPath("/blog4/v3/e",groupName))
print(router:getMatchRouteTargetPath("/blog1/v1/user",groupName))
print(router:getMatchRouteTargetPath("/blog1/v2/user",groupName))
print(router:getMatchRouteTargetPath("/blog2/v3/f",groupName))
print(router:getMatchRouteTargetPath("/blog3/v3/f",groupName))

local blogRoute =router:getMatchRoute("/blog2/v3/cc",groupName)
print(blogRoute.app,blogRoute.targetPath)


print( "" )
print( "默认group测试-异常【显示为nil】【" .. groupName .. "】：" )

print(router:getMatchRouteTargetPath("/app02/v3/cc"))
route=router:getMatchRoute("/app20/v3/cc")
print(route or "nil,不能匹配的路由规则")
































































