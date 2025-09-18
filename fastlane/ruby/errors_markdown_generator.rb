require 'json'
require_relative 'issue_fetcher'

class ErrorsMarkdownGenerator
    ERRORS = "Errors"
    TEST_FAILURES = "Test Failures"

    def generate_markdown(errors_json_path, output_file_path)
      markdown = initialize_markdown_sections

      errors = fetch_all_issues(errors_json_path, :error)
      markdown[:errors] += markdown_rows_text(errors, true)  

      failures = fetch_all_failures(errors_json_path)
      if !failures.empty?
        markdown[:test_failures] += test_failures_to_markdown(failures)
      end
      
      markdown = append_close_tags(markdown)
  
      header = "Errors and Failures\n---"
      markdown_text = header + build_final_markdown(markdown)

      File.write(output_file_path, markdown_text) unless markdown_text == header
      markdown_text != header
    end

    private def fetch_all_failures(json_path)
      failed_tests = []

      json_data = File.read(json_path)
      parsed_data = JSON.parse(json_data)

      actions = parsed_data.dig("actions", "_values")
      return failed_tests unless actions

      actions.each do |action|
        test_failures = action.dig("actionResult", "issues", "testFailureSummaries", "_values")
        next unless test_failures

        test_failures.each do |failure|
          failureHash = {}
          failureHash[:testcase] = failure.dig("testCaseName", "_value")
          failureHash[:reason] = failure.dig("message", "_value")

          url = failure.dig("documentLocationInCreatingWorkspace", "url", "_value")
          url_info = extract_url_params(url)

          if url && url_info
            failureHash[:details] = "#{url_info[:file_name]} (#{url_info[:starting_line_number]} - #{url_info[:ending_line_number]})"
          else
            failureHash[:details] = ""
          end

          failed_tests << failureHash unless failureHash.empty?
        end
      end

      failed_tests
    end

    def extract_url_params(url)
      # Extract file path and line numbers from URL
      file_path = url.split('#')[0].gsub('file://', '')
      params = url.split('#')[1]
  
      starting_line = params.match(/StartingLineNumber=(\d+)/)&.captures&.first
      ending_line = params.match(/EndingLineNumber=(\d+)/)&.captures&.first
  
      file_name = File.basename(file_path)
  
      {
        file_name: file_name,
        starting_line_number: starting_line,
        ending_line_number: ending_line
      }
    end
  
    def initialize_markdown_sections
      { 
        errors: initial_markdown_text(ERRORS, "Error", "File", "Line"),
        test_failures: initial_markdown_text(TEST_FAILURES, "Reason", "Testcase", "details"),
      }
    end

    private def test_failures_to_markdown(failures) 
      rows_text = ""
      failures.each do |failure|
        text = "| ❌ | #{failure[:reason]} | #{failure[:testcase]} | #{failure[:details]} |\n"
        if !rows_text.include?(text)
          rows_text += text
        end
      end 
      rows_text
    end

    private def markdown_rows_text(errors, is_error) 
      rows_text = ""
      errors.each do |error|
        file = error[:file]
        filename = file.empty? ? "" : File.basename(file)
        text = "| ❌ | #{error[:reason]} | #{filename} | #{error[:line]} |\n"
        if !rows_text.include?(text)
          rows_text += text
        end
      end 
      rows_text
    end
  
    private def append_close_tags(markdown)
      markdown.each_key { |key| markdown[key] += "</details>" }
      markdown
    end
  
    private def initial_markdown_text(summary_name, second_column_header_name, third_column_header_name, fourth_column_header_name)    
      <<~END
        <details open>
        <summary>#{summary_name}</summary>
      
        | | #{second_column_header_name} | #{third_column_header_name} | #{fourth_column_header_name} |
        | :--- | :--- | :--- | :--- |
      END
    end
  
    private def build_final_markdown(markdown)
      final_markdown = ""
  
      markdown.each do |category, content|
        if has_non_header_rows?(content)
          final_markdown += "\n\n" + content
        end
      end
  
      final_markdown
    end  

    private def has_non_header_rows?(content)
        content_lines = content.split("\n")
        content_lines.length > 6 # Minimum number of lines to include non-header rows
    end

end