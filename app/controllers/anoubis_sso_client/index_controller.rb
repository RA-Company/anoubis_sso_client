##
# Index controller class. Output system actions
class AnoubisSsoClient::IndexController < AnoubisSsoClient::ApplicationController

  ##
  # Output allowed menu items
  def menu
    result = {
      result: 0,
      message: I18n.t('anoubis.success'),
      menu: [
        {
          mode: 'dashboard',
          title: I18n.t('anoubis.install.menu.dashboard.title'),
          page_title: I18n.t('anoubis.install.menu.dashboard.page_title'),
          short_title: I18n.t('anoubis.install.menu.dashboard.short_title'),
          position: 0,
          tab: 0,
          action: 'data',
          access: 'write',
          state: 'show',
          parent: nil
        }
      ]
    }

    render json: result
  end
end