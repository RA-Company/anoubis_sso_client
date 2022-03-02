source "https://rubygems.org"
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

gemspec

gem 'redis'
gem 'jwt'
gem 'anoubis', git: 'https://github.com/RA-Company/anoubis.git', branch: 'main'

group :test do
  gem 'dotenv'
  gem 'dotenv-rails'
  gem 'tzinfo-data', platforms: %i[mingw mswin x64_mingw jruby]
end
