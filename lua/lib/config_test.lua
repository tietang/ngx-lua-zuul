--
-- User: Tietang Wang 铁汤 
-- Date: 16/8/8 14:26
-- Blog: http://tietang.wang
--

local config=require "config"
function dump(o)
    if type(o) == "table" then
        local s = "{ "
        for k,v in pairs(o) do
            if type(k) ~= "number" then k = "\""..k.."\"" end
            s = s .. "["..k.."] = " .. dump(v) .. ","
        end
        return s .. "} "
    else
        return tostring(o)
    end
end
print(dump(config.limiter))