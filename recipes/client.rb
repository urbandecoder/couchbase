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
  apt_repository "couchbase" do
    uri "http://packages.couchbase.com/ubuntu"
    distribution node['lsb']['codename']
    components ["#{node['lsb']['codename']}/main"]
    key "http://packages.couchbase.com/ubuntu/couchbase.key"
  end

  %w{libcouchbase2 libcouchbase-dev}.each do |p|
    package p do
      action :install
    end
  end

when "rhel"
  yum_repository "couchbase-rpm.key" do
    url "http://packages.couchbase.com/rpm/couchbase-rpm.key"
    action :add
  end

  case
  when node['platform_version'].to_f >= 5.0 && node['platform_version'].to_f < 6.0
    osver = '5.5'
  when node['platform_version'].to_f >= 6.0
    osver = '6.2'
  else
    Chef::Log.error("Platform version #{node['platform_version']} is unsupported by Couchbase C library")
  end

  yum_repository "couchbase" do
    name "couchbase"
    description "Couchbase package repository"
    url "http://packages.couchbase.com/rpm/#{osver}/$basearch/"
    action :add
  end

  %w{libcouchbase2 libcouchbase-devel}.each do |p|
    package p do
      action :install
    end
  end

else
  Chef::Log.error("Platform family #{node['platform_family']} is unsupported by Couchbase C library")
end
