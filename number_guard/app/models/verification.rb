# 身份核验单：短信登录被拦截后，用户需通过以下任一方式证明
# “我是账号原主人”，核验方式：
#   email_code        邮箱验证码（向账号绑定邮箱发送验证码）
#   security_question 安全问题（回答注册时设置的安全问题）
#   manual_review     人工审核（用户提交说明，运营在后台审批）
class Verification < ApplicationRecord
  METHODS = %w[email_code security_question manual_review].freeze
  STATUSES = %w[pending passed failed].freeze

  METHOD_TEXTS = {
    "email_code"        => "邮箱验证码",
    "security_question" => "安全问题",
    "manual_review"     => "人工审核"
  }.freeze

  STATUS_TEXTS = {
    "pending" => "待核验",
    "passed"  => "核验通过",
    "failed"  => "核验未通过"
  }.freeze

  belongs_to :user
  belongs_to :login_attempt

  validates :method, inclusion: { in: METHODS }, allow_nil: true
  validates :status, inclusion: { in: STATUSES }

  scope :recent_first, -> { order(created_at: :desc) }
  scope :awaiting_manual_review, -> { where(method: "manual_review", status: "pending") }

  def pending?; status == "pending"; end
  def passed?;  status == "passed";  end
  def failed?;  status == "failed";  end

  def method_text
    method.present? ? METHOD_TEXTS[method] : "未选择"
  end

  def status_text
    STATUS_TEXTS[status] || status
  end

  # ---- 邮箱验证码 ----

  def start_email_code!
    code = format("%06d", SecureRandom.random_number(1_000_000))
    update!(
      method: "email_code",
      payload: { "email_code" => code, "sent_at" => Time.current.iso8601 }.to_json
    )
    # 模拟发送邮件：真实环境走邮件/通知服务，这里写日志并在页面上展示
    Rails.logger.info "[模拟邮件] 向 #{user.email} 发送身份核验验证码: #{code}"
    code
  end

  def email_code
    parsed_payload["email_code"]
  end

  def verify_email_code!(code)
    if pending? && method == "email_code" && code.to_s.strip == email_code
      pass!
      true
    else
      fail!(admin_note: "邮箱验证码错误")
      false
    end
  end

  # ---- 安全问题 ----

  def verify_security_answer!(answer)
    update!(method: "security_question") if method.blank?
    if pending? && user.security_answer_matches?(answer)
      pass!
      true
    else
      fail!(admin_note: "安全问题回答错误")
      false
    end
  end

  # ---- 人工审核 ----

  def submit_manual_review!(note)
    update!(method: "manual_review", applicant_note: note)
  end

  def approve!(admin_note = nil)
    update!(status: "passed", admin_note: admin_note, reviewed_at: Time.current)
    user.confirm_phone_now!
  end

  def reject!(admin_note = nil)
    update!(status: "failed", admin_note: admin_note, reviewed_at: Time.current)
  end

  # 核验通过：重新确认手机号归属
  def pass!
    update!(status: "passed", reviewed_at: Time.current)
    user.confirm_phone_now!
  end

  def fail!(admin_note: nil)
    update!(status: "failed", admin_note: admin_note, reviewed_at: Time.current)
  end

  private

  def parsed_payload
    return {} if payload.blank?
    JSON.parse(payload)
  rescue JSON::ParserError
    {}
  end
end
