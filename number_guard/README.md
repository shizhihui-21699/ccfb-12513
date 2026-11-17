# NumberGuard · 号码回收风险防护服务

运营商会把注销的手机号回收再售，新机主凭短信验证码即可登入前任机主的账号。
本服务在短信登录链路中插入一道**号码回收风险判定**：登录时查询（本地模拟的）
运营商接口获取号码**入网时间**，若入网时间**晚于**账号侧**最后一次确认手机号
归属的时间**，说明号码很可能已易主 —— 暂停短信登录，改走其他身份核验。

## 核心判定规则

```
运营商入网时间(carrier.activated_at) > 账号最后确认手机号时间(user.last_phone_confirmed_at)
    → 拦截短信登录，生成风控记录 + 身份核验单
    → 否则放行
```

`last_phone_confirmed_at` 只会在以下时机刷新，**普通登录不会刷新它**（否则判定失效）：

- 新用户注册
- 身份核验通过
- 用户在账号页主动点击“确认本号码仍归我所有”

边界情况：运营商查无该号码数据时放行，但风控记录标记 `carrier_data_missing` 便于后台观察。

## 身份核验方式（三种，定义见 `app/models/verification.rb`）

| 方式 | 说明 |
|---|---|
| 邮箱验证码 `email_code` | 向账号绑定邮箱发 6 位验证码（演示环境模拟发送，验证码直接显示在页面/日志） |
| 安全问题 `security_question` | 回答注册时设置的安全问题（答案 SHA256 摘要存储） |
| 人工审核 `manual_review` | 用户提交归属说明，运营在后台人工通过/拒绝 |

核验通过后自动刷新 `last_phone_confirmed_at`，该号码后续即可正常短信登录。

## 代码结构

```
app/services/carrier_gateway.rb       # 模拟运营商接口（本地 carrier_records 表，可整体替换为 HTTP 客户端）
app/services/recycled_number_risk.rb  # 风险判定规则
app/models/login_attempt.rb           # 每次短信登录的风控判定记录（含入网时间/确认时间快照）
app/models/verification.rb            # 身份核验单（三种方式 + 状态机）
app/controllers/sessions_controller.rb    # 短信登录主流程
app/controllers/verifications_controller.rb # 用户侧核验
app/controllers/admin/                # 运营后台（HTTP Basic 认证）
```

## 运营后台

`/admin`，HTTP Basic 认证，默认 `admin / admin123`（可用环境变量
`ADMIN_USER` / `ADMIN_PASSWORD` 覆盖）：

- **概览**：今日登录/拦截/放行、待人工审核、累计核验通过与失败
- **登录风控记录**：每次判定的放行/拦截及原因、入网时间与确认时间快照、IP/UA
- **身份核验单**：按状态/方式筛选，人工审核的通过/拒绝操作
- **用户**：账号信息与其风控记录
- **运营商数据(模拟)**：维护本地模拟的号码入网数据，可自行构造回收号场景

## 运行

```bash
bundle install --local
bin/rails db:migrate db:seed
bin/rails server -p 3001
```

> 注意：本机 3000 端口被其他进程占用时请换端口。
> 仓库中 `lib/openssl3_gcm_fix.rb` 是系统 Ruby 2.6（LibreSSL 3）无法处理
> GCM AAD 的兼容补丁，将 GCM 加密降级为 CBC+HMAC，仅开发环境使用。

## 演示场景（种子数据）

| 手机号 | 场景 | 预期 |
|---|---|---|
| 13800000001 | 入网 2020，确认 2024 | 放行 |
| 13800000002 | 入网 2025（回收再售），确认 2023 | **拦截** → 邮箱验证码（lisi@example.com）/ 安全问题（答案：豆豆）/ 人工审核 |
| 13800000004 | 正常 | 放行 |
| 其他号码 | 未注册 | 自动注册；再次登录时运营商无数据，放行并标记待观察 |
