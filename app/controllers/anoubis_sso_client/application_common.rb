##
# Common functions for all controllers
module AnoubisSsoClient::ApplicationCommon
  ##  Returns [Anoubis::Etc::Base] global system parameters
  attr_accessor :etc

  ## Returns main SSO server URL.
  attr_accessor :sso_server

  ## Returns SSO JWK data URL
  attr_accessor :sso_jwk_data_url

  ## Returns SSO userinfo URL
  attr_accessor :sso_userinfo_url

  ## Returns Hash of current user
  attr_accessor :current_user

  ## Returns Hash of menu for current user
  attr_accessor :current_menu

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
  # Returns SSO Menu model.
  # Can be redefined in Rails.application configuration_anoubis_sso_menu_model configuration parameter.
  # By default returns {AnoubisSsoClient::Menu} model class
  # @return [Class] Menu model class
  def menu_model
    begin
      value = Object.const_get Rails.configuration.anoubis_sso_menu_model
    rescue StandardError
      value = AnoubisSsoClient::Menu
    end

    value
  end

  ##
  # Returns SSO Group model.
  # Can be redefined in Rails.application configuration_anoubis_sso_group_model configuration parameter.
  # By default returns {AnoubisSsoClient::Group} model class
  # @return [Class] Group model class
  def group_model
    begin
      value = Object.const_get Rails.configuration.anoubis_sso_group_model
    rescue StandardError
      value = AnoubisSsoClient::Group
    end

    value
  end

  ##
  # Returns SSO GroupMenu model.
  # Can be redefined in Rails.application configuration_anoubis_sso_group_menu_model configuration parameter.
  # By default returns {AnoubisSsoClient::GroupMenu} model class
  # @return [Class] GroupMenu model class
  def group_menu_model
    begin
      value = Object.const_get Rails.configuration.anoubis_sso_group_menu_model
    rescue StandardError
      value = AnoubisSsoClient::GroupMenu
    end

    value
  end

  ##
  # Returns SSO GroupUser model.
  # Can be redefined in Rails.application configuration_anoubis_sso_group_user_model configuration parameter.
  # By default returns {AnoubisSsoClient::GroupUser} model class
  # @return [Class] GroupUser model class
  def group_user_model
    begin
      value = Object.const_get Rails.configuration.anoubis_sso_group_user_model
    rescue StandardError
      value = AnoubisSsoClient::GroupUser
    end

    value
  end

  ##
  # Returns SSO User model.
  # Can be redefined in Rails.application configuration_anoubis_sso_user_model configuration parameter.
  # By default returns {AnoubisSsoClient::User} model class
  # @return [Class] User model class
  def user_model
    begin
      value = Object.const_get Rails.configuration.anoubis_sso_user_model
    rescue
      value = AnoubisSsoClient::User
    end

    value
  end

  ##
  # Action fires before any other actions
  def after_anoubis_initialization
    self.current_user = nil
    self.current_menu = nil
    self.sso_jwk_data_url = nil
    self.sso_userinfo_url = nil
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
          allow = false
          if current_menu.key? params[:controller].to_sym
            etc.menu = Anoubis::Etc::Menu.new current_menu[params[:controller].to_sym]
            allow = true unless current_menu[params[:controller].to_sym][:access] == 'disable'
          end
          unless allow
            render_error_exit({ error: I18n.t('anoubis.errors.access_not_allowed') })
            return
          end
        end
      end
    end

    Time.zone = current_user[:timezone] if current_user

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

    self.current_user = session[:user]
    self.current_menu = session[:menu]
  end

  ##
  # Check if menu access required
  # @return [Boolean] menu access requirements
  def check_menu_access?
    if controller_name == 'index'
      if action_name == 'login' || action_name == 'menu' || action_name == 'logout'
        return false
      end
    end
    return true
  end

  ##
  # Return OAUTH session for current request. Session name gets from cookies. If session present but it's timeout was expired, then session regenerated.
  def get_oauth_session
    begin
      session = JSON.parse(redis.get("#{redis_prefix}session:#{token}"),{ symbolize_names: true })
    rescue
      session = nil
    end

    return session if session

    puts 'get_oauth_session'

    jwt = check_sso_token

    puts "JWT #{jwt}"

    return nil unless jwt

    ttl = jwt['exp'] - Time.now.utc.to_i

    puts "Time: #{Time.now.to_i} -> #{ttl}"

    return nil if ttl <= 0

    session = {
      user: {},
      menu: {}
    }

    user_data = load_user_from_sso_server

    puts "User data: #{user_data}"

    return nil unless user_data
    return nil if user_data.key? :error

    c_user = user_model.where(sso_uuid: user_data[:public]).first
    c_user = user_model.create(sso_uuid: user_data[:public]) unless c_user
    c_user.update_user_data(user_data)
    c_user.save if c_user.changed?
    session[:user] = c_user.session_data
    session[:menu] = load_full_menu(c_user.id)

    puts session.inspect

    redis.set("#{redis_prefix}session:#{token}", session.to_json, ex: ttl)

    session
  end

  ##
  # Load full menu from database
  # @param [Integer] user_id - User ID
  def load_full_menu(user_id)
    query = <<-SQL
          SELECT `t`.*
          FROM
            (
              SELECT `t2`.`id`, `t2`.`mode`, `t2`.`action`, `t2`.`title_locale`, `t2`.`page_title_locale`, `t2`.`short_title_locale`, 
                `t2`.`position`, `t2`.`tab`, `t2`.`menu_id`, `t2`.`state`, MAX(`t2`.`access`) AS `access`,
                `t2`.`user_id`, `t2`.`parent_mode`
              FROM (
                SELECT `menus`.`id`, `menus`.`id` AS `menu_id`, `menus`.`mode`, `menus`.`action`, `menus`.`title_locale`, `menus`.`page_title_locale`,
                  `menus`.`short_title_locale`, `menus`.`position`, `menus`.`tab`, `menus`.`menu_id` AS `parent_menu_id`, `menus`.`state`,
                  `group_menus`.`access`, `group_users`.`user_id`, `parent_menu`.`mode` AS `parent_mode`
                FROM (`menus`, `group_menus`, `groups`, `group_users`)
                  LEFT JOIN `menus` AS `parent_menu` ON `menus`.`menu_id` = `parent_menu`.`id`
                WHERE `menus`.`id` = `group_menus`.`menu_id` AND `menus`.`status` = 0 AND `group_menus`.`group_id` = `groups`.`id` AND
                  `groups`.`id` = `group_users`.`group_id` AND `group_users`.`user_id` = #{user_id}
                ) AS `t2`
               GROUP BY `t2`.`id`, `t2`.`mode`, `t2`.`action`, `t2`.`title_locale`, `t2`.`page_title_locale`, `t2`.`short_title_locale`,
                  `t2`.`position`, `t2`.`tab`, `t2`.`menu_id`, `t2`.`state`, `t2`.`user_id`, `t2`.`parent_mode`
            ) AS `t`
          ORDER BY `t`.`tab`, `t`.`position`
    SQL

    result = {}
    group_menu_model.find_by_sql(query).each do |data|
      result[data.mode.to_sym] = {
        mode: data.mode,
        title: data.title,
        page_title: data.page_title,
        short_title: data.short_title,
        position: data.position,
        tab: data.tab,
        action: data.action,
        access: data.access,
        state: menu_model.states.invert[data.state],
        parent: data.parent_mode
      }
      #self.output[:data].push menu_id[data.id.to_s.to_sym]
    end

    result
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

    puts "JWT #{jwt}"

    return nil unless jwt
    return nil unless jwt.key? :payload
    return nil unless jwt[:payload].key? 'iss'

    puts "ISS #{jwt[:payload]['iss']} -> #{sso_server}"
    puts jwt[:payload]['iss'].index(sso_server)

    return nil if jwt[:payload]['iss'].index(sso_server) == nil
    return nil if jwt[:payload]['iss'].index(sso_server) != 0

    begin
      iss = JSON.parse(redis.get("#{redis_prefix}iss:#{jwt[:payload]['iss']}"),{ symbolize_names: true })
    rescue StandardError
      iss = nil
    end

    puts "ISS1 #{iss}"

    unless iss
      begin
        response = RestClient.get "#{jwt[:payload]['iss']}.well-known/openid-configuration", { accept: :json }
      rescue StandardError
        return nil
      end

      begin
        iss = JSON.parse(response.body, { symbolize_names: true })
      rescue StandardError
        return nil
      end

      redis.set("#{redis_prefix}iss:#{jwt[:payload]['iss']}", iss.to_json, ex: 86400)
    end

    puts "ISS2 #{iss}"
    return nil unless iss.key? :jwks_uri
    self.sso_jwk_data_url = iss[:jwks_uri]
    self.sso_userinfo_url = iss[:userinfo_endpoint]

    jwk = jwk_key(jwt[:header]['kid'])

    puts "JWK #{jwk}"

    return nil unless jwk

    begin
      public_key = JWT::JWK::RSA.import(jwk).public_key
    rescue StandardError
      return nil
    end

    begin
      jwt_v = JWT.decode token, public_key, true, { algorithm: jwk[:alg] }
    rescue StandardError => e
      puts e
      return nil
    end

    jwt_v[0]
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
    puts "jwk_key #{key}"
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
    puts "jwk_data"
    puts "#{redis_prefix}jwk"
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
    puts 'load_jwk_data_from_sso_server'
    puts sso_jwk_data_url
    begin
      response = RestClient.get sso_jwk_data_url
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

  ##
  # Loads user data from SSO server and returns it.
  # @return [Hash] User data
  def load_user_from_sso_server
    puts 'load_user_from_sso_server'
    puts sso_userinfo_url
    begin
      response = RestClient.get sso_userinfo_url, { authorization: "Bearer #{token}" }
    rescue StandardError
      return nil
    end

    begin
      result = JSON.parse(response.body, { symbolize_names: true })
    rescue StandardError
      return nil
    end

    result
  end
end