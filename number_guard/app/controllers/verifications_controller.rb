# 被拦截用户的身份核验（用户侧）。
class VerificationsController < ApplicationController
  before_action :load_verification
  before_action :ensure_pending!, except: :show

  def show
    if @verification.passed?
      redirect_to root_path, notice: "身份核验已通过" and return
    end
    @email_code_sent = @verification.method == "email_code" && @verification.pending?
  end

  # 选择邮箱验证码：生成并“发送”
  def start_email_code
    if @verification.user.email.blank?
      redirect_to verification_path(@verification), alert: "该账号未绑定邮箱，请选择其他核验方式" and return
    end
    code = @verification.start_email_code!
    redirect_to verification_path(@verification),
                notice: "验证码已发送至绑定邮箱 #{masked_email}（模拟邮件，验证码：#{code}）"
  end

  def verify_email_code
    if @verification.verify_email_code!(params[:email_code])
      log_in_and_redirect "邮箱核验通过，已恢复登录"
    else
      redirect_to verification_path(@verification), alert: "验证码错误，核验未通过。请重新选择核验方式。"
    end
  end

  def verify_security_question
    if @verification.user.security_question.blank?
      redirect_to verification_path(@verification), alert: "该账号未设置安全问题，请选择其他核验方式" and return
    end
    if @verification.verify_security_answer!(params[:security_answer])
      log_in_and_redirect "安全问题核验通过，已恢复登录"
    else
      redirect_to verification_path(@verification), alert: "回答错误，核验未通过。请重新选择核验方式。"
    end
  end

  def submit_manual_review
    note = params[:applicant_note].to_s.strip
    if note.length < 10
      redirect_to verification_path(@verification), alert: "请至少填写 10 个字的说明，便于运营审核" and return
    end
    @verification.submit_manual_review!(note)
    redirect_to verification_path(@verification),
                notice: "已提交人工审核，运营处理后会更新核验结果。审核通过前请留意本页面。"
  end

  private

  def load_verification
    @verification = Verification.find(params[:id])
  end

  def ensure_pending!
    unless @verification.pending?
      redirect_to verification_path(@verification), alert: "该核验单已处理完毕"
    end
  end

  def log_in_and_redirect(message)
    reset_session
    session[:user_id] = @verification.user.id
    redirect_to root_path, notice: message
  end

  def masked_email
    email = @verification.user.email.to_s
    name, domain = email.split("@", 2)
    "#{name.to_s.first(2)}***@#{domain}"
  end
end
