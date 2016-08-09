--
-- User: Tietang Wang 铁汤 
-- Date: 16/8/9 15:01
-- Blog: http://tietang.wang
--


local MSG = {}
MSG.supportMediaTypes = {
    ["application/json"] = "json",
    ["application/xml"] = "xml",
    ["application/html"] = "text",
    ["text/html"] = "text",
}

local MediaTypes = require('mediatypes');

function MSG:toString(encodeFun, status, err, msg, path)
    local msg = {
        timestamp = os.time * 1000, -- or ngx.now(),
        status = status,
        error = err,
        message = msg,
        path = path
    }
    return encodeFun(msg)
end

function MSG:encodeFun(mimeType)
    local mt = MediaTypes.new(mimeType);
    for k, v in pairs() do
        local type = self.supportMediaTypes[mimeType]
        if type then
            if type == "json" then return cjson.encode
            elseif type == "xml" then return toXml
            else return toText
            end
        else
            return toText
        end
    end
end

local function toText(msg)
    return cjson.encode(msg)
end

local function toXml(msg)
    return cjson.encode(msg)
end

