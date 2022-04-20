##
# Index controller class. Output system actions
class AnoubisSsoClient::IndexController < AnoubisSsoClient::ApplicationController

  ##
  # Output allowed menu items
  def menu
    result = {
      result: 0,
      message: I18n.t('anoubis.success'),
      menu: []
    }

    if current_menu
      current_menu.each_value do |dat|
        result[:menu].push dat
      end
    end

    before_menu_output result

    render json: result
  end

  ##
  # Callback for change menu output
  def before_menu_output(result)

  end
end