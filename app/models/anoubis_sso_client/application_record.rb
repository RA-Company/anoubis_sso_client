##
# Main Active Record object inherited from {https://www.rubydoc.info/gems/anoubis/Anoubis/ApplicationRecord Anoubis::ApplicationRecord}
class AnoubisSsoClient::ApplicationRecord < Anoubis::ApplicationRecord
  self.abstract_class = true

  ##
  # Returns SSO Menu model.
  # Can be redefined in Rails.application configuration_anoubis_sso_menu_model configuration parameter.
  # By default returns {AnoubisSsoClient::Menu} model class
  # @return [Class] Menu model class
  def self.menu_model
    begin
      value = Object.const_get Rails.configuration.anoubis_sso_menu_model
    rescue StandardError
      value = AnoubisSsoClient::Menu
    end

    value
  end

  ##
  # Returns SSO Menu model.
  # Can be redefined in Rails.application configuration_anoubis_sso_menu_model configuration parameter.
  # By default returns {AnoubisSsoClient::Menu} model class
  # @return [Class] Menu model class
  def menu_model
    AnoubisSsoClient::ApplicationRecord.menu_model
  end

  ##
  # Returns SSO Group model.
  # Can be redefined in Rails.application configuration_anoubis_sso_group_model configuration parameter.
  # By default returns {AnoubisSsoClient::Group} model class
  # @return [Class] Group model class
  def self.group_model
    begin
      value = Object.const_get Rails.configuration.anoubis_sso_group_model
    rescue StandardError
      value = AnoubisSsoClient::Group
    end

    value
  end

  ##
  # Returns SSO Group model.
  # Can be redefined in Rails.application configuration_anoubis_sso_group_model configuration parameter.
  # By default returns {AnoubisSsoClient::Group} model class
  # @return [Class] Group model class
  def group_model
    AnoubisSsoClient::ApplicationRecord.group_model
  end

  ##
  # Returns SSO GroupMenu model.
  # Can be redefined in Rails.application configuration_anoubis_sso_group_menu_model configuration parameter.
  # By default returns {AnoubisSsoClient::GroupMenu} model class
  # @return [Class] GroupMenu model class
  def self.group_menu_model
    begin
      value = Object.const_get Rails.configuration.anoubis_sso_group_menu_model
    rescue StandardError
      value = AnoubisSsoClient::GroupMenu
    end

    value
  end

  ##
  # Returns SSO GroupMenu model.
  # Can be redefined in Rails.application configuration_anoubis_sso_group_menu_model configuration parameter.
  # By default returns {AnoubisSsoClient::GroupMenu} model class
  # @return [Class] GroupMenu model class
  def group_menu_model
    AnoubisSsoClient::ApplicationRecord.group_menu_model
  end

  ##
  # Returns SSO GroupUser model.
  # Can be redefined in Rails.application configuration_anoubis_sso_group_user_model configuration parameter.
  # By default returns {AnoubisSsoClient::GroupUser} model class
  # @return [Class] GroupUser model class
  def self.group_user_model
    begin
      value = Object.const_get Rails.configuration.anoubis_sso_group_user_model
    rescue StandardError
      value = AnoubisSsoClient::GroupUser
    end

    value
  end

  ##
  # Returns SSO GroupUser model.
  # Can be redefined in Rails.application configuration_anoubis_sso_group_user_model configuration parameter.
  # By default returns {AnoubisSsoClient::GroupUser} model class
  # @return [Class] GroupUser model class
  def group_user_model
    AnoubisSsoClient::ApplicationRecord.group_user_model
  end

  ##
  # Returns SSO User model.
  # Can be redefined in Rails.application configuration_anoubis_sso_user_model configuration parameter.
  # By default returns {AnoubisSsoClient::User} model class
  # @return [Class] User model class
  def self.user_model
    begin
      value = Object.const_get Rails.configuration.anoubis_sso_user_model
    rescue
      value = AnoubisSsoClient::User
    end

    value
  end

  ##
  # Returns SSO User model.
  # Can be redefined in Rails.application configuration_anoubis_sso_user_model configuration parameter.
  # By default returns {AnoubisSsoClient::User} model class
  # @return [Class] User model class
  def user_model
    AnoubisSsoClient::ApplicationRecord.user_model
  end
end
