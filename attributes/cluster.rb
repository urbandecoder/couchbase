#
# Cookbook Name:: couchbase
# Attributes:: cluster
#
# Author:: Chris Armstrong (<chris@chrisarmstrong.me>)
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

include_attribute "couchbase::server"

default['couchbase']['cluster'] = Chef::DataBagItem.load('couchbase', 'cluster')[node.chef_environment] rescue {}

default['couchbase']['cluster']['name'] = "default"# unless node['couchbase']['cluster']['name']

# If this server is a member of a cluster, the cluster settings should override some server settings
override['couchbase']['server']['username'] = node['couchbase']['cluster']['username'] if node['couchbase']['cluster']['username']
override['couchbase']['server']['password'] = node['couchbase']['cluster']['password'] if node['couchbase']['cluster']['password']
override['couchbase']['server']['memory_quota_mb'] = node['couchbase']['cluster']['memory_quota_mb'] if node['couchbase']['cluster']['memory_quota_mb']
