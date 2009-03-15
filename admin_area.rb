# template.rb
run "mv public/index.html  public/index.html-bak"

generate(:rspec_controller, "admin index")

generate(:rspec_scaffold, "Admin::CmsPage name:string title:string sub_title:string body:text meta_keyword:text meta_description:text position:integer parent_id:integer")

generate(:rspec_controller, "CmsPage home")

generate(:rspec_scaffold, "Admin::ConfigValue name:string value:string sys_var:boolean")

route "map.root :controller => 'cms_page', :action => 'home'"

rake("db:migrate")

git :init
git :add => "."
git :commit => "-a -m 'Admin Area Created'"