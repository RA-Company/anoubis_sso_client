##
# Main menu model
class AnoubisSsoClient::Menu < ApplicationRecord
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
  belongs_to :menu, class_name: 'AnoubisSsoClientt::Menu', optional: true
  has_many :menus, class_name: 'AnoubisSsoClient::Menu'

  ##
  # Is called before menu will be created in database. Sets {#position} as last {#position} + 1 on current {#tab}.
  # After this calls {#before_update_menu} for additional modification.
  def before_sso_client_create_menu
    data = AnoubisSsoClient::Menu.where(menu_id: menu_id).maximum(:position)
    self.position = data ? data + 1 : 0

    self.before_update_menu
  end

  ##
  # Is called before menu will be stored in database. Sets {#mode} and {#action} in lowercase. If {#page_size}
  # doesn't defined then sets it to 20. If defined parent menu element then sets {#tab} based on {#tab} of
  # parent menu element + 1.
  def before_sso_client_update_menu
    self.menu_id = nil if menu_id = ''
    self.mode = mode.downcase
    self.action = action.downcase
    self.page_size = 20 unless page_size
    self.page_size = page_size.to_i

    parent_menu = AnoubisSsoClient::Menu.where(id: menu_id).first
    self.tab = parent_menu ? parent_menu.tab + 1 : 0
  end

  ##
  # Is called before menu will be deleted from database. Checks the ability to destroy a menu. Delete
  # all translations for menu model from {MenuLocale}.
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
  # @param [Hash] options initial model options
  # @option options [String] :mode menu identifier
  # @option options [String] :action menu action type ('data', 'menu' and etc.)
  def self.create_group(params)
    return nil if !params.key? :mode
    return nil if !params.key? :action

    params[:access] = 'read' unless params.key? :access
    params[:state] = 'visible' unless params.key? :state


  end
end
