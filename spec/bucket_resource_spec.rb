require "spec_helper"
require "bucket_resource"

describe Chef::Resource::CouchbaseBucket do
  let(:resource) { described_class.new "default" }
  it_should_behave_like "a resource with couchbase credentials"

  describe ".ancestors" do
    it { described_class.ancestors.should include Chef::Resource }
  end

  describe "#action" do
    it "defaults to :create" do
      resource.action.should == :create
    end
  end

  describe "#allowed_actions" do
    subject { resource.allowed_actions }
    it { should include :create }
    it { should include :nothing }
  end

  describe "#bucket" do
    it "can be assigned a String" do
      resource.bucket "default"
      resource.bucket.should == "default"
    end

    it "cannot be assigned an Integer" do
      expect { resource.bucket 42 }.to raise_error Chef::Exceptions::ValidationFailed
    end

    it "defaults to the name attribute" do
      resource.bucket.should == resource.name
    end
  end

  describe "#cluster" do
    it "can be assigned a String" do
      resource.cluster "pillowfight"
      resource.cluster.should == "pillowfight"
    end

    it "cannot be assigned an Integer" do
      expect { resource.cluster 42 }.to raise_error Chef::Exceptions::ValidationFailed
    end

    it "defaults to 'default'" do
      resource.cluster.should == "default"
    end
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

    it "can be assigned 100" do
      resource.memory_quota_mb 100
      resource.memory_quota_mb.should == 100
    end

    it "cannot be assigned 99" do
      expect { resource.memory_quota_mb 99 }.to raise_error Chef::Exceptions::ValidationFailed, "Option memory_quota_mb's value 99 must be at least 100!"
    end

    it "cannot be assigned a negative number" do
      expect { resource.memory_quota_mb -1 }.to raise_error Chef::Exceptions::ValidationFailed, "Option memory_quota_mb's value -1 must be at least 100!"
    end
  end

  describe "#memory_quota_percent" do
    it "can be assigned 1.0" do
      resource.memory_quota_percent 1.0
      resource.memory_quota_percent.should == 1.0
    end

    it "can be assigned 1" do
      resource.memory_quota_percent 1
      resource.memory_quota_percent.should == 1
    end

    it "cannot be assigned a String" do
      expect { resource.memory_quota_percent "one" }.to raise_error Chef::Exceptions::ValidationFailed
    end

    it "cannot be assigned 0.0" do
      expect { resource.memory_quota_percent 0.0 }.to raise_error Chef::Exceptions::ValidationFailed,
      "Option memory_quota_percent's value 0.0 must be a positive number!"
    end

    it "cannot be assigned a numer greater than 1.0" do
      number = 1.0 + rand
      expect { resource.memory_quota_percent number }.to raise_error Chef::Exceptions::ValidationFailed,
      "Option memory_quota_percent's value #{number} must be less than or equal to 1.0!"
    end

    it "cannot be assigned a negative number" do
      negative_number = -rand
      expect { resource.memory_quota_percent negative_number }.to raise_error Chef::Exceptions::ValidationFailed,
      "Option memory_quota_percent's value #{negative_number} must be a positive number!"
    end
  end
    describe "#proxyport" do
    
    it "can be assigned 11217" do
      resource.proxyport 11217
      resource.proxyport.should == 11217
    end

    it "cannot be assigned a String" do
      expect { resource.proxyport "one" }.to raise_error Chef::Exceptions::ValidationFailed
    end

    it "cannot be assigned a Float" do
      expect { resource.proxyport 11215.5 }.to raise_error Chef::Exceptions::ValidationFailed
    end

    it "cannot be assigned false" do
      expect { resource.proxyport false }.to raise_error Chef::Exceptions::ValidationFailed
    end

    it "cannot be assigned true" do
      expect { resource.proxyport true }.to raise_error Chef::Exceptions::ValidationFailed
    end

   #it "cannot be assigned a negative number" do
     #negative_number = -rand
      #expect { resource.proxyport negative_number }.to raise_error Chef::Exceptions::ValidationFailed, "Option proxyport's value -3 must be a non-negative integer!"
    #end
  end

  describe "#replicas" do
    it "can be assigned 1" do
      resource.replicas 1
      resource.replicas.should == 1
    end

    it "cannot be assigned a String" do
      expect { resource.replicas "one" }.to raise_error Chef::Exceptions::ValidationFailed
    end

    it "cannot be assgned a Float" do
      expect { resource.replicas 1.5 }.to raise_error Chef::Exceptions::ValidationFailed
    end

    it "can be assigned false" do
      resource.replicas false
      resource.replicas.should be false
    end

    it "cannot be assigned a negative number" do
      expect { resource.replicas -3 }.to raise_error Chef::Exceptions::ValidationFailed, "Option replicas's value -3 must be a non-negative integer!"
    end

    it "cannot be assigned -1" do
      expect { resource.replicas -1 }.to raise_error Chef::Exceptions::ValidationFailed, "Option replicas's value -1 must be a non-negative integer!"
    end

    it "can be assigned 0" do
      resource.replicas 0
      resource.replicas.should == 0
    end

    it "defaults to 1" do
      resource.replicas.should == 1
    end
  end

  describe "#resource_name" do
    subject { resource.resource_name }
    it { should == :couchbase_bucket }
  end

  describe "#type" do
    it "can be assigned memcached" do
      resource.type "memcached"
      resource.type.should == "memcached"
    end

    it "cannot be assigned an Integer" do
      expect { resource.type 42 }.to raise_error Chef::Exceptions::ValidationFailed
    end

    it "defaults to couchbase" do
      resource.type.should == "couchbase"
    end

    it "cannot be assigned memcache" do
      expect { resource.type "memcache" }.to raise_error Chef::Exceptions::ValidationFailed, "Option type's value memcache must be either couchbase or memcached!"
    end
  end
end
