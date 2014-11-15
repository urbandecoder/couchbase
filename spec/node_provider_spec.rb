require "spec_helper"
require "node_resource"
require "node_provider"

describe Chef::Provider::CouchbaseNode do
  let(:provider) { described_class.new(new_resource, double("run_context")) }
  let(:base_uri) { "#{new_resource.username}:#{new_resource.password}@localhost:8091" }
  let(:id) { "self" }
  let(:new_database_path) { "/opt/couchbase/var/lib/couchbase/data" }
  let(:new_index_path) { "/opt/couchbase/var/lib/couchbase/data" }

  let :new_resource do
    double({
      :name => "my node",
      :id => id,
      :username => "Administrator",
      :password => "password",
      :database_path => new_database_path,
      :index_path => new_index_path,
      :updated_by_last_action => nil,
    })
  end

  describe ".ancestors" do
    it { described_class.ancestors.should include Chef::Provider }
  end

  describe "#current_resource" do
    let(:current_resource) { provider.tap(&:load_current_resource).current_resource }

    context "for the local node" do
      before { stub_request(:get, "#{base_uri}/nodes/self").to_return(fixture("nodes_self_mnt.http")) }

      it { current_resource.should be_a_kind_of Chef::Resource::CouchbaseNode }

      it "has the same name as the new resource" do
        current_resource.name.should == new_resource.name
      end

      it "has the same id as the new resource" do
        current_resource.id.should == new_resource.id
      end

      it "populates the database_path" do
        current_resource.database_path.should == "/mnt/couchbase-server/data"
      end
    end

    context "for a remote node" do
      let(:id) { "10.0.1.20" }
      before { stub_request(:get, "#{base_uri}/nodes/10.0.1.20").to_return(fixture("nodes_self_opt.http")) }

      it "has the same name as the new resource" do
        current_resource.name.should == new_resource.name
      end

      it "has the same id as the new resource" do
        current_resource.id.should == new_resource.id
      end

      it "populates the database_path" do
        current_resource.database_path.should == "/opt/couchbase/var/lib/couchbase/data"
      end
    end
  end

  describe "#load_current_resource" do
    context "Couchbase fails the request" do
      let(:id) { "10.0.1.20" }

      before do
        Chef::Log.stub(:error)
        stub_request(:get, "#{base_uri}/nodes/#{id}").to_return(fixture("nodes_id_404.http"))
      end

      it { expect { provider.load_current_resource }.to raise_error(Net::HTTPExceptions) }

      it "logs the error" do
        Chef::Log.should_receive(:error).with(%{"Node is unknown to this cluster."})
        provider.load_current_resource rescue nil
      end
    end
  end

  describe "#action_modify" do
    before { provider.current_resource = current_resource }

    context "database path does not match" do
      shared_examples "modify couchbase node" do
        let(:new_database_path) { "/mnt/couchbase-server/data/#{SecureRandom.hex(8)}" }

        let :current_resource do
          double({
            :name => "my node",
            :id => id,
            :database_path => "/opt/couchbase/var/lib/couchbase/data",
            :index_path => "/opt/couchbase/var/lib/couchbase/data",
          })
        end

        let! :node_request do
          stub_request(:post, "#{base_uri}/nodes/#{id}/controller/settings").with({
            :body => hash_including("path" => new_resource.database_path),
          })
        end

        it "POSTs to the Management REST API to update the database path" do
          provider.action_modify
          node_request.should have_been_made.once
        end

        it "updates the new resource" do
          new_resource.should_receive(:updated_by_last_action).with(true)
          provider.action_modify
        end

        it "logs the modification" do
          Chef::Log.should_receive(:info).with(/modified/)
          provider.action_modify
        end
      end

      context "addressing the node as self" do
        let(:id) { "self" }
        include_examples "modify couchbase node"
      end

      context "addressing the node by hostname" do
        let(:id) { "10.0.1.20" }
        include_examples "modify couchbase node"
      end
    end

    context "database path matches" do
      let :new_resource do
        double({
          :name => "my node",
          :id => "self",
          :database_path => "/opt/couchbase/var/lib/couchbase/data",
          :index_path => "/opt/couchbase/var/lib/couchbase/data",
        })
      end

      let :current_resource do
        double({
          :name => "my node",
          :id => "self",
          :database_path => "/opt/couchbase/var/lib/couchbase/data",
          :index_path => "/opt/couchbase/var/lib/couchbase/data",
        })
      end

      subject { provider.action_modify }
      it_should_behave_like "a no op provider action"
    end

    context "Couchbase fails the request" do
      let(:new_database_path) { "/mnt/couchbase-server/data" }

      let :current_resource do
        double(:name => "my node", :id => "self", :database_path => "/opt/couchbase/var/lib/couchbase/data")
      end

      before do
        Chef::Log.stub(:error)

        stub_request(:post, "#{base_uri}/nodes/self/controller/settings").with({
          :body => hash_including("path" => new_resource.database_path),
        }).to_return(fixture("nodes_self_controller_settings_400.http"))
      end

      it { expect { provider.action_modify }.to raise_error(Net::HTTPExceptions) }

      it "logs the error" do
        Chef::Log.should_receive(:error).with(%{["Could not set the storage path. It must be a directory writable by 'couchbase' user."]})
        provider.action_modify rescue nil
      end
    end
  end
end
