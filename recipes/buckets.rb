#
# Cookbook Name:: couchbase
# Recipe:: buckets
#
# Author:: Enrico Stahn (<mail@enricostahn.com>)
# Copyright 2013, Zanui
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

node['couchbase']['buckets'].each do |bucket_name, bucket_config|
  bucket_config = {} if bucket_config.nil? or [TrueClass, FalseClass].include?(bucket_config.class)
  
  couchbase_bucket bucket_name do
    bucket bucket_name
    
    type         bucket_config['type'] if bucket_config.has_key?('type')
    replicas     bucket_config['replicas'] if bucket_config.has_key?('replicas')
    cluster      bucket_config['cluster'] if bucket_config.has_key?('cluster')
    saslpassword bucket_config['saslpassword'] if bucket_config.has_key?('saslpassword')
    
    memory_quota_mb      bucket_config['memory_quota_mb'] if bucket_config.has_key?('memory_quota_mb')
    memory_quota_percent bucket_config['memory_quota_percent'] if bucket_config.has_key?('memory_quota_percent')
    
    memory_quota_mb 100 unless bucket_config.has_key?('memory_quota_mb') or bucket_config.has_key?('memory_quota_percent')

    replica_index   bucket_config['replica_index'] if bucket_config.has_key?('replica_index')
    flush_enabled   bucket_config['flush_enabled'] if bucket_config.has_key?('flush_enabled')
    
    username node['couchbase']['server']['username']
    password node['couchbase']['server']['password']
  end
end
