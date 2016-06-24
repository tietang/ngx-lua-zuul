
 local cjson = require "cjson"



function json1()

	local t1 = os.time()
	for i=1, 1000000 do 
	local apps=cjson.decode('{"apps":[{"name":"GATEAWAY","hosts":[{"name":"GATEAWAY","id":"192.168.99.1:gateaway","hostName":"192.168.99.1","ip":"192.168.99.1","port":8080,"sport":null,"status":"UP","lastRenewalTimestamp":1451974902150}]}],"timestamp":1451974835461}')
 

	end
	local t2 = os.time()

	print(1000000/(t2-t1),t2-t1)
	 
end


function lua1()

	local t1 = os.time()
	for i=1, 1000000 do 
	local f=assert(load('return {apps={{name="GATEAWAY",hosts={{name="GATEAWAY",id="192.168.99.1:gateaway",hostName="192.168.99.1",ip="192.168.99.1",port=8080,sport=nil,status="UP",lastRenewalTimestamp=1451963306051}}}},timestamp=1451963237677}' ))
	local  apps =  f()

	end
	local t2 = os.time()

	print(1000000/(t2-t1),t2-t1)
	 
end

function jsonPrint()

	local t1 = os.time()
	 
	local apps=cjson.decode('{"apps":[{"name":"GATEAWAY","hosts":[{"name":"GATEAWAY","id":"192.168.99.1:gateaway","hostName":"192.168.99.1","ip":"192.168.99.1","port":8080,"sport":null,"status":"UP","lastRenewalTimestamp":1451974902150}]}],"timestamp":1451974835461}')
 	local hosts = {}
 	for index,appList in pairs(apps.apps) do
 		local x = 1
 		hosts[appList.name]={}
        for k,v in pairs(appList.hosts) do
            if v.status=="UP" then
            	self.hosts[v.name][x]="http://" .. v.hostName .. ":" .. v.port
                x=x+1
            end
        print(k,v.name)
       	end
        print(index,appList.name)
    end

	 
	local t2 = os.time()

	print(1000000/(t2-t1),t2-t1)
	 
end

jsonPrint()
for i=1,10 do

	-- lua1()
	-- json1()

end	
