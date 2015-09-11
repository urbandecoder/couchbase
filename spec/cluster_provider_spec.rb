require "spec_helper"
require "cluster_provider"
require "cluster_resource"

describe Chef::Provider::CouchbaseCluster do
  let(:provider) { described_class.new(new_resource, double("run_context")) }
  let(:base_uri) { "#{new_resource.username}:#{new_resource.password}@localhost:8091" }

  let :new_resource do
    double({
      :name => "my new pool",
      :cluster => "default",
      :username => "Administrator",
      :password => "password",
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

      # it { expect { provider.action_create_if_missing }.to raise_error(Net::HTTPExceptions) }

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
end
