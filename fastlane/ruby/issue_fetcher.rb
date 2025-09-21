

def fetch_all_issues(json_path, issue_type)
    issues = []
    issue_key = issue_type == :warning ? "warningSummaries" : "errorSummaries"
    parsed_data = nil

    begin
      json_data = File.read(json_path)
      if json_data.nil? || json_data.strip.empty?
        puts "Warning: JSON file is empty: #{json_path}"
        return issues
      end

      first_char = json_data.strip[0]
      unless ['{', '['].include?(first_char)
        puts "Warning: File doesn't appear to contain valid JSON (starts with '#{first_char}'): #{json_path}"
        puts "First 100 characters: #{json_data[0..99]}"
        return issues
      end

      parsed_data = JSON.parse(json_data)
    rescue JSON::ParserError => e
      puts "Error parsing JSON file #{json_path}: #{e.message}"
      return issues
    rescue Errno::ENOENT
      puts "Error: JSON file not found: #{json_path}"
      return issues
    rescue => e
      puts "Unexpected error reading JSON file #{json_path}: #{e.message}"
      return issues
    end

    issues_list = parsed_data.dig("issues", issue_key, "_values")
  
    unless issues_list.nil?
      issues_list.each do |each_issue|
        file_info = each_issue.dig("documentLocationInCreatingWorkspace", "url", "_value")
        unless file_info.nil?
          uri = URI.parse(file_info)
          fragment_parameters = URI.decode_www_form(uri.fragment)
          starting_line_number = fragment_parameters.assoc("StartingLineNumber")&.last.to_i
          ending_line_number = fragment_parameters.assoc("EndingLineNumber")&.last.to_i
          if starting_line_number == ending_line_number
            line = "#{starting_line_number}"
          else
            line = "#{starting_line_number} to #{ending_line_number}"
          end
          uri.fragment = nil
          uri.query = nil
          issue = {
            :reason => each_issue.dig("message", "_value"),
            :file => uri.to_s.gsub("file://", ''),
            :line => line
          }
          issues << issue
        end
      end
    end
  
    issues
  end
  