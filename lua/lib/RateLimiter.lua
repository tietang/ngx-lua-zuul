--
-- User: Tietang Wang 铁汤 
-- Date: 16/8/5 10:41
-- Blog: http://tietang.wang
--





local _M = {
    type = "LeakyBucket", --Leaky Bucket or Token Bucket
    config = {
        default = {}
    }
}





local defaultPermitsPerSecond = 10000 -- 最大请求数,默认10k

table.insert(_M.config.default, defaultPermitsPerSecond) -- 默认10k

function _M:config(config, share)
    self.share = share
    for k, v in pairs(config) do
        table.insert(self.config[k], v[1] or defaultPermitsPerSecond)
    end
end


return _M

