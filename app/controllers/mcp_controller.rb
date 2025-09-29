class McpController < ApplicationController
  skip_before_action :verify_authenticity_token
  before_action :validate_mcp_request

  def handle
    method = params[:method]
    id = params[:id]

    case method
    when "initialize"
      handle_initialize(id)
    when "ping"
      handle_ping(id)
    when "tools/list"
      handle_tools_list(id)
    when "tools/call"
      handle_tools_call(id, params.dig(:params))
    when "resources/list"
      handle_resources_list(id)
    when "resources/read"
      handle_resources_read(id, params.dig(:params, :uri))
    else
      render json: {
        jsonrpc: "2.0",
        id: id,
        error: {
          code: -32601,
          message: "方法未找到: #{method}"
        }
      }
    end
  end

  private

  def handle_initialize(id)
    render json: {
      jsonrpc: "2.0",
      id: id,
      result: {
        protocolVersion: "2024-11-05",
        capabilities: {
          # 用途：根资源是服务器提供的固定资源入口点，类似于文件系统的根目录。
          # 示例：
          #  一个文件系统 MCP 服务器可能提供 /home、/tmp 等根路径
          #  一个数据库 MCP 服务器可能提供 tables://、schemas:// 等根资源
          roots: {
            list: true, # 支持列出根资源
            read: true  # 支持读取根资源内容
          },
          # 用途：资源是可以通过 URI 标识的数据源，可以是静态的或动态生成的。
          # 示例：
          #   user://recent - 最近用户列表
          #   database://users/123 - 特定用户数据
          #   weather://beijing - 北京天气信息
          # 特点：
          #   资源有唯一的 URI 标识
          #   可以包含元数据（名称、描述、MIME 类型等）
          #   内容可以是文本、JSON、HTML 等格式
          # 对应的方法：
          #   resources/list - 列出所有可用资源
          #   resources/read - 读取特定资源内容
          resources: {
            list: true, # 支持列出可用资源
            read: true  # 支持读取资源内容
          },
          tools: {
            list: true, # 支持列出可用工具
            call: true  # 支持调用工具
          }
        },
        serverInfo: {
          name: "rails-http-mcp-server",
          version: "1.0.0"
        }
      }
    }
  end

  def handle_ping(id)
    render json: {
      jsonrpc: "2.0",
      id: id,
      result: {}
    }
  end

  def handle_tools_list(id)
    tools = [
      {
        name: "search_users",
        description: "根据条件搜索用户",
        inputSchema: {
          type: "object",
          properties: {
            query: { type: "string", description: "搜索关键词" },
            limit: { type: "number", description: "返回结果数量", default: 10 }
          },
          required: []
        }
      },
      {
        name: "create_user",
        description: "创建新用户",
        inputSchema: {
          type: "object",
          properties: {
            name: { type: "string" },
            email: { type: "string" },
            role: { type: "string", enum: [ "admin", "user", "guest" ] }
          },
          required: [ "name", "email" ]
        }
      },
      {
        name: "get_weather",
        description: "获取天气信息",
        inputSchema: {
          type: "object",
          properties: {
            city: { type: "string", description: "城市名称" }
          },
          required: [ "city" ]
        },
        "outputSchema": {
          "type": "object",
          "properties": {
            "forecast": {
              "type": "array",
              "items": {
                "type": "object",
                "properties": {
                  "date": { "type": "string" },
                  "high": { "type": "number" },
                  "low": { "type": "number" },
                  "condition": { "type": "string" }
                },
                "required": [ "date", "high", "low", "condition" ]
              }
            },
            "today": {
              "type": "object",
              "properties": {
                "high": { "type": "number" },
                "low": { "type": "number" },
                "condition": { "type": "string" }
              },
              "required": [ "high", "low", "condition" ]
            }
          },
          "required": [ "forecast", "today" ]
        }
      }
    ]

    render json: {
      jsonrpc: "2.0",
      id: id,
      result: {
        tools: tools
      }
    }
  end

  def handle_tools_call(id, params)
    tool_name = params[:name]
    arguments = params[:arguments] || {}

    result, error_message = case tool_name
    when "search_users"
               handle_search_users(arguments)
    when "create_user"
               handle_create_user(arguments)
    when "get_weather"
               handle_get_weather(arguments)
    else
               [ nil, "未知的工具: #{tool_name}" ]
    end

    if error_message
      render json: {
        jsonrpc: "2.0",
        id: id,
        error: {
          code: -32601,
          message: error_message
        }
      }
    else
      render json: {
        jsonrpc: "2.0",
        id: id,
        result: result
      }
    end
  end

  def handle_resources_list(id)
    resources = [
      {
        uri: "user://recent",
        name: "最近活跃用户",
        description: "显示最近活跃的用户列表",
        mimeType: "text/plain"
      },
      {
        uri: "system://stats",
        name: "系统统计",
        description: "显示系统统计信息",
        mimeType: "application/json"
      }
    ]

    render json: {
      jsonrpc: "2.0",
      id: id,
      result: {
        resources: resources
      }
    }
  end

  def handle_resources_read(id, uri)
    content = case uri
    when "user://recent"
                [ { type: "text", text: "最近用户: 张三, 李四, 王五" } ]
    when "system://stats"
                [ {
                  type: "text",
                  text: JSON.pretty_generate({
                    total_users: User.count,
                    active_today: 42,
                    system_status: "正常"
                  })
                } ]
    else
                nil
    end

    if content
      render json: {
        jsonrpc: "2.0",
        id: id,
        result: {
          contents: content
        }
      }
    else
      render json: {
        jsonrpc: "2.0",
        id: id,
        error: {
          code: -32602,
          message: "资源不存在: #{uri}"
        }
      }
    end
  end

  def validate_mcp_request
    # 这里可以添加认证逻辑，比如 API Key 验证
    # authorization_header = request.headers['Authorization']
    # unless valid_token?(authorization_header)
    #   return render json: { error: "Unauthorized" }, status: 401
    # end
  end

  def handle_search_users(arguments)
    query = arguments["query"]
    limit = arguments["limit"] || 10

    # 模拟搜索逻辑
    if query.present?
      users = [ "张三", "李四", "王五" ].select { |name| name.include?(query) }
      content = "找到 #{users.size} 个用户: #{users.join(', ')}"
    else
      content = "最近用户: 张三, 李四, 王五 (共3人)"
    end

    [ { content: [ { type: "text", text: content } ] }, nil ]
  end

  def handle_create_user(arguments)
    name = arguments["name"]
    email = arguments["email"]
    role = arguments["role"] || "user"

    # 这里应该是实际的用户创建逻辑
    # user = User.create!(name: name, email: email, role: role)

    [ {
      content: [
        {
          type: "text",
          text: "用户创建成功: #{name} (#{email}) - 角色: #{role}"
        }
      ]
    }, nil ]
  end

  def handle_get_weather(arguments)
    city = arguments["city"]

    # 模拟天气API调用
    weather_data = {
      "北京" => "晴, 999°C",
      "上海" => "多云, 3000°C",
      "深圳" => "雨, 80000°C"
    }

    weather = weather_data[city] || "未知城市"

    # { content: [ {
    #   type: "text",
    #   text: "#{city}的天气: #{weather}"
    # } ] }

    structuredContent = {
      "forecast": [
        { "date": "2025-09-28", "high": 28, "low": 21, "condition": "晴1" },
        { "date": "2025-09-29", "high": 27, "low": 22, "condition": "多云" },
        { "date": "2025-09-30", "high": 26, "low": 20, "condition": "小雨" }
      ],
      "today": { "high": 28, "low": 21, "condition": "晴" }
    }

    [
      {
        content: [ {
          type: "text",
          text: structuredContent.to_json
        } ],
        structuredContent: structuredContent
      }, nil
   ]
  end
end
