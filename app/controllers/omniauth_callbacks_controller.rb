class OmniauthCallbacksController < ApplicationController
  def callback
    auth_info = request.env['omniauth.auth']['info']
    user = User.find_or_initialize_by(id: auth_info['user_id'])
    user.nickname = auth_info['nickname']
    user.avatar_url = auth_info['image_48']

    session['user_id'] = auth_info['user_id']
    redirect_to root_path
  end

  def destroy
    session.clear
    redirect_to root_path
  end
end
