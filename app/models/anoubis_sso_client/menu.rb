##
# Main menu model
class AnoubisSsoClient::Menu < AnoubisSsoClient::ApplicationRecord
  # Redefines default table name
  self.table_name = 'menus'

  before_create :before_sso_client_create_menu
  before_update :before_sso_client_update_menu
  before_destroy :before_sso_client_destroy_menu
  after_destroy :after_sso_client_destroy_menu

  # @!attribute mode
  #   @return [String] the controller path for menu element.
  validates :mode, presence: true, uniqueness: true

  # @!attribute action
  #   @return [String] the default action of menu element ('data', 'menu', etc.).
  validates :action, presence: true

  # @!attribute tab
  #   @return [Integer] the nesting level of menu element
  validates :tab, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  # @!attribute position
  #   @return [Integer] the order position of menu element in current level.
  validates :position, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  # @!attribute page_size
  #   @return [Integer] the default page size for table of data frame.
  validates :page_size, numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  # @!attribute status
  #   @return ['enabled', 'disabled'] the status of menu element.
  #     - 'enabled' --- element is enabled and is used by the system.
  #     - 'disabled' --- element is disabled and isn't used by the system.
  enum status: { enabled: 0, disabled: 1 }

  # @!attribute state
  #   @return ['visible', 'hidden'] the visibility of menu element. Attribute is used in fronted application.
  #     - 'visible' --- element is visible.
  #     - 'hidden' --- element is hidden.
  enum state: { visible: 0, hidden: 1 }

  validates :title, presence: true, length: { maximum: 100 }
  validates :page_title, presence: true, length: { maximum: 200 }
  validates :short_title, presence: true, length: { maximum: 200 }

  # @!attribute menu
  #   @return [Menu, nil] the parent menu for element menu (if exists).
  belongs_to :menu, class_name: 'AnoubisSsoClient::Menu', optional: true
  has_many :menus, class_name: 'AnoubisSsoClient::Menu'
  has_many :group_menus, class_name: 'AnoubisSsoClient::GroupMenu'

  ##
  # Is called before menu will be created in database. Sets {#position} as last {#position} + 1 on current {#tab}.
  def before_sso_client_create_menu
    data = AnoubisSsoClient::Menu.where(menu_id: menu_id).maximum(:position)
    self.position = data ? data + 1 : 0

    before_sso_client_update_menu
  end

  ##
  # Is called before menu will be stored in database. Sets {#mode} and {#action} in lowercase. If {#page_size}
  # doesn't defined then sets it to 20. If defined parent menu element then sets {#tab} based on {#tab} of
  # parent menu element + 1.
  def before_sso_client_update_menu
    self.menu_id = nil if menu_id == ''
    self.mode = mode.downcase
    self.action = action.downcase
    self.page_size = 20 unless page_size
    self.page_size = page_size.to_i

    parent_menu = AnoubisSsoClient::Menu.where(id: menu_id).first
    self.tab = parent_menu ? parent_menu.tab + 1 : 0
  end

  ##
  # Is called before menu will be deleted from database. Procedure clears most child components.
  def before_sso_client_destroy_menu
    unless menus.empty?
      errors.add(:base, I18n.t('activerecord.errors.anoubis_sso_client/menu.errors.has_child_menus'))
      throw(:abort, __method__)
    end
  end

  ##
  # Is called after menu was deleted from database. Procedure recalculates position of other menu elements.
  def after_sso_client_destroy_menu
    query = <<-SQL
            UPDATE menus
            SET menus.position = menus.position - 1
            WHERE menus.tab = #{tab} AND menus.position > #{position}
    SQL
    AnoubisSsoClient::Menu.connection.execute query
  end

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
  # Returns short title according by I18n.locale
  # @return [String] Localized title
  def short_title
    get_locale_field 'short_title_locale'
  end

  ##
  # Defines short title according by I18n.locale
  # @param value [String] Localized short title
  def short_title=(value)
    set_locale_field 'short_title_locale', value
  end

  ##
  # Returns page title according by I18n.locale
  # @return [String] Localized page title
  def page_title
    get_locale_field 'page_title_locale'
  end

  ##
  # Defines page title according by I18n.locale
  # @param value [String] Localized page title
  def page_title=(value)
    set_locale_field 'page_title_locale', value
  end

  ##
  # Create multi language menu
  # @param [Hash] params initial model options
  # @option params [String] :mode menu identifier
  # @option params [String] :action menu action type ('data', 'menu' and etc.)
  # @option params [String] :access access mode ('read', 'write', 'disable'). Optional. By default set to 'read'
  # @option params [String] :state menu visibility ('visible', 'hidden'). Optional. By default set to 'visible'
  # @option params [String] :page_size default table size for action 'data'. Optional. By default set 20
  # @option params [String] :group User's group or array of user's group. Optional.
  # @return [AnoubisSsoClient::Menu] returns created menu object
  def self.create_menu(params)
    return nil if !params.key? :mode
    return nil if !params.key? :action

    params[:access] = 'read' unless params.key? :access
    params[:state] = 'visible' unless params.key? :state

    data = AnoubisSsoClient::Menu.where(mode: params[:mode]).first
    data = AnoubisSsoClient::Menu.create({ mode: params[:mode], action: params[:action] }) unless data

    return unless data

    data.action = params[:action]
    if params.key? :parent
      data.menu = params[:parent]
    else
      data.menu_id = nil
    end
    data.page_size = params.key?(:page_size) ? params[:page_size] : 20
    data.state = params[:state]

    prefix = "install.menu.#{params[:mode]}"

    I18n.available_locales.each do |locale|
      I18n.locale = locale
      data.title = I18n.t("#{prefix}.title")
      data.page_title = I18n.t("#{prefix}.page_title")
      data.short_title = I18n.t("#{prefix}.short_title", default: data.title)
    end

    if data.changed?
      unless data.save
        puts data.errors.full_messages
        return nil
      end
    end

    data.add_group params

    data
  end

  ##
  # Add access to group for menu element
  # @param [Hash] params parameters
  # @option params [Group | Array<Group>] :group <Group> model or array of <Group> models
  # @option params [String] :access access mode ('read', 'write', 'disable'). Optional. By default set to 'read'
  def add_group(params = {})
    return if !params.has_key? :group

    params[:access] = 'read' unless params.key? :access

    if params[:group].class == Array
      params[:group].each do |group|
        data = group_menu_model.find_or_create_by group: group, menu_id: id
        if group_menu_model.accesses[params[:access].to_sym] > group_menu_model.accesses[data.access.to_sym]
          data.access = params[:access]
          data.save
        end
      end
    else
      data = group_menu_model.find_or_create_by group: params[:group], menu_id: id
      if group_menu_model.accesses[params[:access].to_sym] > group_menu_model.accesses[data.access.to_sym]
        data.access = params[:access]
        data.save
      end
    end

    nil
  end
end
