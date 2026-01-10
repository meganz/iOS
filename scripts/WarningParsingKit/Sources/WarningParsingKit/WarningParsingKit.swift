import ArgumentParser
import Foundation
import XCResultKit

@main
struct WarningParsingKit: ParsableCommand {
    lazy var filePath = "./../../derivedData/Logs/Test"
    lazy var outputFilePath = "./../../outputs/warnings.md"

    mutating func run() throws {
        let directoryURL = URL(fileURLWithPath: filePath)

        let contents = try FileManager.default.contentsOfDirectory(
            at: directoryURL,
            includingPropertiesForKeys: [.creationDateKey]
        )

        let xcresultFiles = contents.filter { $0.pathExtension == "xcresult" }

        guard let xcresultURL = xcresultFiles.max(by: { url1, url2 in
            let date1 = try? url1.resourceValues(forKeys: [.creationDateKey]).creationDate
            let date2 = try? url2.resourceValues(forKeys: [.creationDateKey]).creationDate
            return (date1 ?? .distantPast) < (date2 ?? .distantPast)
        }) else {
            throw NSError(domain: "XCResultParser", code: 1, userInfo: [NSLocalizedDescriptionKey: "No .xcresult file found in \(filePath)"])
        }

        let xcresultFile = XCResultFile(url: xcresultURL)
        guard let invocationRecord = xcresultFile.getInvocationRecord() else {
            print("Error: Could not get invocation record")
            throw NSError(domain: "ErrorParsingKit", code: 2, userInfo: [NSLocalizedDescriptionKey: "No invocation record found"])
        }

        let warningSummaries = invocationRecord.issues.warningSummaries
        let warnings = warningSummaries.compactMap { issue in
            if let urlString = issue.documentLocationInCreatingWorkspace?.url,
                let url = URL(string: urlString) {
                let message = issue.message
                let file = url.absoluteString
                var startingLine = "-"
                var endingLine = "-"
                if let fragment = url.fragment {
                    let params = fragment
                        .split(separator: "&")
                        .reduce(into: [String: String]()) { dict, pair in
                            let parts = pair.split(separator: "=", maxSplits: 1)
                            if parts.count == 2 {
                                dict[String(parts[0])] = String(parts[1])
                            }
                        }

                    startingLine = params["StartingLineNumber"] ?? startingLine
                    endingLine = params["EndingLineNumber"] ?? endingLine
                }
                return WarningsMarkdownGenerator.Issue(
                    file: file,
                    reason: message,
                    line: "\(startingLine) - \(endingLine)"
                )
            }

            return nil
        }

        let warningsMarkdownGenerator = WarningsMarkdownGenerator()
        try warningsMarkdownGenerator.generateMarkdown(warnings: warnings, outputFilePath: outputFilePath)
    }
}
