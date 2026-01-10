import Foundation

final class WarningsMarkdownGenerator {
    struct Issue {
        let file: String
        let reason: String
        let line: String
    }

    enum IssueKind {
        case warning
    }

    // MARK: - Constants
    private enum Constants {
        static let swiftPackages = "Third Party Swift Packages Warnings"
        static let sdkAndChatWarnings = "SDK and MEGAChatSDK Warnings"
        static let analyticsLibrary = "Analytics Library Warnings"
        static let otherWarnings = "Other Warnings"
        
        static let swiftPackagesPath = "SwiftPackages"
        static let sdkPath = "Modules/DataSource"
        static let analyticsPath = "MEGAAnalyticsiOS"
    }

    // MARK: - Public API
    @discardableResult
    func generateMarkdown(warnings: [Issue], outputFilePath: String) throws -> Bool {
        var markdown = initializeMarkdownSections()
        markdown = appendWarningsToMarkdown(warnings, markdown: markdown)
        markdown = appendCloseTags(markdown)

        let header = "Warnings\n---"
        let markdownText = header + buildFinalMarkdown(markdown)

        if markdownText != header {
            try ensureDirectoryExists(for: outputFilePath)
            try markdownText.write(toFile: outputFilePath, atomically: true, encoding: .utf8)
            return true
        }

        return false
    }

    // MARK: - Sections
    private enum SectionKey: CaseIterable {
        case swiftPackages
        case sdkAndChatWarnings
        case analyticsLibrary
        case otherWarnings
    }

    private func initializeMarkdownSections() -> [SectionKey: String] {
        return [
            .swiftPackages: initialMarkdownText(summaryName: Constants.swiftPackages, isOpen: false),
            .sdkAndChatWarnings: initialMarkdownText(summaryName: Constants.sdkAndChatWarnings, isOpen: false),
            .analyticsLibrary: initialMarkdownText(summaryName: Constants.analyticsLibrary, isOpen: false),
            .otherWarnings: initialMarkdownText(summaryName: Constants.otherWarnings, isOpen: true)
        ]
    }

    // MARK: - Append warnings
    private func appendWarningsToMarkdown(_ warnings: [Issue], markdown: [SectionKey: String]) -> [SectionKey: String] {
        var updated = markdown

        for warning in warnings {
            let file = warning.file
            let reason = warning.reason
            let lineNumber = warning.line

            let filename: String
            if let lastPathComponent = URL(string: file)?.lastPathComponent {
                filename = lastPathComponent
            } else {
                filename = ""
            }

            let rowText = "| ⚠️ | \(reason) | \(filename) | \(lineNumber) |\n"

            // Match Ruby case/when with regex-ish substring checks
            if file.contains(Constants.swiftPackagesPath) {
                appendUnique(rowText, to: .swiftPackages, in: &updated)
            } else if file.contains(Constants.sdkPath) {
                appendUnique(rowText, to: .sdkAndChatWarnings, in: &updated)
            } else if file.contains(Constants.analyticsPath) {
                appendUnique(rowText, to: .analyticsLibrary, in: &updated)
            } else {
                appendUnique(rowText, to: .otherWarnings, in: &updated)
            }
        }

        return updated
    }

    private func appendUnique(_ rowText: String, to key: SectionKey, in markdown: inout [SectionKey: String]) {
        guard var content = markdown[key] else { return }
        if !content.contains(rowText) {
            content += rowText
            markdown[key] = content
        }
    }

    // MARK: - Close tags
    private func appendCloseTags(_ markdown: [SectionKey: String]) -> [SectionKey: String] {
        var updated = markdown
        for key in SectionKey.allCases {
            if var content = updated[key] {
                content += "</details>"
                updated[key] = content
            }
        }
        return updated
    }

    // MARK: - Templates
    private func initialMarkdownText(summaryName: String, isOpen: Bool) -> String {
        let openAttribute = isOpen ? "open" : ""
        return """
        <details \(openAttribute)>
        <summary>\(summaryName)</summary>

        | | Warnings | File | Line |
        | :--- | :--- | :--- | :--- |
        
        """
    }

    // MARK: - Final markdown build
    private func buildFinalMarkdown(_ markdown: [SectionKey: String]) -> String {
        var finalMarkdown = ""

        let orderedKeys: [SectionKey] = [.swiftPackages, .sdkAndChatWarnings, .analyticsLibrary, .otherWarnings]

        for key in orderedKeys {
            guard let content = markdown[key] else { continue }
            if hasNonHeaderRows(content) {
                finalMarkdown += "\n\n" + content
            }
        }

        return finalMarkdown
    }

    private func hasNonHeaderRows(_ content: String) -> Bool {
        let lines = content.split(separator: "\n", omittingEmptySubsequences: false)
        return lines.count > 6
    }

    private func ensureDirectoryExists(for filePath: String) throws {
        let url = URL(fileURLWithPath: filePath)
        let directoryURL = url.deletingLastPathComponent()

        let fileManager = FileManager.default
        if !fileManager.fileExists(atPath: directoryURL.path) {
            try fileManager.createDirectory(
                at: directoryURL,
                withIntermediateDirectories: true,
                attributes: nil
            )
        }
    }
}
