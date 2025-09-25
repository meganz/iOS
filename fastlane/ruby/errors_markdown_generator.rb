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
      all_failures = []
      
      # Parse JSON with comprehensive error handling
      parsed_data = parse_json_file(json_path)
      return all_failures unless parsed_data

      # Get expected failure count and validate
      tests_failed_count = extract_failed_test_count(parsed_data)
      return all_failures if tests_failed_count.zero?

      # Extract test failures from actions
      test_failures = extract_test_failures(parsed_data)
      return all_failures if test_failures.empty?

      # Count failures and build details hash
      failure_counts, failure_details = process_test_failures(test_failures)
      return all_failures if failure_counts.empty?

      # Return top failed tests based on count
      select_top_failed_tests(failure_counts, failure_details, tests_failed_count)
    end

    private def parse_json_file(json_path)
      json_data = File.read(json_path)
      
      if json_data.nil? || json_data.strip.empty?
        puts "Warning: JSON file is empty: #{json_path}"
        return nil
      end

      unless json_data.strip.start_with?('{', '[')
        puts "Warning: File doesn't appear to contain valid JSON: #{json_path}"
        puts "First 100 characters: #{json_data[0..99]}"
        return nil
      end

      JSON.parse(json_data)
    rescue JSON::ParserError => e
      puts "Error parsing JSON file #{json_path}: #{e.message}"
      nil
    rescue Errno::ENOENT
      puts "Error: JSON file not found: #{json_path}"
      nil
    rescue StandardError => e
      puts "Unexpected error reading JSON file #{json_path}: #{e.message}"
      nil
    end

    private def extract_failed_test_count(parsed_data)
      count = parsed_data.dig("metrics", "testsFailedCount", "_value")
      count ? count.to_i : 0
    end

    private def extract_test_failures(parsed_data)
      actions = parsed_data.dig("actions", "_values")
      return [] unless actions

      actions.filter_map do |action|
        action.dig("actionResult", "issues", "testFailureSummaries", "_values")
      end.flatten
    end

    private def process_test_failures(test_failures)
      failure_counts = Hash.new(0)
      failure_details = {}

      test_failures.each do |failure|
        test_case_name = failure.dig("testCaseName", "_value")
        next unless test_case_name

        failure_counts[test_case_name] += 1
        failure_details[test_case_name] = build_failure_hash(failure, test_case_name)
      end

      [failure_counts, failure_details]
    end

    private def build_failure_hash(failure, test_case_name)
      url = failure.dig("documentLocationInCreatingWorkspace", "url", "_value")
      url_info = url ? extract_url_params(url) : nil

      {
        testcase: test_case_name,
        reason: failure.dig("message", "_value")&.gsub("\n", "") || "",
        details: build_details_string(url_info)
      }
    end

    private def build_details_string(url_info)
      return "" unless url_info

      "#{url_info[:file_name]} (#{url_info[:starting_line_number]} - #{url_info[:ending_line_number]})"
    end

    private def select_top_failed_tests(failure_counts, failure_details, tests_failed_count)
      top_failed_tests = failure_counts
        .sort_by { |_, count| -count }
        .first(tests_failed_count)
  
      top_failed_tests.map { |test_name, _| failure_details[test_name] }
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