# 短信验证码登录。
# 流程：输入手机号 → 发送验证码（模拟） → 提交验证码 →
# 号码回收风险判定 → 放行登录 / 拦截并转身份核验。
class SessionsController < ApplicationController
  CODE_TTL = 5.minutes

  def new
    redirect_to root_path if logged_in?
  end

  # 发送短信验证码（模拟：验证码直接展示在页面上）
  def send_code
    phone = params[:phone].to_s.strip
    unless phone.match?(/\A1\d{10}\z/)
      redirect_to login_path, alert: "请输入正确的 11 位手机号" and return
    end

    code = format("%06d", SecureRandom.random_number(1_000_000))
    session[:sms_login] = { "phone" => phone, "code" => code, "sent_at" => Time.current.to_i }
    Rails.logger.info "[模拟短信] 向 #{phone} 发送登录验证码: #{code}"
    redirect_to login_path(phone: phone), notice: "验证码已发送（模拟短信，验证码：#{code}，5 分钟内有效）"
  end

  def create
    pending = session[:sms_login]
    phone = params[:phone].to_s.strip
    code  = params[:code].to_s.strip

    unless pending && pending["phone"] == phone
      redirect_to login_path(phone: phone), alert: "请先获取短信验证码" and return
    end
    if Time.current.to_i - pending["sent_at"] > CODE_TTL
      session.delete(:sms_login)
      redirect_to login_path(phone: phone), alert: "验证码已过期，请重新获取" and return
    end
    unless pending["code"] == code
      redirect_to login_path(phone: phone), alert: "验证码错误" and return
    end

    session.delete(:sms_login)
    user = User.find_by(phone: phone)

    if user.nil?
      # 新用户：短信验证通过即注册，入网确认时间记为当前
      user = User.create!(phone: phone, last_phone_confirmed_at: Time.current)
      record_attempt(user: user, phone: phone, decision: "allowed", reason: "new_registration")
      log_in(user)
      redirect_to root_path, notice: "注册成功，欢迎！" and return
    end

    # —— 号码回收风险判定 ——
    risk = RecycledNumberRisk.check(user: user)
    attempt = record_attempt(user: user, phone: phone,
                             decision: risk.allowed? ? "allowed" : "blocked",
                             reason: risk.reason,
                             carrier_activated_at: risk.carrier_activated_at,
                             phone_confirmed_at: risk.phone_confirmed_at)

    if risk.allowed?
      log_in(user)
      redirect_to root_path, notice: "登录成功"
    else
      verification = Verification.create!(user: user, login_attempt: attempt)
      redirect_to verification_path(verification),
                  alert: "该手机号入网时间晚于账号记录，存在回收再售风险。为保障账号安全，已暂停短信登录，请通过其他方式核验身份。"
    end
  end

  def destroy
    reset_session
    redirect_to login_path, notice: "已退出登录"
  end

  private

  def log_in(user)
    reset_session
    session[:user_id] = user.id
  end

  def record_attempt(user:, phone:, decision:, reason:, carrier_activated_at: nil, phone_confirmed_at: nil)
    LoginAttempt.create!(
      user: user, phone: phone, decision: decision, reason: reason,
      carrier_activated_at: carrier_activated_at,
      phone_confirmed_at: phone_confirmed_at,
      ip: request.remote_ip, user_agent: request.user_agent.to_s.first(200)
    )
  end
end
