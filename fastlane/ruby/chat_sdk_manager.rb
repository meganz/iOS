class ChatSDKManager
    def initialize(sdk_third_party_path, chat_third_party_path)
        @sdk_third_party_path = sdk_third_party_path
        @chat_third_party_path = chat_third_party_path
    end

    def create_include_folder
        chat_include_path = File.join(@chat_third_party_path, "include")

        FileUtils.mkdir_p chat_include_path unless Dir.exist? chat_include_path
    end

    def copy_headers
        sdk_third_party_parent_folder = Pathname.new(@sdk_third_party_path).parent.to_s
        sdk_mega_folder = File.join(sdk_third_party_parent_folder, "mega")
        chat_mega_folder = File.join(@chat_third_party_path, "include", "mega")
        FileUtils.cp_r "#{sdk_mega_folder}/.", chat_mega_folder, remove_destination: true, :verbose => true
        sdk_root_path = Pathname.new(@sdk_third_party_path).parent.parent.parent.to_s

        sdk_third_party_private_folder = File.join(sdk_third_party_parent_folder, "private")
        FileUtils.cp_r "#{sdk_third_party_private_folder}/DelegateMEGARequestListener.h",  "#{@chat_third_party_path}/include", remove_destination: true, :verbose => true
        FileUtils.cp_r "#{sdk_third_party_private_folder}/DelegateMEGATransferListener.h",  "#{@chat_third_party_path}/include", remove_destination: true, :verbose => true
        FileUtils.cp_r "#{sdk_third_party_private_folder}/MEGAHandleList+init.h",  "#{@chat_third_party_path}/include", remove_destination: true, :verbose => true
        FileUtils.cp_r "#{sdk_third_party_private_folder}/MEGANode+init.h",  "#{@chat_third_party_path}/include", remove_destination: true, :verbose => true
        FileUtils.cp_r "#{sdk_third_party_private_folder}/MEGANodeList+init.h",  "#{@chat_third_party_path}/include", remove_destination: true, :verbose => true
        FileUtils.cp_r "#{sdk_third_party_private_folder}/MEGASdk+init.h",  "#{@chat_third_party_path}/include", remove_destination: true, :verbose => true
        FileUtils.cp_r "#{sdk_third_party_private_folder}/MEGAStringList+init.h",  "#{@chat_third_party_path}/include", remove_destination: true, :verbose => true
        FileUtils.cp_r "#{sdk_root_path}/third_party/ccronexpr/ccronexpr.h",  "#{@chat_third_party_path}/include", remove_destination: true, :verbose => true
    end
end
