class ChatSDKManager
    def initialize(sdk_third_party_path, chat_third_party_path)
        @sdk_third_party_path = sdk_third_party_path
        @chat_third_party_path = chat_third_party_path
    end

    def create_include_and_lib_folders
        chat_include_path = File.join(@chat_third_party_path, "include")
        chat_lib_path = File.join(@chat_third_party_path, "lib")

        FileUtils.mkdir_p chat_include_path unless Dir.exist? chat_include_path
        FileUtils.mkdir_p chat_lib_path unless Dir.exist? chat_lib_path
    end

    def copy_headers
        FileUtils.cp_r "#{@sdk_third_party_path}/webrtc/.", "#{@chat_third_party_path}/webrtc", remove_destination: true, :verbose => true

        sdk_third_party_parent_folder = Pathname.new(@sdk_third_party_path).parent.to_s
        sdk_mega_folder = File.join(sdk_third_party_parent_folder, "mega")
        chat_mega_folder = File.join(@chat_third_party_path, "include", "mega")
        FileUtils.cp_r "#{sdk_mega_folder}/.", chat_mega_folder, remove_destination: true, :verbose => true

        sdk_third_party_private_folder = File.join(sdk_third_party_parent_folder, "private")
        FileUtils.cp_r "#{sdk_third_party_private_folder}/DelegateMEGARequestListener.h",  "#{@chat_third_party_path}/include", remove_destination: true, :verbose => true
        FileUtils.cp_r "#{sdk_third_party_private_folder}/DelegateMEGATransferListener.h",  "#{@chat_third_party_path}/include", remove_destination: true, :verbose => true
        FileUtils.cp_r "#{sdk_third_party_private_folder}/MEGAHandleList+init.h",  "#{@chat_third_party_path}/include", remove_destination: true, :verbose => true
        FileUtils.cp_r "#{sdk_third_party_private_folder}/MEGANode+init.h",  "#{@chat_third_party_path}/include", remove_destination: true, :verbose => true
        FileUtils.cp_r "#{sdk_third_party_private_folder}/MEGANodeList+init.h",  "#{@chat_third_party_path}/include", remove_destination: true, :verbose => true
        FileUtils.cp_r "#{sdk_third_party_private_folder}/MEGASdk+init.h",  "#{@chat_third_party_path}/include", remove_destination: true, :verbose => true
        FileUtils.cp_r "#{sdk_third_party_private_folder}/MEGAStringList+init.h",  "#{@chat_third_party_path}/include", remove_destination: true, :verbose => true
    end

    def move_libraries
        sdk_lib_path = File.join(@sdk_third_party_path, "lib")
        chat_lib_path = File.join(@chat_third_party_path, "lib")

        frameworks = [
            "libnative_api.xcframework",
            "libnative_video.xcframework",
            "libvideocapture_objc.xcframework",
            "libvideoframebuffer_objc.xcframework",
            "libwebsockets.xcframework"
        ]

        frameworks.each { |framework| 
            from_path = File.join("#{sdk_lib_path}", framework)
            remove_folder File.join("#{chat_lib_path}", framework)
            FileUtils.move "#{from_path}", "#{chat_lib_path}", :verbose => true
        }
    end

    private def remove_folder(folder_path)
        FileUtils.rm_rf(folder_path) if folder_exists?(folder_path)
    end

    private def folder_exists?(folder_path)
        File.directory?(folder_path)
    end
end