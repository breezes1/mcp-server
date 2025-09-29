### 测试mcp功能

#### 启动rails服务, 以对外输出http mcp服务
bundle i
rails s -p 3002

#### 启动调试 modelcontextprotocol/inspector
使用固定config，关闭鉴权，http传输
默认端口6277
npx @modelcontextprotocol/inspector --config ./modelcontextprotocol/config.json -e DANGEROUSLY_OMIT_AUTH=true --transport http