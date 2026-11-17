module Admin
  class DashboardController < BaseController
    def index
      @today_attempts   = LoginAttempt.where("created_at >= ?", Time.current.beginning_of_day)
      @today_blocked    = @today_attempts.blocked.count
      @today_allowed    = @today_attempts.where(decision: "allowed").count
      @pending_manual   = Verification.awaiting_manual_review.count
      @pending_total    = Verification.where(status: "pending").count
      @passed_total     = Verification.where(status: "passed").count
      @failed_total     = Verification.where(status: "failed").count
      @recent_blocked   = LoginAttempt.blocked.recent_first.includes(:user).limit(10)
    end
  end
end
