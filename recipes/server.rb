#
# Cookbook Name:: couchbase
# Recipe:: server
#
# Copyright 2012, getaroom
#
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:
#
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
# WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
#

::Chef::Recipe.send(:include, Opscode::OpenSSL::Password)

if Chef::Config[:solo]
  missing_attrs = %w{
    password
  }.select do |attr|
    node['couchbase']['server'][attr].nil?
  end.map { |attr| "node['couchbase']['server']['#{attr}']" }

  if !missing_attrs.empty?
    Chef::Application.fatal!([
        "You must set #{missing_attrs.join(', ')} in chef-solo mode.",
        "For more information, see https://github.com/juliandunn/couchbase#chef-solo-note"
      ].join(' '))
  end
else
  # generate all passwords
  (node.set['couchbase']['server']['password'] = secure_password && node.save) unless node['couchbase']['server']['password']
end

remote_file File.join(Chef::Config[:file_cache_path], node['couchbase']['server']['package_file']) do
  source node['couchbase']['server']['package_full_url']
  action :create_if_missing
end

case node['platform']
when "debian", "ubuntu"
  package "libssl1.0.0"
  dpkg_package File.join(Chef::Config[:file_cache_path], node['couchbase']['server']['package_file'])
when "redhat", "centos", "scientific", "amazon", "fedora"
  yum_package File.join(Chef::Config[:file_cache_path], node['couchbase']['server']['package_file']) do
    options node['couchbase']['server']['allow_unsigned_packages'] == true ? "--nogpgcheck" : ""
  end
when "windows"

  template "#{Chef::Config[:file_cache_path]}/setup.iss" do
    source "setup.iss.erb"
    action :create
  end

  windows_package "Couchbase Server" do
    source File.join(Chef::Config[:file_cache_path], node['couchbase']['server']['package_file'])
    options "/s"
    installer_type :custom
    action :install
  end
end

ruby_block "block_until_operational" do
  block do
    Chef::Log.info "Waiting until Couchbase is listening on port #{node['couchbase']['server']['port']}"
    until CouchbaseHelper.service_listening?(node['couchbase']['server']['port']) do
      sleep 1
      Chef::Log.debug(".")
    end

    Chef::Log.info "Waiting until the Couchbase admin API is responding"
    test_url = URI.parse("http://localhost:#{node['couchbase']['server']['port']}")
    until CouchbaseHelper.endpoint_responding?(test_url) do
      sleep 1
      Chef::Log.debug(".")
    end
  end
  action :nothing
end

directory node['couchbase']['server']['log_dir'] do
  owner "couchbase"
  group "couchbase"
  mode 0755
  recursive true
end

ruby_block "rewrite_couchbase_log_dir_config" do
  log_dir_line = %{{error_logger_mf_dir, "#{node['couchbase']['server']['log_dir']}"}.}
  static_config_file = ::File.join(node['couchbase']['server']['install_dir'], 'etc', 'couchbase', 'static_config')

  block do
    file = Chef::Util::FileEdit.new(static_config_file)
    file.search_file_replace_line(/error_logger_mf_dir/, log_dir_line)
    file.write_file
  end

  notifies :restart, "service[couchbase-server]"
  not_if "grep '#{log_dir_line}' #{static_config_file}" # XXX won't work on Windows, no 'grep'
end

directory node['couchbase']['server']['database_path'] do
  owner "couchbase"
  group "couchbase"
  mode 0755
  recursive true
end

directory node['couchbase']['server']['index_path'] do
  owner "couchbase"
  group "couchbase"
  mode 0755
  recursive true
end

service "couchbase-server" do
  supports :restart => true, :status => true
  action [:enable, :start]
  notifies :create, "ruby_block[block_until_operational]", :immediately
end

couchbase_node "self" do
  database_path node['couchbase']['server']['database_path']
  index_path node['couchbase']['server']['index_path']

  username node['couchbase']['server']['username']
  password node['couchbase']['server']['password']
  retries 3
  retry_delay 5
end

couchbase_cluster "default" do
  memory_quota_mb node['couchbase']['server']['memory_quota_mb']

  username node['couchbase']['server']['username']
  password node['couchbase']['server']['password']
end

couchbase_settings "web" do
  settings({
    "username" => node['couchbase']['server']['username'],
    "password" => node['couchbase']['server']['password'],
    "port" => 8091,
  })

  username node['couchbase']['server']['username']
  password node['couchbase']['server']['password']
end
