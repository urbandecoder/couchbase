#
# Cookbook Name:: couchbase
# Recipe:: client
#
# Copyright 2012, getaroom
#
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:
#
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
# WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
#

case node['platform_family']
when "debian"
  remote_file "#{Chef::Config[:file_cache_path]}/couchbase-release-1.0-0-amd64.deb" do
    source "http://packages.couchbase.com/releases/couchbase-release/couchbase-release-1.0-0-amd64.deb"
    action :create_if_missing
  end

  dpkg_package "couchbase-release" do
    source "#{Chef::Config[:file_cache_path]}/couchbase-release-1.0-0-amd64.deb"
    action :install
  end

  %w{libcouchbase2 libcouchbase-dev}.each do |p|
    package p do
      action :install
    end
  end

when "rhel"
  case
  when node['platform_version'].to_f >= 5.0 && node['platform_version'].to_f < 6.0
    osver = '5.5'
  when node['platform_version'].to_f >= 6.0
    osver = '6.2'
  else
    Chef::Log.error("Platform version #{node['platform_version']} is unsupported by Couchbase C library")
  end

  remote_file "#{Chef::Config[:file_cache_path]}/couchbase-release-1.0-0-x86_64.rpm" do
    source "http://packages.couchbase.com/releases/couchbase-release/couchbase-release-1.0-0-x86_64.rpm"
    action :create_if_missing
  end

  rpm_package "couchbase-release" do
    source "#{Chef::Config[:file_cache_path]}/couchbase-release-1.0-0-x86_64.rpm"
    action :install
  end

  %w{libcouchbase2 libcouchbase-devel}.each do |p|
    package p do
      action :install
    end
  end

else
  Chef::Log.error("Platform family #{node['platform_family']} is unsupported by Couchbase C library")
end
