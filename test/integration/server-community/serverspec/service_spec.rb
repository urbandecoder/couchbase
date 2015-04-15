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

node = JSON.parse(IO.read(File.join(ENV["TEMP"] || "/tmp", "export-node/node.json")))["default"]["couchbase"]["server"]

describe service(node["service_name"]) do
  it { should be_enabled }
  it { should be_running }
end

describe file(node["log_dir"]) do
  it { should be_directory }
  unless host_inventory['platform'] == "windows"
    it { should be_owned_by "couchbase" }
    it { should be_grouped_into "couchbase" }
  end
end

describe file(File.join(node["install_dir"], "etc/couchbase/static_config")) do
  let(:node) { JSON.parse(IO.read(File.join(ENV["TEMP"] || "/tmp", "/tmp/export-node/node.json")))["default"]["couchbase"]["server"] }
  its(:content) { should contain "{error_logger_mf_dir, \"#{node["log_dir"]}\"}." }
  its(:content) { should_not match /error_logger_mf_dir.*error_logger_mf_dir/ }
end

describe file(node["database_path"]) do
  it { should be_directory }
  unless host_inventory['platform'] == "windows"
    it { should be_owned_by "couchbase" }
    it { should be_grouped_into "couchbase" }
  end
end

describe "couchbase service state" do
  let(:response) do
    resp = Net::HTTP.start "localhost", 8091 do |http|
      request = Net::HTTP::Get.new path
      request.basic_auth "Administrator", "whatever"
      http.request request
    end
    JSON.parse(resp.body)
  end

  describe "self node" do
    let(:path) { "/nodes/self" }

    it "has its database path configured" do
      expect(response["storage"]["hdd"][0]["path"]).to eq node["database_path"]
    end

    it "has its index path configured" do
      expect(response["storage"]["hdd"][0]["index_path"]).to eq node["database_path"]
    end
  end

  describe "default cluster" do
    let(:path) { "/pools/default" }

    it "has its memory quota configured" do
      expect((response["storageTotals"]["ram"]["quotaTotal"] / response["nodes"].size / 1024 / 1024).to_i).to eq node["memory_quota_mb"]
    end
  end  
end