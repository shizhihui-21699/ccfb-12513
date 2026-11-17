module Admin
  class VerificationsController < BaseController
    def index
      @verifications = Verification.recent_first.includes(:user, :login_attempt)
      @verifications = @verifications.where(status: params[:status]) if params[:status].in?(Verification::STATUSES)
      @verifications = @verifications.where(method: params[:method]) if params[:method].in?(Verification::METHODS)
      @verifications = @verifications.limit(200)
    end

    def show
      @verification = Verification.find(params[:id])
    end

    # 人工审核：通过
    def approve
      verification = Verification.find(params[:id])
      if verification.method == "manual_review" && verification.pending?
        verification.approve!(params[:admin_note])
        redirect_to admin_verification_path(verification), notice: "已通过该用户的人工审核，其手机号确认时间已更新"
      else
        redirect_to admin_verification_path(verification), alert: "该核验单不在人工审核待处理状态"
      end
    end

    # 人工审核：拒绝
    def reject
      verification = Verification.find(params[:id])
      if verification.method == "manual_review" && verification.pending?
        verification.reject!(params[:admin_note].presence || "人工审核未通过")
        redirect_to admin_verification_path(verification), notice: "已拒绝该核验申请"
      else
        redirect_to admin_verification_path(verification), alert: "该核验单不在人工审核待处理状态"
      end
    end
  end
end
