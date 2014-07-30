#
# Cookbook Name:: php-expressionengine-env
# Recipe:: default
#
# Copyright 2014, Rob Newman
#

package "unzip" do
  action :install # required for unzipping Expression Engine source
end

# Install a sane text editor
include_recipe "vim"

# Append server name
[ node['php-expressionengine-env']['ipv6_address'], node['php-expressionengine-env']['ipv4_address'] ].each do |entry|
  hostsfile_entry "#{entry}" do
    hostname node['php-expressionengine-env']['vm_name']
    aliases [ node['php-expressionengine-env']['server_name'] ]
    comment 'DNS entry appended by php-expressionengine-env recipe'
    action :append
  end
end

# Update iptables: open port 80 (http) & port 443 (https)
include_recipe "simple_iptables"
simple_iptables_rule "http" do
  rule [ "--proto tcp --dport 80",
         "--proto tcp --dport 443" ]
  jump "ACCEPT"
end

include_recipe "apache2"
include_recipe "mysql::client"
include_recipe "mysql::server"
include_recipe "php"
include_recipe "php::module_mysql"
include_recipe "apache2::mod_php5"
include_recipe "mysql::ruby"

# Turn off default Apache site
apache_site "default" do
  enable false
end

# Build virtualhost
web_app 'php-expressionengine-env' do
  template 'site.conf.erb'
  servername node['php-expressionengine-env']['server_name'] # For global http.conf
  iris_docroot node['php-expressionengine-env']['iris_path'] + "/httpdocs"
  iris_ip node['php-expressionengine-env']['ipv4_address']
  iris_serveradmin node['php-expressionengine-env']['iris_server_admin']
  iris_servername node['php-expressionengine-env']['server_name']
  iris_customlog_path node['php-expressionengine-env']['iris_customlog_path']
  iris_customlog_format node['php-expressionengine-env']['iris_customlog_format']
  iris_errorlog_path node['php-expressionengine-env']['iris_errorlog_path']
end


mysql_database node['php-expressionengine-env']['database'] do
  connection ({:host => 'localhost', 
               :username => 'root',
               :password => node['mysql']['server_root_password']
             })
  action :create
end

mysql_database_user node['php-expressionengine-env']['db_username'] do
  connection ({:host => 'localhost',
               :username => 'root',
               :password => node['mysql']['server_root_password']
             })
  password node['php-expressionengine-env']['db_password']
  database_name node['php-expressionengine-env']['database']
  privileges [:select,:update,:insert,:create,:delete]
  action :grant
end

expression_engine_latest = Chef::Config[:file_cache_path] + "/expression-engine-latest.zip"

remote_file expression_engine_latest do
  source node["php-expressionengine-env"]["ee_source"]
  mode "0644"
end

# Create vhosts dir
directory node["php-expressionengine-env"]["vhostsdir"] do
  owner "root"
  group "root"
  mode "0755"
  action :create
  recursive true
end


# Create iris.edu
directory node["php-expressionengine-env"]["iris_path"] do
  owner "root"
  group "root"
  mode "0755"
  action :create
  recursive true
end

# Create iris.edu web directory structure
['httpdocs', 'db_backups', 'scripts', 'statistics'].each do |webdir|
  directory node["php-expressionengine-env"]["iris_path"] + "/#{webdir}" do
    owner "root"
    group "root"
    mode "0755"
    action :create
    recursive true
  end
end

# Create the ugly /hq path
directory node["php-expressionengine-env"]["iris_path"] + "/httpdocs/hq" do
  owner "root"
  group "root"
  mode "0755"
  action :create
  recursive true
end

# ---------
# START: EE
# ---------

# Unzip EE
default_system = node['php-expressionengine-env']['iris_path'] + "/httpdocs/hq/system"
secure_system = node['php-expressionengine-env']['iris_path'] + "/system"
config_dir = node['php-expressionengine-env']['iris_path'] + "/config"

execute "unzip-expression-engine" do
  cwd node['php-expressionengine-env']['iris_path'] + "/httpdocs/hq"
  command "unzip " + expression_engine_latest
  creates node['php-expressionengine-env']['iris_path'] + "/httpdocs/hq/system/expressionengine/config/database.php"
  not_if { File.exists?(secure_system) }
end

# Assume Apache, not IIS, and make permissions correct
# Source: http://ellislab.com/expressionengine/user-guide/installation/installation.html
file_permissions = {
  "0666" => [
    node["php-expressionengine-env"]["iris_path"] + "/httpdocs/hq/system/expressionengine/config/config.php",
    node["php-expressionengine-env"]["iris_path"] + "/httpdocs/hq/system/expressionengine/config/database.php"
  ],
  "0777" => [
    node["php-expressionengine-env"]["iris_path"] + "/httpdocs/hq/system/expressionengine/cache",
    node["php-expressionengine-env"]["iris_path"] + "/httpdocs/hq/images/avatars/uploads",
    node["php-expressionengine-env"]["iris_path"] + "/httpdocs/hq/images/captchas",
    node["php-expressionengine-env"]["iris_path"] + "/httpdocs/hq/images/member_photos",
    node["php-expressionengine-env"]["iris_path"] + "/httpdocs/hq/images/pm_attachments",
    node["php-expressionengine-env"]["iris_path"] + "/httpdocs/hq/images/signature_attachments",
    node["php-expressionengine-env"]["iris_path"] + "/httpdocs/hq/images/uploads"
  ]
}

file_permissions.each do |permission,filename|
  filename.each do |f|
    directory "#{f}" do
      mode "#{permission}"
      if mode == "0777"
        recursive true
      end
      not_if { File.exists?(secure_system) }
    end
  end
end

# 1. EE best practices: Move the system directory
bash "Move EE to secure location and delete default system install" do
  code <<-EOL
    mv #{default_system} #{secure_system}
    EOL
  not_if { File.exists?(secure_system) }
end

# 1.1 Remember to update references in admin.php and index.php to ./system by hand

# ---------
# END: EE
# ---------

# Install git
include_recipe "git"

# Clone the latest EE Master Config from Focus Lab LLC
ee_master_config_latest = Chef::Config[:file_cache_path] + "/ee-master-config"
git ee_master_config_latest do
  repository "https://github.com/focuslabllc/ee-master-config.git"
  revision "master"
  action :sync
end

# Move the master config directory
ee_master_config_dir = ee_master_config_latest + "/config"
bash "Move the EE Master config directory to the same level as the system directory" do
  code <<-EOL
    mv #{ee_master_config_dir} #{config_dir}
    rm -rf #{ee_master_config_latest}
    EOL
  not_if { File.exists?(config_dir) }
end

# Grant sudo privs to all members of 'wheel'
sudo 'wheel' do
    group    '%wheel'
    nopasswd true
end
