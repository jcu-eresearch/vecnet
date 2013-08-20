require Curate::Engine.root.join('app/controllers/application_controller')
class ApplicationController < ActionController::Base

  before_filter :decode_user_if_pubtkt_present

  helper_method :current_user, :user_signed_in?, :user_login_url, :user_logout_url

  def decode_user_if_pubtkt_present
    # use authenticate instead of authenticate! since we
    # do not raise an error if there is a problem with the pubtkt.
    # in that case we make the current user nil
    env['warden'].authenticate(:pubtkt)
    @current_user = env['warden'].user
  end

  # provide the "devise API" for 'user'

  def current_user
    @current_user
  end

  def user_signed_in?
    current_user != nil
  end

  def authenticate_user!(opts={})
    throw(:warden, opts) unless user_signed_in?
  end

  def user_session
    current_user && session
  end

  # path helpers, since pubtkt passes the return url as a parameter

  def user_login_url(back=nil)
    back = root_path unless back
    redirect_params = { back: back }
    "#{Rails.configuration.pubtkt_login_url}?#{redirect_params.to_query}"
  end

  alias_method :user_logout_url, :user_login_url
end
