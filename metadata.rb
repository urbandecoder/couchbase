name             "couchbase-ng"
maintainer       "Zanui"
maintainer_email "engineering@zanui.com.au"
license          "MIT"
description      "Installs and configures Couchbase Server."
long_description IO.read(File.join(File.dirname(__FILE__), "README.md"))
version          "1.3.2"
source_url       "https://github.com/zanui/chef-couchbase-ng"
issues_url       "https://github.com/zanui/chef-couchbase-ng/issues"

%w{debian ubuntu centos redhat oracle amazon scientific windows}.each do |os|
  supports os
end

%w{apt openssl windows yum}.each do |d|
  depends d
end

recipe "couchbase::server", "Installs couchbase-server"
recipe "couchbase::client", "Installs libcouchbase"
recipe "couchbase::moxi", "Installs moxi-server"
