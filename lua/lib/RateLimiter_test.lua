--
-- User: Tietang Wang 铁汤 
-- Date: 16/8/5 10:41
-- Blog: http://tietang.wang
--



local share = {}

function share:incr(key, value, initValue)
    self[key] = (self[key] or 0) + value + initValue;
    return self[key]
end


