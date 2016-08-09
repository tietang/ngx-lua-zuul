lua-mediatypes
==

MIME type utility module.

## Installation

```
luarocks install mediatypes --from=http://mah0x211.github.io/rocks/
```

## Creating a MediaTypes Object

### mt = mediatypes.new( [mimetypes:string] )


**Parameters**

- `mimetypes:string`: mime types definition string. (default: `mediatype.default`)

**Returns**

1. `mt:table`: mediatypes object

**Example**

```lua
local MediaTypes = require('mediatypes');
local mt = MediaTypes.new([[
    my/mimetype     my myfile;    # this is my example mime type definition
]]);
```

## Methods

### mime = mt:getMIME( ext:string )

returns a MIME type string associated with ext argument.

**Parameters**

- `ext:string`: extension string.

**Returns**

- `mime:string`: mime type string or nil.

**Example**

```lua
print( mt:getMIME('my') ); -- 'my/mimetype'
print( mt:getMIME('myfile') ); -- 'my/mimetype'
```

### ext = mt:getExt( mime:string )

returns a extension strings table associated with mime argument.

**Parameters**

- `mime:string`: mime string.

**Returns**

- `mime:string`: extension strings table or nil.

**Example**

```lua
--[[ output
1	my
2	myfile
--]]
for i, ext in ipairs( mt:getExt('my/mimetype') ) do
    print( i, ext );
end
```
