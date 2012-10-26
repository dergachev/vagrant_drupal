# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant::Config.run do |config|
  # config.vm.box = "precise64-customized"
  config.vm.box = "precise64"
  config.vm.customize ["modifyvm", :id, "--memory", "2048"]
  config.vm.forward_port 80, 8080

  # consider enabling nfs for a speedup
  config.vm.share_folder "v-root", "/vagrant", ".", :nfs => false

  # mkdir ./tmp/vagrant_aptcache before uncommenting; see https://gist.github.com/3798773
  # config.vm.share_folder("v-apt", "/var/cache/apt/archives", "./tmp/vagrant_aptcache")

  config.vm.provision :chef_solo do |chef|
    chef.cookbooks_path = ["site-cookbooks", "cookbooks"]

    chef.add_recipe 'deploy_drupal::lamp_stack'
    chef.add_recipe 'deploy_drupal::pear_dependencies'
    chef.add_recipe 'deploy_drupal'

    chef.json.merge!({
      :deploy_drupal => { 
        :apache_group => 'sysadmin', # defaults to www-data
        :sql_load_file => '/vagrant/db/fga.sql.gz', # load this SQL dump file
        :sql_post_load_script => '/vagrant/db/fga-sql-post-load.sh', # run this bash script after loading db
        :site_name => 'fga.vbox.local', # used for VHOST configuration, deployment directory, etc.
        :codebase_source_path =>  "/vagrant/public/fga.vbox.local/www", # deploy drupal from a mounted folder
        # :apache_port => '80'
      },
      :mysql => {
        :server_root_password => "root", # hardcoded MySQL root password.
      },
    })

    # chef.log_level = :debug
  end
  
end
