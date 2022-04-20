##
# Model links {Menu} and {User}. Describes users that belongs to group.
class AnoubisSsoClient::GroupUser < AnoubisSsoClient::ApplicationRecord
  # Redefines default table name
  self.table_name = 'group_users'

  before_update :before_update_sso_client_group_user

  # @!attribute group
  #   @return [Group] reference to the {Group} model
  belongs_to :group, class_name: 'AnoubisSsoClient::Group'
  validates :group, presence: true, uniqueness: { scope: [:user_id] }

  # @!attribute user
  #   @return [User] reference to the {User} model
  belongs_to :user, class_name: 'AnoubisSsoClient::User'
  validates :user, presence: true, uniqueness: { scope: [:group_id] }

  ##
  # Procedure prevents changing {User} and {Group} data.
  def before_update_sso_client_group_user
    self.user_id = user_id_was if user_id.changed?
    self.group_id = group_id_was if group_id.changed?
  end
end
