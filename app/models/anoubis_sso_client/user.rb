##
# User model
class AnoubisSsoClient::User < AnoubisSsoClient::ApplicationRecord
  self.table_name = 'users'

  ## Timezone
  attr_accessor :timezone

  ## Locale
  attr_accessor :locale

  before_validation :before_validation_sso_client_user_on_create, on: :create

  validates :sso_uuid, presence: true, uniqueness: { case_sensitive: true }
  validates :uuid, presence: true, length: { maximum: 40 }, uniqueness: { case_sensitive: true }

  ##
  # Fires before create any User on the server. Procedure generates internal UUID and setup timezone to GMT.
  # Public user identifier is generated also if not defined.
  def before_validation_sso_client_user_on_create
    self.uuid = setup_private_user_id
  end

  ##
  # Procedure setup private user identifier. Procedure can be redefined.
  # @return [String] public user identifier
  def setup_private_user_id
    SecureRandom.uuid
  end

  ##
  # Update user data information in user database
  # @param user_data [Hash] - User data information received from SSO server
  def update_user_data(user_data)
    self.name = user_data[:name] if user_data.key? :name
    self.surname = user_data[:surname] if user_data.key? :surname
    self.email = user_data[:email] if user_data.key? :email
    self.timezone = user_data.key?(:timezone) ? user_data[:timezone] : 'GMT'
    self.locale = user_data.key?(:locale) ? user_data[:locale] : 'ru-RU'
  end

  ##
  # Returns user data for saving into the session
  def session_data
    {
      name: name,
      surname: surname,
      email: email,
      locale: locale,
      timezone: timezone
    }
  end
end
