local _M = {
    _VERSION="1.0",
    requestTimes=0,
    loadTime=os.date(),
    apps={},
    hosts={},


}

local http=require "resty.http"
-- https://github.com/pintsized/lua-resty-http
local json=require "cjson"
local url="http://127.0.0.1:8761/v1/apps"

--[[
    请求discovery，获取在线服务器列表
--]]
function _M:getAllApps()
    
    local httpc=http.new()
    httpc:set_timeout(1000)
    local res,err=httpc:request_uri(url,{
        method ="GET",
        headers = {
              ["Accept"] = "application/json",
          },

    })

    if not res then
        ngx.log(ngx.ERR,"failed to request :",err)
        return nil,nil,nil
    end
    local content=res.body
    -- local f=assert(loadstring("return " .. content))
    -- local  apps =  f()
    -- ngx.log(ngx.ERR, type(apps))
           
    --转换json字符串到lua table
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
    local apps = json.decode(content)
    self.apps=apps 
   
    local shared = ngx.shared.apps
    self.requestTimes = getAndSetCountByAppName(shared,"requestTimes")
    if apps == nil then
        return content,nil,nil
    end

    --[[
        hosts格式：
        {
            "GATEAWAY": [
                "http://192.168.99.1:8080",
                "http://192.168.99.2:8080",
            ]
        }
    --]]

    local hosts = {}
    for index,appList in pairs(apps.apps) do
        local x = 1
        hosts[appList.name]={}
        for k,v in pairs(appList.hosts) do
            if v.status=="UP" then
                hosts[v.name][x]="http://" .. v.hostName .. ":" .. v.port
                -- ngx.log(ngx.ERR, self.hosts[v.name][x])
                x=x+1
                
            end
        -- print(k,v.name)
        end
        -- print(index,appList.name)
    end
    self.hosts=hosts

    



    -- ngx.log(ngx.ERR, type(apps))
        -- print(type(apps))

    ngx.log(ngx.ERR, "content=",content,", requestTimes: ",self.requestTimes)

    return content,hosts,apps
end


--[[

启动定时任务，获取在线服务器列表

--]]
local KEY_LAST_EXECUTED_PID = "last_executed_pid"
local KEY_LAST_EXECUTED_PID_TIME = "last_executed_pid_time"
local KEY_LAST_EXECUTED_TIME = "last_executed_time"


function _M:schedule()
 
    local shared = ngx.shared.apps
    local interval=1 

    function getAndSet(premature, shared ) 

        
        local c = ngx.worker.count()
        local currentWorkerPid = ngx.worker.pid()--ngx.var.pid -- 

        local last_executed_pid = shared:get(KEY_LAST_EXECUTED_PID)
        local last_executed_time = shared:get(KEY_LAST_EXECUTED_TIME)
        local keyPidTime = KEY_LAST_EXECUTED_PID_TIME.."-"..currentWorkerPid
        local last_executed_pid_time = shared:get(keyPidTime)
      

    
       
        local now = ngx.now()
        local rt = shared:get("requestTimes")
        -- ngx.log(ngx.ERR," ",currentWorkerPid," ",currentWorkerPid%c,",",ngx.time()%c,",",rt)

        -- if last_executed_pid_time == nil then
            -- last_executed_pid_time=now
        -- end
        -- ngx.log(ngx.ERR,"worker count:",c,", PID:",currentWorkerPid,",",last_executed_time,",",now-last_executed_time,",",interval-0.1)
        --旨在同一时间只有一个worker执行定时任务，并且不一致在同一个worker执行
        if last_executed_pid ==nil or last_executed_time == nil or last_executed_pid_time==nil
            or (
                    (now-last_executed_time) >= interval-0.1 --如果最后执行时间>=设定间隔-0.1，-0.1是纠正偶尔存在的执行时间偏差
                and last_executed_pid ~= currentWorkerPid -- 如果当前worker pid != 最后一次worker pid
                and (now-last_executed_pid_time) >= interval*c-0.1 --如果当前worker最后执行时间 >= 设定间隔*worker数量 - 0.1

            ) then
        -- if ngx.time()%c==currentWorkerPid %c then

            local content,hosts,apps=_M:getAllApps()
            
            if content ~= nil then
                local succ, err, forcible = shared:set("apps", content) 
                    ---ngx.log(ngx.ERR, "succ:", succ, " err:", err,"forcible",forcible)
            end

            if hosts ~= nil then
                for k,v in pairs(hosts) do
                    shared:set(k,json.encode(v))
                end
            end

            shared:set(KEY_LAST_EXECUTED_TIME,now)
            shared:set(KEY_LAST_EXECUTED_PID,currentWorkerPid)
            shared:set(keyPidTime,now)
        end

        local ok,err = ngx.timer.at(interval,getAndSet,shared)
        -- local last=shared:get("lastRenewalTimestamp")
        ngx.log(ngx.DEBUG, "ok:", ok, " err:", err)
    end
    
    local ok,err = ngx.timer.at(interval,getAndSet,shared)
    ngx.log(ngx.DEBUG, "ok:", ok, " err:", err)  

end

function isUP(url)
    
    local httpc=http.new()
    httpc:set_timeout(1000)
    local res,err=httpc:request_uri(url,{
        method ="GET",
    })

    if not res or res.status == ngx.HTTP_OK then
        ngx.log(ngx.ERR,"failed to request :",err)
        return false 
    end    
end



function _M:getHttpEndpont(path)
    local shared = ngx.shared.apps
    local apps =shared:get("apps")
    local uri = ngx.var.uri
    local first,last = string.find(uri,"/",2)
    local appName = string.upper(string.sub(s,0,first-1))
    -- local hosts=self.hosts[appName]
    local hostsStr=shared:get(string.upper(appName))
    local hosts = json.decode(hostsStr)
    local x = self:getAndSetCountByAppName(appName)%table.nums(hosts)+1
    return hosts[x]
end

function _M:getAndSetCountByAppName( appName)
    local shared = ngx.shared.apps_count
    return getAndSetCountByAppName(shared,appName)
end

function getAndSetCountByAppName(shared, appName)
    
    local v,e = shared:incr(appName, 1)
    if v ==nil then
        shared:set(appName,1)
        return 1
    end
    return v
end
-- function _M.getHostByName(shared,name,balance)
--     local apps=shared:get("apps")
--     self.apps=
     
-- end

-- apps={
--     ["CALM_EDGE"]={
--         {
--             name="CALM_EDGE",
--             id= "192.168.99.1:calm_edge",
--             hostName="192.168.99.1",
--             ip="192.168.99.1",
--             port=8080,
--             sport=null,
--             status="UP",
--             lastRenewalTimestamp=1451030859398
 
--         }
--     }
-- }

return _M

-- {
--     "apps": [
--         {
--             "name": "CALM_EDGE",
--             "hosts": [
--                 {
--                     "name": "CALM_EDGE",
--                     "id": "192.168.99.1:calm_edge",
--                     "hostName": "192.168.99.1",
--                     "ip": "192.168.99.1",
--                     "port": 8080,
--                     "sport": null,
--                     "status": "UP",
--                     "lastRenewalTimestamp": 1451030859398
--                 }
--             ]
--         }
--     ],
--     "timestamp": 1451030794105
-- }
                -- local http=require "resty.http"
                -- local httpc=http.new()
                -- httpc:set_timeout(1000)
                -- local res,err=httpc:request_uri("http://127.0.0.1:8761/v1/apps",{
                --     method ="GET"
                -- })

                -- if not res then
                --     ngx.say("failed to request :",err)
                --     return
                -- end
                -- local content=res.body
                -- ngx.log(ngx.ERR,content)