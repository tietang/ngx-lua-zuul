--
-- User: Tietang Wang 铁汤 
-- Date: 16/8/9 14:19
-- Blog: http://tietang.wang
--

local MediaTypes = require('mediatypes');
local mt = MediaTypes.new([[
    my/mimetype     my myfile;    # this is my example mime type definition
]]);

print(mt:getMIME("my"))
print( mt:getMIME('my') ); -- 'my/mimetype'
print( mt:getMIME('myfile') ); -- 'my/mimetype'


local mt2=MediaTypes.new([[
application/json json;
application/json+zip json;

]])

print(mt2:equals("application/json"))