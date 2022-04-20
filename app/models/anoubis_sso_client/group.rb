##
# User group model
class AnoubisSsoClient::Group < AnoubisSsoClient::ApplicationRecord
  self.table_name = 'groups'

  ## Identifier validation constant
  VALID_IDENT_REGEX = /\A[a-z]*\z/i

  # @!attribute ident
  #   @return [String] the group's identifier. Identifier consists of lowercase alphabetical symbols.
  validates :ident, length: { minimum: 3, maximum: 50 }, uniqueness: { case_sensitive: false }, format: { with: VALID_IDENT_REGEX }

  validates :title, presence: true, length: { maximum: 100 }

  has_many :group_menus, class_name: 'AnoubisSsoClient::GroupMenu'
  has_many :group_users, class_name: 'AnoubisSsoClient::GroupUser'

  ##
  # Returns title according by I18n.locale
  # @return [String] Localized title
  def title
    get_locale_field 'title_locale'
  end

  ##
  # Defines title according by I18n.locale
  # @param value [String] Localized title
  def title=(value)
    set_locale_field 'title_locale', value
  end

  ##
  # Create multi language group
  # @param [Hash] params initial model options
  # @option params [String] :ident group identifier
  # @option params [String] :translate translate identifier
  # @return [Group] returns created group object
  def self.create_group(params)
    return nil if !params.key? :ident
    return nil if !params.key? :translate

    group = group_model.find_or_create_by ident: params[:ident]

    return nil unless group

    I18n.available_locales.each do |locale|
      I18n.locale = locale
      group.title = I18n.t(params[:translate])
    end
    group.save if group.changed?

    group
  end

  ##
  # Add access to menu element for current group
  # @param [Hash] params parameters
  # @option params [Menu | Array<Menu>] :menu {Menu} model or array of {Menu} models
  # @option params [String] :access access mode ('read', 'write', 'disable'). Optional. By default set to 'read'
  def add_menu(params = {})
    return if !params.has_key? :menu

    params[:access] = 'read' unless params.key? :access

    if params[:menu].class == Array
      params[:menu].each do |menu|
        data = group_menu_model.find_or_create_by group_id: id, menu: menu
        if group_menu_model.accesses[params[:access].to_sym] > group_menu_model.accesses[data.access.to_sym]
          data.access = params[:access]
          data.save
        end
      end
    else
      data = group_menu_model.find_or_create_by group_id: id, menu: params[:menu]
      if group_menu_model.accesses[params[:access].to_sym] > group_menu_model.accesses[data.access.to_sym]
        data.access = params[:access]
        data.save
      end
    end

    nil
  end

  ##
  # Add user to current group
  # @param [Hash] params parameters
  # @option params [User | Array<User>] :user {User} model or array of {User} models
  def add_user(params = {})
    return if !params.has_key? :user

    if params[:user].class == Array
      params[:user].each do |user|
        group_menu_model.find_or_create_by group_id: id, user: user
      end
    else
      group_menu_model.find_or_create_by group_id: id, user: params[:user]
    end

    nil
  end
end
