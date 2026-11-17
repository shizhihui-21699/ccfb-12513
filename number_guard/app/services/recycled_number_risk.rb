# 号码回收风险判定。
#
# 核心规则：运营商处该号码的（当前持有人）入网时间 晚于
# 账号侧最后一次确认手机号归属的时间 → 号码很可能被回收转售，
# 当前持机人可能不是账号主人 → 暂停短信登录，改走其他身份核验。
class RecycledNumberRisk
  Decision = Struct.new(:allowed?, :reason, :carrier_activated_at, :phone_confirmed_at, keyword_init: true)

  def self.check(user:)
    carrier = CarrierGateway.lookup(user.phone)

    unless carrier.found?
      # 运营商查无数据：无法判断，放行但记录，便于后台观察
      return Decision.new(allowed?: true, reason: "carrier_data_missing",
                          carrier_activated_at: nil,
                          phone_confirmed_at: user.last_phone_confirmed_at)
    end

    if carrier.activated_at > user.last_phone_confirmed_at
      Decision.new(allowed?: false, reason: "recycled_number",
                   carrier_activated_at: carrier.activated_at,
                   phone_confirmed_at: user.last_phone_confirmed_at)
    else
      Decision.new(allowed?: true, reason: "ok",
                   carrier_activated_at: carrier.activated_at,
                   phone_confirmed_at: user.last_phone_confirmed_at)
    end
  end
end
