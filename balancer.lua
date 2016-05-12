#!/usr/bin/env luajit
local md5 = require "resty/md5"

local _M = {}
local mt = {}
local repository = {}
local time_repository = {}
local vnode_num = 160


mt.__eq = function(x, y)
    if #x == #y then
        for i = 1, #x, 1 do
            if x[i].ip ~= y[i].ip or x[i].port ~= y[i].port then
                return false
            end
        end
    else
        return false
    end
    return true
end

local ok, clear_tab = pcall(require, "table.clear")
if not ok then
    clear_tab = function (tab)
        for k, _ in pairs(tab) do
            tab[k] = nil
        end
    end
end


function print_lua_table (lua_table, indent)
    indent = indent or 0
    for k, v in pairs(lua_table) do
        if type(k) == "string" then
            k = string.format("%q", k)
        end
        local szSuffix = ""
        if type(v) == "table" then
            szSuffix = "{"
        end
        local szPrefix = string.rep("    ", indent)
        formatting = szPrefix.."["..k.."]".." = "..szSuffix
        if type(v) == "table" then
            print(formatting)
            print_lua_table(v, indent + 1)
            print(szPrefix.."},")
        else
            local szValue = ""
            if type(v) == "string" then
                szValue = string.format("%q", v)
            else
                szValue = tostring(v)
            end
            print(formatting..szValue..",")
        end
    end
end

local function get_now_time()
    return ngx.now()
end

local function get_hash_value(original)
    local md5 = md5:new()
    md5:update(original)
    local final = md5:final()
    local bs = {string.byte(final, 1, -1)}
    local sum = 0
    for i, v in ipairs(bs) do
        sum = sum + v * 2^((i%4)*8)
    end
    return sum % 2^32
end

local function create_server_table(servers)
    local server_table = {}
    local next = servers

    while next ~= nil and string.len(next) > 0 do
        local start, stop = string.find(next, '[^%.0-9:]+');
        local server_string = nil
        if (start == nil) then
            server_string = next
            next = nil
        else
            if (start ~= 1) then
                server_string = string.sub(next, 0, start - 1);
            end
            next = string.sub(next, stop + 1)
        end

        if (server_string ~= nil) then
            local _, _, ip, port = string.find(server_string, '^([^:]+):?([0-9]*)$')
            local server = nil
            if (port == nil or string.len(port) == 0) then
                port = 80
            else
                port = tonumber(port)
            end
            server = {ip = ip, port = port}
            table.insert(server_table, server)
        end
    end

    local function compare(x, y)
        if (x.ip == y.ip) then
            return x.port < y.port
        else
            return x.ip < y.ip
        end
    end

    table.sort(server_table, compare)

    -- server_table's equal action
    setmetatable(server_table, mt);
    return server_table
end

local function get_entrance(key)
    return repository[key]
end

local function get_entrance_server_table(entrance)
    return entrance['server_table']
end

local function create_entrance(server_table)

    local total_weight = 0
    local hash_ring = {}
    for index, server in ipairs(server_table) do
        server.fails = 0
        server.max_fails = 5
        server.fail_timeout = 30
        server.checked = 0
        server.effictive_weight = 1
        server.current_weight = 1
        total_weight = total_weight + 1
        for i = 1, vnode_num, 1 do
            local hash_key = server.ip .. server.port .. i
            local hash_value = get_hash_value(hash_key)
            local vnode = {
                server_index = index,
                hash_value = hash_value
            }
            table.insert(hash_ring, vnode)
        end
    end

    local function compare(x, y)
        if (x.hash_value ~= y.hash_value) then
            return x.hash_value < y.hash_value
        else
            return x.server_index < y.server_index
        end
    end

    table.sort(hash_ring, compare)
    local entrance = {
        server_table = server_table,
        hash_ring = hash_ring,
        total_weight = total_weight
    }
    return entrance
end

local function set_entrance(host, entrance)
    repository[host] = entrance
end

local function set_host_time(host)
    time_repository[host] = get_now_time()
end

function _M.get_host_time(host)
    local t = time_repository[host]
    if t == nil then
        t = 0
    end
    return t
end



function _M.init_host_upstream(host, servers)
    set_host_time(host)
    local server_table = create_server_table(servers)
    if (server_table == nil or #server_table == 0) then
        set_entrance(host, nil)
    else
        local old_entrance = get_entrance(host)
        if (old_entrance == nil) then
            local new_entrace = create_entrance(server_table)
            set_entrance(host, new_entrace)
        else
            local old_server_table = get_entrance_server_table(old_entrance)
            if (old_server_table ~= server_table) then
                local new_entrace = create_entrance(server_table)
                set_entrance(host, new_entrace)
            end
        end
    end
end

function _M.prepare(repository_key, hash_key)
    if (repository_key == nil) then
        return nil
    end

    local entrance = get_entrance(repository_key)

    if (entrance == nil) then
        return nil
    end

    if (hash_key ~= nil) then
        local hash = get_hash_value(tostring(hash_key))

        -- find server index
        local ring = entrance.hash_ring
        local front = 1
        local tail = #ring
        local middle = nil
        local ring_index = nil
        while front < tail - 1 and ring[front].hash_value < hash and ring[tail].hash_value > hash do
            middle = math.ceil((front + tail) / 2);
            if ring[middle].hash_value >= hash then
                tail = middle
            else
                front = middle
            end
        end
        if ring[front].hash_value < hash and ring[tail].hash_value >= hash then
            ring_index = tail
        else
            ring_index = front
        end

        local prepared_request = {
            entrance = entrance,
            ring_index = ring_index,
            chash_mode = true,
            last_tried = nil,
            tried_num = 0,
            tried = {},
            invalid_num = 0,
            invalid = {}
        }
        return prepared_request
    else
        local prepared_request = {
            entrance = entrance,
            ring_index = nil,
            server_index = nil,
            chash_mode = false,
            last_tried = nil,
            tried_num = 0,
            tried = {},
            invalid_num = 0,
            invalid = {}
        }
        return prepared_request
    end

end

function _M.action(prepared_request)
    local ring_index = prepared_request.ring_index
    local ring = prepared_request.entrance.hash_ring
    local server_table = prepared_request.entrance.server_table
    local tried = prepared_request.tried
    local invalid = prepared_request.invalid
    local selected_index = nil
    local now = get_now_time()
    local balancer = require("ngx.balancer")

    if (prepared_request.last_tried ~= nil) then
        server_table[prepared_request.last_tried].fails = server_table[prepared_request.last_tried].fails + 1
    end

    if prepared_request.tried_num == 0 then
        balancer.set_more_tries(#server_table - 1)
    end


    if prepared_request.chash_mode == true then
        while true do
            if prepared_request.tried_num + prepared_request.invalid_num == #server_table then
                for i, s in ipairs(server_table) do
                    s.fails = 0
                end
                clear_tab(invalid)
                prepared_request.invalid_num = 0
            end

            local server_index = ring[ring_index].server_index
            local server = server_table[server_index]

            if tried[server_index] == nil and invalid[server_index] == nil then
                if server.fails < server.max_fails or now - server.checked > server.fail_timeout then
                    if server.fails >= server.max_fails then
                        server.fails = 0
                    end
                    selected_index = server_index
                    break
                else
                    invalid[server_index] = true
                    prepared_request.invalid_num = prepared_request.invalid_num + 1
                end
            end
            ring_index = ring_index + 1
            if (ring_index > #ring) then
                ring_index = 1
            end
        end
    else
        -- TODO rr
    end

    server_table[selected_index].checked = now
    prepared_request.last_tried = selected_index
    prepared_request.tried_num = prepared_request.tried_num + 1
    tried[selected_index] = true

    balancer.set_current_peer(server_table[selected_index].ip, server_table[selected_index].port)
end

-- local a = '  192.168.1.1:80; 192.168.1.3:81  ; 192.168.1.2 ; 192.168.1.1:88'
-- local ffi=require('ffi')
-- ffi.load('crypto', true)

return _M