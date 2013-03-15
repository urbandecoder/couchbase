require "spec_helper"
require "bucket_provider"
require "bucket_resource"
require "securerandom"

describe Chef::Provider::CouchbaseBucket do
  let(:provider) { described_class.new new_resource, stub("run_context") }
  let(:base_uri) { "#{new_resource.username}:#{new_resource.password}@localhost:8091" }
  let(:bucket_name) { "default" }
  let(:new_bucket_type) { "couchbase" }
  let(:new_replicas) { 1 }
  let(:new_memory_quota_mb) { 100 }
  let(:new_memory_quota_percent) { nil }

  let :new_resource do
    stub({
      :name => "mah_bukkit",
      :bucket => bucket_name,
      :type => new_bucket_type,
      :cluster => "default_#{SecureRandom.hex(2)}",
      :username => "Administrator",
      :password => "password",
      :memory_quota_mb => new_memory_quota_mb,
      :memory_quota_percent => new_memory_quota_percent,
      :replicas => new_replicas,
      :updated_by_last_action => nil,
    })
  end

  describe ".ancestors" do
    it { described_class.ancestors.should include Chef::Provider }
  end

  describe "#current_resource" do
    let(:current_resource) { provider.tap(&:load_current_resource).current_resource }

    context "when a couchbase bucket exists" do
      before do
        stub_request(:get, "#{base_uri}/pools/#{new_resource.cluster}/buckets/#{new_resource.bucket}").
        to_return(fixture("pools_default_buckets_couchbase_exists.http"))
      end

      it { current_resource.should be_a_kind_of Chef::Resource::CouchbaseBucket }

      it "should have the same name as the new resource" do
        current_resource.name.should == new_resource.name
      end

      it "has the same bucket name as the new resource" do
        current_resource.bucket.should == new_resource.bucket
      end

      it "has the same cluster as the new resource" do
        current_resource.cluster.should == new_resource.cluster
      end

      it "populates exists with true" do
        current_resource.exists.should be_true
      end

      it "populates the memory_quota_mb" do
        current_resource.memory_quota_mb.should == 128
      end

      it "populates the replicas" do
        current_resource.replicas.should == 2
      end

      it "populates the type" do
        current_resource.type.should == "couchbase"
      end
    end

    context "when a memcached bucket exists" do
      let(:bucket_name) { "memcached" }

      before do
        stub_request(:get, "#{base_uri}/pools/#{new_resource.cluster}/buckets/#{new_resource.bucket}").
        to_return(fixture("pools_default_buckets_memcached_exists.http"))
      end

      it { current_resource.should be_a_kind_of Chef::Resource::CouchbaseBucket }

      it "should have the same name as the new resource" do
        current_resource.name.should == new_resource.name
      end

      it "has the same bucket name as the new resource" do
        current_resource.bucket.should == new_resource.bucket
      end

      it "has the same cluster as the new resource" do
        current_resource.cluster.should == new_resource.cluster
      end

      it "populates exists with true" do
        current_resource.exists.should be_true
      end

      it "populates the memory_quota_mb" do
        current_resource.memory_quota_mb.should == 512
      end

      it "populates the replicas" do
        current_resource.replicas.should == 0
      end

      it "populates the type" do
        current_resource.type.should == "memcached"
      end
    end

    context "when the bucket does not exist" do
      before do
        stub_request(:get, "#{base_uri}/pools/#{new_resource.cluster}/buckets/#{new_resource.bucket}").
        to_return(fixture("pools_default_buckets_default_404.http"))
      end

      it { current_resource.should be_a_kind_of Chef::Resource::CouchbaseBucket }

      it "should have the same name as the new resource" do
        current_resource.name.should == new_resource.name
      end

      it "has the same bucket name as the new resource" do
        current_resource.bucket.should == new_resource.bucket
      end

      it "populates exists with false" do
        current_resource.exists.should be_false
      end
    end
  end

  describe "#load_current_resource" do
    context "authorization error" do
      before do
        stub_request(:get, "#{base_uri}/pools/#{new_resource.cluster}/buckets/default").
        to_return(fixture("pools_default_buckets_default_401.http"))
      end

      it { expect { provider.load_current_resource }.to raise_error(Net::HTTPExceptions) }
    end
  end

  describe "#action_create" do
    before { provider.current_resource = current_resource }
    subject { provider.action_create }
    let(:current_memory_quota_mb) { new_resource.memory_quota_mb }
    let(:current_replicas) { new_resource.replicas || 0 }

    let :current_resource do
      stub({
        :name => new_resource.name,
        :bucket => new_resource.bucket,
        :exists => bucket_exists,
        :memory_quota_mb => current_memory_quota_mb,
        :replicas => current_replicas,
      })
    end

    context "when the bucket does not exist" do
      let(:bucket_exists) { false }
      let!(:request) { stub_request(:post, "#{base_uri}/pools/#{new_resource.cluster}/buckets") }

      context "with a default configuration" do
        it "POSTs to the Management REST API to create the bucket" do
          provider.action_create
          request.with(:body => hash_including({
            "authType" => "sasl",
            "saslPassword" => "",
            "bucketType" => "membase",
            "name" => new_resource.bucket,
            "ramQuotaMB" => new_resource.memory_quota_mb.to_s,
            "replicaNumber" => new_resource.replicas.to_s,
          })).should have_been_made.once
        end

        it "updates the new resource" do
          new_resource.should_receive(:updated_by_last_action).with(true)
          provider.action_create
        end

        it "logs the creation" do
          Chef::Log.should_receive(:info).with(/created/)
          provider.action_create
        end
      end

      context "and replicas are set to false" do
        let(:new_replicas) { false }

        it "POSTs replicaNumber=0 to the Management REST API" do
          provider.action_create
          request.with(:body => hash_including("replicaNumber" => "0")).should have_been_made.once
        end
      end

      context "and memory quota percent is set" do
        let(:new_memory_quota_mb) { nil }

        context "the server quota is 256MB" do
          before { stub_request(:get, "#{base_uri}/pools/#{new_resource.cluster}").to_return(fixture("pools_default_exists.http")) }

          context "to 0.5" do
            let(:new_memory_quota_percent) { 0.5 }

            it "POSTs ramQuotaMB=128 to the Management REST API" do
              provider.action_create
              request.with(:body => hash_including("ramQuotaMB" => "128")).should have_been_made.once
            end
          end

          context "to 1.0" do
            let(:new_memory_quota_percent) { 1.0 }

            it "POSTs ramQuotaMB=256 to the Management REST API" do
              provider.action_create
              request.with(:body => hash_including("ramQuotaMB" => "256")).should have_been_made.once
            end
          end
        end

        context "the server quota is 1024MB" do
          before { stub_request(:get, "#{base_uri}/pools/#{new_resource.cluster}").to_return(fixture("pools_default_1gb.http")) }

          context "to 0.5" do
            let(:new_memory_quota_percent) { 0.5 }

            it "POSTs ramQuotaMB=512 to the Management REST API" do
              provider.action_create
              request.with(:body => hash_including("ramQuotaMB" => "512")).should have_been_made.once
            end
          end
        end
      end

      context "and the bucket type is memcached" do
        let(:new_bucket_type) { "memcached" }

        it "POSTs to the Management REST API to create the bucket" do
          provider.action_create
          request.with(:body => hash_including({
            "authType" => "sasl",
            "saslPassword" => "",
            "bucketType" => "memcached",
            "name" => new_resource.bucket,
            "ramQuotaMB" => new_resource.memory_quota_mb.to_s,
          })).should have_been_made.once
        end

        it "updates the new resource" do
          new_resource.should_receive(:updated_by_last_action).with(true)
          provider.action_create
        end

        it "logs the creation" do
          Chef::Log.should_receive(:info).with(/created/)
          provider.action_create
        end
      end
    end

    context "when the bucket exists" do
      let(:bucket_exists) { true }
      let!(:request) { stub_request(:post, "#{base_uri}/pools/#{new_resource.cluster}/buckets/#{new_resource.bucket}") }

      context "when the bucket configuration exactly matches using a memory quota mb" do
        it_should_behave_like "a no op provider action"
      end

      context "when the bucket configuration exactly matches using a memory quota percent" do
        let(:new_memory_quota_mb) { nil }
        let(:current_memory_quota_mb) { 512 }
        let(:new_memory_quota_percent) { 0.5 }
        before { stub_request(:get, "#{base_uri}/pools/#{new_resource.cluster}").to_return(fixture("pools_default_1gb.http")) }
        it_should_behave_like "a no op provider action"
      end

      context "when the memory quota mb does not match" do
        let(:current_memory_quota_mb) { new_resource.memory_quota_mb + 1 }

        it "POSTs to the Management REST API to modify the bucket" do
          provider.action_create
          request.with(:body => hash_including({
            "ramQuotaMB" => new_resource.memory_quota_mb.to_s,
          })).should have_been_made.once
        end

        it "updates the new resource" do
          new_resource.should_receive(:updated_by_last_action).with(true)
          provider.action_create
        end

        it "logs the modification" do
          Chef::Log.should_receive(:info).with(/memory_quota_mb changed to #{new_resource.memory_quota_mb}/)
          provider.action_create
        end
      end

      context "when the memory quota percent does not match" do
        let(:new_memory_quota_mb) { nil }
        let(:current_memory_quota_mb) { 256 }
        let(:new_memory_quota_percent) { 0.5 }
        before { stub_request(:get, "#{base_uri}/pools/#{new_resource.cluster}").to_return(fixture("pools_default_1gb.http")) }

        it "POSTs to the Management REST API to modify the bucket" do
          provider.action_create
          request.with(:body => hash_including("ramQuotaMB" => "512")).should have_been_made.once
        end

        it "updates the new resource" do
          new_resource.should_receive(:updated_by_last_action).with(true)
          provider.action_create
        end

        it "logs the modification" do
          Chef::Log.should_receive(:info).with(/memory_quota_mb changed to 512/)
          provider.action_create
        end
      end
    end

    context "Couchbase fails the request" do
      let(:bucket_exists) { false }

      before do
        Chef::Log.stub(:error)
        stub_request(:post, "#{base_uri}/pools/#{new_resource.cluster}/buckets").to_return(fixture("pools_default_buckets_400.http"))
      end

      it { expect { provider.action_create }.to raise_error(Net::HTTPExceptions) }

      it "logs the error" do
        Chef::Log.should_receive(:error).with(/invalid authType/)
        provider.action_create rescue nil
      end
    end
  end
end
