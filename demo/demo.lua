local _M={}

 
function _M:hello(hello) 
    self.content=hello
    self.count= (self.count or 0 )+1

 
end 

function _M:incr(shared, key)
    local v,e = shared:incr(key, 1)
    if v ==nil then
        shared:set(key,1)
        return 1
    end
    return v
end

_M:hello("wok")

return _M