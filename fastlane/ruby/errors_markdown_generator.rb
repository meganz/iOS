require 'nokogiri'
require_relative 'issue_fetcher'

class ErrorsMarkdownGenerator
    ERRORS = "Errors"
    TEST_FAILURES = "Test Failures"

    def generate_markdown(errors_json_path, junit_file_path, output_file_path)
      markdown = initialize_markdown_sections

      errors = fetch_all_issues(errors_json_path, :error)
      markdown[:errors] += markdown_rows_text(errors, true)  

      if File.exist?(junit_file_path)
        failures = fetch_all_failures(junit_file_path)
        markdown[:test_failures] += test_failures_to_markdown(failures)  
      end
      
      markdown = append_close_tags(markdown)
  
      header = "Errors and Failures\n---"
      markdown_text = header + build_final_markdown(markdown)

      File.write(output_file_path, markdown_text) unless markdown_text == header
      markdown_text != header
    end

    private def fetch_all_failures(junit_file_path)
      failures = []

      doc = Nokogiri::XML(File.open(junit_file_path))
      doc.xpath(".//testsuite").each do |testsuite|
        testsuite.xpath(".//testcase").each do |testcase|
          failureHash = {}
          testcase.xpath(".//failure").each do |failure|
            failureHash[:classname] = testcase["classname"]
            failureHash[:testcase] = testcase["name"]  
            parts = failure["message"].rpartition("(")
            failureHash[:reason] = parts[0]
          end
          failures << failureHash unless failureHash.empty?
        end
      end

      failures
    end
  
    def initialize_markdown_sections
      { 
        errors: initial_markdown_text(ERRORS, "Error", "File", "Line"),
        test_failures: initial_markdown_text(TEST_FAILURES, "Reason", "Class", "Testcase"),
      }
    end

    private def test_failures_to_markdown(failures) 
      rows_text = ""
      failures.each do |failure|
        text = "| ❌ | #{failure[:reason]} | #{failure[:classname]} | #{failure[:testcase]} |\n"
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