package_machine = node['kernel']['machine'] == "x86_64" ? "x86_64" : "x86"

default['couchbase']['server']['edition'] = "community"
default['couchbase']['server']['version'] = "2.0.0"

case node['platform_family']
when "debian"
  default['couchbase']['server']['package_file'] = "couchbase-server-#{node['couchbase']['server']['edition']}_#{package_machine}_#{node['couchbase']['server']['version']}.deb"
when "rhel"
  default['couchbase']['server']['package_file'] = "couchbase-server-#{node['couchbase']['server']['edition']}_#{package_machine}_#{node['couchbase']['server']['version']}.rpm"
when "windows"
  if node['kernel']['machine'] != 'x86_64'
    Chef::Log.error("Couchbase Server on Windows must be installed on a 64-bit machine")
  else
    default['couchbase']['server']['package_file'] = "couchbase-server-#{node['couchbase']['server']['edition']}_#{package_machine}_#{node['couchbase']['server']['version']}.setup.exe"
  end
else
  Chef::Log.error("Couchbase Server is not supported on #{platform_family}")
end

default['couchbase']['server']['package_base_url'] = "http://packages.couchbase.com/releases/#{node['couchbase']['server']['version']}"
default['couchbase']['server']['package_full_url'] = "#{node['couchbase']['server']['package_base_url']}/#{node['couchbase']['server']['package_file']}"

case node['platform_family']
when "windows"
  default['couchbase']['server']['install_dir'] = File.join("C:","Program Files","Couchbase","Server")
  default['couchbase']['server']['database_path'] = File.join(node['couchbase']['server']['install_dir'],"var","lib","couchbase","data")
  default['couchbase']['server']['log_dir'] = File.join(node['couchbase']['server']['install_dir'],"var","lib","couchbase","logs")
else
  default['couchbase']['server']['install_dir'] = "/opt/couchbase"
  default['couchbase']['server']['database_path'] = "#{node['couchbase']['server']['install_dir']}/var/lib/couchbase/data"
  default['couchbase']['server']['log_dir'] = "#{node['couchbase']['server']['install_dir']}/var/lib/couchbase/logs"
end

default['couchbase']['server']['username'] = "Administrator"
default['couchbase']['server']['password'] = ""

default['couchbase']['server']['memory_quota_mb'] = Couchbase::MaxMemoryQuotaCalculator.from_node(node).in_megabytes
