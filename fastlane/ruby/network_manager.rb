require 'json'
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

    # Updates this user's note that starts with marker, or adds a new note.
    # With update_only, it adds nothing when no such note exists.
    def upsert(mark_down_text, marker, update_only = false)
        note_id = find_note_id(marker)
        if note_id
            send_note(Net::HTTP::Put, "#{@merge_request_url}/#{note_id}", mark_down_text)
        elsif update_only
            puts "No earlier note starts with #{marker}. Nothing to update."
        else
            send_note(Net::HTTP::Post, @merge_request_url, mark_down_text)
        end
    end

    private

    # Only a note this user wrote and that starts with marker counts. A reviewer
    # may quote the marker, and the token can edit other users' notes.
    def find_note_id(marker)
        user_id = get_json("#{@merge_request_url[%r{\A.*/api/v4}]}/user")['id']
        page = 1
        loop do
            notes = get_json("#{@merge_request_url}?sort=desc&order_by=updated_at&per_page=100&page=#{page}")
            note = notes.find { |item| item.dig('author', 'id') == user_id && item['body'].to_s.start_with?(marker) }
            return note['id'] if note
            return nil if notes.length < 100
            page += 1
        end
    end

    def get_json(url_string)
        url = URI.parse(url_string)
        response = make_http(url).request(Net::HTTP::Get.new(url.request_uri, { 'PRIVATE-TOKEN' => @token }))
        check_response(response)
        JSON.parse(response.body)
    end

    def send_note(request_class, url_string, text)
        url = URI.parse(url_string)
        request = request_class.new(url.path, { 'PRIVATE-TOKEN' => @token })
        request.set_form({ 'body' => text }, 'multipart/form-data')
        response = make_http(url).request(request)
        puts "Response Code: #{response.code}"
        check_response(response)
    end

    def make_http(url)
        http = Net::HTTP.new(url.host, url.port)
        http.use_ssl = url.scheme == 'https'
        http
    end

    # The caller decides what a failed request means, so raise instead of only printing.
    def check_response(response)
        return if response.code.to_i.between?(200, 299)
        raise "GitLab request failed with #{response.code}: #{response.body}"
    end
end