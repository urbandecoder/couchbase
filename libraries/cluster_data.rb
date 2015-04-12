module Couchbase
  module ClusterData
    private

    def pool_memory_quota_mb
      (pool_data["storageTotals"]["ram"]["quotaTotal"] / pool_data["nodes"].size / 1024 / 1024).to_i
    end

    def pool_data
      return @pool_data if instance_variable_defined? "@pool_data"

      @pool_data ||= begin
        response = get(
          "/pools/#{@new_resource.cluster}",
          @new_resource.hostname,
          @new_resource.port
        )
        response.error! unless response.kind_of?(Net::HTTPSuccess) || response.kind_of?(Net::HTTPNotFound)
        Chef::JSONCompat.from_json response.body if response.kind_of? Net::HTTPSuccess
      end
    end
  end
end
