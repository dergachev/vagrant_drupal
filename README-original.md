vagrant_drupal
==============

Deploy a local Drupal development stack with Vagrant, using the following:

./Vagrantfile:                    configures Vagrant project, including port-forwarding and other customizations
./Cheffile:                       specifies dependent cookbooks to be automatically installed into ./cookbooks
./site-cookbooks/deploy_drupal:   cookbook to deploy and configure Drupal; see its README.md for further instructions

The deploy_drupal cookbook assumes that you have a Drupal site at ./public/vbox/fga.vbox.lan/www. You should checkout your Drupal files in this directory. This cookbook also assumes that your database is located at ./db/fga.sql.gz. After the database is loaded, the cookbook will run any additional commands in ./db/fga-sql-post-load.sh. This script can contain Drush commands that you want to run after the database has been loaded (i.e. create an admin user). These paths are configured in the ./VagrantFile.

Run with the following commands:

```bash
# install librarian-chef cookbook management tool (if necessary)
sudo gem install librarian --no-rdoc --no-ri

# ask librarian-chef to build out cookbooks/ directory based on Cheffile
librarian-chef install 

# start the VM
vagrant up
```

Notes on removed attributes
===========================

PHP Overrides
-------------

These used to be supported because drupal::minimal overrides php.ini. Not clear
if it is necessary, given https://github.com/opscode-cookbooks/php/pull/9):
```ruby
:php5 => { 
  :max_execution_time => "60",
  :memory_limit => "256M"
},
```

Removed Varnish and Hosts Overrides
-----------------------------------

These settings were associated with the removed Varnish and Hosts cookbooks dependencies.

```ruby
:varnish => { # probably incorrect
  :listen_port => "80",
  :backend_address => "127.0.0.1",
  :backend_port => "8080"
},
:hosts => { :localhost_aliases => ["fga.vbox.local"] },
```

Apache2 and Memcached Overrides
-------------------------------

These performanced tweaks seemed unnecessary, for now:

```ruby
:apache => {
  :listen_ports => [ "8080", "443" ], # defaults to 80,443
  :keepaliverequests => 10, # default 100
    :prefork => { # lower than default
      :startservers => 2,
      :minspareservers => 1,
      :maxspareservers => 3,
      :serverlimit => 4,
      :maxclients => 4,
      :maxrequestsperchild => 1000
    },
},
:memcached => {
  :memory => "128", #default 64
}
