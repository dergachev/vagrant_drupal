#
## Author:: Alex Dergachev
## Cookbook Name:: deploy_drupal
## Recipe:: default
##
## Copyright 2012, Evolving Web Inc.
##
## Licensed under the Apache License, Version 2.0 (the "License");
## you may not use this file except in compliance with the License.
## You may obtain a copy of the License at
##
##     http://www.apache.org/licenses/LICENSE-2.0
##
## Unless required by applicable law or agreed to in writing, software
## distributed under the License is distributed on an "AS IS" BASIS,
## WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
## See the License for the specific language governing permissions and
## limitations under the License.
##
#

MYSQL_ROOT_PASS = node[:mysql][:server_root_password]
SQL_LOAD_FILE = node['deploy_drupal']['sql_load_file']
SQL_POST_LOAD_SCRIPT = node['deploy_drupal']['sql_post_load_script']
DRUPAL_SITE_NAME = node['deploy_drupal']['site_name']
DRUPAL_SOURCE_PATH = node['deploy_drupal']['codebase_source_path']
DRUPAL_DEPLOY_DIR = node['deploy_drupal']['deploy_directory']
APACHE_PORT = node['deploy_drupal']['apache_port']
APACHE_USER = node['deploy_drupal']['apache_user']
APACHE_GROUP = node['deploy_drupal']['apache_group']

directory DRUPAL_DEPLOY_DIR do
  owner APACHE_USER
  group APACHE_GROUP #specific to your usecase; perhaps should default to Vagrant
  recursive true
end

# validates node['deploy_drupal']['codebase_source_path'] is actually set, and
# contains a Drupal site
# TODO: handle this in the future by deploying stock drupal via drush
execute "validate-codebase-source-path-attribute" do
  command "test -d '#{DRUPAL_SOURCE_PATH}' && test -f #{DRUPAL_SOURCE_PATH}/index.php"
end

# drush make a default drupal site example
bash "install-fga-drupal-site" do
  # see http://superuser.com/a/367303 for cp syntax discussion
  # assumes target directory already exists
  code <<-EOH
    cp -Rf #{DRUPAL_SOURCE_PATH}/. '#{DRUPAL_DEPLOY_DIR}'
    chown -R #{APACHE_USER}:#{APACHE_GROUP} #{DRUPAL_DEPLOY_DIR}
  EOH
  creates "#{DRUPAL_DEPLOY_DIR}/index.php"
  notifies :restart, resources("service[apache2]"), :delayed
end

web_app DRUPAL_SITE_NAME do
  template "web_app.conf.erb"
  port APACHE_PORT
  server_name DRUPAL_SITE_NAME
  server_aliases [DRUPAL_SITE_NAME]
  docroot DRUPAL_DEPLOY_DIR
  notifies :restart, resources("service[apache2]"), :delayed
end

# Disable the default apache site (don't need it, and it conflicts with deploying on port 80)
# TODO: solve this more nicely
apache_site "000-default" do
  enable false
  notifies :restart, resources("service[apache2]"), :delayed
end

# drush sql-create to create a database for the site (requires drush 5.7)
execute "add-drupal-db" do
  command "drush sql-create -y --db-su=root --db-su-pw=#{MYSQL_ROOT_PASS}"
  cwd DRUPAL_DEPLOY_DIR 
  # only do this if unable to connect to the right DB with the right credentials
  not_if "`drush sql-connect`", :cwd => DRUPAL_DEPLOY_DIR
end

# load the drupal database from specified local SQL file
execute "load-drupal-db-from-sql" do
  cwd DRUPAL_DEPLOY_DIR 
  #TODO: not robust to errors connecting to DB
  mysql_empty_check_cmd = "drush sql-query 'show tables;' | wc -l | xargs test 0 -eq"

  # SQL_LOAD_FILE might be nil, must be quoted
  only_if "test -f '#{SQL_LOAD_FILE}'  && #{mysql_empty_check_cmd}", :cwd => DRUPAL_DEPLOY_DIR

  # Using zless instead of cat/zcat to optionally support gzipped files 
  # "`drush sql-connect`" because "drush sqlc" returns 0 even on connection failure
  command "zless '#{SQL_LOAD_FILE}' | `drush sql-connect`"
end

# drush cache clear
execute "drush cache-clear" do
  cwd DRUPAL_DEPLOY_DIR 
  action :nothing
  subscribes :run, resources(:execute => "load-drupal-db-from-sql")
end

# run customized sql-post-load-script, if requested
execute "customized-sql-post-load-script" do
  command "bash '#{SQL_POST_LOAD_SCRIPT}'"
  cwd DRUPAL_DEPLOY_DIR 
  only_if "test -f '#{SQL_POST_LOAD_SCRIPT}'"
  action :nothing
  subscribes :run, resources(:execute => "load-drupal-db-from-sql")
end
