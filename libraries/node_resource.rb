require "chef/resource"
require File.join(File.dirname(__FILE__), "credentials_attributes")

class Chef
  class Resource
    class CouchbaseNode < Resource
      include Couchbase::CredentialsAttributes

      def id(arg=nil)
        set_or_return(:id, arg, :kind_of => String, :name_attribute => true)
      end

      def database_path(arg=nil)
        set_or_return(:database_path, arg, :kind_of => String, :default => "/opt/couchbase/var/lib/couchbase/data")
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
