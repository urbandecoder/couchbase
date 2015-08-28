name             "couchbase"
maintainer       "Julian C. Dunn"
maintainer_email "jdunn@chef.io"
license          "MIT"
description      "Installs and configures Couchbase Server."
long_description IO.read(File.join(File.dirname(__FILE__), "README.md"))
version          "1.3.2"

%w{debian ubuntu centos redhat oracle amazon scientific windows}.each do |os|
  supports os
end

%w{apt openssl windows yum}.each do |d|
  depends d
end

recipe "couchbase::server", "Installs couchbase-server"
recipe "couchbase::client", "Installs libcouchbase"
recipe "couchbase::moxi", "Installs moxi-server"
