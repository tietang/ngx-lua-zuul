 
local _M ={}
 
local allApp="http://127.0.0.1:8761/eureka/apps"
 
-- https://github.com/pintsized/lua-resty-http
local http=require "resty.http"



function _M:queryAllApps(allAppUrl)
    ---从Eureka server获取注册的apps
    --参考https://github.com/Netflix/eureka/wiki/Eureka-REST-operations
    httpc:set_timeout(1000)
    local obj,err= self:httpRequest("GET",allAppUrl)
    return obj
end

function _M:getAllAppHosts( allAppUrl)
    local eurekaApps = self:queryAllApps(allAppUrl)
    -- 定义app对象
    local apps = {apps={},timestamp=os.time()*1000}


    --[[
    local hosts = {
        appName={
            [1]="http://127.0.0.1:8080",
            [2]="http://127.0.0.2:8082"
            [3]="http://127.0.0.3:8083"
        },
        app2={
            [1]="http://127.0.0.1:8080",
            [2]="http://127.0.0.6:8080"
        },
        app3={
            [1]="http://127.0.0.7:8080",
            [2]="https://127.0.0.9:8443",
            [3]="https://127.0.0.1:8443"
        }  

    }
    ]]--
    local hosts = {}
    for k,v in pairs(eurekaApps.applications.application) do

        local app,appHosts = eureka2app(v)
        table.insert(apps.apps,app)

        hosts[v.name]=app.hosts --appHosts
        -- ngx.log(ngx.ERR, os.time(),table.getn(appHosts))

    end



    --[[
        json格式例子
        {
            "timestamp": 1452042891719,
            "apps": [
                {
                    "name": "GATEAWAY",
                    "hosts": [
                        {
                            "lastRenewalTimestamp": 1452042964223,
                            "hostName": "192.168.99.1",
                            "ip": "192.168.99.1",
                            "id": "192.168.99.1:gateaway",
                            "status": "UP",
                            "sport": null,
                            "name": "GATEAWAY",
                            "port": 8080
                        }
                    ]
                }
            ]
        }    
    --]]


    self.apps=apps

    local shared = ngx.shared.discovery
    self.requestTimes = getAndSetCountByAppName(shared,"requestTimes")
    if apps == nil then
        return content,nil,nil
    end



    self.hosts=hosts




    -- ngx.log(ngx.ERR, type(apps))
    -- print(type(apps))

    -- ngx.log(ngx.ERR, "content=",content,", requestTimes: ",self.requestTimes)

    -- ngx.log(ngx.ERR, json.encode(self.hosts))

    return hosts,apps
end
 

function _M:httpRequest(method,url)

    local httpc=http.new()
    httpc:set_timeout(1000)
    local res,err=httpc:request_uri(allAppUrl,{
        method = method,
        headers = {
            ["Accept"] = "application/json",
            ["Content-Type"] = "application/json;charset=UTF-8",
        },

    })
    -- 响应ok
    if not res  or not res.body then
        ngx.log(ngx.ERR,"getApps failed to request :",err)
        return nil,err 
    end
    
    local content=res.body
    -- ngx.log(ngx.ERR,content)
    -- json数据转换为lua table
    local obj = json.decode(content)
    return obj,err

end



function eureka2app(application,hosts )


    local appName = application.name
    local app = {
        name=appName,
        hosts={}
    }


    -- for index,appList in pairs(apps.apps) do
    --     local x = 1
    --     hosts[appList.name]={}
    --     for k,v in pairs(appList.hosts) do
    --         if v.status=="UP" then
    --             hosts[v.name][x]="http://" .. v.hostName .. ":" .. v.port
    --             -- ngx.log(ngx.ERR, self.hosts[v.name][x])
    --             x=x+1

    --         end
    --     -- print(k,v.name)
    --     end
    --     -- print(index,appList.name)
    -- end
    local hosts = {}


    for k,v in pairs(application.instance) do

        local ip = v.ipAddr
        local hostName = v.hostName
        local port = v.port["$"]
        local schema = "http"
        if v.securePort["@enabled"] == "true" then
            port = v.securePort["$"]
            schema="https"
        end
        local url= schema.."://" .. hostName .. ":" .. port
        local hostStr = hostName .. ":" .. port

        local host={
            name=appName,
            hostName=hostName,
            ip=ip,
            port=port,
            healthCheckUrl=v.healthCheckUrl,
            status=v.status,
            lastRenewalTimestamp=v.leaseInfo.lastRenewalTimestamp,
            url=url,
            hostStr=hostStr,
            weight=10,
            cweight=0
        }

        table.insert(app.hosts,host)



        -- ngx.log(ngx.ERR,"app=",appName," ip=",ip," hostName=",hostName," port=",port)
    end
    return app,hosts
end

 