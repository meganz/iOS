require 'net/http'
require 'uri'

class NetworkManager 
    def initialize(token, merge_request_url)
        @token = token
        @merge_request_url = merge_request_url
    end

    def post(mark_down_text)
        url = URI.parse(@merge_request_url)
        
        http = Net::HTTP.new(url.host, url.port)
        http.use_ssl = url.scheme == 'https'

        headers = {
            'PRIVATE-TOKEN' => @token,
            'Content-Type' => 'multipart/form-data'
        }

        data = {
            'body' => "#{mark_down_text}"
        }

        request = Net::HTTP::Post.new(url.path, headers)
        request.set_form(data, 'multipart/form-data')

        response = http.request(request)

        # You can check the response code and response body here if needed
        puts "Response Code: #{response.code}"
        puts "Response Body: #{response.body}"
    end
end