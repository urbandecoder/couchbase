require 'serverspec'
require "json"
require "net/http"

set :backend, :exec

describe service('couchbase-server') do
  it { should be_enabled }
  it { should be_running }
end

describe file("/opt/couchbase/var/lib/couchbase/logs") do
  it { should be_directory }
  it { should be_owned_by "couchbase" }
  it { should be_grouped_into "couchbase" }
end

describe file("/opt/couchbase/etc/couchbase/static_config") do
  its(:content) { should contain "{error_logger_mf_dir, \"/opt/couchbase/var/lib/couchbase/logs\"}." }
  its(:content) { should_not match /error_logger_mf_dir.*error_logger_mf_dir/ }
end

describe file("/opt/couchbase/var/lib/couchbase/data") do
  it { should be_directory }
  it { should be_owned_by "couchbase" }
  it { should be_grouped_into "couchbase" }
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
    let(:data_dir) { "/opt/couchbase/var/lib/couchbase/data" }
    let(:path) { "/nodes/self" }

    it "has its database path configured" do
      expect(response["storage"]["hdd"][0]["path"]).to eq data_dir
    end

    it "has its index path configured" do
      expect(response["storage"]["hdd"][0]["index_path"]).to eq data_dir
    end
  end

  describe "default cluster" do
    let(:path) { "/pools/default" }
    let(:node) {JSON.parse(IO.read('/tmp/kitchen/chef_node.json'))}

    it "has its memory quota configured" do
      expect((response["storageTotals"]["ram"]["quotaTotal"] / response["nodes"].size / 1024 / 1024).to_i).to eq node["default"]["couchbase"]["server"]["memory_quota_mb"]
    end
  end  
end