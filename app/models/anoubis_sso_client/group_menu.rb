##
# Model links {Menu} and {Group}. Describes group access to menu.
class AnoubisSsoClient::GroupMenu < AnoubisSsoClient::ApplicationRecord
  # Redefines default table name
  self.table_name = 'group_menus'

  before_validation :before_validation_sso_client_group_menu
  after_create :after_create_sso_client_group_menu
  before_update :before_update_sso_client_group_menu
  after_destroy :after_destroy_sso_client_group_menu

  # @!attribute group
  #   @return [Group] reference to the {Group} model
  belongs_to :group, :class_name => 'AnoubisSsoClient::Group'
  validates :group, presence: true, uniqueness: { scope: [:menu_id] }

  # @!attribute menu
  #   @return [Menu] reference to the {Menu} model
  belongs_to :menu, :class_name => 'AnoubisSsoClient::Menu'
  validates :menu, presence: true, uniqueness: { scope: [:group_id] }

  # @!attribute access
  #   @return ['read', 'write', 'disable'] group access to menu element.
  #     - 'read' --- group has access to menu element only for read data
  #     - 'write' --- group has access to menu element for read and write data
  #     - 'disable' --- group hasn't access to menu element
  enum access: { read: 0, write: 50, disable: 100 }

  ##
  # Is called before validation when the link between menu and group is being created or updated.
  # Procedure checks if group belongs a system that has access to this menu element. If {#access} doesn't
  # defined then {#access} sets to 'read'
  def before_validation_sso_client_group_menu
    self.access = 'read' unless access
  end

  ##
  # Is called after new link between menu and group was created. If new element has parent with link that
  # doesn't present in database then adds this link to database with {#access} defined as 'read'.
  def after_create_sso_client_group_menu
    if menu.menu_id
      AnoubisSsoClient::GroupMenu.find_or_create_by(menu_id: menu.menu_id, group_id: group_id) do |menu|
        menu.access = 'read'
      end
    end
  end

  ##
  # Is called before link between menu and group will be updated. Procedure prevents changing {#menu}
  # and {#group} value.
  def before_update_sso_client_group_menu
    self.menu_id = menu_id_was if menu_id_changed?
    self.group_id = group_id_was if group_id_changed?
  end

  ##
  # Is called after link between menu and group had been deleted from database. It also deletes all child links.
  def after_destroy_sso_client_group_menu
    AnoubisSsoClient::Menu.select(:id).where(menu_id: menu_id).each do |menu|
      AnoubisSsoClient::GroupMenu.where(menu_id: menu.id, group_id: group_id).each do |group_menu|
        group_menu.destroy
      end
    end
  end

  ##
  # Add access to menu element for group
  # @param [Hash] options initial model options
  # @option options [String] :group group model
  # @option options [String] :menu menu model
  # @option options [String] :access access mode ('read', 'write', 'disable'). Optional. By default set to 'read'
  def self.add_menu_access(params = {})
    return if !params.has_key? :group
    return if !params.has_key? :menu

    params[:access] = 'read' unless params.key? :access

    if params[:group].class == Array
      params[:group].each do |group|
        data = group_menu_model.find_or_create_by group: group, menu: params[:menu]
        if group_menu_model.accesses[params[:access].to_sym] > group_menu_model.accesses[data.access.to_sym]
          data.access = params[:access]
          data.save
        end
      end
    else
      data = group_menu_model.find_or_create_by group: params[:group], menu: params[:menu]
      if group_menu_model.accesses[params[:access].to_sym] > group_menu_model.accesses[data.access.to_sym]
        data.access = params[:access]
        data.save
      end
    end

    nil
  end
end
