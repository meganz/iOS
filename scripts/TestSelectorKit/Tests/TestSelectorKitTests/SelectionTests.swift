import Foundation
import Testing
@testable import TestSelectorKit

// MARK: - Fixtures

// Small graph with real repo paths.
// Home -> ViewedLinks -> MEGADomain, Search -> MEGASwift, Accounts -> MEGAPresentation -> ImpressionKit.
private enum Path {
    static let home = "Modules/Features/Home"
    static let viewedLinks = "Modules/Features/ViewedLinks"
    static let search = "Modules/Features/Search"
    static let accounts = "Modules/Features/Accounts"
    static let domain = "Modules/Domain/MEGADomain"
    static let presentation = "Modules/Presentation/MEGAPresentation"
    static let megaSwift = "Modules/MEGASharedRepo/MEGASwift"
    static let impressionKit = "Modules/MEGASharedRepo/ImpressionKit"
    static let sdk = "Modules/DataSource/MEGASDK"
    static let chatRepo = "Modules/Repository/ChatRepo"
    static let appSDKRepo = "Modules/Repository/MEGAAppSDKRepo"
    static let megaUI = "Modules/UI/MEGAUI"
    static let megaUIKit = "Modules/UI/MEGAUIKit"
    static let megaSwiftUI = "Modules/UI/MEGASwiftUI"
}

private let packages: [PackageInfo] = [
    PackageInfo(path: Path.home, localDependencyPaths: [Path.viewedLinks], regularTargets: ["Home"]),
    PackageInfo(path: Path.viewedLinks, localDependencyPaths: [Path.domain], regularTargets: ["ViewedLinks"]),
    PackageInfo(path: Path.search, localDependencyPaths: [Path.megaSwift], regularTargets: ["Search"]),
    PackageInfo(path: Path.accounts, localDependencyPaths: [Path.presentation], regularTargets: ["Accounts"]),
    PackageInfo(path: Path.domain, localDependencyPaths: [], regularTargets: ["MEGADomain"]),
    PackageInfo(path: Path.presentation, localDependencyPaths: [Path.impressionKit], regularTargets: ["MEGAPresentation"]),
    PackageInfo(path: Path.megaSwift, localDependencyPaths: [], regularTargets: ["MEGASwift"]),
    PackageInfo(path: Path.impressionKit, localDependencyPaths: [], regularTargets: ["ImpressionKit"]),
    // Real Package.swift files spell the SDK folder "MEGASdk" (ChatRepo/Package.swift:25).
    PackageInfo(path: Path.sdk, localDependencyPaths: [], regularTargets: ["MEGASDK"]),
    PackageInfo(path: Path.chatRepo, localDependencyPaths: ["Modules/DataSource/MEGASdk"], regularTargets: ["ChatRepo"]),
    PackageInfo(path: Path.appSDKRepo, localDependencyPaths: ["Modules/DataSource/MEGASdk"], regularTargets: ["MEGAAppSDKRepo"]),
    PackageInfo(path: Path.megaSwiftUI, localDependencyPaths: [Path.domain], regularTargets: ["MEGASwiftUI"])
]

private let packagePaths = packages.map(\.path)

// Same shape as MEGAModulesTests.xctestplan, with escaped slashes.
private let testPlanJSON = """
{
  "testTargets" : [
    {
      "parallelizable" : true,
      "target" : {
        "containerPath" : "container:Modules\\/Features\\/ViewedLinks",
        "identifier" : "ViewedLinksTests",
        "name" : "ViewedLinksTests"
      }
    },
    {
      "parallelizable" : true,
      "target" : {
        "containerPath" : "container:Modules\\/Features\\/Home",
        "identifier" : "HomeTests",
        "name" : "HomeTests"
      }
    },
    {
      "parallelizable" : true,
      "target" : {
        "containerPath" : "container:Modules\\/Features\\/Search",
        "identifier" : "SearchTests",
        "name" : "SearchTests"
      }
    },
    {
      "parallelizable" : true,
      "target" : {
        "containerPath" : "container:Modules\\/Features\\/Accounts",
        "identifier" : "AccountsTests",
        "name" : "AccountsTests"
      }
    },
    {
      "parallelizable" : true,
      "target" : {
        "containerPath" : "container:Modules\\/Domain\\/MEGADomain",
        "identifier" : "MEGADomainTests",
        "name" : "MEGADomainTests"
      }
    },
    {
      "parallelizable" : true,
      "target" : {
        "containerPath" : "container:Modules\\/Repository\\/ChatRepo",
        "identifier" : "ChatRepoTests",
        "name" : "ChatRepoTests"
      }
    },
    {
      "parallelizable" : true,
      "target" : {
        "containerPath" : "container:Modules\\/Repository\\/MEGAAppSDKRepo",
        "identifier" : "MEGAAppSDKRepoTests",
        "name" : "MEGAAppSDKRepoTests"
      }
    },
    {
      "enabled" : false,
      "parallelizable" : true,
      "target" : {
        "containerPath" : "container:Modules\\/UI\\/MEGASwiftUI",
        "identifier" : "MEGASwiftUITests",
        "name" : "MEGASwiftUITests"
      }
    }
  ]
}
"""

private func testPlan() throws -> [String: [String]] {
    try TestSelection.testTargets(fromTestPlan: Data(testPlanJSON.utf8))
}

private func selectedTests(_ selection: Selection) -> [String]? {
    guard case let .targets(tests, _, _) = selection else { return nil }
    return tests
}

private func selectedCoverage(_ selection: Selection) -> [String]? {
    guard case let .targets(_, coverage, _) = selection else { return nil }
    return coverage
}

private func allReason(_ selection: Selection) -> String? {
    guard case let .all(reason, _) = selection else { return nil }
    return reason
}

private func allCoverage(_ selection: Selection) -> [String]? {
    guard case let .all(_, coverage) = selection else { return nil }
    return coverage
}

private func isNone(_ selection: Selection) -> Bool {
    if case .none = selection { return true }
    return false
}

private func lines(_ text: String) -> [String] {
    var result = text.split(separator: "\n", omittingEmptySubsequences: false).map(String.init)
    if result.last == "" { result.removeLast() }
    return result
}

private let globalFiles = [
    "iMEGA.xcworkspace/xcshareddata/swiftpm/Package.resolved",
    "iMEGA.xcworkspace/contents.xcworkspacedata",
    "fastlane/Fastfile",
    "jenkinsfile/ios_build_status.groovy",
    "MEGAModulesTests/MEGAModulesTests.xctestplan",
    "MEGA.xcodeproj/xcshareddata/xcschemes/MEGAModulesTests.xcscheme",
    ".gitmodules",
    "scripts/TestSelectorKit/Sources/TestSelectorKit/Selection.swift"
]

// MARK: - AC1: only package X changed runs X and its dependents

@Suite("AC1 package X and dependents")
struct AC1Tests {
    @Test func ac1_viewedLinksChange_runsViewedLinksAndHomeTestsOnly() throws {
        let selection = TestSelection.select(
            changedFiles: ["Modules/Features/ViewedLinks/Sources/ViewedLinks/ViewedLinksView.swift"],
            packages: packages,
            testPlan: try testPlan()
        )
        #expect(Set(try #require(selectedTests(selection))) == ["HomeTests", "ViewedLinksTests"])
    }

    @Test func ac1_domainChange_runsDomainAndAllIndirectDependents() throws {
        let selection = TestSelection.select(
            changedFiles: ["Modules/Domain/MEGADomain/Sources/MEGADomain/NodeEntity.swift"],
            packages: packages,
            testPlan: try testPlan()
        )
        let tests = Set(try #require(selectedTests(selection)))
        #expect(tests == ["MEGADomainTests", "ViewedLinksTests", "HomeTests"])
    }

    @Test func ac1_searchChange_doesNotRunUnrelatedTests() throws {
        let selection = TestSelection.select(
            changedFiles: ["Modules/Features/Search/Sources/Search/SearchView.swift"],
            packages: packages,
            testPlan: try testPlan()
        )
        #expect(try #require(selectedTests(selection)) == ["SearchTests"])
    }

    @Test func ac1_movedFile_runsOldAndNewPackageTests() throws {
        // --no-renames gives a move as a delete path plus an add path.
        let selection = TestSelection.select(
            changedFiles: [
                "Modules/Features/Search/Sources/Search/Moved.swift",
                "Modules/Features/ViewedLinks/Sources/ViewedLinks/Moved.swift"
            ],
            packages: packages,
            testPlan: try testPlan()
        )
        #expect(Set(try #require(selectedTests(selection))) == ["HomeTests", "ViewedLinksTests", "SearchTests"])
    }

    @Test func ac1_outputLine1_isSortedCommaListOfSelectedTargets() throws {
        let selection = TestSelection.select(
            changedFiles: ["Modules/Features/ViewedLinks/Sources/ViewedLinks/ViewedLinksView.swift"],
            packages: packages,
            testPlan: try testPlan()
        )
        let output = lines(TestSelection.outputText(selection))
        #expect(output.count == 3)
        #expect(output.first == "HomeTests,ViewedLinksTests")
    }
}

// MARK: - AC2 + AC9: global files run the full suite

@Suite("AC2 AC9 global files")
struct AC2GlobalFileTests {
    @Test(arguments: globalFiles)
    func ac9_globalFile_selectsAllWithThatFile(path: String) throws {
        let selection = TestSelection.select(changedFiles: [path], packages: packages, testPlan: try testPlan())
        #expect(allReason(selection) == "global file \(path)")
    }

    @Test(arguments: globalFiles)
    func ac9_firstGlobalFile_findsEachGlobalPath(path: String) {
        #expect(TestSelection.firstGlobalFile(in: ["README.md", path]) == path)
    }

    @Test func ac2_globalFilePlusPackageFile_selectsAll() throws {
        let selection = TestSelection.select(
            changedFiles: ["Modules/Features/ViewedLinks/Sources/ViewedLinks/A.swift", "fastlane/Fastfile"],
            packages: packages,
            testPlan: try testPlan()
        )
        #expect(allReason(selection) == "global file fastlane/Fastfile")
    }

    @Test func ac2_fastfileAndJenkinsfileChanged_reasonIsFirstInSortedOrder() throws {
        let selection = TestSelection.select(
            changedFiles: ["jenkinsfile/ios_build_status.groovy", "fastlane/Fastfile"],
            packages: packages,
            testPlan: try testPlan()
        )
        #expect(allReason(selection) == "global file fastlane/Fastfile")
    }

    @Test func ac2_noGlobalFile_firstGlobalFileIsNil() {
        #expect(TestSelection.firstGlobalFile(in: ["README.md", "Modules/Features/Home/Sources/Home/A.swift"]) == nil)
    }

    @Test func ac2_outputText_allHasCoverageOnLine2AndReasonOnLine3() {
        let output = lines(TestSelection.outputText(.all(reason: "global file fastlane/Fastfile", coverage: ["Home", "MEGADomain"])))
        #expect(output == ["ALL", "Home,MEGADomain", "global file fastlane/Fastfile"])
    }

    @Test func ac4_globalFile_coverageHasEveryPackageTarget() throws {
        let selection = TestSelection.select(changedFiles: ["fastlane/Fastfile"], packages: packages, testPlan: try testPlan())
        let coverage = try #require(allCoverage(selection))
        #expect(coverage == [
            "Accounts", "ChatRepo", "Home", "ImpressionKit", "MEGAAppSDKRepo", "MEGADomain",
            "MEGAPresentation", "MEGASDK", "MEGASwift", "MEGASwiftUI", "Search", "ViewedLinks"
        ])
    }

    @Test func ac2_packageSelection_ignoresGlobalFiles() throws {
        // The selector logs this list for a global-file ALL.
        let selection = TestSelection.packageSelection(
            changedFiles: ["Modules/Features/ViewedLinks/Sources/ViewedLinks/A.swift", "fastlane/Fastfile"],
            packages: packages,
            testPlan: try testPlan()
        )
        #expect(Set(try #require(selectedTests(selection))) == ["HomeTests", "ViewedLinksTests"])
    }
}

// MARK: - AC3: no package change runs no package tests

@Suite("AC3 no package change")
struct AC3Tests {
    @Test func ac3_onlyAppAndReadmeChanged_selectsNone() throws {
        let selection = TestSelection.select(
            changedFiles: ["iMEGA/Main/MainTabBarController.swift", "README.md"],
            packages: packages,
            testPlan: try testPlan()
        )
        #expect(isNone(selection))
    }

    @Test func ac3_noChangedFiles_selectsNone() throws {
        #expect(isNone(TestSelection.select(changedFiles: [], packages: packages, testPlan: try testPlan())))
    }

    @Test func ac3_outputText_none() {
        #expect(lines(TestSelection.outputText(.none)) == ["NONE", "", "no package change"])
    }

    @Test func ac3_affectedPackagesWithNoTestTargets_selectsNone() throws {
        // ImpressionKit is changed but has no test plan entry. Its only dependents are also dropped here.
        let noTests: [PackageInfo] = [
            PackageInfo(path: Path.impressionKit, localDependencyPaths: [], regularTargets: ["ImpressionKit"])
        ]
        let selection = TestSelection.select(
            changedFiles: ["Modules/MEGASharedRepo/ImpressionKit/Sources/ImpressionKit/A.swift"],
            packages: noTests,
            testPlan: try testPlan()
        )
        #expect(isNone(selection))
    }
}

// MARK: - AC4: coverage for the targets that ran

@Suite("AC4 coverage targets")
struct AC4Tests {
    @Test func ac4_viewedLinksChange_coverageIsHomeAndViewedLinks() throws {
        let selection = TestSelection.select(
            changedFiles: ["Modules/Features/ViewedLinks/Sources/ViewedLinks/A.swift"],
            packages: packages,
            testPlan: try testPlan()
        )
        #expect(Set(try #require(selectedCoverage(selection))) == ["Home", "ViewedLinks"])
    }

    @Test func ac4_megaSwiftChange_coverageKeepsMEGASwiftAndSearch() throws {
        let selection = TestSelection.select(
            changedFiles: ["Modules/MEGASharedRepo/MEGASwift/Sources/MEGASwift/A.swift"],
            packages: packages,
            testPlan: try testPlan()
        )
        #expect(try #require(selectedCoverage(selection)) == ["MEGASwift", "Search"])
    }

    @Test func ac4_coverageTargets_dropsMockTargetsAndSorts() {
        let withMocks = [
            PackageInfo(path: "Modules/B", localDependencyPaths: [], regularTargets: ["B", "BMock"]),
            PackageInfo(path: "Modules/A", localDependencyPaths: [], regularTargets: ["A", "AMocks", "A"])
        ]
        #expect(TestSelection.coverageTargets(of: withMocks) == ["A", "B"])
    }

    @Test func ac4_outputLine2_isCoverageList() throws {
        let selection = TestSelection.select(
            changedFiles: ["Modules/Features/ViewedLinks/Sources/ViewedLinks/A.swift"],
            packages: packages,
            testPlan: try testPlan()
        )
        let output = lines(TestSelection.outputText(selection))
        #expect(output.count == 3)
        #expect(output[1] == "Home,ViewedLinks")
        #expect(output[2].hasPrefix("packages: "))
        #expect(output[2].contains(Path.viewedLinks))
    }
}

// MARK: - AC5 + AC6: graph from Package.swift files

@Suite("AC6 package graph")
struct AC6Tests {
    @Test func ac6_topLevelPackagePaths_dropsNestedSDKPackage() {
        let paths = [Path.sdk, "Modules/DataSource/MEGASDK/Sources/MEGASDK", Path.megaSwift, Path.home]
        let top = Set(TestSelection.topLevelPackagePaths(paths))
        #expect(top == [Path.sdk, Path.megaSwift, Path.home])
    }

    @Test func ac6_topLevelPackagePaths_keepsSiblingWithSharedPrefix() {
        // MEGAUI is not a folder parent of MEGAUIKit.
        #expect(Set(TestSelection.topLevelPackagePaths([Path.megaUI, Path.megaUIKit])) == [Path.megaUI, Path.megaUIKit])
    }

    @Test func ac6_resolveDependency_matchesWithoutCase() {
        #expect(TestSelection.resolveDependency("Modules/DataSource/MEGASdk", packagePaths: packagePaths) == Path.sdk)
    }

    @Test func ac6_resolveDependency_missingPackage_returnsNil() {
        // NodeBackgroundDownloader/Package.swift:21 points to this missing folder.
        #expect(TestSelection.resolveDependency("Modules/MEGASharedRepo/MEGARepo", packagePaths: packagePaths) == nil)
    }

    @Test func ac6_sdkChange_selectsDependentsDeclaredWithOtherCase() throws {
        let selection = TestSelection.select(
            changedFiles: ["Modules/DataSource/MEGASDK/Sources/MEGASDK/src/megaapi.cpp"],
            packages: packages,
            testPlan: try testPlan()
        )
        let tests = Set(try #require(selectedTests(selection)))
        #expect(tests.contains("ChatRepoTests"))
        #expect(tests.contains("MEGAAppSDKRepoTests"))
    }

    @Test func ac6_missingDependency_doesNotBreakSelection() throws {
        let withMissing = packages + [
            PackageInfo(
                path: "Modules/Features/NodeBackgroundDownloader",
                localDependencyPaths: ["Modules/MEGASharedRepo/MEGARepo"],
                regularTargets: ["NodeBackgroundDownloader"]
            )
        ]
        let selection = TestSelection.select(
            changedFiles: ["Modules/Features/Search/Sources/Search/A.swift"],
            packages: withMissing,
            testPlan: try testPlan()
        )
        #expect(try #require(selectedTests(selection)) == ["SearchTests"])
    }
}

// MARK: - AC5 + AC7: file to owning package

@Suite("AC7 owner package")
struct AC7Tests {
    @Test func ac7_nearestPackageOwnsFile() {
        let paths = [Path.sdk, "Modules/DataSource/MEGASDK/Sources/MEGASDK/examples/App"]
        let owner = TestSelection.ownerPackage(of: "Modules/DataSource/MEGASDK/Sources/MEGASDK/examples/App/main.swift", packagePaths: paths)
        #expect(owner == "Modules/DataSource/MEGASDK/Sources/MEGASDK/examples/App")
    }

    @Test func ac7_fileOutsidePackages_hasNoOwner() {
        #expect(TestSelection.ownerPackage(of: "iMEGA/AppDelegate.swift", packagePaths: packagePaths) == nil)
        #expect(TestSelection.ownerPackage(of: "README.md", packagePaths: packagePaths) == nil)
    }

    @Test func ac7_megaUIDoesNotOwnMEGAUIKitFile() {
        let owner = TestSelection.ownerPackage(
            of: "Modules/UI/MEGAUIKit/Sources/MEGAUIKit/A.swift",
            packagePaths: [Path.megaUI, Path.megaUIKit]
        )
        #expect(owner == Path.megaUIKit)
        #expect(TestSelection.ownerPackage(of: "Modules/UI/MEGAUIKit/A.swift", packagePaths: [Path.megaUI]) == nil)
    }

    @Test func ac7_pathEqualToPackage_isOwnedByThatPackage() {
        // A nested gitlink change shows as the package folder path itself.
        #expect(TestSelection.ownerPackage(of: Path.impressionKit, packagePaths: packagePaths) == Path.impressionKit)
    }

    @Test func ac7_sdkCppFile_mapsToSDKPackage() {
        let files = TestSelection.submoduleFiles(
            submodulePath: "Modules/DataSource/MEGASDK/Sources/MEGASDK",
            innerFiles: ["src/megaapi.cpp"]
        )
        let file = "Modules/DataSource/MEGASDK/Sources/MEGASDK/src/megaapi.cpp"
        #expect(files.contains(file))
        #expect(TestSelection.ownerPackage(of: file, packagePaths: packagePaths) == Path.sdk)
    }
}

// MARK: - AC5 + AC8: changed + direct and indirect dependents

@Suite("AC8 affected packages")
struct AC8Tests {
    @Test func ac8_directDependentIsAffected() {
        let affected = Set(TestSelection.affectedPackages(changed: [Path.viewedLinks], packages: packages))
        #expect(affected == [Path.viewedLinks, Path.home])
    }

    @Test func ac8_indirectDependentIsAffected() {
        let affected = Set(TestSelection.affectedPackages(changed: [Path.domain], packages: packages))
        #expect(affected.contains(Path.home))
        #expect(affected.contains(Path.viewedLinks))
        #expect(affected.contains(Path.megaSwiftUI))
    }

    @Test func ac8_unrelatedPackageIsNotAffected() {
        let affected = Set(TestSelection.affectedPackages(changed: [Path.domain], packages: packages))
        #expect(!affected.contains(Path.search))
        #expect(!affected.contains(Path.megaSwift))
        #expect(!affected.contains(Path.accounts))
    }

    @Test func ac8_cycleEnds() {
        let cycle = [
            PackageInfo(path: "Modules/A", localDependencyPaths: ["Modules/B"], regularTargets: ["A"]),
            PackageInfo(path: "Modules/B", localDependencyPaths: ["Modules/A"], regularTargets: ["B"])
        ]
        #expect(Set(TestSelection.affectedPackages(changed: ["Modules/A"], packages: cycle)) == ["Modules/A", "Modules/B"])
    }
}

// MARK: - AC5: test plan parse

@Suite("AC5 test plan")
struct AC5TestPlanTests {
    @Test func ac5_testPlan_mapsPackagePathToTargets() throws {
        let plan = try testPlan()
        #expect(plan[Path.viewedLinks] == ["ViewedLinksTests"])
        #expect(plan[Path.home] == ["HomeTests"])
    }

    @Test func ac5_disabledTestPlanEntry_isNeverSelected() throws {
        let plan = try testPlan()
        #expect(plan.values.flatMap { $0 }.contains("MEGASwiftUITests") == false)

        // MEGASwiftUI depends on MEGADomain in the fixture.
        let selection = TestSelection.select(
            changedFiles: ["Modules/Domain/MEGADomain/Sources/MEGADomain/A.swift"],
            packages: packages,
            testPlan: plan
        )
        #expect(try #require(selectedTests(selection)).contains("MEGASwiftUITests") == false)
    }

    @Test func ac5_realTestPlan_hasEnabledTargetsOnly() throws {
        // #filePath is scripts/TestSelectorKit/Tests/TestSelectorKitTests/SelectionTests.swift.
        let repoRoot = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent().deletingLastPathComponent()
            .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
        let url = repoRoot.appendingPathComponent("MEGAModulesTests/MEGAModulesTests.xctestplan")
        let plan = try TestSelection.testTargets(fromTestPlan: try Data(contentsOf: url))
        let names = plan.values.flatMap { $0 }

        #expect(plan[Path.viewedLinks] == ["ViewedLinksTests"])
        #expect(names.contains("HomeTests"))
        #expect(!names.contains("MEGASwiftUITests"))
        #expect(!names.contains("MEGAUIKitTests"))
        #expect(plan.keys.allSatisfy { $0.hasPrefix("Modules/") })
    }
}

// MARK: - AC10: submodule inner diff

@Suite("AC10 submodules")
struct AC10Tests {
    @Test func ac10_diffArguments_useNoRenames() {
        let arguments = TestSelection.diffArguments(from: "abc", to: "def")
        #expect(arguments.first == "diff")
        #expect(arguments.contains("--no-renames"))
        #expect(arguments.contains("--name-only"))
        #expect(Array(arguments.suffix(2)) == ["abc", "def"])
    }

    @Test func ac10_submoduleFiles_prefixesInnerPaths() {
        let files = TestSelection.submoduleFiles(
            submodulePath: "Modules/MEGASharedRepo",
            innerFiles: ["MEGASwift/Sources/MEGASwift/A.swift", "README.md"]
        )
        #expect(files.contains("Modules/MEGASharedRepo/MEGASwift/Sources/MEGASwift/A.swift"))
        #expect(files.contains("Modules/MEGASharedRepo/README.md"))
        #expect(!files.contains("MEGASwift/Sources/MEGASwift/A.swift"))
    }

    @Test func ac10_sharedRepoInnerChange_selectsDependentPackageTests() throws {
        let files = TestSelection.submoduleFiles(
            submodulePath: "Modules/MEGASharedRepo",
            innerFiles: ["MEGASwift/Sources/MEGASwift/A.swift"]
        )
        let selection = TestSelection.select(changedFiles: files, packages: packages, testPlan: try testPlan())
        #expect(try #require(selectedTests(selection)) == ["SearchTests"])
    }

    @Test func ac10_nestedGitlinkInnerChange_selectsThatPackageDependents() throws {
        // A nested gitlink shows in the inner diff as one path: the package folder.
        let files = TestSelection.submoduleFiles(submodulePath: "Modules/MEGASharedRepo", innerFiles: ["ImpressionKit"])
        let selection = TestSelection.select(changedFiles: files, packages: packages, testPlan: try testPlan())
        #expect(try #require(selectedTests(selection)) == ["AccountsTests"])
    }

    @Test func ac10_nonPackageNestedGitlink_selectsNothing() throws {
        let files = TestSelection.submoduleFiles(submodulePath: "Modules/MEGASharedRepo", innerFiles: ["iosTransifex"])
        #expect(isNone(TestSelection.select(changedFiles: files, packages: packages, testPlan: try testPlan())))
    }
}

// MARK: - Executable helpers

@Suite("Executable helpers")
struct ExecutableHelperTests {
    private let repoRoot = "/repo"

    @Test func dumpPackage_keepsLocalDependenciesAndRegularTargets() throws {
        let json = """
        {
          "dependencies": [
            {"fileSystem": [{"path": "/repo/Modules/Domain/MEGADomain"}]},
            {"sourceControl": [{"identity": "mega-design-token"}]}
          ],
          "targets": [
            {"name": "ViewedLinks", "type": "regular"},
            {"name": "ViewedLinksTests", "type": "test"}
          ]
        }
        """
        let info = try TestSelection.packageInfo(fromDumpPackage: Data(json.utf8), path: Path.viewedLinks, repoRoot: repoRoot)
        #expect(info == PackageInfo(path: Path.viewedLinks, localDependencyPaths: [Path.domain], regularTargets: ["ViewedLinks"]))
    }

    @Test func dumpPackage_dependencyOutsideRepo_staysAbsolute() throws {
        let json = #"{"dependencies": [{"fileSystem": [{"path": "/other/Kit"}]}]}"#
        let info = try TestSelection.packageInfo(fromDumpPackage: Data(json.utf8), path: Path.home, repoRoot: repoRoot)
        #expect(info.localDependencyPaths == ["/other/Kit"])
        #expect(info.regularTargets.isEmpty)
    }

    @Test func dumpPackage_notAnObject_throws() {
        #expect(throws: SelectorError.self) {
            try TestSelection.packageInfo(fromDumpPackage: Data("[1]".utf8), path: Path.home, repoRoot: repoRoot)
        }
    }

    @Test func missingDependencies_listsOnlyUnknownPaths() {
        let list = [
            PackageInfo(path: Path.home, localDependencyPaths: [Path.viewedLinks, "Modules/Gone"], regularTargets: []),
            PackageInfo(path: Path.viewedLinks, localDependencyPaths: [], regularTargets: [])
        ]
        #expect(TestSelection.missingDependencies(list) == ["\(Path.home) -> Modules/Gone"])
    }

    @Test func gitlinkSha_readsShaFromCommitLine() {
        let line = "160000 commit 944d1e3abc\tModules/MEGASharedRepo"
        #expect(TestSelection.gitlinkSha(fromLsTree: line) == "944d1e3abc")
    }

    @Test func gitlinkSha_blobLineOrEmpty_isNil() {
        #expect(TestSelection.gitlinkSha(fromLsTree: "100644 blob abc\tREADME.md") == nil)
        #expect(TestSelection.gitlinkSha(fromLsTree: "") == nil)
    }

    @Test func parseArguments_readsPairsAndIgnoresLoneLastName() {
        let result = TestSelection.parseArguments(["--base", "origin/develop", "--output", "out.txt", "--repo-root"])
        #expect(result == ["--base": "origin/develop", "--output": "out.txt"])
    }

    @Test func relativePath_dropsRepoRootOnly() {
        #expect(TestSelection.relativePath("/repo/Modules/Features/Home", repoRoot: repoRoot) == Path.home)
        #expect(TestSelection.relativePath("/repository/Modules", repoRoot: repoRoot) == "/repository/Modules")
    }

    @Test func standardPath_removesDotSegments() {
        #expect(TestSelection.standardPath("/repo/Modules/./UI") == "/repo/Modules/UI")
    }

    @Test func nonEmptyLines_dropsEmptyLines() {
        #expect(TestSelection.nonEmptyLines("a\n\nb\n") == ["a", "b"])
    }
}
