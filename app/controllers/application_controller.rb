class ApplicationController < ActionController::Base
  helper_method :current_user, :logined?, :admin_user?

  def current_user
    if session[:user_id]
      @current_user ||= User.find(session[:user_id])
    end
  end

  def logined?
    !current_user.nil?
  end

  def admin_user?
    current_user&.[]('is_admin') == 1
  end
end
