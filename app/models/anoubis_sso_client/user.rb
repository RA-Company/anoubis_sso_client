##
# User model
class AnoubisSsoClient::User < AnoubisSsoClient::ApplicationRecord
  self.table_name = 'users'

  after_create :after_sso_client_create_user

  ## Timezone
  attr_accessor :timezone

  ## Locale
  attr_accessor :locale

  before_validation :before_validation_sso_client_user_on_create, on: :create

  validates :sso_uuid, presence: true, uniqueness: { case_sensitive: true }
  validates :uuid, presence: true, length: { maximum: 40 }, uniqueness: { case_sensitive: true }

  has_many :group_users, class_name: 'AnoubisSsoClient::GroupUser'

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

  ##
  # Fires after create new user.
  def after_sso_client_create_user
    attach_groups
  end

  ##
  # Procedure attaches groups to new created user. By default visitor group is attached to new user
  def attach_groups
    gr = group_model.where(ident: 'visitor').first

    return unless gr

    add_group group: gr
  end

  ##
  # Add current user to the group
  # @param [Hash] params parameters
  # @option params [Group | Array<Group>] :group <Group> model or array of <Group> models
  def add_group(params = {})
    return if !params.has_key? :group

    if params[:group].class == Array
      params[:group].each do |group|
        group_user_model.find_or_create_by group: group, user_id: id
      end
    else
      group_user_model.find_or_create_by group: params[:group], user_id: id
    end

    nil
  end
end
