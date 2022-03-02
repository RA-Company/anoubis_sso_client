##
# Defines default routes
AnoubisSsoClient::Engine.routes.draw do
  Rails.application.routes.draw do
    scope path: 'api', defaults: { format: 'json' } do
      scope path: ':version' do
        #get 'login', to: 'anoubis_sso_server/main#login', as: 'api_internal_login'
        #get 'auth', to: 'anoubis_sso_server/main#auth', as: 'api_internal_auth'
        #get 'dashboard', to: 'anoubis_sso_server/index#dashboard'
        get 'menu', to: 'anoubis_sso_client/index#menu'
      end
    end

    scope path: 'openid', defaults: { format: 'json' } do
      #get '.well-known/openid-configuration', to: 'anoubis_sso_server/open_id#configuration', as: 'openid_configuration'
      #get '.well-known/jwks.json', to: 'anoubis_sso_server/open_id#jwks', as: 'openid_jwks'
      #get 'oauth2/auth', to: 'anoubis_sso_server/open_id#auth', as: 'oauth_auth'
      #post 'oauth2/token', to: 'anoubis_sso_server/open_id#access_token', as: 'oauth_token'
      #options 'oauth2/token', to: 'anoubis_sso_server/application#options', as: nil
      #get 'oauth2/logout', to: 'anoubis_sso_server/open_id#logout', as: 'oauth_logout'
    end
  end
end