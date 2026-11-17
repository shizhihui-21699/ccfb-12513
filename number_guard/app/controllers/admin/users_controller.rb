module Admin
  class UsersController < BaseController
    def index
      @users = User.order(created_at: :desc).limit(200)
    end

    def show
      @user = User.find(params[:id])
      @attempts = @user.login_attempts.recent_first.limit(50)
      @carrier_record = CarrierRecord.find_by(phone: @user.phone)
    end
  end
end
