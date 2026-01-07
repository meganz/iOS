import ArgumentParser
import Foundation
import XCResultKit

@main
struct CodeCoverageParserKit: ParsableCommand {
    @Option(help: "targets to include", transform: { $0.split(separator: ",").map(String.init) })
    var targets: [String]

    @Option(help: "should include the header in the report")
    var shouldIncludeHeader: Bool = false

    lazy var filePath = "./../../derivedData/Logs/Test"
    lazy var coveragePath = "./../../fastlane/code_coverage.md"

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

        let resultFile = XCResultFile(url: xcresultURL)
        let coverage = resultFile.getCodeCoverage()

        var coverageText = ""
        if shouldIncludeHeader {
            coverageText = """
            ## Unit Tests Coverage Summary
            Target | Percentage
            ---    | ---
            
            """
        }

        for target in coverage?.targets ?? [] where targets.contains(target.name) {
            let percentage = (target.lineCoverage * 1000).rounded() / 10
            coverageText += "\(target.name) | \(percentage)%\n"
        }

        let outputURL = URL(fileURLWithPath: coveragePath)
        try coverageText.write(to: outputURL, atomically: true, encoding: .utf8)
    }
}
