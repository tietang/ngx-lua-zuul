 
local _M ={}
 
local allApp="http://127.0.0.1:8761/eureka/apps"
 
-- https://github.com/pintsized/lua-resty-http
local http=require "resty.http"



function _M:queryApps( ... )
    ---从Eureka server获取注册的apps
    --参考https://github.com/Netflix/eureka/wiki/Eureka-REST-operations
    local httpc=http.new()
    httpc:set_timeout(1000)
    local res,err=httpc:request_uri(allAppUrl,{
        method ="GET",
        headers = {
            ["Accept"] = "application/json;charset=UTF-8",
        },

    })
    -- 响应ok
    if not res  or not res.body then
        ngx.log(ngx.ERR,"getApps failed to request :",err)
        return nil,nil,nil
    end
    --响应数据https://github.com/Netflix/eureka/wiki/Eureka-REST-operations
    local content=res.body
    -- ngx.log(ngx.ERR,content)
    -- json数据转换为lua table
    local eurekaApps = json.decode(content)
    return eurekaApps
end

 