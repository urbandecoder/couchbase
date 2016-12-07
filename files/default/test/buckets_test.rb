describe_recipe "couchbase::buckets" do
  include MiniTest::Chef::Assertions
  include MiniTest::Chef::Context
  include MiniTest::Chef::Resources

  MiniTest::Chef::Resources.register_resource :couchbase_bucket, :username, :password

  # I'd love to have dynamic tests here based on node['couchbase']['buckets'],
  # but MiniTest::Chef only exposes the nobe object in "it" blocks
  describe "bucket one" do
    let :bucket do
      couchbase_bucket("one", {
        :username => node["couchbase"]["server"]["username"],
        :password => node["couchbase"]["server"]["password"],
      })
    end

    it "exists" do
      assert bucket.exists
    end

    it "is correct type" do
      bucket.must_have :type, "memcached"
    end

    it "has correct number of replicas" do
      bucket.must_have :replicas, 0
    end

    it "has correct quota" do
      bucket.must_have :memory_quota_mb, 256
    end

    it "has correct saslpassword" do
      bucket.must_have :saslpassword, "nevertellanyone"
    end
  end

  describe "bucket two" do
    let :bucket do
      couchbase_bucket("two", {
        :username => node["couchbase"]["server"]["username"],
        :password => node["couchbase"]["server"]["password"],
      })
    end

    it "exists" do
      assert bucket.exists
    end

    it "is correct type" do
      bucket.must_have :type, "couchbase"
    end

    it "has correct number of replicas" do
      bucket.must_have :replicas, 1
    end

    it "has correct quota" do
      bucket.must_have :memory_quota_mb, (node['couchbase']['cluster']['memory_quota_mb'] * 0.5).to_i
    end

    it "has correct saslpassword" do
      bucket.must_have :saslpassword, "mustbedifferent"
    end
  end

end
