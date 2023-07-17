require_relative './../ruby/chat_sdk_manager'

module Fastlane
  module Actions
    class CopySdkLibrariesToChatSdkAction < Action
      def self.run(params)
          sdk_third_party_path = params[:sdk_third_party_path]
          chat_third_party_path = params[:chat_third_party_path]

          chat_sdk_manager = ChatSDKManager.new(sdk_third_party_path, chat_third_party_path)

          create_include_and_lib_folders chat_sdk_manager
          copy_headers chat_sdk_manager
          move_libraries chat_sdk_manager
      end

      def self.create_include_and_lib_folders(chat_sdk_manager)
        UI.important "Creating include and lib folders in 3rdparty for chat"
        chat_sdk_manager.create_include_and_lib_folders
        UI.success "Successfully created include and lib folders in 3rdparty for chat ✅"
      end

      def self.copy_headers(chat_sdk_manager)
        UI.important "Copying headers needed by MEGAChat"
        chat_sdk_manager.copy_headers
        UI.success "Successfully Copied headers needed by MEGAChat ✅"
      end

      def self.move_libraries(chat_sdk_manager)
        UI.important "Move xcframeworks needed by MEGAChat"
        chat_sdk_manager.move_libraries
        UI.success "Successfully moved xcframeworks needed by MEGAChat ✅"
      end

      def self.description
          "Copies the required files from SDK to chat SDK"
      end

      def self.details
        "Copies the required files from SDK to chat SDK"
      end

      def self.available_options
        [
          FastlaneCore::ConfigItem.new(key: :sdk_third_party_path,
                                       description: "relative folder path for sdk",
                                       verify_block: proc do |value|
                                          UI.user_error!("No folder path given, pass using `sdk_third_party_path: 'path'`") unless (value and not value.empty?)
                                       end),
          FastlaneCore::ConfigItem.new(key: :chat_third_party_path,
                                       description: "relative folder path for chat sdk",
                                       verify_block: proc do |value|
                                          UI.user_error!("No folder path given, pass using `chat_third_party_path: 'path'`") unless (value and not value.empty?)
                                       end)
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
