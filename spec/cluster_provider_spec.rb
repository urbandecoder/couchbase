require "spec_helper"
require "cluster_provider"
require "cluster_resource"

describe Chef::Provider::CouchbaseCluster do
  let(:node_address) { "127.0.0.1" }
  let(:hostname) { "localhost" }
  let(:provider) { described_class.new(new_resource, double("run_context", :node => { "ipaddress" => node_address })) }
  let(:base_uri) { "#{new_resource.username}:#{new_resource.password}@localhost:8091" }

  let :new_resource do
    double({
      :name => "my new pool",
      :cluster => "default",
      :username => "Administrator",
      :password => "password",
      :hostname => hostname,
      :port => 8091,
      :memory_quota_mb => 256,
      :updated_by_last_action => nil,
    })
  end

  describe ".ancestors" do
    it { described_class.ancestors.should include Chef::Provider }
  end

  describe "#current_resource" do
    let(:current_resource) { provider.tap(&:load_current_resource).current_resource }

    context "a cluster exists" do
      before { stub_request(:get, "#{base_uri}/pools/default").to_return(fixture("pools_default_exists.http")) }

      it { current_resource.should be_a_kind_of Chef::Resource::CouchbaseCluster }

      it "has the same name as the new resource" do
        current_resource.name.should == new_resource.name
      end

      it "has the same cluster as the new resource" do
        current_resource.cluster.should == new_resource.cluster
      end

      it "populates the memory_quota_mb" do
        current_resource.memory_quota_mb.should == 256
      end

      it "populates exists with true" do
        current_resource.exists.should be true
      end
    end

    context "a cluster does not exist" do
      before { stub_request(:get, "#{base_uri}/pools/default").to_return(fixture("pools_default_404.http")) }

      it { current_resource.should be_a_kind_of Chef::Resource::CouchbaseCluster }

      it "has the same name as the new resource" do
        current_resource.name.should == new_resource.name
      end

      it "has the same cluster as the new resource" do
        current_resource.cluster.should == new_resource.cluster
      end

      it "does not populate the memory_quota_mb" do
        expect { current_resource.memory_quota_mb }.to raise_error
      end

      it "populates exists with false" do
        current_resource.exists.should be false
      end
    end
  end

  describe "#load_current_resource" do
    context "authorization error" do
      before { stub_request(:get, "#{base_uri}/pools/default").to_return(fixture("pools_default_401.http")) }

      it { expect { provider.load_current_resource }.to raise_error(Net::HTTPExceptions) }
    end
  end

  describe "#action_create_if_missing" do
    let(:memory_quota_mb) { 256 }

    before do
      provider.current_resource = double({
        :cluster => "default",
        :memory_quota_mb => memory_quota_mb,
        :exists => cluster_exists,
      })
    end

    context "cluster does not exist" do
      let(:cluster_exists) { false }

      let! :cluster_request do
        stub_request(:post, "#{base_uri}/pools/default").with({
          :body => hash_including("memoryQuota" => new_resource.memory_quota_mb.to_s),
        })
      end

      it "POSTs to the Management REST API to create the cluster" do
        provider.action_create_if_missing
        cluster_request.should have_been_made.once
      end

      it "updates the new resource" do
        new_resource.should_receive(:updated_by_last_action).with(true)
        provider.action_create_if_missing
      end

      it "logs the creation" do
        Chef::Log.should_receive(:info).with(/created/)
        provider.action_create_if_missing
      end
    end

    context "Couchbase fails the request" do
      let(:cluster_exists) { false }

      before do
        Chef::Log.stub(:error)
        stub_request(:post, "#{base_uri}/pools/default").to_return(fixture("pools_default_400.http"))
      end

      it { expect { provider.action_create_if_missing }.to raise_error(Net::HTTPExceptions) }

      it "logs the error" do
        Chef::Log.should_receive(:error).with(%{["The RAM Quota value is too large. Quota must be between 256 MB and 796 MB (80% of memory size)."]})
        provider.action_create_if_missing rescue nil
      end
    end

    context "cluster exists but quotas don't match" do
      let(:cluster_exists) { true }
      let(:memory_quota_mb) { new_resource.memory_quota_mb * 2 }
      subject { provider.action_create_if_missing }
      it_should_behave_like "a no op provider action"
    end
  end

  describe "#action_join" do
    before do
      provider.current_resource = double({
        :cluster => "default",
        :exists => cluster_exists
      })
    end
    let(:cluster_exists) { true }

    context "cluster does not exist" do
      let(:cluster_exists) { false }

      it "should raise error" do
        expect { provider.action_join }.to raise_error
      end
    end

    context "has not joined cluster" do
      let(:node_address) { "1.2.3.4" }

      before { stub_request(:get, "#{base_uri}/pools/default").to_return(fixture("pools_default_exists.http")) }

      let! :cluster_request do
        stub_request(:post, "#{base_uri}/controller/addNode").with({
          :body => hash_including("hostname" => node_address),
        })
      end

      it "POSTs to the Management REST API to add node to the cluster" do
        provider.action_join
        cluster_request.should have_been_made.once
      end

      it "updates the new resource" do
        new_resource.should_receive(:updated_by_last_action).with(true)
        provider.action_join
      end

      it "logs the join" do
        Chef::Log.should_receive(:info).with(/joined/)
        provider.action_join
      end
    end

    context "has already joined cluster" do
      before { stub_request(:get, "#{base_uri}/pools/default").to_return(fixture("pools_default_exists.http")) }
      subject { provider.action_join }
      it_should_behave_like "a no op provider action"
    end
  end
end
