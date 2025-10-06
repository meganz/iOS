import CloudDrive
@testable import MEGA
import MEGAAppSDKRepoMock
import MEGADomain
import MEGADomainMock
import Testing

@Suite("FloatingAddButtonVisibilityDataSourceTests")
struct FloatingAddButtonVisibilityDataSourceTests {
    enum TestInput {
        static let parentNode = NodeEntity(handle: 0)
        static let allNodeAccessLevels = NodeAccessTypeEntity.allCases

        static let enabledNodeAccessLevels: [NodeAccessTypeEntity] = [.readWrite, .full, .owner]
        static let disabledNodeAccesslevels = allNodeAccessLevels.filter { !enabledNodeAccessLevels.contains($0) }

        static let allIsFromViewInFolder = [false, true]
        static let enabledIsFromViewInFolder = [false]
        static let disabledIsFromViewInFolder = allIsFromViewInFolder.filter { !enabledIsFromViewInFolder.contains($0) }

        static let allDisplayModes = DisplayMode.allCases
        static let disabledDisplayModes: [DisplayMode] = [.rubbishBin, .backup]
        static let enabledDisplayModes = allDisplayModes.filter { !disabledDisplayModes.contains($0) }
    }

    // MARK: - Helpers

    private static func makeBrowserConfig(
        displayMode: DisplayMode,
        isFromViewInFolder: Bool
    ) -> NodeBrowserConfig {
        var config = NodeBrowserConfig.default
        config.displayMode = displayMode
        config.isFromViewInFolder = isFromViewInFolder
        return config
    }

    private static func makeSUT(
        parentNode: NodeEntity?,
        displayMode: DisplayMode,
        isFromViewInFolder: Bool,
        nodeAccessLevel: NodeAccessTypeEntity
    ) -> FloatingAddButtonVisibilityDataSource {
        let nodeUseCase = MockNodeUseCase(nodeAccessLevel: { nodeAccessLevel })
        return FloatingAddButtonVisibilityDataSource(
            parentNode: parentNode,
            nodeBrowserConfig: makeBrowserConfig(displayMode: displayMode, isFromViewInFolder: isFromViewInFolder),
            nodeUpdatesProvider: MockNodeUpdatesProvider(),
            nodeUseCase: nodeUseCase
        )
    }

    private static func collectOutputs(_ sut: FloatingAddButtonVisibilityDataSource) async -> [Bool] {
        var results = [Bool]()
        for await val in sut.floatingButtonVisibility {
            results.append(val)
        }
        return results
    }

    @Suite("Single emission of `floatingButtonVisibility`")
    struct SingleValue {
        typealias Test = FloatingAddButtonVisibilityDataSourceTests

        @Test("Nil parentNode always yields `[false]`",
              arguments: TestInput.allNodeAccessLevels, TestInput.allDisplayModes)
        func nilParentNode(nodeAccessLevel: NodeAccessTypeEntity, displayMode: DisplayMode) async {
            for isFromViewInFolder in TestInput.allIsFromViewInFolder {
                let sut = Test.makeSUT(parentNode: nil,
                                       displayMode: displayMode,
                                       isFromViewInFolder: isFromViewInFolder,
                                       nodeAccessLevel: nodeAccessLevel)
                #expect(await Test.collectOutputs(sut) == [false])
            }
        }

        @Test("Non-nil parentNode with enabled inputs yields `[true]`",
              arguments: TestInput.enabledNodeAccessLevels, TestInput.enabledDisplayModes)
        func nonNilParentNodeEnabled(nodeAccessLevel: NodeAccessTypeEntity, displayMode: DisplayMode) async {
            for isFromViewInFolder in TestInput.enabledIsFromViewInFolder {
                let sut = Test.makeSUT(parentNode: TestInput.parentNode,
                                       displayMode: displayMode,
                                       isFromViewInFolder: isFromViewInFolder,
                                       nodeAccessLevel: nodeAccessLevel)
                #expect(await Test.collectOutputs(sut) == [true])
            }
        }

        @Test("Non-nil parentNode with disabled access levels yields `[false]`",
              arguments: TestInput.disabledNodeAccesslevels, TestInput.allDisplayModes)
        func nonNilParentNodeWithDisabledNodeAccessLevels(nodeAccessLevel: NodeAccessTypeEntity, displayMode: DisplayMode) async {
            for isFromViewInFolder in TestInput.allIsFromViewInFolder {
                let sut = Test.makeSUT(parentNode: TestInput.parentNode,
                                       displayMode: displayMode,
                                       isFromViewInFolder: isFromViewInFolder,
                                       nodeAccessLevel: nodeAccessLevel)
                #expect(await Test.collectOutputs(sut) == [false])
            }
        }

        @Test("Non-nil parentNode with disabled access levels yields `[false]`",
              arguments: TestInput.allNodeAccessLevels, TestInput.disabledDisplayModes)
        func nonNilParentNodeWithDisabledDisplayMode(nodeAccessLevel: NodeAccessTypeEntity, displayMode: DisplayMode) async {
            for isFromViewInFolder in TestInput.allIsFromViewInFolder {
                let sut = Test.makeSUT(parentNode: TestInput.parentNode,
                                       displayMode: displayMode,
                                       isFromViewInFolder: isFromViewInFolder,
                                       nodeAccessLevel: nodeAccessLevel)
                #expect(await Test.collectOutputs(sut) == [false])
            }
        }

        @Test("Non-nil parentNode with disabled access levels yields `[false]`",
              arguments: TestInput.allNodeAccessLevels, TestInput.allDisplayModes)
        func nonNilParentNodeWithDisabledIsFromViewInFolder(nodeAccessLevel: NodeAccessTypeEntity, displayMode: DisplayMode) async {
            for isFromViewInFolder in TestInput.disabledIsFromViewInFolder {
                let sut = Test.makeSUT(parentNode: TestInput.parentNode,
                                       displayMode: displayMode,
                                       isFromViewInFolder: isFromViewInFolder,
                                       nodeAccessLevel: nodeAccessLevel)
                #expect(await Test.collectOutputs(sut) == [false])
            }
        }
    }

    @Suite("Single emissions of `floatingButtonVisibility`")
    struct MultipleValues {
        typealias Test = FloatingAddButtonVisibilityDataSourceTests

        @Test("Multiple updates should toggle values")
        func multipleNodesUpdates() async {
            let browserConfig = Test.makeBrowserConfig(
                displayMode: TestInput.enabledDisplayModes.randomElement()!,
                isFromViewInFolder: TestInput.enabledIsFromViewInFolder.randomElement()!
            )
            let randomNodes = [UInt64.random(in: 1...100)].map { NodeEntity(handle: $0) } + [TestInput.parentNode]
            let nodeUpdateSequence = Array(repeating: randomNodes, count: 5)
            let nodeUpdatesProvider = MockNodeUpdatesProvider(nodeUpdates: nodeUpdateSequence.async.eraseToAnyAsyncSequence())

            var results = [Bool]()
            let nodeUseCase = MockNodeUseCase(nodeAccessLevel: { results.count % 2 == 0 ? .full : .read })
            let sut = FloatingAddButtonVisibilityDataSource(
                parentNode: TestInput.parentNode,
                nodeBrowserConfig: browserConfig,
                nodeUpdatesProvider: nodeUpdatesProvider,
                nodeUseCase: nodeUseCase
            )

            for await val in sut.floatingButtonVisibility {
                results.append(val)
            }

            #expect(results == [true, false, true, false, true, false])
        }
    }
}
