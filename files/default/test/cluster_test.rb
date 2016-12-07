describe_recipe "couchbase::cluster" do
  include MiniTest::Chef::Assertions
  include MiniTest::Chef::Context
  include MiniTest::Chef::Resources

  MiniTest::Chef::Resources.register_resource :couchbase_cluster, :username, :password

  describe "creates Couchbase cluster" do
    let(:cluster) do
      couchbase_cluster(node["couchbase"]["cluster"]["name"], {
        :username => node["couchbase"]["server"]["username"],
        :password => node["couchbase"]["server"]["password"]
      })
    end

    it "exists" do
      assert cluster.exists
    end

    it "has its memory quota configured" do
      cluster.must_have :memory_quota_mb, node["couchbase"]["cluster"]["memory_quota_mb"]
    end
  end
end
