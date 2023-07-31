require_relative "./../ruby/network_manager"

module Fastlane
  module Actions
    class PostMarkdownToMrAction < Action
      def self.run(params)
        markdown_data = File.read(params[:markdown_path])
        network_manager = NetworkManager.new(params[:token], params[:merge_request_url])
        network_manager.post(markdown_data)
      end

      def self.description
        'Reads the markdown file and posts as a comment'
      end

      def self.available_options
        [
          FastlaneCore::ConfigItem.new(key: :merge_request_url,
                                       description: "merge_request_url where the comment should be posted",
                                       verify_block: proc do |value|
                                          UI.user_error!("No merge_request_url provided, pass using `mr: 'mr number'`") unless (value and not value.empty?)
                                       end),
          FastlaneCore::ConfigItem.new(key: :token,
                                       description: "token for posting the message",
                                       verify_block: proc do |value|
                                          UI.user_error!("No token given, pass using `token: 'token'`") unless (value and not value.empty?)
                                       end),
          FastlaneCore::ConfigItem.new(key: :markdown_path,
                                       description: "markdown file path to parse",
                                       verify_block: proc do |value|
                                          UI.user_error!("No markdown file path given, pass using `markdown_path: 'path'`") unless (value and not value.empty?)
                                       end)
        ]
      end

      def self.authors
        ['MEGA']
      end

      def self.is_supported?(platform)
        platform == :ios
      end
    end
  end
end
