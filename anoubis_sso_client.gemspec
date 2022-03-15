require_relative "lib/anoubis_sso_client/version"

Gem::Specification.new do |spec|
  spec.name        = "anoubis_sso_client"
  spec.version     = AnoubisSsoClient::VERSION
  spec.authors     = ["Andrey Ryabov"]
  spec.email       = ["andrey.ryabov@ra-company.kz"]

  spec.summary     = "Library for create basic SSO Client based on OAUTH authentication."
  spec.description = "Library for create basic SSO Client based on OAUTH authentication."
  spec.homepage    = "https://github.com/RA-Company/"
  spec.license     = "MIT"
  spec.required_ruby_version = ">= 2.7.1"
  
  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/RA-Company/" + spec.name
  spec.metadata["changelog_uri"] = "https://github.com/RA-Company/" + spec.name + "/blob/main/CHANGELOG.md"
  spec.metadata["documentation_uri"] = "https://www.rubydoc.info/gems/" + spec.name + "/" + spec.version.to_s

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md"]
  end

  spec.add_dependency "rails", ">= 7.0.2.2"
  spec.add_dependency "anoubis", "~> 1.0.2"
  spec.add_dependency "redis", "~> 4.5.1"
  spec.add_dependency "rest-client", "~> 2.1.0"
  spec.add_dependency "mysql2", "~> 0.5.3"
  spec.add_dependency "jwt", "~> 2.3.0"

  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "rspec", "~> 3.11.0"
  spec.add_development_dependency "rspec-rails", "~> 5.1"
  spec.add_development_dependency "factory_bot_rails", "~> 6.2.0"
  spec.add_development_dependency "dotenv", '~> 2.7'
  spec.add_development_dependency "rubocop", '~> 1.25'
end
