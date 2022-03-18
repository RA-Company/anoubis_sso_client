##
# Main application class inherited from {https://www.rubydoc.info/gems/anoubis/Anoubis/ApplicationController Anoubis::ApplicationController}
class AnoubisSsoClient::ApplicationController < Anoubis::ApplicationController
  ##  Returns [Anoubis::Etc::Base] global system parameters
  attr_accessor :etc

  ## Returns main SSO server URL.
  attr_accessor :sso_server

  ##
  # Returns main SSO server URL. Link should be defined in Rails.configuration.anoubis.sso_server configuration parameter
  # @return [String] link to SSO server
  def sso_server
    @sso_server ||= get_sso_server
  end

  private def get_sso_server
    begin
      value = Rails.configuration.anoubis_sso_server
    rescue StandardError
      value = ''
      render json: { error: 'Please setup Rails.configuration.anoubis_sso_server configuration variable' }
    end

    value
  end

  ##
  # Returns SSO JWK data url according by OAUTH specification and {sso_server}.
  # @return [String] SSO JWK data url
  def sso_jwk_data
    return "#{sso_server}/openid/.well-known/jwks.json"
  end

  ##
  # Action fires before any other actions
  def after_anoubis_initialization
    if defined? params
      self.etc = Anoubis::Etc::Base.new({ params: params })
    else
      self.etc = Anoubis::Etc::Base.new
    end

    if access_allowed?
      options request.method.to_s.upcase
    else
      render_error_exit({ error: I18n.t('anoubis.errors.access_not_allowed') })
      return
    end

    if authenticate?
      if authentication
        if check_menu_access?
          return if !menu_access params[:controller]
        end
      end
    end

    after_sso_client_initialization
  end

  ##
  # Procedure fires after initializes all parameters of {AnoubisSsoClient::ApplicationController}
  def after_sso_client_initialization
    puts etc.inspect
  end

  ##
  # Check for site access. By default return true.
  def access_allowed?
    true
  end

  ##
  # Gracefully terminate script execution with code 422 (Unprocessable entity). And JSON data
  # @param data [Hash] Resulting data
  # @option data [Integer] :code resulting error code
  # @option data [String] :error resulting error message
  def render_error_exit(data = {})
    result = {
      result: -1,
      message: I18n.t('anoubis.error')
    }

    result[:result] = data[:code] if data.has_key? :code
    result[:message] = data[:error] if data.has_key? :error


    render json: result, status: :unprocessable_entity

    begin
      exit
    rescue SystemExit => e
      puts result[:message]
    end
  end

  ##
  # Checks if needed user authentication.
  # @return [Boolean] if true, then user must be authenticated. By default application do not need authorization.
  def authenticate?
    true
  end

  ##
  # Procedure authenticates user in the system
  def authentication
    session = get_oauth_session

    unless session
      render_error_exit code: -2, error: I18n.t('anoubis.errors.session_expired')
      return
    end

    self.current_user = get_user_by_uuid session[:uuid]

    unless current_user
      self.redis.del("#{redis_prefix}session:#{cookies[:oauth_session]}")
      cookies[:oauth_session] = nil
      render_error_exit code: -3, error: I18n.t('anoubis.errors.incorrect_user')
      return
    end
  end

  ##
  # Return OAUTH session for current request. Session name gets from cookies. If session present but it's timeout was expired, then session regenerated.
  def get_oauth_session
    begin
      session = JSON.parse(self.redis.get("#{redis_prefix}session:#{token}"),{ symbolize_names: true })
    rescue
      session = nil
    end

    return session if session

    puts 'get_oauth_session'

    jwt = check_sso_token

    return session

    if session
      if session[:ttl] < Time.now.utc.to_i
        session_name = SecureRandom.uuid
        session[:ttl] = Time.now.utc.to_i + session[:timeout]
        redis.del("#{redis_prefix}session:#{cookies[:oauth_session]}")
        cookies[:oauth_session] = session_name
        redis.set("#{redis_prefix}session:#{session_name}", session.to_json, ex: 86400)
      end
    end

    session
  end

  ##
  # Get current token based on HTTP Authorization
  # @return [String] current token
  def token
    return params[:oauth_token] if params.key? :oauth_token
    request.env.fetch('HTTP_AUTHORIZATION', '').scan(/Bearer (.*)$/).flatten.last
  end

  ##
  # Validate SSO token
  def check_sso_token
    puts 'check_sso_token'
    jwt = jwt_decode token

    puts jwt

    return nil unless jwt

    jwk = jwk_key(jwt[:header]['kid'])

    puts "JWK #{jwk}"

    public_key = JWT::JWK::RSA.import(jwk).public_key

    begin
      jwt_v = JWT.decode token, public_key, true, { algorithm: jwk[:alg] }
    rescue StandardError => e
      puts e
      return nil
    end

    jwt_v
  end

  ##
  # Decode JWT token
  # @param token [String] selected token
  # @return [Hash] Encoded JWT token
  def jwt_decode(token)
    begin
      jwt = JWT.decode token, nil, false
    rescue StandardError => e
      puts e
      return nil
    end

    #puts jwt

    return nil if jwt.count != 2

    payload = nil
    payload = jwt[0] if jwt[0].key? 'aud'
    payload = jwt[1] if jwt[1].key? 'aud'

    header = nil
    header = jwt[0] if jwt[0].key? 'alg'
    header = jwt[1] if jwt[1].key? 'alg'

    return nil unless payload || header

    return nil if Time.now.utc.to_i > payload['exp']

    {
      header: header,
      payload: payload
    }
  end

  ##
  # Receives JWK key
  # @param [String] key - public key identifier
  # @return [Hash] - JWK selected key
  def jwk_key(key)
    jwk = jwk_data

    return nil unless jwk

    jwk[:keys].each do |item|
      return item if item[:kid] == key
    end

    nil
  end

  ##
  # Load JWK keys from cache or server.
  # @return [Hash] JWK loaded from cache or server
  def jwk_data
    jwk = redis.get("#{redis_prefix}jwk")

    if jwk
      begin
        return JSON.parse(jwk,{ symbolize_names: true })
      rescue StandardError
        return nil
      end
    end

    jwk = load_jwk_data_from_sso_server

    return nil unless jwk

    redis.set("#{redis_prefix}jwk", jwk.to_json, ex: 3600)

    jwk
  end

  ##
  # Load JWK keys from server according by OAUTH specification.
  # @return [Object] returns JWK loaded from server
  def load_jwk_data_from_sso_server
    puts sso_jwk_data
    begin
      response = RestClient.get sso_jwk_data
    rescue StandardError
      return nil
    end

    begin
      data = JSON.parse(response.body, { symbolize_names: true })
    rescue StandardError
      return nil
    end

    data[:update] = Time.now

    data
  end
end