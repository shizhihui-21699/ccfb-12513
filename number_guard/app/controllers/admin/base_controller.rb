module Admin
  # 运营后台基类：HTTP Basic 认证（账号密码可用环境变量覆盖）
  class BaseController < ActionController::Base
    before_action :authenticate_admin!

    layout "admin"

    private

    def authenticate_admin!
      authenticate_or_request_with_http_basic("NumberGuard 运营后台") do |user, password|
        expected_user = ENV.fetch("ADMIN_USER", "admin")
        expected_pass = ENV.fetch("ADMIN_PASSWORD", "admin123")
        ActiveSupport::SecurityUtils.secure_compare(user, expected_user) &
          ActiveSupport::SecurityUtils.secure_compare(password, expected_pass)
      end
    end
  end
end
