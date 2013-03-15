require "chef/resource"
require File.join(File.dirname(__FILE__), "credentials_attributes")

class Chef
  class Resource
    class CouchbaseSettings < Resource
      include Couchbase::CredentialsAttributes

      def group(arg=nil)
        set_or_return(:group, arg, :kind_of => String, :name_attribute => true)
      end

      def settings(arg=nil)
        set_or_return(:settings, arg, :kind_of => Hash, :required => true)
      end

      def initialize(*)
        super
        @action = :modify
        @allowed_actions.push :modify
        @resource_name = :couchbase_settings
      end
    end
  end
end
