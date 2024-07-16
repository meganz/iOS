require_relative 'issue_fetcher'

class WarningsMarkdownGenerator
  SWIFT_PACKAGES = "Third Party Swift Packages Warnings"
  SDK_AND_CHAT_WARNINGS = "SDK and MEGAChatSDK Warnings"
  ANALYTICS_LIBRARY = "Analytics Library Warnings"
  OTHER_WARNINGS = "Other Warnings"
  SWIFT_PACKAGES_PATH = "SwiftPackages"
  SDK_PATH = "Modules/DataSource"
  ANALYTICS_PATH = "MEGAAnalyticsiOS"

  def generate_markdown(warnings_json_path, output_file_path)
    warnings = fetch_all_issues(warnings_json_path, :warning)
    markdown = initialize_markdown_sections
    markdown = append_warnings_to_markdown(warnings, markdown)
    markdown = append_close_tags(markdown)

    header = "Warnings\n---"
    markdown_text = header + build_final_markdown(markdown)
    
    File.write(output_file_path, markdown_text) unless markdown_text == header
    markdown_text != header
  end

  private def initialize_markdown_sections
    { 
      swift_packages: initial_markdown_text(SWIFT_PACKAGES),
      sdk_and_chat_warnings: initial_markdown_text(SDK_AND_CHAT_WARNINGS),
      analytics_library: initial_markdown_text(ANALYTICS_LIBRARY),
      other_warnings: initial_markdown_text(OTHER_WARNINGS)
    }
  end

  private def append_warnings_to_markdown(warnings, markdown) 
    warnings.each do |warning|
      file = warning[:file]
      reason = warning[:reason]
      line_number = warning[:line]
      filename = file.empty? ? "" : File.basename(file)

      current_directory = Pathname.getwd
      row_text = "| ⚠️ | #{reason} | #{filename} | #{line_number} |\n"

      case file
      when /#{SWIFT_PACKAGES_PATH}/
        markdown[:swift_packages] += row_text unless markdown[:swift_packages].include?(row_text)
      when /#{SDK_PATH}/
        markdown[:sdk_and_chat_warnings] += row_text unless markdown[:sdk_and_chat_warnings].include?(row_text)
      when /#{ANALYTICS_PATH}/
        markdown[:analytics_library] += row_text unless markdown[:analytics_library].include?(row_text)
      else
        markdown[:other_warnings] += row_text unless markdown[:other_warnings].include?(row_text)
      end
    end

    markdown
  end

  private def append_close_tags(markdown)
    markdown.each_key { |key| markdown[key] += "</details>" }
    markdown
  end

  private def initial_markdown_text(summary_name, is_open = false)
    open_attribute = is_open ? "open" : ""
  
    <<~END
      <details #{open_attribute}>
      <summary>#{summary_name}</summary>
    
      | | Warnings | File | Line |
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
