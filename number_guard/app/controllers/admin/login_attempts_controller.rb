module Admin
  class LoginAttemptsController < BaseController
    def index
      @attempts = LoginAttempt.recent_first.includes(:user)
      @attempts = @attempts.where(decision: params[:decision]) if params[:decision].in?(LoginAttempt::DECISIONS)
      @attempts = @attempts.limit(200)
    end

    def show
      @attempt = LoginAttempt.find(params[:id])
      @verification = @attempt.verification
    end
  end
end
