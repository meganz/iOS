require_relative './../ruby/download_manager'

module Fastlane
  module Actions
    module SharedValues
      DOWNLOADED_FILE_PATH = :DOWNLOADED_FILE_PATH
    end

    class DownloadLibrariesAction < Action
      def self.run(params)
        mega_url, destination_folder, use_cache = params[:mega_url], params[:destination_folder], params[:use_cache]
        UI.important "download from: #{mega_url} to path: #{destination_folder}"
        zip_file_path = download mega_url, destination_folder, use_cache
        set_shared_values_and_show_success zip_file_path
      end

      def self.download(mega_url, destination_folder, use_cache) 
        download_manager = DownloadManger.new
        download_manager.download mega_url, destination_folder, use_cache
      end

      def self.set_shared_values_and_show_success(zip_file_path)
        Actions.lane_context[SharedValues::DOWNLOADED_FILE_PATH] = zip_file_path
        UI.success "Successfully downlaoded the third party libraries ✅"
        UI.success "File path: #{zip_file_path}"
      end
      
      def self.description
        "Downloads the zip file hosted in MEGA to destination folder."
      end

      def self.details
        "You can use this action to download the zip file that is hosted in MEGA. This action uses MEGACmd to download the zip file."
      end

      def self.available_options
        [
          FastlaneCore::ConfigItem.new(key: :mega_url,
                                       description: "URL of the zip file to download", 
                                       verify_block: proc do |value|
                                          UI.user_error!("No URL for zip file given, pass using `mega_url: 'url'`") unless (value and not value.empty?)
                                       end),
          FastlaneCore::ConfigItem.new(key: :destination_folder,
                                       description: "destination folder where the zip file is downloaded",
                                       verify_block: proc do |value|
                                          UI.user_error!("No destination folder given, pass using `destination_folder: 'folder_path'`") unless (value and not value.empty?)
                                       end),
          FastlaneCore::ConfigItem.new(key: :use_cache,
                                       description: "uses cache if the file is already downloaded",
                                       optional: true,
                                       default_value: true,
                                       type: Boolean)
        ]
      end

      def self.output
        [
          ['DOWNLOADED_FILE_PATH', 'Download path of the zip file including the file name']
        ]
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
