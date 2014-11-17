module Couchbase
  module Client
    private

    def uri_from_path(path)
      escaped_uri = URI.escape "http://localhost:8091#{path}"
      URI.parse escaped_uri
    end

    def post(path, params)
      uri = uri_from_path path

      req = Net::HTTP::Post.new(uri.path)
      req.basic_auth @new_resource.username, @new_resource.password
      req.set_form_data(params)
      response = Net::HTTP.new(uri.host, uri.port).start {|http| http.request(req) }
      Chef::Log.error response.body unless response.kind_of? Net::HTTPSuccess
      response.value
      response
    end

    def get(path)
      uri = uri_from_path path

      response = Net::HTTP.start uri.host, uri.port do |http|
        request = Net::HTTP::Get.new uri.path
        request.basic_auth @new_resource.username, @new_resource.password
        http.request request
      end
    end
  end
end
