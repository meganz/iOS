import ArgumentParser
import Foundation
import XCResultKit

@main
struct ErrorParsingKit: ParsableCommand {
    lazy var filePath = "./../../derivedData/Logs/Test"
    lazy var errorFilePath = "./../../outputs/errors.md"

    @Option(help: "is the main app target")
    var isMainAppTarget: Bool = false

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
        let actions = invocationRecord.actions

        if actions.map(\.buildResult.status).contains(where: { $0 == "failed" }) {
            var errorText = """
            ## Errors - \(isMainAppTarget ? "Main App Target" : "Swift Packages")
            <details open>
            <summary>Errors</summary>
            
            &nbsp; | Error | File | Line
            --- | --- | --- | ---
            
            """

            for errorSummary in actions.flatMap(\.buildResult.issues.errorSummaries) {
                let details = errorSummary.documentLocationInCreatingWorkspace?.url ?? ""
                let parsedDetails = parseError(urlString: details)
                let lineInfo = "\(parsedDetails.start) - \(parsedDetails.end)"

                errorText += "❌ | \(errorSummary.message) | \(parsedDetails.fileName) | \(lineInfo)\n"
            }

            errorText += "</details>"
            try write(text: errorText)
        } else if actions.map(\.actionResult.status).contains(where: { $0 == "failed" }) {
            var failedTestCasesText = """
            ## Test Failures - \(isMainAppTarget ? "Main App Target" : "Swift Packages")
            ### Count: \(actions.compactMap(\.actionResult.metrics.testsFailedCount).first ?? -1)
            <details open>
            <summary>Failures</summary>
            
            &nbsp; | Error | Test Case 
            --- | --- | ---
            
            """

            let failedTestCases = extractFailedTests(
                from: actions,
                in: xcresultFile
            ).map {
                $0.split(separator: "/").joined(separator: ".")
            }

            for testFailure in actions.flatMap(\.actionResult.issues.testFailureSummaries) {
                if let failedTestCase = failedTestCases.first(where: { $0.contains(testFailure.testCaseName)}) {
                    let testCaseDetails = failedTestCase.split(separator: ".").joined(separator: "->")
                    failedTestCasesText += "❌ | \(testFailure.message) | \(testCaseDetails)\n"
                }
            }

            failedTestCasesText += "</details>"
            try write(text: failedTestCasesText)
        }
    }

    mutating private func write(text: String) throws {
        let outputURL = URL(fileURLWithPath: errorFilePath)
        let directoryURL = outputURL.deletingLastPathComponent()
        try FileManager.default.createDirectory(at: directoryURL,
                                                withIntermediateDirectories: true,
                                                attributes: nil)
        print(text)
        try text.write(to: outputURL, atomically: true, encoding: .utf8)
    }

    private func parseError(urlString: String) -> (fileName: String, start: Int, end: Int) {
        if let components = URLComponents(string: urlString) {
            // Get the file path and extract filename
            let filePath = components.path
            let fileName = (filePath as NSString).lastPathComponent

            // Parse query items from fragment
            let fragment = components.fragment ?? ""
            let fragmentItems = fragment.components(separatedBy: "&")

            var startLine: Int?
            var endLine: Int?

            for item in fragmentItems {
                let parts = item.components(separatedBy: "=")
                guard parts.count == 2 else { continue }

                let key = parts[0]
                let value = parts[1]

                switch key {
                case "StartingLineNumber":
                    startLine = Int(value)
                case "EndingLineNumber":
                    endLine = Int(value)
                default:
                    break
                }
            }

            return (fileName, startLine ?? 0, endLine ?? 0)
        }

        return ("", 0, 0)
    }

    private func extractFailedTests(from actions: [ActionRecord], in xcresultFile: XCResultFile) -> [String] {
        var failedTests: Set<String> = []
        var passedTests: Set<String> = []

        for action in actions {
            if let testRef = action.actionResult.testsRef {
                if let testPlanSummaries = xcresultFile.getTestPlanRunSummaries(id: testRef.id) {
                    for testPlanSummary in testPlanSummaries.summaries {
                        for testableSummary in testPlanSummary.testableSummaries {
                            collectFailedTests(
                                from: testableSummary.tests,
                                failedTests: &failedTests,
                                passedTests: &passedTests
                            )
                        }
                    }
                }
            }
        }

        return failedTests.filter { passedTests.contains($0) == false }
    }

    private func collectFailedTests(
        from tests: [ActionTestSummaryGroup],
        failedTests: inout Set<String>,
        passedTests: inout Set<String>
    ) {
        for test in tests {
            for subTest in test.subtests {
                if subTest.testStatus == "Failure" {
                    failedTests.insert(subTest.identifier!)
                } else {
                    passedTests.insert(subTest.identifier!)
                }
            }

            collectFailedTests(from: test.subtestGroups, failedTests: &failedTests, passedTests: &passedTests)
        }
    }
}
