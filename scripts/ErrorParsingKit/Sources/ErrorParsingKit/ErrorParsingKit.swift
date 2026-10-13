import ArgumentParser
import Foundation
import XCResultKit

@main
struct ErrorParsingKit: ParsableCommand {
    lazy var filePath = "./../../derivedData/Logs/Test"
    lazy var errorFilePath = "./../../outputs/errors.md"
    lazy var flakyTestsFilePath = "./../../outputs/flaky_tests.md"

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
            try write(text: errorText, to: errorFilePath)
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
            try write(text: failedTestCasesText, to: errorFilePath)
        }

        try writeFlakyTests(from: xcresultURL)
    }

    // MARK: - Flaky tests

    // A flaky test failed in one attempt, and its last attempt passed or was skipped.
    // The build passes, so this report is the only place that names the test.
    mutating private func writeFlakyTests(from xcresultURL: URL) throws {
        let flakyTests = try readTestNodes(from: xcresultURL).flatMap { findFlakyTests(in: $0, path: []) }
        guard !flakyTests.isEmpty else { return }

        var flakyTestsText = """
        ## Flaky Tests - \(isMainAppTarget ? "Main App Target" : "Swift Packages")
        These tests failed at least once, then passed or were skipped on retry.
        <details open>
        <summary>Flaky tests: \(flakyTests.count)</summary>

        &nbsp; | Error | Test Case
        --- | --- | ---

        """

        for flakyTest in flakyTests {
            flakyTestsText += "⚠️ | \(tableCellText(flakyTest.message)) | \(tableCellText(flakyTest.name))\n"
        }

        flakyTestsText += "</details>"
        try write(text: flakyTestsText, to: flakyTestsFilePath)
    }

    // A new line or a "|" would break the Markdown table row.
    // GitLab reads text such as "<nil>" as an HTML tag and hides it.
    private func tableCellText(_ text: String) -> String {
        text
            .replacingOccurrences(of: "\n", with: " ")
            .replacingOccurrences(of: "|", with: "\\|")
            .replacingOccurrences(of: "<", with: "&lt;")
    }

    // The legacy summaries in XCResultKit do not list the retries of Swift Testing tests.
    // The test-results format lists every attempt for XCTest and Swift Testing.
    private func readTestNodes(from xcresultURL: URL) throws -> [TestNode] {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/xcrun")
        process.arguments = ["xcresulttool", "get", "test-results", "tests", "--path", xcresultURL.path]
        let pipe = Pipe()
        process.standardOutput = pipe
        try process.run()
        // Read before waiting, so a large output cannot fill the pipe and block the process.
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        process.waitUntilExit()
        guard process.terminationStatus == 0 else {
            throw NSError(
                domain: "ErrorParsingKit",
                code: 3,
                userInfo: [NSLocalizedDescriptionKey: "xcresulttool failed with exit code \(process.terminationStatus)"]
            )
        }
        return try JSONDecoder().decode(TestResults.self, from: data).testNodes
    }

    // A node with "Repetition" children is one test run: a test case,
    // or one argument set of a parameterized Swift Testing test.
    private func findFlakyTests(in node: TestNode, path: [String]) -> [FlakyTest] {
        let children = node.children ?? []
        let nodeName = node.nodeType == "Arguments" ? "arguments: \(node.name)" : node.name
        let repetitions = children.filter { $0.nodeType == "Repetition" }

        guard repetitions.isEmpty else {
            guard let firstFailure = repetitions.first(where: { $0.result == "Failed" }),
                  repetitions.last?.result != "Failed" else {
                return []
            }
            let message = firstFailure.children?.first(where: { $0.nodeType == "Failure Message" })?.name ?? "-"
            return [FlakyTest(name: (path + [nodeName]).joined(separator: "->"), message: message)]
        }

        // The test plan name is the scheme name, which adds nothing to the test name.
        let childPath = node.nodeType == "Test Plan" ? path : path + [nodeName]
        return children.flatMap { findFlakyTests(in: $0, path: childPath) }
    }

    private func write(text: String, to path: String) throws {
        let outputURL = URL(fileURLWithPath: path)
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

// The parts of `xcresulttool get test-results tests` output that the flaky test report reads.
private struct TestResults: Decodable {
    let testNodes: [TestNode]
}

private struct TestNode: Decodable {
    let nodeType: String
    let name: String
    let result: String?
    let children: [TestNode]?
}

private struct FlakyTest {
    let name: String
    let message: String
}
