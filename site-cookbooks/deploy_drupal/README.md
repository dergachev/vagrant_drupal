Deploy Drupal Cookbook 
================

Description
-----------

Installs and configures a Drupal site. Currently copies codebase from
/vagrant/public/SITE/www and looks for the database dump at
/vagrant/db/SITE.sql. It will create the mysql user/pass/db-name as referenced
in settings.php.

Installation and Usage
======================

Coming soon.

Requirements
============

Cookbooks: hosts::default, drush::head

NOTE: resource names must be unique, else strange behavior happens.  This
explained why recipe[drupal::suzanne]#execute[add-drupal-db]#not_if was being
applied to recipe[drupal::example]#execute[add-drupal-db]. See
http://tickets.opscode.com/browse/CHEF-2812

Recipes
=======

deploy_drupal::default 
----------------------

installs Drupal, includes deploy_drupal::dependencies

This recipe will copy over the site from FGA_SITE_ROOT_VAGRANT.  It uses drush
sql-create (available in 6.x-HEAD) to create the mysql user/password/database specified in settings.php.

deploy_drupal::dependencies
---------------------------
Installs PEAR, PECL, and required packages.

Attributes
----------

This cookbook defines the following default attributes under node['default']['deploy_drupal']:

<table>
<tr>
<th> Attribute </th> <th> Default value </th> <th> Notes </th> </tr>
<tr> <td> codebase_source_path </td>
     <td>  </td>
     <td> required attribute, absolute path to drupal folder containing index.php and settings.php </td>
</tr>
<tr> <td> site_name </td>
     <td> 'drupalsite.lan' </td>
     <td> vhost server name </td>
</tr>
<tr> <td> deploy_directory </td>
     <td>  "/var/shared/sites/#{deploy_drupal['site_name']}/site" </td>
     <td> can be same as codebase_source_path </td>
</tr>
<tr> <td> apache_port</td>
     <td>  80 </td>
     <td> should be consistent with  node['apache']['listen_ports'] </td>
</tr>
<tr> <td> apache_user </td>
     <td>  www-data </td>
     <td> user owning drupal codebase files </td>
</tr>
<tr> <td> apache_group </td>
     <td>  www-data </td>
     <td> group owning drupal codebase files </td>
</tr>
<tr> <td> sql_load_file </td>
     <td>  </td>
     <td> absolute path to drupal SQL dump (can be .gz) </td>
</tr>
<tr> <td> sql_post_load_script </td>
     <td>  </td>
     <td> absolute path to bash script to run after loading SQL dump </td>
</tr>
</table>

TODO
====

Add resources to test for successful deployment, eg http://wiki.opscode.com/display/chef/Resources#highlighter_558172

Deploy drupal from git (or via drush make) if not already deployed. 
Perhaps drush_core-quick-install or drush_make_--prepare-install.
See also https://github.com/mdxp/drupal-cookbook/blob/master/recipes/default.rb

Build deploy_drupal::cron, see:
  https://github.com/mdxp/drupal-cookbook/blob/master/recipes/cron.rb
  http://drupal.org/node/23714

Too much other stuff to mention.
