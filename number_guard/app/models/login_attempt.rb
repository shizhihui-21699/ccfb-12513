class LoginAttempt < ApplicationRecord
  belongs_to :user, optional: true
  has_one :verification, dependent: :destroy

  DECISIONS = %w[allowed blocked].freeze

  REASONS = {
    "ok"                     => "入网时间早于账号确认时间，放行",
    "recycled_number"        => "入网时间晚于账号最后确认时间，疑似回收号，拦截",
    "carrier_data_missing"   => "运营商无该号码数据，放行（待观察）",
    "new_registration"       => "新用户注册，放行"
  }.freeze

  validates :decision, inclusion: { in: DECISIONS }
  validates :reason, inclusion: { in: REASONS.keys }

  scope :blocked, -> { where(decision: "blocked") }
  scope :recent_first, -> { order(created_at: :desc) }

  def blocked?
    decision == "blocked"
  end

  def reason_text
    REASONS[reason] || reason
  end
end
