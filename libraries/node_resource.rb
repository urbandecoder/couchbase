require 'chef/resource'
require_relative 'credentials_attributes'
require_relative 'client'

class Chef
  class Resource
    class CouchbaseNode < Chef::Resource
      include Couchbase::CredentialsAttributes
      include Couchbase::Client
      provides :couchbase_node

      def id(arg=nil)
        set_or_return(:id, arg, :kind_of => String, :name_attribute => true)
      end

      def database_path(arg=nil)
        set_or_return(:database_path, arg, :kind_of => String, :default => "/opt/couchbase/var/lib/couchbase/data")
      end

      def index_path(arg=nil)
        set_or_return(:index_path, arg, :kind_of => String, :default => "/opt/couchbase/var/lib/couchbase/data")
      end

      def initialize(*)
        super
        @action = :modify
        @allowed_actions.push(:modify)
        @resource_name = :couchbase_node
      end
    end
  end
end
