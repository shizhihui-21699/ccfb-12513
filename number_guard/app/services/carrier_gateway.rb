# 模拟运营商接口。
# 真实场景：通过 HTTP 调用运营商的号码状态查询服务，返回号码的入网时间。
# 这里用本地 carrier_records 表模拟，接口形态保持一致，便于日后替换为真实 HTTP 客户端。
class CarrierGateway
  Result = Struct.new(:found?, :phone, :activated_at, :carrier_name, :status, keyword_init: true)

  # 查询号码当前的入网信息；查不到返回 found? = false 的 Result
  def self.lookup(phone)
    Rails.logger.info "[CarrierGateway] 模拟调用运营商接口查询号码 #{phone}"
    record = CarrierRecord.find_by(phone: phone.to_s.strip)
    if record
      Result.new(found?: true, phone: record.phone, activated_at: record.activated_at,
                 carrier_name: record.carrier_name, status: record.status)
    else
      Result.new(found?: false, phone: phone.to_s.strip)
    end
  end
end
