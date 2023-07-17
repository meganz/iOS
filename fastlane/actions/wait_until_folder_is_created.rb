module Fastlane
  module Actions
    class WaitUntilFolderIsCreatedAction < Action
      def self.run(params)
        folder_path, timeout = params[:folder_path], params[:timeout]
        until timeout < 0 or Dir.exist? folder_path
            UI.important "folder #{folder_path} does not exists"
            UI.important "waiting for 5 seconds before rechecking again"
            timeout -= 5
            sleep 5
        end
      end


      def self.description
        "Check if the folder exists. Also, wait until timeout before throwing error"
      end

      def self.details
        "You can use this action to see if the folder is created. This action waits until timeout to see if the folder is created"
      end

      def self.available_options
        [
          FastlaneCore::ConfigItem.new(key: :folder_path,
                                       description: "relative folder path to be checked if created",
                                       verify_block: proc do |value|
                                          UI.user_error!("No folder path given, pass using `folder_path: 'path'`") unless (value and not value.empty?)
                                       end),
          FastlaneCore::ConfigItem.new(key: :timeout,
                                       description: "timeout in seconds - waits until x seconds for the folder to be created ",
                                       type: Integer,
                                       default_value: 120)
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