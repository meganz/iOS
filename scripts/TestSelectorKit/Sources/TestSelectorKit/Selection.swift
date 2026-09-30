import Foundation

// MARK: - Models

/// One Swift package, with repo-relative paths.
struct PackageInfo: Equatable, Sendable {
    let path: String
    let localDependencyPaths: [String]
    let regularTargets: [String]
}

struct SelectorError: Error, CustomStringConvertible {
    let description: String
}

enum Selection: Equatable, Sendable {
    case all(reason: String, coverage: [String])
    case none
    case targets(tests: [String], coverage: [String], packages: [String])
}

/// The selection logic. No git and no file system, so unit tests cover it.
enum TestSelection {
    // MARK: - Global files

    /// A change to one of these files runs the full suite.
    private static let globalPathPrefixes = [
        "iMEGA.xcworkspace/",
        "jenkinsfile/",
        "scripts/TestSelectorKit/"
    ]

    private static let globalExactPaths: Set<String> = [
        "fastlane/Fastfile",
        "MEGAModulesTests/MEGAModulesTests.xctestplan",
        "MEGA.xcodeproj/xcshareddata/xcschemes/MEGAModulesTests.xcscheme",
        ".gitmodules"
    ]

    /// The first global file in path-sorted order, so the reason is stable.
    static func firstGlobalFile(in changedFiles: [String]) -> String? {
        changedFiles.sorted().first { file in
            globalExactPaths.contains(file) || globalPathPrefixes.contains { file.hasPrefix($0) }
        }
    }

    // MARK: - Package graph

    /// Drops a package when another package in the list is its parent folder.
    static func topLevelPackagePaths(_ paths: [String]) -> [String] {
        paths.filter { path in
            !paths.contains { other in other != path && path.hasPrefix(other + "/") }
        }
    }

    /// The nearest package folder that holds the file. A path equal to a package folder counts too.
    static func ownerPackage(of file: String, packagePaths: [String]) -> String? {
        packagePaths
            .filter { file == $0 || file.hasPrefix($0 + "/") }
            .max { $0.count < $1.count }
    }

    /// Some Package.swift files use another letter case than the folder (for example `MEGASdk`).
    static func resolveDependency(_ dependencyPath: String, packagePaths: [String]) -> String? {
        let lowercased = dependencyPath.lowercased()
        return packagePaths.first { $0.lowercased() == lowercased }
    }

    /// Changed packages plus every package that depends on them, direct or indirect.
    static func affectedPackages(changed: [String], packages: [PackageInfo]) -> [String] {
        let packagePaths = packages.map(\.path)
        var dependents: [String: [String]] = [:]
        for package in packages {
            for dependency in package.localDependencyPaths {
                guard let resolved = resolveDependency(dependency, packagePaths: packagePaths) else { continue }
                dependents[resolved, default: []].append(package.path)
            }
        }

        var visited = Set<String>()
        var queue = changed
        while let current = queue.popLast() {
            guard visited.insert(current).inserted else { continue }
            queue.append(contentsOf: dependents[current] ?? [])
        }
        return visited.sorted()
    }

    // MARK: - Test plan

    private struct TestPlan: Decodable {
        struct Entry: Decodable {
            struct Target: Decodable {
                let containerPath: String
                let name: String
            }

            let enabled: Bool?
            let target: Target
        }

        let testTargets: [Entry]
    }

    /// Package path -> enabled test target names.
    static func testTargets(fromTestPlan data: Data) throws -> [String: [String]] {
        let plan = try JSONDecoder().decode(TestPlan.self, from: data)
        var result: [String: [String]] = [:]
        for entry in plan.testTargets where entry.enabled != false {
            let path = entry.target.containerPath.replacingOccurrences(of: "container:", with: "")
            result[path, default: []].append(entry.target.name)
        }
        return result
    }

    // MARK: - Package dump

    /// Reads the output of `swift package dump-package`. Keeps local dependencies and regular targets.
    static func packageInfo(fromDumpPackage data: Data, path: String, repoRoot: String) throws -> PackageInfo {
        guard let object = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw SelectorError(description: "dump-package \(path) gave no JSON object")
        }
        let dependencies = object["dependencies"] as? [[String: Any]] ?? []
        let localPaths = dependencies.compactMap { dependency -> String? in
            guard let fileSystem = dependency["fileSystem"] as? [[String: Any]],
                  let absolute = fileSystem.first?["path"] as? String else { return nil }
            return relativePath(standardPath(absolute), repoRoot: repoRoot)
        }
        let targets = object["targets"] as? [[String: Any]] ?? []
        let regularTargets = targets.compactMap { target -> String? in
            guard target["type"] as? String == "regular" else { return nil }
            return target["name"] as? String
        }
        return PackageInfo(path: path, localDependencyPaths: localPaths, regularTargets: regularTargets)
    }

    /// "<package> -> <dependency>" for each local dependency that is not in the package list.
    static func missingDependencies(_ packages: [PackageInfo]) -> [String] {
        let packagePaths = packages.map(\.path)
        return packages.flatMap { package in
            package.localDependencyPaths
                .filter { resolveDependency($0, packagePaths: packagePaths) == nil }
                .map { "\(package.path) -> \($0)" }
        }
    }

    // MARK: - Git helpers

    static func diffArguments(from: String, to: String) -> [String] {
        ["diff", "--no-renames", "--name-only", from, to]
    }

    /// ls-tree prints "160000 commit <sha>\t<path>". Any other line has no gitlink.
    static func gitlinkSha(fromLsTree text: String) -> String? {
        let fields = text.split { $0 == " " || $0 == "\t" }
        guard fields.count >= 3, fields[1] == "commit" else { return nil }
        return String(fields[2])
    }

    /// Inner submodule paths as repo paths. The caller keeps the gitlink path itself.
    static func submoduleFiles(submodulePath: String, innerFiles: [String]) -> [String] {
        innerFiles.map { submodulePath + "/" + $0 }
    }

    // MARK: - Selection

    static func select(changedFiles: [String], packages: [PackageInfo], testPlan: [String: [String]]) -> Selection {
        if let globalFile = firstGlobalFile(in: changedFiles) {
            return .all(reason: "global file \(globalFile)", coverage: coverageTargets(of: packages))
        }
        return packageSelection(changedFiles: changedFiles, packages: packages, testPlan: testPlan)
    }

    /// The same as `select` without the global file check.
    static func packageSelection(changedFiles: [String], packages: [PackageInfo], testPlan: [String: [String]]) -> Selection {
        let packagePaths = packages.map(\.path)
        let changed = Set(changedFiles.compactMap { ownerPackage(of: $0, packagePaths: packagePaths) }).sorted()
        guard !changed.isEmpty else { return .none }

        let affected = affectedPackages(changed: changed, packages: packages)
        let tests = Set(affected.flatMap { testPlan[$0] ?? [] }).sorted()
        guard !tests.isEmpty else { return .none }

        let affectedSet = Set(affected)
        let coverage = coverageTargets(of: packages.filter { affectedSet.contains($0.path) })
        return .targets(tests: tests, coverage: coverage, packages: changed)
    }

    /// Regular targets of the packages without mock targets. Mocks are test helpers, not app code.
    static func coverageTargets(of packages: [PackageInfo]) -> [String] {
        Set(packages.flatMap(\.regularTargets))
            .filter { !$0.hasSuffix("Mock") && !$0.hasSuffix("Mocks") }
            .sorted()
    }

    /// Line 1: ALL, NONE or test targets. Line 2: coverage targets. Line 3: reason.
    static func outputText(_ selection: Selection) -> String {
        let lines = switch selection {
        case .all(let reason, let coverage):
            ["ALL", coverage.joined(separator: ","), reason]
        case .none:
            ["NONE", "", "no package change"]
        case .targets(let tests, let coverage, let packages):
            [tests.joined(separator: ","), coverage.joined(separator: ","), "packages: " + packages.joined(separator: ",")]
        }
        return lines.joined(separator: "\n") + "\n"
    }

    // MARK: - Small helpers

    /// Pairs of "--name value". A last name without a value is ignored.
    static func parseArguments(_ arguments: [String]) -> [String: String] {
        var result: [String: String] = [:]
        var index = 0
        while index + 1 < arguments.count {
            result[arguments[index]] = arguments[index + 1]
            index += 2
        }
        return result
    }

    static func standardPath(_ path: String) -> String {
        URL(fileURLWithPath: path).standardizedFileURL.resolvingSymlinksInPath().path
    }

    /// A path under the repo root without the root. Any other path stays absolute.
    static func relativePath(_ path: String, repoRoot: String) -> String {
        let resolved = standardPath(path)
        guard resolved.hasPrefix(repoRoot + "/") else { return resolved }
        return String(resolved.dropFirst(repoRoot.count + 1))
    }

    static func nonEmptyLines(_ text: String) -> [String] {
        text.split(separator: "\n").map(String.init).filter { !$0.isEmpty }
    }
}
