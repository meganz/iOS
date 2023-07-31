class ErrorsMarkdownGenerator
    ERRORS = "Errors"
    TEST_FAILURES = "Test Failures"
  
    def generate_markdown(json_path, output_file_path, repo_url)
      file = File.read(json_path)
      data_hash = JSON.parse(file)

      compile_errors = data_hash["compile_errors"]
      file_missing_errors = data_hash["file_missing_errors"]
      undefined_symbols_errors = data_hash["undefined_symbols_errors"]
      duplicate_symbols_errors = data_hash["duplicate_symbols_errors"]
      tests_failures = data_hash["tests_failures"]

      markdown = initialize_markdown_sections
      markdown[:errors] += markdown_rows_text(compile_errors, true)
      markdown[:errors] += markdown_rows_text(file_missing_errors, true)
      markdown[:errors] += markdown_rows_text(undefined_symbols_errors, true)
      markdown[:errors] += markdown_rows_text(duplicate_symbols_errors, true)
      markdown[:test_failures] += test_failures_to_markdown(tests_failures)
      markdown = append_close_tags(markdown)
  
      header = "Errors and Failures\n---"
      markdown_text = header + build_final_markdown(markdown)

      File.write(output_file_path, markdown_text) unless markdown_text == header
      markdown_text != header
    end
  
    def initialize_markdown_sections
      { 
        errors: initial_markdown_text(ERRORS, "Error", "File"),
        test_failures: initial_markdown_text(TEST_FAILURES, "Reason", "Test Case"),
      }
    end

    private def test_failures_to_markdown(test_failures) 
        rows_text = ""
        test_failures.each do |key, failures|
            rows_text += markdown_rows_text(failures, false)
        end
        rows_text
    end

    private def markdown_rows_text(errors_or_failures, is_error) 
      rows_text = ""
      errors_or_failures.each do |error_or_failure|
        file_path = error_or_failure["file_path"]
        line_number = file_path.match(is_error ? /:(\d+):(\d+)\z/ : /:(\d+)\z/)[1]
        text = "| ❌ | #{error_or_failure['reason']} | #{error_or_failure[is_error ? 'file_name' : 'test_case']} | #{line_number} |\n"
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
  
    private def initial_markdown_text(summary_name, second_column_header_name, third_column_header_name)    
      <<~END
        <details open>
        <summary>#{summary_name}</summary>
      
        | | #{second_column_header_name} | #{third_column_header_name} | Line |
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