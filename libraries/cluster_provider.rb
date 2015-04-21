require "chef/provider"
require File.join(File.dirname(__FILE__), "client")
require File.join(File.dirname(__FILE__), "cluster_data")

class Chef
  class Provider
    class CouchbaseCluster < Provider
      include Couchbase::Client
      include Couchbase::ClusterData

      def load_current_resource
        @current_resource = Resource::CouchbaseCluster.new @new_resource.name
        @current_resource.cluster @new_resource.cluster
        @current_resource.hostname @new_resource.hostname
        @current_resource.port @new_resource.port
        @current_resource.exists !!pool_data
        @current_resource.memory_quota_mb pool_memory_quota_mb if @current_resource.exists
      end

      def action_create_if_missing
        unless @current_resource.exists
          post(
            "/pools/#{@new_resource.cluster}",
            { "memoryQuota" => @new_resource.memory_quota_mb },
            @new_resource.hostname,
            @new_resource.port
          )
          @new_resource.updated_by_last_action true
          Chef::Log.info "#{@new_resource} created"
        end
      end

      def action_join
        raise "The cluster has not been created on #{@new_resource.hostname}:#{@new_resource.port}" unless @current_resource.exists
        unless has_joined?
          post(
            "/controller/addNode",
            { 
              "hostname" => node["ipaddress"],
              "user" => @new_resource.username,
              "password" => @new_resource.password
            },
            @new_resource.hostname,
            @new_resource.port
          )
          @new_resource.updated_by_last_action true
          Chef::Log.info "#{@new_resource} joined #{@new_resource.hostname}:#{@new_resource.port}"
        end
      end

      def has_joined?
        pool_data['nodes'].each do |cluster_node|
          if cluster_node['hostname'] == "#{node['ipaddress']}:#{@new_resource.port}"
            return true
          end
        end
        return false
      end
    end
  end
end
