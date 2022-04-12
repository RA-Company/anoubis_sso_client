##
# User group model
class AnoubisSsoClient::Group < Anoubis::ApplicationRecord
  self.table_name = 'groups'

  ## Identifier validation constant
  VALID_IDENT_REGEX = /\A[a-z]*\z/i

  # @!attribute ident
  #   @return [String] the group's identifier. Identifier consists of lowercase alphabetical symbols.
  validates :ident, length: { minimum: 3, maximum: 50 }, uniqueness: { case_sensitive: false }, format: { with: VALID_IDENT_REGEX }

  validates :title, presence: true, length: { maximum: 100 }

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
  # @param [Hash] options initial model options
  # @option options [String] :ident group identifier
  # @option options [String] :translate translate identifier
  def self.create_group(params)
    return nil if !params.key? :ident
    return nil if !params.key? :translate

    group = AnoubisSsoClient::Group.find_or_create_by ident: params[:ident]

    if group
      I18n.available_locales.each do |locale|
        I18n.locale = locale
        group.title = I18n.t(params[:translate])
      end
      group.save
    end

    group
  end
end
