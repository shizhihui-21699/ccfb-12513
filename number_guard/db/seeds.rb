# 种子数据：覆盖三种典型场景
#
# 1) 13800000001 正常用户：入网时间早于账号确认时间 → 短信登录放行
# 2) 13800000002 回收号：号码 2025 年重新入网，晚于账号最后确认时间 → 拦截，走身份核验
# 3) 13800000003 运营商无数据 → 放行并记录“待观察”

CarrierRecord.find_or_create_by!(phone: "13800000001") do |r|
  r.carrier_name = "中国移动"
  r.activated_at = Time.zone.parse("2020-05-01 10:00:00")
end

CarrierRecord.find_or_create_by!(phone: "13800000002") do |r|
  r.carrier_name = "中国联通"
  r.activated_at = Time.zone.parse("2025-08-15 09:30:00") # 回收后重新放号
end

CarrierRecord.find_or_create_by!(phone: "13800000004") do |r|
  r.carrier_name = "中国电信"
  r.activated_at = Time.zone.parse("2019-11-20 14:00:00")
end

User.find_or_create_by!(phone: "13800000001") do |u|
  u.email = "zhangsan@example.com"
  u.nickname = "张三"
  u.security_question = "我小学班主任的姓氏？"
  u.security_answer = "王"
  u.last_phone_confirmed_at = Time.zone.parse("2024-01-10 12:00:00")
end

User.find_or_create_by!(phone: "13800000002") do |u|
  u.email = "lisi@example.com"
  u.nickname = "李四"
  u.security_question = "我的第一只宠物名字？"
  u.security_answer = "豆豆"
  # 原机主 2023 年确认过号码，之后弃用被运营商回收
  u.last_phone_confirmed_at = Time.zone.parse("2023-06-01 08:00:00")
end

User.find_or_create_by!(phone: "13800000004") do |u|
  u.nickname = "王五"
  u.last_phone_confirmed_at = Time.zone.parse("2024-12-01 10:00:00")
end

puts "种子数据完成：用户 #{User.count} 个，运营商记录 #{CarrierRecord.count} 条"
