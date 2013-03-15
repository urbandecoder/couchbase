require "chef/resource"
require File.join(File.dirname(__FILE__), "credentials_attributes")

class Chef
  class Resource
    class CouchbaseCluster < Resource
      include Couchbase::CredentialsAttributes

      def cluster(arg=nil)
        set_or_return(:cluster, arg, :kind_of => String, :name_attribute => true)
      end

      def exists(arg=nil)
        set_or_return(:exists, arg, :kind_of => [TrueClass, FalseClass], :required => true)
      end

      def memory_quota_mb(arg=nil)
        set_or_return(:memory_quota_mb, arg, :kind_of => Integer, :required => true, :callbacks => {
        	"must be at least 256" => lambda { |quota| quota >= 256 }
      	})
      end

      def initialize(*)
        super
        @action = :create_if_missing
        @allowed_actions.push :create_if_missing
        @resource_name = :couchbase_cluster
      end
    end
  end
end
