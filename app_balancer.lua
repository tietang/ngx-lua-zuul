

local balancer=require "ngx.balancer"
local robins=require "eureka_robin"
local appRobin=robins["APP1"]
local app=appRobin.next()
local host=app.ip
local port=app.port
local ok,err=balancer.set_current_peer(host,port)

if not ok then
    ngx.log(ngx.ERR, "failed to set the current peer: ", err)

    return ngx.exit(500)
end