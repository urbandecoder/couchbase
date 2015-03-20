require "chef/provider"
require File.join(File.dirname(__FILE__), "client")
require File.join(File.dirname(__FILE__), "cluster_data")

class Chef
  class Provider
    class CouchbaseBucket < Provider
      include Couchbase::Client
      include Couchbase::ClusterData

      def load_current_resource
        @current_resource = Resource::CouchbaseBucket.new @new_resource.name
        @current_resource.bucket @new_resource.bucket
        @current_resource.cluster @new_resource.cluster
        @current_resource.exists !!bucket_data

        if @current_resource.exists
          @current_resource.type bucket_type
          @current_resource.memory_quota_mb bucket_memory_quota_mb
          @current_resource.replicas bucket_replicas
        end
      end

      def action_create
        if !@current_resource.exists
          create_bucket
        elsif @current_resource.memory_quota_mb != new_memory_quota_mb
          modify_bucket
        end
      end

      private

      def create_bucket
        post "/pools/#{@new_resource.cluster}/buckets", create_params
        new_resource.updated_by_last_action true
        Chef::Log.info "#{new_resource} created"
      end

      def modify_bucket
        post "/pools/#{@new_resource.cluster}/buckets/#{@new_resource.bucket}", modify_params
        new_resource.updated_by_last_action true
        Chef::Log.info "#{new_resource} memory_quota_mb changed to #{new_memory_quota_mb}"
      end

      def create_params
        {
          "authType" => "sasl",
          "saslPassword" =>  new_resource.saslpassword,
          "bucketType" => new_api_type,
          "name" => new_resource.bucket,
          "ramQuotaMB" => new_memory_quota_mb,
          "replicaNumber" => new_resource.replicas || 0,
          "replicaIndex" => new_resource.replica_index,
          "flushEnabled" => new_resource.flush_enabled
        }
      end

      def new_api_type
        new_resource.type == "couchbase" ? "membase" : new_resource.type
      end

      def modify_params
        {
          "ramQuotaMB" => new_memory_quota_mb,
        }
      end

      def new_memory_quota_mb
        new_resource.memory_quota_mb || (new_resource.memory_quota_percent * pool_memory_quota_mb).to_i
      end

      def bucket_memory_quota_mb
        (bucket_data["quota"]["rawRAM"] / 1024 / 1024).to_i
      end

      def bucket_replicas
        bucket_data["replicaNumber"]
      end

      def bucket_type
        bucket_data["bucketType"] == "membase" ? "couchbase" : bucket_data["bucketType"]
      end

      def bucket_data
        return @bucket_data if instance_variable_defined? "@bucket_data"

        @bucket_data ||= begin
          response = get "/pools/#{@new_resource.cluster}/buckets/#{@new_resource.bucket}"
          response.error! unless response.kind_of?(Net::HTTPSuccess) || response.kind_of?(Net::HTTPNotFound)
          JSONCompat.from_json response.body if response.kind_of? Net::HTTPSuccess
        end
      end
    end
  end
end
