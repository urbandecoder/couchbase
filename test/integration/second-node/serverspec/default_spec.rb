require 'serverspec'
require "json"
require "net/http"

require 'rbconfig'
case RbConfig::CONFIG['host_os']
when /mswin|msys|mingw|cygwin|bccwin|wince|emc/
  set :backend, :cmd
  set :os, :family => 'windows'
else
  set :backend, :exec
end

describe "cluster" do
  let(:node) { JSON.parse(IO.read(File.join(ENV["TEMP"] || "/tmp", "kitchen/chef_node.json"))) }
  let(:response) do
    resp = Net::HTTP.start node["normal"]["couchbase-tests"]["primary_ip"], 8091 do |http|
      request = Net::HTTP::Get.new "/pools/default"
      request.basic_auth "Administrator", "whatever"
      http.request request
    end
    JSON.parse(resp.body)
  end

  it "has found the priary node and it is not itself" do
    expect(node["normal"]["couchbase-tests"]["primary_ip"]).not_to eq(node['automatic']['ipaddress'])
  end

  it "has joined the primary cluster" do
    joined = false
    response['nodes'].each do |cluster_node|
      if cluster_node['hostname'] == "#{node['automatic']['ipaddress']}:8091"
        joined =  true
      end
    end

    expect(joined).to be true
  end
end