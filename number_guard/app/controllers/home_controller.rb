class HomeController < ApplicationController
  before_action :require_login!

  def index
  end

  # 用户主动确认手机号仍归本人所有，刷新确认时间
  def confirm_phone
    current_user.confirm_phone_now!
    redirect_to root_path, notice: "已确认，手机号确认时间已更新为当前时间"
  end
end
