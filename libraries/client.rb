module Couchbase
  module Client
    private

    def uri_from_path(host, port, path)
      URI.parse "http://#{@new_resource.username}:#{@new_resource.password}@#{host}:#{port}#{path}"
    end

    def post(path, params, host = "localhost", port = "8091")
      response = Net::HTTP.post_form(uri_from_path(host, port, path), params)
      Chef::Log.error response.body unless response.kind_of? Net::HTTPSuccess
      response.value
      response
    end

    def get(path, host = "localhost", port = "8091")
      uri = uri_from_path(host, port, path)

      response = Net::HTTP.start uri.host, uri.port do |http|
        request = Net::HTTP::Get.new uri.path
        request.basic_auth uri.user, uri.password
        http.request request
      end
    end
  end
end
