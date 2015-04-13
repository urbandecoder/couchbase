#
# Cookbook Name:: couchbase
# Attributes:: server
#
# Author:: Julian C. Dunn (<jdunn@opscode.com>)
# Copyright (C) 2012, SecondMarket Labs, LLC.
# Copyright (C) 2013, Opscode, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

default['couchbase']['server']['edition'] = "community"
default['couchbase']['server']['version'] = "3.0.0"
default['couchbase']['server']['service_name'] = "couchbase-server"
default['couchbase']['server']['install_dir'] = "/opt/couchbase"
default['couchbase']['server']['memory_quota_mb'] = Couchbase::MaxMemoryQuotaCalculator.from_node(node).in_megabytes

case node['platform']
when "debian"
  package_machine = node['kernel']['machine'] == "x86_64" ? "amd64" : "x86"
  default['couchbase']['server']['package_file'] = "couchbase-server-#{node['couchbase']['server']['edition']}_#{node['couchbase']['server']['version']}-debian7_#{package_machine}.deb"
when "centos", "redhat", "amazon", "scientific"
  package_machine = node['kernel']['machine'] == "x86_64" ? "x86_64" : "x86"
  default['couchbase']['server']['package_file'] = "couchbase-server-#{node['couchbase']['server']['edition']}-#{node['couchbase']['server']['version']}-centos6.#{package_machine}.rpm"
when "ubuntu"
  package_machine = node['kernel']['machine'] == "x86_64" ? "amd64" : "x86"
  default['couchbase']['server']['package_file'] = "couchbase-server-#{node['couchbase']['server']['edition']}_#{node['couchbase']['server']['version']}-ubuntu12.04_#{package_machine}.deb"
when "windows"
  default['couchbase']['server']['service_name'] = "CouchbaseServer"
  default['couchbase']['server']['install_dir'] = File.join("C:","Program Files","Couchbase","Server")
  mem_quota = Couchbase::MaxMemoryQuotaCalculator.from_node(node).in_megabytes
  default['couchbase']['server']['memory_quota_mb'] = mem_quota - 1 if mem_quota - 1 >= 256
  if node['kernel']['machine'] != 'x86_64'
    Chef::Log.error("Couchbase Server on Windows must be installed on a 64-bit machine")
  else
    default['couchbase']['server']['version'] = "3.0.3"
    default['couchbase']['server']['package_file'] = "couchbase-server-#{node['couchbase']['server']['edition']}_#{node['couchbase']['server']['version']}-windows_amd64.exe"
  end
else
  Chef::Log.error("Couchbase Server is not supported on #{node['platform_family']}")
end

default['couchbase']['server']['package_base_url'] = "http://packages.couchbase.com/releases/#{node['couchbase']['server']['version']}"
default['couchbase']['server']['package_full_url'] = "#{node['couchbase']['server']['package_base_url']}/#{node['couchbase']['server']['package_file']}"

default['couchbase']['server']['database_path'] = File.join(node['couchbase']['server']['install_dir'],"var","lib","couchbase","data")
default['couchbase']['server']['index_path'] = File.join(node['couchbase']['server']['install_dir'],"var","lib","couchbase","data")
default['couchbase']['server']['log_dir'] = File.join(node['couchbase']['server']['install_dir'],"var","lib","couchbase","logs")

default['couchbase']['server']['username'] = "Administrator"
default['couchbase']['server']['password'] = nil

default['couchbase']['server']['port'] = 8091

default['couchbase']['server']['allow_unsigned_packages'] = true
