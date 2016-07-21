
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

        #access_log  logs/host.access.log  main;


        location /_admin/set {
            default_type application/json;
            content_by_lua '

                
                local content=discovery.getApps()
                local dogs = ngx.shared.apps
                if content ~= nil then
                    dogs:set("apps", content)

                end

                ngx.say(content)
             ';
         }

         location /_admin/get {
            default_type application/json;
             content_by_lua '
                 
                local json=require "cjson"
                local shared = ngx.shared.apps
                local apps =shared:get("apps")

                ngx.log(ngx.ERR,"^^^^^^^^^", ngx.var.uri," ",ngx.var.request_uri)


               --- ngx.say(apps)
               --- ngx.say()


                ---local a1 = json.decode(apps)


                ---ngx.say(type(a1))
                ngx.say(ngx.var.uri)
                ngx.say(ngx.var.request_uri)
             

                local discovery = require "discovery"

                ---  ngx.say(discovery.requestTimes)

               ngx.say(json.encode(discovery.apps)) 
                ---ngx.say(json.encode(shared("appHosts")))
    
             ';
         }

         location /_admin/routes {
            default_type application/json;
             content_by_lua '
                 
                local json=require "cjson"
                local shared = ngx.shared.routes
                 
                ngx.say(ngx.var.uri)
                ngx.say(ngx.var.request_uri)
                ngx.say(shared:get("ROUTERS"))
                
                local shared = ngx.shared.apps
                local appHostsJson = shared:get("appHosts")

                ngx.say(appHostsJson)
          
                
    
             ';
         } 

         location /_admin/stats {
            # default_type text/html;
             default_type application/json;
            content_by_lua_file lua_lib/lib/show_stats.lua;
         }

        location /_admin/stats.json {
             default_type application/json;
             content_by_lua_file lua_lib/lib/show_stats_json.lua;
        }

        location / {
            set $bk_host '';
            set $targetUri '';


            # default_type text/html;
            access_by_lua_file lua_lib/lib/app_route.lua;
            # set_by_lua_file $targetPath lua_lib/lib/app_route_set.lua;
            # rewrite_by_lua_file lua_lib/lib/app_route.lua;
            # rewrite_by_lua '
            #     ngx.req.set_uri(ngx.var.targetUri, true) 
            # ';
            
           
            # access_by_lua ' 
            #     local shared = ngx.shared.apps
            #     local apps =shared:get("app1")

            #     local er = require "eureka_robin"
            #     robin=er["app1"]
            #     host=robin.next()
            #      ngx.log(ngx.ERR,"^^^^^^^^^", host.hostStr)
  

            #     ngx.var.bk_host= host.ip .. ":" .. host.port

                
            # ';

            log_by_lua_file lua_lib/lib/stats.lua;
            proxy_set_header Host   $host;
            proxy_set_header   X-Real-IP        $remote_addr;
            proxy_pass http://$bk_host;


        }

       

        location /lua_h {
            # resolver 192.168.10.1; 
            resolver 8.8.8.8;
            default_type text/html;
            content_by_lua '

            ';
        }
        # location / {
            # root   html;
            # index  index.html index.htm;
        # }

        #error_page  404              /404.html;

        # redirect server error pages to the static page /50x.html
        #
        error_page   500 502 503 504  /50x.html;
        location = /50x.html {
            root   html;
        }

        # proxy the PHP scripts to Apache listening on 127.0.0.1:80
        #
        #location ~ \.php$ {
        #    proxy_pass   http://127.0.0.1;
        #}

        # pass the PHP scripts to FastCGI server listening on 127.0.0.1:9000
        #
        #location ~ \.php$ {
        #    root           html;
        #    fastcgi_pass   127.0.0.1:9000;
        #    fastcgi_index  index.php;
        #    fastcgi_param  SCRIPT_FILENAME  /scripts$fastcgi_script_name;
        #    include        fastcgi_params;
        #}

        # deny access to .htaccess files, if Apache's document root
        # concurs with nginx's one
        #
        #location ~ /\.ht {
        #    deny  all;
        #}
    }


    # another virtual host using mix of IP-, name-, and port-based configuration
    #
    #server {
    #    listen       8000;
    #    listen       somename:8080;
    #    server_name  somename  alias  another.alias;

    #    location / {
    #        root   html;
    #        index  index.html index.htm;
    #    }
    #}


    # HTTPS server
    #
    #server {
    #    listen       443 ssl;
    #    server_name  localhost;

    #    ssl_certificate      cert.pem;
    #    ssl_certificate_key  cert.key;

    #    ssl_session_cache    shared:SSL:1m;
    #    ssl_session_timeout  5m;

    #    ssl_ciphers  HIGH:!aNULL:!MD5;
    #    ssl_prefer_server_ciphers  on;

    #    location / {
    #        root   html;
    #        index  index.html index.htm;
    #    }
    #}

}
