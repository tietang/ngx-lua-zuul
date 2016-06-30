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

    lua_package_path "/Users/tietang/nginx/nginx/lua_lib/lib/?.lua;;";
    lua_shared_dict apps 10m; 
    # lua_shared_dict route_matching_keys 1m;
    lua_shared_dict routes 2m;
    lua_shared_dict apps_count 1m;
    lua_shared_dict apps_res_time 10m;
    lua_shared_dict api_count 10m;
    lua_shared_dict api_res_time 10m;
    init_worker_by_lua  '
          discovery = require "discovery"
          discovery:schedule() 
    '; 
 
    server {
        listen       8000;
        server_name  localhost;
        default_type text/html;

        charset utf8;

       

         location /_admin/stats {
             default_type application/json;
             content_by_lua_file lua_lib/lib/show_stats.lua;
         }

        location / {
            set $bk_host '';
            set $targetUri '';


            # default_type text/html;
            access_by_lua_file lua_lib/lib/app_route.lua;
 

            log_by_lua_file lua_lib/lib/stats.lua;
            proxy_set_header Host   $host;
            proxy_set_header   X-Real-IP        $remote_addr;
            proxy_pass http://$bk_host;


        }

       
 

        #error_page  404              /404.html;

        # redirect server error pages to the static page /50x.html
        #
        error_page   500 502 503 504  /50x.html;
        location = /50x.html {
            root   html;
        }

 
    }



}


```