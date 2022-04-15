# AnoubisSsoClient
Short description and motivation.

## Usage
How to use my plugin.

## Installation
Add this line to your application's Gemfile:

```ruby
gem "anoubis_sso_client"
```

And then execute:
```bash
$ bundle
```

Or install it yourself as:
```bash
$ gem install anoubis_sso_client
```

## Configuration parameters

This configuration parameters can be placed at files config/application.rb for global configuration or config/environments/<environment>.rb for custom environment configuration.

```ruby
config.anoubis_sso_server = 'https://sso.example.com/' # Full URL of SSO server (*required)
config.anoubis_sso_user_model = 'AnoubisSsoClient::User'# Used User model. ()By default used AnoubisSsoServer::User model) (*optional)
config.anoubis_sso_menu_model = 'AnoubisSsoClient::Menu'# Used Menu model. ()By default used AnoubisSsoServer::Menu model) (*optional)
config.anoubis_sso_group_model = 'AnoubisSsoClient::Group'# Used Group model. ()By default used AnoubisSsoServer::Group model) (*optional)
config.anoubis_sso_group_menu_model = 'AnoubisSsoClient::GroupModel'# Used GroupMenu model. ()By default used AnoubisSsoServer::GroupMenu model) (*optional)
```

## Contributing
Contribution directions go here.

## License
The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
