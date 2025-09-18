require_relative "./../ruby/errors_markdown_generator"

module Fastlane
  module Actions
    class GenerateErrorsMarkdownFromJsonAction < Action
      def self.run(params)
        errors_markdown_generator = ErrorsMarkdownGenerator.new()
        return errors_markdown_generator.generate_markdown(params[:errors_json_path], params[:output_file_path])
      end

      def self.description
        'Generates errors markdown from json. The output of the fastlane scan is fed to this action.'
      end

      def self.available_options
        [
          FastlaneCore::ConfigItem.new(key: :errors_json_path,
                                       description: "errors json file path",
                                       verify_block: proc do |value|
                                          UI.user_error!("No file path given, pass using `errors_json_path: 'path'`") unless (value and not value.empty?)
                                       end),
          FastlaneCore::ConfigItem.new(key: :output_file_path,
                                       description: "file path including the file name where the markdown text needs to be created",
                                       verify_block: proc do |value|
                                          UI.user_error!("No output file path given, pass using `output_file_path: 'path'`") unless (value and not value.empty?)
                                       end)
        ]
      end

      def self.output
        []
      end

      def self.return_value
        "Boolean: true if the markdown file was generated, false otherwise"
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