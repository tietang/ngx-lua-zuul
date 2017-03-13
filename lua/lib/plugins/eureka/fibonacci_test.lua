--
-- User: Tietang Wang 铁汤 
-- Date: 2017/3/13 16:52
-- Blog: http://tietang.wang
--

local f = require "fibonacci"

--for i, v in pairs(f.FibonacciTable) do
--    print(i, v[3])
--end

for i = 1, 1000, 30 do
    k=i-100
    print(i,k,f:getCeiling(k))
end
