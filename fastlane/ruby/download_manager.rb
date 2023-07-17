class DownloadManger
    def download(file_link_url, destination_folder, use_cache)
        filename = filename file_link_url
        remove_folder destination_folder, use_cache
        file_already_exists = check_if_zip_file_exists destination_folder
         
        if file_already_exists and use_cache
            return zip_file_path destination_folder
        elsif
            FileUtils.rm_rf(destination_folder)
        end

        add_megacmd_to_path
        FileUtils.mkdir_p destination_folder
        begin
            puts "Downloading from #{file_link_url}"
            system "mega-get #{file_link_url} #{destination_folder}" 
            zip_file_path destination_folder
        rescue Exception => e
            puts "❌ failed to download the third party libraries."
            puts "❌ Please install MEGACmd before run this script https://mega.nz/cmd"
            raise e
        end
    end
    
    private def add_megacmd_to_path
        ENV['PATH'] = '/Applications/MEGAcmd.app/Contents/MacOS:' + ENV['PATH']
    end
    
    private def filename(file_link_url) 
        last_path_component = File.basename(file_link_url)
        parts = last_path_component.split '!'
        parts[1]
    end

    private def check_if_zip_file_exists(destination_folder)
        zip_files = Dir.glob File.join(destination_folder, "*.zip")
        zip_files.empty? == false
    end

    private def zip_file_path(destination_folder)
        zip_files = Dir.glob File.join(destination_folder, "*.zip")
        return nil if zip_files.empty?
        return zip_files[0]
    end
    
    private def remove_folder(destination_folder, use_cache)
        file_already_exists = check_if_zip_file_exists destination_folder
        if not use_cache and file_already_exists
            FileUtils.rm_rf destination_folder 
        end
    end
end