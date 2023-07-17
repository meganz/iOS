require_relative './../ruby/unzip_manager'

module Fastlane
  module Actions
    class UnzipContentsAction < Action
      def self.run(params)
        unzip_manager = UnzipManager.new
        unzip_manager.unzip_contents params[:zip_file_path], params[:intermediate_folder_path], params[:destination_folder_path], params[:use_cache]
      end

      def self.description
        "unzip file"
      end

      def self.details
        "Unzips the content into the intermediate folder and then copies it to the final destination"
      end

      def self.available_options
        [
          FastlaneCore::ConfigItem.new(key: :zip_file_path,
                                       description: "zip file path to unzip", 
                                       verify_block: proc do |value|
                                          UI.user_error!("No zip file path given, pass using `zip_file_path: 'path'`") unless (value and not value.empty?)
                                       end),
          FastlaneCore::ConfigItem.new(key: :intermediate_folder_path,
                                       description: "intermediate folder path where to unzip the contents",
                                       verify_block: proc do |value|
                                          UI.user_error!("No intermediate folder path given, pass using `intermediate_folder: 'path'`") unless (value and not value.empty?)
                                       end),
          FastlaneCore::ConfigItem.new(key: :destination_folder_path,
                                       description: "destination folder path where to place the contents of zip file",
                                       verify_block: proc do |value|
                                          UI.user_error!("No destination folder path given, pass using `intermediate_folder: 'path'`") unless (value and not value.empty?)
                                       end),
          FastlaneCore::ConfigItem.new(key: :use_cache,
                                       description: "use the cache (intermediate_folder_path) provided and don't overwrite when true",
                                       optional: true,
                                       default_value: true,
                                       type: Boolean)
        ]
      end

      def self.output
       []
      end

      def self.authors
        ["MEGA"]
      end

      def self.is_supported?(platform)
        platform == :ios
      end
    end
  end
end
