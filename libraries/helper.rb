#
# Cookbook Name:: couchbase
# Library:: helper
#
# Author:: Seth Chisamore <schisamo@opscode.com>
# Author:: Julian Dunn <jdunn@opscode.com>
#
# Copyright 2013, Opscode, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

# Shamelessly stolen from Opscode's jenkins cookbook. Works for now.

require 'chef/mixin/shell_out'
require 'chef/rest'

module CouchbaseHelper
  extend Chef::Mixin::ShellOut

  def self.endpoint_responding?(url)
    # XXX Should probably not use Chef::REST for this. Chef::REST only
    # Accepts application/json; why not just use Net::HTTP directly?
    response = Chef::REST::RESTRequest.new(:GET, url, nil).call
    if response.kind_of?(Net::HTTPSuccess) ||
          response.kind_of?(Net::HTTPRedirection) ||
          response.kind_of?(Net::HTTPForbidden)
      Chef::Log.debug("GET to #{url} successful")
      return true
    else
      Chef::Log.debug("GET to #{url} returned #{response.code} / #{response.class}")
      return false
    end
  rescue EOFError, Errno::ECONNREFUSED
    return false
  end
end
