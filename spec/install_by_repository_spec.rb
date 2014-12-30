require 'spec_helper'

describe 'debian::couchbase::server' do
  let(:chef_run) do
    runner = ChefSpec::Runner.new(
                                   platform: 'debian',
                                   version: '7.4'
                                 ) do |node|
      node.set['couchbase']['server']['password'] = 'password'
    end
    runner.converge('couchbase::server')
  end
  before do
    stub_command("grep '{error_logger_mf_dir, \"/opt/couchbase/var/lib/couchbase/logs\"}.' /opt/couchbase/etc/couchbase/static_config").and_return('OK')
  end

  it "Do not use repository install" do
    expect(chef_run).to_not install_package('couchbase-server')
  end

  context "Attribute use_repository true" do
    let(:chef_run) do
      runner = ChefSpec::Runner.new(
                                     platform: 'debian',
                                     version: '7.4'
                                   ) do |node|
        node.set['couchbase']['server']['password'] = 'password'
        node.set['couchbase']['server']['use_repository'] = true
      end
      runner.converge('couchbase::server')
    end

    it "Use apt repository install" do
      expect(chef_run).to install_package('couchbase-server')
    end
  end
end
