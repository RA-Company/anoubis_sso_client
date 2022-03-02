module AnoubisSsoClient
  class User < ApplicationRecord
    self.table_name = 'users'

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
  end
end
