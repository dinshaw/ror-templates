# Download JQuery
run "curl -L http://jqueryjs.googlecode.com/files/jquery-1.2.6.min.js > public/javascripts/jquery.js"
run "curl -L http://jqueryjs.googlecode.com/svn/trunk/plugins/form/jquery.form.js > public/javascripts/jquery.form.js"

# Copy database.yml for distribution use
# and smtp config for gmail
run "cp config/database.yml config/database.yml.example"
initializer 'smtp_gmail.rb.example', <<-CODE
if ['production','staging'].include?(RAILS_ENV)
  ActionMailer::Base.smtp_settings = {
    :address => "smtp.gmail.com",
    :port => 587,
    :authentication => :plain,
    :enable_starttls_auto => true
    :user_name: your_username@gmail.com
    :password: h@ckme
  }
end
CODE

# Set up git repository
# need this before we can call the submoduled stuff below
git :init
# Initialize submodules
git :submodule => "init"

# Set up .gitignore files
run "touch tmp/.gitignore log/.gitignore vendor/.gitignore"
run %{find . -type d -empty | grep -v "vendor" | grep -v ".git" | grep -v "tmp" | xargs -I xxx touch xxx/.gitignore}
file '.gitignore', <<-END
      .DS_Store
      log/*.log
      tmp/**/*
      config/database.yml
      db/*.sqlite3
END

# Install submoduled plugins
plugin 'rspec', :git => 'git://github.com/dchelimsky/rspec.git', :submodule => true
plugin 'rspec-rails', :git => 'git://github.com/dchelimsky/rspec-rails.git', :submodule => true
plugin 'asset_packager', :git => 'git://github.com/sbecker/asset_packager.git', :submodule => true
plugin 'exception_notifier', :git => 'git://github.com/rails/exception_notification.git', :submodule => true
plugin 'open_id_authentication', :git => 'git://github.com/rails/open_id_authentication.git', :submodule => true
plugin 'restful-authentication', :git => 'git://github.com/technoweenie/restful-authentication.git' , :submodule => true
plugin 'role_requirement', :git => 'git://github.com/timcharper/role_requirement.git' , :submodule => true
plugin 'acts_as_taggable_redux', :git => 'git://github.com/geemus/acts_as_taggable_redux.git', :submodule => true
plugin 'acts_as_ordered_tree', :git => 'git://github.com/ffmike/acts_as_ordered_tree.git ', :submodule => true
plugin 'paperclip', :git => 'git://github.com/thoughtbot/paperclip.git', :submodule => true
plugin 'simple_auto_complete', :git => 'git://github.com/grosser/simple_auto_complete.git', :submodule => true
plugin 'custom-err-msg', :git => 'git://github.com/gumayunov/custom-err-msg.git', :submodule => true  
plugin 'thinking-sphinx', :git => 'git://github.com/freelancing-god/thinking-sphinx.git ', :submodule => true    

# Install all gems
gem 'sqlite3-ruby', :lib => 'sqlite3'
gem 'hpricot', :source => 'http://code.whytheluckystiff.net'
gem 'RedCloth', :lib => 'redcloth'
gem "chronic", :source => "http://gems.github.com"
gem "prawn", :source => "http://gems.github.com"
gem 'mislav-will_paginate', :version => '~> 2.2.3', :lib => 'will_paginate', :source => 'http://gems.github.com'
gem 'rubyist-aasm', :lib => 'aasm'
gem 'ruby-openid', :lib => 'openid'
gem 'capistrano'
gem "openrain-action_mailer_tls", :lib => "smtp_tls.rb", :source => "http://gems.github.com"

rake('gems:install', :sudo => true)
# restful auth routes
route("map.resources :users, :member => { :suspend   => :put, :unsuspend => :put, :purge => :delete }")
route("map.activate '/activate/:activation_code', :controller => 'users', :action => 'activate', :activation_code => nil")

# fix the Role Requirment Plugin
in_root do
  sentinel = 'app_filename = "#{RAILS_ROOT}/app/controllers/application.rb"'
  new_text = 'app_filename = "#{RAILS_ROOT}/app/controllers/application_controller.rb"'
  gsub_file 'vendor/plugins/role_requirement/generators/role_generator_helpers.rb', /(#{Regexp.escape(sentinel)})/, new_text
end

# Set up sessions, RSpec, user model, OpenID, etc, and run migrations
generate("authenticated", "user sessions")
generate("roles", "Role User")
generate("rspec")

rake('db:sessions:create')
rake('acts_as_taggable:db:create')
rake('open_id_authentication:db:create')
rake('db:migrate')

# add includes to application_controller
application_include("ExceptionNotifiable")

# add the restful auth observer
add_observer('users')

# Set up session store initializer
initializer 'session_store.rb', <<-END
ActionController::Base.session = { :session_key => '_#{(1..6).map { |x| (65 + rand(26)).chr }.join}_session', :secret => '#{(1..40).map { |x| (65 + rand(26)).chr }.join}' }
ActionController::Base.session_store = :active_record_store
END

# freeze rails
freeze!
capify!

# Commit all work so far to the repository
git :add => '.'
git :commit => "-a -m 'Initial commit'"

# add git aliases
append_file '.git/config',"
[alias]
      st = status
      di = diff
      co = checkout
      ci = commit
      br = branch
      sta = stash"
      
# Success!
puts "SUCCESS!"