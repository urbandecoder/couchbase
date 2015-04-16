include_recipe "couchbase::server"

primary = search_for_nodes("run_list:*couchbase??server* AND platform:#{node['platform']}")
node.normal["couchbase-tests"]["primary_ip"] = primary[0]['ipaddress']
ruby_block "block_until_operational" do
  block do
    Chef::Log.info "Waiting until the Couchbase admin API is responding"
    test_url = URI.parse("http://#{node["couchbase-tests"]["primary_ip"]}:#{node['couchbase']['server']['port']}")
    until CouchbaseHelper.endpoint_responding?(test_url) do
      sleep 1
      Chef::Log.debug(".")
    end
  end
end

couchbase_cluster "default" do
  action :join
  memory_quota_mb node['couchbase']['server']['memory_quota_mb']
  hostname node["couchbase-tests"]["primary_ip"]
  username node['couchbase']['server']['username']
  password node['couchbase']['server']['password']
end
