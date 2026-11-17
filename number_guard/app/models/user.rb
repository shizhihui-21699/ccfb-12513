class User < ApplicationRecord
  has_many :login_attempts, dependent: :nullify
  has_many :verifications, dependent: :destroy

  validates :phone, presence: true, uniqueness: true,
            format: { with: /\A1\d{10}\z/, message: "必须是 11 位手机号" }

  before_validation :normalize_phone

  def security_answer=(answer)
    self.security_answer_digest = self.class.digest_answer(answer)
  end

  def security_answer_matches?(answer)
    return false if security_answer_digest.blank? || answer.blank?
    security_answer_digest == self.class.digest_answer(answer)
  end

  def self.digest_answer(answer)
    Digest::SHA256.hexdigest(answer.to_s.strip.downcase)
  end

  # 重新确认手机号归属（核验通过 / 用户主动确认后调用）
  def confirm_phone_now!
    update!(last_phone_confirmed_at: Time.current)
  end

  private

  def normalize_phone
    self.phone = phone.to_s.strip
  end
end
