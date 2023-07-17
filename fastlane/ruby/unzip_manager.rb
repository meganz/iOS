class UnzipManager
    def unzip_contents(zip_file_path, intermediate_folder_path, destination_folder_path, use_cache) 
        if folder_exists?(intermediate_folder_path) and not use_cache
            remove_folder intermediate_folder_path
        end

        unless folder_exists?(intermediate_folder_path)
            unzip_file zip_file_path, intermediate_folder_path
        end

        FileUtils.cp_r "#{intermediate_folder_path}/.", destination_folder_path, remove_destination: true, :verbose => true

        unless use_cache
            folder_to_delete = Pathname.new(zip_file_path).parent.parent.to_s
            puts "deleting folder #{folder_to_delete}"
            remove_folder folder_to_delete
            puts "deleted folder #{folder_to_delete}"
        end
    end

    private def remove_folder(folder_path)
        FileUtils.rm_rf(folder_path) if folder_exists?(folder_path)
    end

    private def folder_exists?(folder_path)
        File.directory?(folder_path)
    end

    private def unzip_file(file, destination_path)
        Zip::File.open(file) do |zip|
          zip.each do |entry|
            next if entry.name.start_with?('__MACOSX/')
            next if entry.name.start_with?('._')      
            entry_destination = File.join(destination_path, entry.name)
            File.delete(entry_destination) if File.exist?(entry_destination)
            entry.extract(entry_destination)
          end
        end
    end
end