# 本地模拟的运营商数据记录。
# 真实场景中这些数据在运营商一侧，这里用本地表模拟，
# 通过 CarrierGateway（模拟运营商接口）查询。
class CarrierRecord < ApplicationRecord
  STATUSES = %w[in_service cancelled].freeze
  CARRIERS = ["中国移动", "中国联通", "中国电信"].freeze

  validates :phone, presence: true, uniqueness: true,
            format: { with: /\A1\d{10}\z/, message: "必须是 11 位手机号" }
  validates :activated_at, presence: true
  validates :status, inclusion: { in: STATUSES }

  scope :in_service, -> { where(status: "in_service") }

  def status_text
    { "in_service" => "在用", "cancelled" => "已销户" }[status] || status
  end
end
