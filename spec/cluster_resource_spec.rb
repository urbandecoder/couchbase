require "spec_helper"
require "cluster_resource"

describe Chef::Resource::CouchbaseCluster do
  let(:resource) { described_class.new("default") }
  it_should_behave_like "a resource with couchbase credentials"

  describe ".ancestors" do
    it { described_class.ancestors.should include Chef::Resource }
  end

  describe "#action" do
    it "defaults to :create_if_missing" do
      resource.action.should == :create_if_missing
    end
  end

  describe "#allowed_actions" do
    subject { resource.allowed_actions }
    it { should include :join }
    it { should include :create_if_missing }
    it { should include :nothing }
  end

  describe "#exists" do
    it "can be assigned true" do
      resource.exists true
      resource.exists.should == true
    end

    it "can be assigned false" do
      resource.exists false
      resource.exists.should == false
    end

    it "cannot be assigned an Integer" do
      expect { resource.exists 42 }.to raise_error Chef::Exceptions::ValidationFailed
    end

    it "cannot be assigned nil" do
      expect { resource.exists nil }.to raise_error Chef::Exceptions::ValidationFailed
    end
  end

  describe "#cluster" do
    it "can be assigned" do
      resource.cluster "new_pool"
      resource.cluster.should == "new_pool"
    end

    it "cannot be assigned an Integer" do
      expect { resource.cluster 42 }.to raise_error Chef::Exceptions::ValidationFailed
    end

    it "defaults to the name attribute" do
      resource.cluster.should == resource.name
    end
  end

  describe "#hostname" do
    it "can be assigned" do
      resource.hostname "new_hostname"
      resource.hostname.should == "new_hostname"
    end

    it "cannot be assigned an Integer" do
      expect { resource.hostname 42 }.to raise_error Chef::Exceptions::ValidationFailed
    end

    it "defaults to localhost" do
      resource.hostname.should == "localhost"
    end
  end

  describe "#port" do
    it "can be assigned" do
      resource.port 777
      resource.port.should == 777
    end

    it "cannot be assigned a String" do
      expect { resource.port "42" }.to raise_error Chef::Exceptions::ValidationFailed
    end

    it "defaults to 8091" do
      resource.port.should == 8091
    end
  end

  describe "#memory_quota_mb" do
    it "can be assigned" do
      resource.memory_quota_mb 512
      resource.memory_quota_mb.should == 512
    end

    it "cannot be assigned a String" do
      expect { resource.memory_quota_mb "happy" }.to raise_error Chef::Exceptions::ValidationFailed
    end

    it "cannot be assigned a Float" do
      expect { resource.memory_quota_mb 512.5 }.to raise_error Chef::Exceptions::ValidationFailed
    end

    it "can be assigned 256" do
      resource.memory_quota_mb 256
      resource.memory_quota_mb.should == 256
    end

    it "cannot be assigned a negative number" do
      expect { resource.memory_quota_mb -1 }.to raise_error Chef::Exceptions::ValidationFailed, "Option memory_quota_mb's value -1 must be at least 256!"
    end

    it "cannot be assigned 255" do
      expect { resource.memory_quota_mb 255 }.to raise_error Chef::Exceptions::ValidationFailed, "Option memory_quota_mb's value 255 must be at least 256!"
    end

    it "is required" do
      expect { resource.memory_quota_mb }.to raise_error Chef::Exceptions::ValidationFailed
    end
  end

  describe "#resource_name" do
    subject { resource.resource_name }
    it { should == :couchbase_cluster }
  end
end
