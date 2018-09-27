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

module CouchbaseHelper
  extend Chef::Mixin::ShellOut

  def self.service_listening?(port)
    netstat_command = "netstat -lnt"
    cmd = shell_out!(netstat_command)
    Chef::Log.debug("`#{netstat_command}` returned: \n\n #{cmd.stdout}")
    cmd.stdout.each_line.select do |l|
      l.split[3] =~ /#{port}/
    end.any?
  end

  def self.endpoint_responding?(url)
    response = Net::HTTP.get_response(url, nil)
    case response
    when Net::HTTPSuccess, Net::HTTPRedirection, Net::HTTPForbidden
      Chef::Log.debug("GET to #{url} successful")
      return true
    else
      Chef::Log.debug("GET to #{url} returned #{response.body if response.response_body_permitted?} / #{response}")
      return false
    end
  rescue EOFError, Errno::ECONNREFUSED
    return false
  end
end
