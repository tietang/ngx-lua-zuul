local _M={}
local allApp="http://127.0.0.1:8761/eureka/apps"
local http = require "resty.http"

function getApps() 
	local httpc=http.new()
    httpc:set_timeout(1000)
    local res,err=httpc:request_uri(url,{
        method ="GET",
        headers = {
              ["Accept"] = "application/json;charset=UTF-8",
          },

    })

    if not res then
        -- ngx.log(ngx.ERR,"failed to request :",err)
        return nil,nil,nil
    end
    local content=res.body
    print(content)

end 

getApps()
