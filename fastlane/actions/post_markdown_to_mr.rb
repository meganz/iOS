require_relative "./../ruby/network_manager"

module Fastlane
  module Actions
    class PostMarkdownToMrAction < Action
      def self.run(params)
        markdown_data = File.read(params[:markdown_path])
        network_manager = NetworkManager.new(params[:token], params[:merge_request_url])
        if params[:marker]
          network_manager.upsert(markdown_data, params[:marker], params[:update_only])
        else
          network_manager.post(markdown_data)
        end
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
                                       end),
          FastlaneCore::ConfigItem.new(key: :marker,
                                       description: "text at the start of the comment; this user's comment that starts with it is updated instead of adding a new one",
                                       optional: true),
          FastlaneCore::ConfigItem.new(key: :update_only,
                                       description: "with marker: update an earlier comment, never add a new one",
                                       type: Fastlane::Boolean,
                                       optional: true,
                                       default_value: false)
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
