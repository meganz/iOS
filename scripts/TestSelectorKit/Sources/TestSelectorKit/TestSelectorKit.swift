import Foundation

// Usage: TestSelectorKit --repo-root . --base origin/develop (or --all <reason>) --test-plan <xctestplan> --output <file>
// Any error gives exit 1 and no output file, so CI runs the full suite.

@main
struct TestSelectorKit {
    static func main() async {
        let arguments = TestSelection.parseArguments(Array(CommandLine.arguments.dropFirst()))
        guard let output = arguments["--output"] else {
            fail("missing --output")
        }
        // A stale file from an earlier run must not look like a result.
        try? FileManager.default.removeItem(atPath: output)

        do {
            let repoRoot = TestSelection.standardPath(arguments["--repo-root"] ?? ".")
            let base = arguments["--base"] ?? "origin/develop"
            let testPlanPath = arguments["--test-plan"] ?? "MEGAModulesTests/MEGAModulesTests.xctestplan"
            try await run(repoRoot: repoRoot, base: base, testPlanPath: testPlanPath, allReason: arguments["--all"], output: output)
        } catch {
            fail("\(error)")
        }
    }

    private static func run(repoRoot: String, base: String, testPlanPath: String, allReason: String?, output: String) async throws {
        let testPlanURL = URL(fileURLWithPath: testPlanPath, relativeTo: URL(fileURLWithPath: repoRoot))
        let testPlan = try TestSelection.testTargets(fromTestPlan: Data(contentsOf: testPlanURL))

        let packagePaths = TestSelection.topLevelPackagePaths(findPackagePaths(repoRoot: repoRoot))
        print("found \(packagePaths.count) packages")
        let packages = try await dumpPackages(packagePaths, repoRoot: repoRoot)
        logMissingDependencies(packages)

        if let allReason {
            try write(.all(reason: allReason, coverage: TestSelection.coverageTargets(of: packages)), to: output)
            return
        }

        let mergeBase = try await git(["merge-base", base, "HEAD"], in: repoRoot)
        let changedFiles = try await changedFiles(repoRoot: repoRoot, from: mergeBase, to: "HEAD")
        print("merge base \(mergeBase), \(changedFiles.count) changed files")

        let selection = TestSelection.select(changedFiles: changedFiles, packages: packages, testPlan: testPlan)
        try write(selection, to: output)

        if case .all = selection {
            let withoutGlobal = TestSelection.packageSelection(changedFiles: changedFiles, packages: packages, testPlan: testPlan)
            let firstLine = TestSelection.outputText(withoutGlobal).split(separator: "\n").first ?? ""
            print("without global files: \(firstLine)")
        }
    }

    private static func write(_ selection: Selection, to output: String) throws {
        let text = TestSelection.outputText(selection)
        try text.write(toFile: output, atomically: true, encoding: .utf8)
        print(text, terminator: "")
    }

    // MARK: - Changed files

    private static func changedFiles(repoRoot: String, from: String, to: String) async throws -> [String] {
        let files = TestSelection.nonEmptyLines(try await git(TestSelection.diffArguments(from: from, to: to), in: repoRoot))
        let submodules = try await submodulePaths(repoRoot: repoRoot)
        var result = files
        // Only submodules under Modules/ can hold package files.
        for file in files where submodules.contains(file) && file.hasPrefix("Modules/") {
            let old = try await submoduleSha(file, at: from, repoRoot: repoRoot)
            let new = try await submoduleSha(file, at: to, repoRoot: repoRoot)
            let innerRoot = repoRoot + "/" + file
            let inner: [String]
            do {
                inner = TestSelection.nonEmptyLines(try await git(TestSelection.diffArguments(from: old, to: new), in: innerRoot))
            } catch {
                throw SelectorError(description: "submodule \(file) diff \(old)..\(new) failed: \(error)")
            }
            print("submodule \(file) \(old)..\(new): \(inner.count) files")
            inner.forEach { print("  \($0)") }
            result += TestSelection.submoduleFiles(submodulePath: file, innerFiles: inner)
        }
        return result
    }

    private static func submodulePaths(repoRoot: String) async throws -> Set<String> {
        let text = try await git(["config", "--file", ".gitmodules", "--get-regexp", "path"], in: repoRoot)
        return Set(TestSelection.nonEmptyLines(text).compactMap { $0.split(separator: " ").last.map(String.init) })
    }

    private static func submoduleSha(_ path: String, at commit: String, repoRoot: String) async throws -> String {
        let text = try await git(["ls-tree", commit, path], in: repoRoot)
        guard let sha = TestSelection.gitlinkSha(fromLsTree: text) else {
            throw SelectorError(description: "submodule \(path) has no gitlink at \(commit)")
        }
        return sha
    }

    // MARK: - Packages

    private static func findPackagePaths(repoRoot: String) -> [String] {
        let modulesURL = URL(fileURLWithPath: repoRoot + "/Modules")
        let skipped: Set<String> = ["derivedData", "SourcePackages"]
        guard let enumerator = FileManager.default.enumerator(
            at: modulesURL,
            includingPropertiesForKeys: nil,
            options: [.skipsHiddenFiles]
        ) else { return [] }

        var result: [String] = []
        for case let url as URL in enumerator {
            let name = url.lastPathComponent
            if skipped.contains(name) {
                enumerator.skipDescendants()
            } else if name == "Package.swift" {
                result.append(TestSelection.relativePath(url.deletingLastPathComponent().path, repoRoot: repoRoot))
            }
        }
        return result.sorted()
    }

    /// Runs `swift package dump-package` with at most 3 at once.
    private static func dumpPackages(_ paths: [String], repoRoot: String) async throws -> [PackageInfo] {
        try await withThrowingTaskGroup(of: PackageInfo.self) { group in
            var result: [PackageInfo] = []
            var remaining = paths[...]
            for _ in 0..<3 {
                guard let path = remaining.popFirst() else { break }
                group.addTask { try await dumpPackage(path, repoRoot: repoRoot) }
            }
            while let info = try await group.next() {
                result.append(info)
                guard let path = remaining.popFirst() else { continue }
                group.addTask { try await dumpPackage(path, repoRoot: repoRoot) }
            }
            return result.sorted { $0.path < $1.path }
        }
    }

    private static func dumpPackage(_ path: String, repoRoot: String) async throws -> PackageInfo {
        let json: String
        do {
            json = try await runProcess("/usr/bin/xcrun", ["swift", "package", "--package-path", repoRoot + "/" + path, "dump-package"])
        } catch {
            throw SelectorError(description: "dump-package \(path) failed: \(error)")
        }
        return try TestSelection.packageInfo(fromDumpPackage: Data(json.utf8), path: path, repoRoot: repoRoot)
    }

    private static func logMissingDependencies(_ packages: [PackageInfo]) {
        TestSelection.missingDependencies(packages).forEach { print("ignored missing dependency \($0)") }
    }

    // MARK: - Process

    private static func git(_ arguments: [String], in directory: String) async throws -> String {
        try await runProcess("/usr/bin/git", ["-C", directory] + arguments)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Output goes to temp files. A pipe can fill up and block a large dump-package.
    private static func runProcess(_ executable: String, _ arguments: [String]) async throws -> String {
        let tempDirectory = FileManager.default.temporaryDirectory
        let outURL = tempDirectory.appendingPathComponent("TestSelectorKit-\(UUID().uuidString).out")
        let errURL = tempDirectory.appendingPathComponent("TestSelectorKit-\(UUID().uuidString).err")
        FileManager.default.createFile(atPath: outURL.path, contents: nil)
        FileManager.default.createFile(atPath: errURL.path, contents: nil)
        defer {
            try? FileManager.default.removeItem(at: outURL)
            try? FileManager.default.removeItem(at: errURL)
        }

        let outHandle = try FileHandle(forWritingTo: outURL)
        let errHandle = try FileHandle(forWritingTo: errURL)
        let process = Process()
        process.executableURL = URL(fileURLWithPath: executable)
        process.arguments = arguments
        process.standardOutput = outHandle
        process.standardError = errHandle

        let status: Int32 = try await withCheckedThrowingContinuation { continuation in
            process.terminationHandler = { continuation.resume(returning: $0.terminationStatus) }
            do {
                try process.run()
            } catch {
                continuation.resume(throwing: error)
            }
        }
        try outHandle.close()
        try errHandle.close()

        // Unreadable output must fail. An empty diff would select no tests.
        let output = try String(contentsOf: outURL, encoding: .utf8)
        guard status == 0 else {
            let errorText = (try? String(contentsOf: errURL, encoding: .utf8)) ?? ""
            let command = ([executable] + arguments).joined(separator: " ")
            throw SelectorError(description: "\(command) exit \(status): \(errorText.trimmingCharacters(in: .whitespacesAndNewlines))")
        }
        return output
    }

    // MARK: - Small helpers

    private static func fail(_ message: String) -> Never {
        FileHandle.standardError.write(Data("TestSelectorKit error: \(message)\n".utf8))
        exit(1)
    }
}
