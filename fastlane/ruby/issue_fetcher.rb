

def fetch_all_issues(json_path, issue_type)
    issues = []
    issue_key = issue_type == :warning ? "warningSummaries" : "errorSummaries"
  
    json_data = File.read(json_path)
    parsed_data = JSON.parse(json_data)
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
  