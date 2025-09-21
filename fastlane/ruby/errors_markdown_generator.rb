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
      threshold = 21
      failure_counts = Hash.new(0) 
      all_failures = []
      parsed_data = nil

      begin
        json_data = File.read(json_path)
        if json_data.nil? || json_data.strip.empty?
          puts "Warning: JSON file is empty: #{json_path}"
          return all_failures
        end

        first_char = json_data.strip[0]
        unless ['{', '['].include?(first_char)
          puts "Warning: File doesn't appear to contain valid JSON (starts with '#{first_char}'): #{json_path}"
          puts "First 100 characters: #{json_data[0..99]}"
          return all_failures
        end

        parsed_data = JSON.parse(json_data)
      rescue JSON::ParserError => e
        puts "Error parsing JSON file #{json_path}: #{e.message}"
        return all_failures
      rescue Errno::ENOENT
        puts "Error: JSON file not found: #{json_path}"
        return all_failures
      rescue => e
        puts "Unexpected error reading JSON file #{json_path}: #{e.message}"
        return all_failures
      end

      actions = parsed_data.dig("actions", "_values")
      return all_failures unless actions

      actions.each do |action|
        test_failures = action.dig("actionResult", "issues", "testFailureSummaries", "_values")
        next unless test_failures

        test_failures.each do |failure|
          test_case_name = failure.dig("testCaseName", "_value")
          next unless test_case_name

          failure_counts[test_case_name] += 1

          failureHash = {}
          failureHash[:testcase] = test_case_name
          failureHash[:reason] = failure.dig("message", "_value")&.gsub("\n", "") || ""

          url = failure.dig("documentLocationInCreatingWorkspace", "url", "_value")
          url_info = extract_url_params(url) if url

          if url && url_info
            failureHash[:details] = "#{url_info[:file_name]} (#{url_info[:starting_line_number]} - #{url_info[:ending_line_number]})"
          else
            failureHash[:details] = ""
          end

          all_failures << failureHash
        end
      end

      test_cases_failure_with_threshold = failure_counts.select { |_, count| count >= threshold }.keys

      failed_tests = all_failures.select do |failure|
        test_cases_failure_with_threshold.include?(failure[:testcase])
      end

      failed_tests.uniq { |failure| failure[:testcase] }
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