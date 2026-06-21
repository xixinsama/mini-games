# 桌面宠物：接入 DeepSeek + 备忘录 + 人设

**日期：** 2026-06-21
**状态：** 已确认

---

## 概述

将现有的 Ollama 桌面宠物项目改造为 DeepSeek 驱动，新增备忘录功能和人设系统。

### 目标

1. **替换 Ollama 为 DeepSeek** — 使用 deepseek-v4-pro 模型，API key 独立配置文件
2. **备忘录功能** — 右键菜单内嵌标签页，可编辑/保存，持久化到 JSON 文件
3. **主动 AI 行为** — 定时俏皮话 + 空闲检测搭话 + 备忘到期提醒
4. **人设系统** — 通过 人设.md 文件定义角色人格，可爱萌宠风格（不用颜文字）
5. **代码整理** — 删除旧的 Ollama 脚本，清理无用文件


---

## 文件结构




---

## 配置格式

### deepseek_config.json

{
  "api_key": "sk-your-key-here",
  "model": "deepseek-v4-pro",
  "base_url": "https://api.deepseek.com",
  "thinking": true,
  "reasoning_effort": "high"
}

### 人设.md

你是奶龙，一只可爱的桌面宠物小恐龙。
- 性格：软萌、黏人、偶尔撒娇
- 说话风格：句尾用~、！
- 你会主动关心主人、给出提醒、说俏皮话
- 主人叫你主人，自称奶龙

### memos.json

{
  "memos": [
    {
      "id": "uuid-string",
      "content": "明天下午3点开会",
      "deadline": "2026-06-22T15:00:00",
      "created_at": "2026-06-21T21:00:00",
      "pinned": false
    }
  ]
}


---

## Autoload 架构

project.godot autoload 顺序:

| 名称 | 脚本 | 职责 |
|------|------|------|
| ClickThrough | click_through.cs | Windows 穿透点击 |
| DetectPassThrough | detect_pass_through.gd | 透明区域检测 |
| DeepSeekClient | deepseek_client.gd | DeepSeek API (HTTPRequest) |
| MemoManager | memo_manager.gd | 备忘录 CRUD + 持久化 |
| PersonaManager | persona_manager.gd | 人设 + system prompt |

---

## 各模块设计

### DeepSeekClient - AI 通信

- 使用 Godot HTTPRequest 节点 (信号驱动，无需 _process poll)
- 端点: POST {base_url}/chat/completions
- 请求头: Authorization: Bearer {api_key}, Content-Type: application/json
- 请求体: model=deepseek-v4-pro, messages (system+user), thinking enabled, reasoning_effort=high, stream=false
- 响应处理: 提取 choices[0].message.content
- 对 <think> 标签特殊处理: 去除思考过程，只展示最终回复
- 错误处理: 非 2xx 响应通过 error_occurred 信号通知
- 保留简单响应缓存 (基于 prompt + model hash)

信号:
- response_received(message: String)
- error_occurred(message: String)

公开方法:
- send_message(user_text: String)
- send_system_trigger(trigger_type: String, context: Dictionary)

### MemoManager - 备忘录管理

- 加载/保存 memos.json
- CRUD: add_memo, update_memo, delete_memo, get_all_memos, get_expired_reminders
- FileAccess 读写, 文件不存在时创建空 memos 数组

信号:
- memo_updated()
- reminder_due(memo: Dictionary)

### PersonaManager - 人设管理

- 加载 人设.md 文件
- build_system_prompt(trigger_type, context) 拼接人设 + 备忘摘要 + 触发上下文
- 四种触发类型:
  - chat: 人设 + 备忘录摘要
  - random_chatter: 人设 + 随机俏皮话指令
  - idle_check: 人设 + 搭话指令
  - reminder: 人设 + 提醒指令 + 备忘内容


---

## 主动行为设计 (main.gd)

### 定时器
- 每 15-30 分钟随机触发
- 调用 DeepSeekClient.send_system_trigger("random_chatter")
- AI 回复显示在对话气泡，持续数秒后消失

### 空闲检测
- _input() 记录最后活动时间戳
- 超过 5 分钟无输入 -> send_system_trigger("idle_check")
- 冷却: 搭话后 10 分钟内不再触发

### 备忘到期提醒
- _process() 中定期检查 MemoManager.get_expired_reminders()
- 到期未提醒 -> send_system_trigger("reminder", memo)
- 标记已提醒，避免重复

### 启动打招呼
- _ready() 中延迟 2 秒 -> send_system_trigger("greeting")

---

## 场景变更

### main.tscn
- 更新信号连接: OllamaClient -> DeepSeekClient
- 新增 MemoManager 和 PersonaManager 信号

### menu.tscn
- 外层套 TabContainer
- Tab 1 对话: QuitButton + ModelLabel + TextEdit + SendButton
- Tab 2 备忘录: TextEdit (多行) + SaveButton
- 移除 ModelLoading 和 ModelPopup (固定 deepseek-v4-pro)

---

## 数据流

用户对话:
  用户输入 -> DeepSeekClient.send_message(user_text)
           -> POST /chat/completions (system=人设+备忘摘要, user=输入)
           -> response_received signal -> pet.gd 打字机效果

主动触发:
  main.gd timer/idle/reminder -> send_system_trigger(type, ctx)
                              -> POST /chat/completions
                              -> response_received -> pet.gd 气泡

备忘保存:
  menu 备忘录 tab -> MemoManager CRUD -> memos.json
                  -> memo_updated -> UI 刷新

---

## 错误处理

- DeepSeekClient: 网络超时/API错误/解析失败 -> error_occurred 信号
- MemoManager: 文件权限错误 -> 日志 + 返回空数据
- PersonaManager: 人设文件不存在 -> 内置默认人设
- main.gd: 冷却机制防止请求风暴

---

## .gitignore 追加

deepseek_config.json
memos.json
