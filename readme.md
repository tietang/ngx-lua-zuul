依赖：lua-resty-http

基于Nginx&Lua 和Netflix Eureka的微服务网关。

- 动态路由
- 简单监控
- 隔离降级？规划中。。。
- 认证安全？规划中。。。
 

 

## 架构图：

![](<doc/zuul Eureka for nginx&lua.png>)





## 使用方法

```

 
#user  nobody;
worker_processes  2;

#error_log  logs/error.log;
#error_log  logs/error.log  notice;
#error_log  logs/error.log  info;

#pid        logs/nginx.pid;


events {
    worker_connections  1024;
}


http {
    include       mime.types;
    default_type  application/octet-stream;

    #log_format  main  '$remote_addr - $remote_user [$time_local] "$request" '
    #                  '$status $body_bytes_sent "$http_referer" '
    #                  '"$http_user_agent" "$http_x_forwarded_for"';

    #access_log  logs/access.log  main;

    sendfile        on;
    #tcp_nopush     on;

    #keepalive_timeout  0;
    keepalive_timeout  65;

    #gzip  on;

    lua_package_path "/Users/tietang/nginx/nginx/lua/lib/?.lua;;";
    lua_shared_dict discovery 10m;

    lua_shared_dict apps_count 1m;
    lua_shared_dict apps_res_time 10m;
    lua_shared_dict api_count 10m;
    lua_shared_dict api_res_time 10m;

    init_by_lua '
        discovery = require "discovery"
        json=require "cjson"
        balancer=require "robin"
        router = require "router" 

    

    ';
    init_worker_by_lua '
        discovery:schedule() 
    ';

    server {
        listen       8000;
        server_name  localhost;

        #charset koi8-r;

        #access_log  logs/host.access.log  main;
        location /_admin/stats {
            # default_type text/html;
             default_type application/json;
            content_by_lua_file lua/lib/show_stats.lua;
         }

        location /_admin/stats.json {
             default_type application/json;
             content_by_lua_file lua/lib/show_stats_json.lua;
        }
        location / {
            set $bk_host '';
     

            # default_type text/html;
            access_by_lua_file lua/lib/app_route.lua;
                    
        
            log_by_lua_file lua/lib/stats.lua;
            proxy_set_header Host   $host;
            proxy_set_header   X-Real-IP        $remote_addr;
            proxy_pass http://$bk_host;

            #  
        }

        location /haha {
        
            default_type text/html;
            # access_by_lua_file demo/demo.lua;
           content_by_lua '
                --- discovery:say()
                ngx.say( json.encode(router.routingTable) .."<br/>") 
                 ngx.say(  "<br/>")
                ngx.say(json.encode(discovery.hosts ) .."<br/>")
              
            ';
            #  
        }

        
    }


  

}


```