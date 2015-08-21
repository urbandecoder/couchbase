require "spec_helper"
require "settings_resource"
require "settings_provider"

describe Chef::Provider::CouchbaseSettings do
  let(:provider) { described_class.new(new_resource, double("run_context")) }
  let(:new_settings) { {} }
  let(:base_uri) { "#{new_resource.username}:#{new_resource.password}@localhost:8091" }

  let :new_resource do
    double({
      :name => "my settings",
      :group => group,
      :username => "Administrator",
      :password => "password",
      :settings => new_settings,
      :updated_by_last_action => nil,
    })
  end

  describe ".ancestors" do
    it { described_class.ancestors.should include Chef::Provider }
  end

  describe "#current_resource" do
    let(:current_resource) { provider.tap(&:load_current_resource).current_resource }

    context "web settings" do
      let(:group) { "web" }

      before do
        stub_request(:get, "#{base_uri}/settings/web").
        to_return(fixture("settings_web_populated.http"))
      end

      it { current_resource.should be_a_kind_of Chef::Resource::CouchbaseSettings }

      it "has the same name as the new resource" do
        current_resource.name.should == new_resource.name
      end

      it "has the same group as the new resource" do
        current_resource.group.should == new_resource.group
      end

      it "populates the settings" do
        current_resource.settings.should == {
          "username" => "Administrator",
          "password" => "password",
          "port" => 8091,
        }
      end
    end

    context "autoFailover settings" do
      let(:group) { "autoFailover" }

      before do
        stub_request(:get, "#{base_uri}/settings/autoFailover").
        to_return(fixture("settings_auto_failover_disabled.http"))
      end

      it { current_resource.should be_a_kind_of Chef::Resource::CouchbaseSettings }

      it "has the same name as the new resource" do
        current_resource.name.should == new_resource.name
      end

      it "has the same group as the new resource" do
        current_resource.group.should == new_resource.group
      end

      it "populates the settings" do
        current_resource.settings.should == {
          "enabled" => false,
          "timeout" => 30,
          "count" => 0,
        }
      end
    end
  end

  describe "#load_current_resource" do
    context "request fails due to invalid credentials" do
      let(:group) { "web" }
      before { stub_request(:get, "#{base_uri}/settings/web").to_return(fixture("settings_web_401.http")) }

      it { expect { provider.load_current_resource }.to raise_error(Net::HTTPExceptions) }

      it "does not log the empty error" do
        Chef::Log.should_not_receive(:error)
        # provider.load_current_resource rescue nil
      end
    end

    context "request fails due to unknown settings group" do
      let(:group) { "unknown" }

      before do
        Chef::Log.stub(:error)
        stub_request(:get, "#{base_uri}/settings/unknown").to_return(fixture("settings_unknown_404.http"))
      end

      it { expect { provider.load_current_resource }.to raise_error(Net::HTTPExceptions) }

      it "logs the error" do
        Chef::Log.should_receive(:error).with(%{Not found.})
        provider.load_current_resource rescue nil
      end
    end
  end

  describe "#action_modify" do
    before { provider.current_resource = current_resource }

    let :current_resource do
      double({
        :name => "current resource",
        :group => group,
        :username => "Administrator",
        :password => "password",
        :settings => current_settings,
      })
    end

    context "stats" do
      let(:group) { "stats" }

      context "the settings do not match" do
        let(:new_settings) { { "sendStats" => true } }
        let(:current_settings) { { "sendStats" => false } }

        let! :stats_request do
          stub_request(:post, "#{base_uri}/settings/#{group}").with({
            :body => hash_including("sendStats" => new_resource.settings["sendStats"].to_s),
          })
        end

        it "updates the new resource" do
          new_resource.should_receive(:updated_by_last_action).with(true)
          provider.action_modify
        end

        it "logs the modification" do
          Chef::Log.should_receive(:info).with(/modified/)
          provider.action_modify
        end

        it "POSTs to the Management REST API to update the sendStats value" do
          provider.action_modify
          stats_request.should have_been_made.once
        end
      end

      context "the settings match" do
        let(:new_settings) { { "sendStats" => true } }
        let(:current_settings) { new_settings }
        subject { provider.action_modify }
        it_should_behave_like "a no op provider action"
      end

      context "the settings match with symbols as keys in the new resource" do
        let(:new_settings) { { :sendStats => true } }
        let(:current_settings) { { "sendStats" => true } }
        subject { provider.action_modify }
        # it_should_behave_like "a no op provider action"
      end

      context "Couchbase fails the request" do
        let(:new_settings) { { "sendStats" => 42 } }
        let(:current_settings) { { "sendStats" => false } }
        before { Chef::Log.stub(:error) }

        let! :stats_request do
          stub_request(:post, "#{base_uri}/settings/#{group}").with({
            :body => hash_including("sendStats" => new_resource.settings["sendStats"].to_s),
          }).to_return(fixture("settings_stats_400.http"))
        end

        # it { expect { provider.action_modify }.to raise_error(Net::HTTPExceptions) }

        it "logs the error" do
          Chef::Log.should_receive(:error).with(%{The value of "sendStats" must be true or false.})
          provider.action_modify rescue nil
        end
      end

      context "cannot contact the Couchbase server" do
        let(:new_settings) { { "sendStats" => true } }
        let(:current_settings) { { "sendStats" => false } }

        let! :stats_request do
          stub_request(:any, "#{base_uri}/settings/#{group}").to_raise(SocketError)
        end

        it { expect { provider.action_modify }.to raise_error(SocketError) }
      end
    end

    context "web" do
      let(:group) { "web" }

      context "the settings do not match" do
        let(:new_settings) { { "username" => "Administrator", "password" => "password", "port" => 8091 } }
        let(:current_settings) { { "username" => "Administrator", "password" => nil, "port" => 8091 } }

        let! :web_request do
          stub_request(:post, "#{base_uri}/settings/#{group}").with({
            :body => hash_including({
              "password" => new_resource.settings["password"],
              "port" => new_resource.settings["port"].to_s,
            }),
          })
        end

        it "updates the new resource" do
          new_resource.should_receive(:updated_by_last_action).with(true)
          provider.action_modify
        end

        it "logs the modification" do
          Chef::Log.should_receive(:info).with(/modified/)
          provider.action_modify
        end

        it "POSTs to the Management REST API to update the settings" do
          provider.action_modify
          web_request.should have_been_made.once
        end
      end

      context "the settings match" do
        let(:new_settings) { { "username" => "Administrator", "password" => "password", "port" => 8091 } }
        let(:current_settings) { new_settings }
        subject { provider.action_modify }
        it_should_behave_like "a no op provider action"
      end
    end

    context "autoFailover" do
      let(:group) { "autoFailover" }

      context "the settings match" do
        let(:new_settings) { { "enabled" => true, "timeout" => 30 } }
        let(:current_settings) { new_settings.merge("count" => 0) }
        subject { provider.action_modify }
        # it_should_behave_like "a no op provider action"
      end

      context "the subset of settings managed by Chef match" do
        let(:new_settings) { { "enabled" => true } }
        let(:current_settings) { new_settings.merge("timeout" => 30, "count" => 0) }
        subject { provider.action_modify }
        # it_should_behave_like "a no op provider action"
      end
    end
  end
end
