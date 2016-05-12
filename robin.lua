local _M = {}


 

 function next(servers)
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


 local servers={
	{["weight"]=1,["name"]="a",["cweight"]=0},
	{["weight"]=2,["name"]="b",["cweight"]=0},
	{["weight"]=4,["name"]="c",["cweight"]=0}
}
 


for i=1,7 do
	print(next(servers).name)

end


local s1 = "/app1"
local s2 = "/app1/v1/user"

print("\n"..string.find(s2,s1,1).."\n")
print("\n"..string.find(s2,"/v1/",1).."\n")
local  sf 
if  sf==nil  then
print(sf)
end



