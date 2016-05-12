local _M = {}


-- local servers={
-- 	{["weight"]=1,["name"]="a",["cweight"]=0},
-- 	{["weight"]=2,["name"]="b",["cweight"]=0},
-- 	{["weight"]=4,["name"]="c",["cweight"]=0}
-- }

_M.servers={}

function _M:setServers(servers )
	self.servers=servers
end

function _M:addServer(server) 
	table.insert(self.servers,server)
end

function _M:down(server)  
	for k,v in pairs(self.servers) do
		if server.name==v.name then
			v.up=false
		end
	end
end

function _M:up(server)  
	for k,v in pairs(self.servers) do
		if server.name==v.name then
			v.up=true
		end
	end
end



function _M:next(servers)
 	local totalWeight = totalWeight(servers)
 	for k,v in pairs(servers) do
		v.cweight=v.weight+v.cweight
	end

	table.sort( servers, 
		function (a,b)
			return a.cweight>b.cweight
		end 
	)
	selected=servers[1]
	selected.cweight=selected.cweight-totalWeight

	return selected

 end

 function totalWeight( servers)
 	local totalWeight = 0
 	for i,v in ipairs(servers) do
 		totalWeight=totalWeight+v.weight
 	end
 	return totalWeight
 end

 return _M

