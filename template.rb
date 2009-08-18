# Copy database.yml
run 'cp config/database.yml config/database.yml.sqlite3'


# Delete unnecessary files
run "rm README"
run "rm public/index.html"
run "rm public/favicon.ico"
run "rm public/robots.txt"
run "rm public/images/rails.png"
run "rm -f public/javascripts/*"

# Download JQuery
run "curl -s -L http://jqueryjs.googlecode.com/files/jquery-1.3.1.min.js > public/javascripts/jquery.js"
run "curl -s -L http://jqueryjs.googlecode.com/svn/trunk/plugins/form/jquery.form.js > public/javascripts/jquery.form.js"

# Install gems
gem 'thoughtbot-factory_girl', :lib => 'factory_girl', :source => 'http://gems.github.com'
gem 'thoughtbot-shoulda', :lib => 'shoulda', :source => 'http://gems.github.com'
gem 'binarylogic-authlogic', :lib => 'authlogic', :source => 'http://gems.github.com'
plugin 'exception_notifier', :git => 'git://github.com/rails/exception_notification.git'
plugin 'active_scaffold', :git => 'git://github.com/activescaffold/active_scaffold.git'
plugin 'acts_as_taggable_redux', :git => 'git://github.com/geemus/acts_as_taggable_redux.git'
plugin 'web-app-theme', :git => 'git://github.com/pilu/web-app-theme.git'

rake('acts_as_taggable:db:create')

# Install gems on local system
rake('gems:install', :sudo => true) if yes?('Install gems on local system? (y/n)')


# Use database (active record) session store
rake('db:sessions:create')
initializer 'session_store.rb', <<-FILE
  ActionController::Base.session = { :session_key => '_#{(1..6).map { |x| (65 + rand(26)).chr }.join}_session', :secret => '#{(1..40).map { |x| (65 + rand(26)).chr }.join}' }
  ActionController::Base.session_store = :active_record_store
FILE

environment( "config.time_zone  = 'config.Eastern Time (US & Canada)'" )

generate(:session, :user_session)
file 'app/models/user_session.rb', <<-FILE
  class UserSession < Authlogic::Session::Base
    # configuration here, see documentation for sub modules of Authlogic::Session
  end
FILE

generate(:model, :user)
  
# Install and configure capistrano
run "sudo gem install capistrano" if yes?('Install Capistrano on your local system? (y/n)')

capify!

file 'Capfile', <<-FILE
  load 'deploy' if respond_to?(:namespace) # cap2 differentiator
  Dir['vendor/plugins/*/recipes/*.rb'].each { |plugin| load(plugin) }
  load 'config/deploy'
FILE

# Set up .gitignore files
run "touch tmp/.gitignore log/.gitignore vendor/.gitignore"
run %{find . -type d -empty | grep -v "vendor" | grep -v ".git" | grep -v "tmp" | xargs -I xxx touch xxx/.gitignore}
file '.gitignore', <<-END
.DS_Store
log/*.log
tmp/**/*
config/database.yml
db/*.sqlite3
vendor/rails
END

git :init
git :add => "."
git :commit => "-a -m 'Initial commit'"

