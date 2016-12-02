

# 编译和运行eureka demo服务

demo包括了一个单实例Eureka Server，Zuul 路由和API demo服务。

> cd java
> 
> mvn clean install
> 
> cd java/discovery/target
> 
> PID_FOLDER=./ LOG_FOLDER=./ ./discovery-1.0-exec.jar start
> 
> cd java/api/target
> 
> PID_FOLDER=./ LOG_FOLDER=./ ./api-1.0-exec.jar start
> 
> cd java/zuul/target
> 
> PID_FOLDER=./ LOG_FOLDER=./ ./zuul-1.0-exec.jar start


用浏览器打开：[http://localhost:8761/](<http://localhost:8761/>)

看到如下图所示，及discovery服务和api服务启动成功：
![](<nginx-eureka-demo.png>)

api服务中包含了一个测试endpoint：

> /test/{sleep}/{index} 

api服务端口：7912

**参数：**

- **sleep**: 用来模拟响应时间，取值：`1~Long.MAX_VALUE`
- **index**: 响应json的字符串长度，取值：`0~7`，实际字节数=15+{表格对应字节数}。参考下面表格

		index|字节数
		---| ---	
		0 | 128
		1 | 256
		2 | 512
		3 | 1024
		4 | 2048
		5 | 16*1024
		6 | 64*1024
		7 | 128*1024


例如：http://127.0.0.1:7912/test/1/0 服务端延迟1ms，返回128字节json，实际字节数=15+{表格对应字节数}

