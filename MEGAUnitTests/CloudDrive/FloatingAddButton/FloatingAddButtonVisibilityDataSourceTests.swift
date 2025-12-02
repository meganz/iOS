import CloudDrive
@testable import MEGA
import MEGAAppSDKRepo
import MEGAAppSDKRepoMock
import MEGADomain
import MEGADomainMock
import MEGASwift
import Testing

@Suite("FloatingAddButtonVisibilityDataSourceTests")
@MainActor
struct FloatingAddButtonVisibilityDataSourceTests {
    typealias Test = FloatingAddButtonVisibilityDataSourceTests
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
        nodeAccessLevel: NodeAccessTypeEntity,
        nodeUpdatesProvider: MockNodeUpdatesProvider = MockNodeUpdatesProvider(),
        searchResultsEmptyStateProvider: MockSearchResultsEmptyStateProvider = MockSearchResultsEmptyStateProvider()
    ) async -> FloatingAddButtonVisibilityDataSource {
        FloatingAddButtonVisibilityDataSource(
            parentNode: parentNode,
            nodeBrowserConfig: makeBrowserConfig(displayMode: displayMode, isFromViewInFolder: isFromViewInFolder),
            nodeUpdatesProvider: MockNodeUpdatesProvider(),
            nodeUseCase: MockNodeUseCase(nodeAccessLevel: { nodeAccessLevel }),
            searchResultsEmptyStateProvider: searchResultsEmptyStateProvider
        )
    }

    private static func collectOutputs(_ sut: FloatingAddButtonVisibilityDataSource) async -> [Bool] {
        var results = [Bool]()
        for await val in sut.floatingButtonVisibility {
            results.append(val)
        }
        return results
    }

    @Suite("Test emission of `floatingButtonVisibility` from node NodeUpdateProvider.nodeUpdates")
    struct NodeUpdatesTests {
        @Suite("Single emission of `floatingButtonVisibility`", .serialized)
        struct SingleValue {
            @Test("Nil parentNode always yields `[false]`",
                  arguments: TestInput.allNodeAccessLevels, TestInput.allDisplayModes)
            @MainActor func nilParentNode(nodeAccessLevel: NodeAccessTypeEntity, displayMode: DisplayMode) async {
                for isFromViewInFolder in TestInput.allIsFromViewInFolder {
                    let sut = await Test.makeSUT(
                        parentNode: nil,
                        displayMode: displayMode,
                        isFromViewInFolder: isFromViewInFolder,
                        nodeAccessLevel: nodeAccessLevel
                    )

                    var results = [Bool]()
                    for await val in sut.floatingButtonVisibility {
                        results.append(val)
                    }
                    #expect(results == [false])
                }
            }

            @Test("Non-nil parentNode with enabled inputs yields `[true]`",
                  arguments: TestInput.enabledNodeAccessLevels, TestInput.enabledDisplayModes)
            @MainActor func nonNilParentNodeEnabled(nodeAccessLevel: NodeAccessTypeEntity, displayMode: DisplayMode) async {

                for isFromViewInFolder in TestInput.enabledIsFromViewInFolder {
                    let searchResultsEmptyStateProvider = MockSearchResultsEmptyStateProvider()
                    let sut = await Test.makeSUT(
                        parentNode: TestInput.parentNode,
                        displayMode: displayMode,
                        isFromViewInFolder: isFromViewInFolder,
                        nodeAccessLevel: nodeAccessLevel,
                        searchResultsEmptyStateProvider: searchResultsEmptyStateProvider
                    )

                    var results = [Bool]()
                    let task = Task {
                        for await val in sut.floatingButtonVisibility.prefix(1) {
                            results.append(val)
                        }

                    }

                    searchResultsEmptyStateProvider.simulateEvent(false)

                    await task.value

                    #expect(results == [true])
                }
            }

            @Test("Non-nil parentNode with disabled access levels yields `[false]`",
                  arguments: TestInput.disabledNodeAccesslevels, TestInput.allDisplayModes)
            @MainActor func nonNilParentNodeWithDisabledNodeAccessLevels(nodeAccessLevel: NodeAccessTypeEntity, displayMode: DisplayMode) async {
                for isFromViewInFolder in TestInput.allIsFromViewInFolder {
                    let searchResultsEmptyStateProvider = MockSearchResultsEmptyStateProvider()
                    let sut = await Test.makeSUT(
                        parentNode: TestInput.parentNode,
                        displayMode: displayMode,
                        isFromViewInFolder: isFromViewInFolder,
                        nodeAccessLevel: nodeAccessLevel,
                        searchResultsEmptyStateProvider: searchResultsEmptyStateProvider
                    )

                    var results = [Bool]()
                    let task = Task {
                        for await val in sut.floatingButtonVisibility.prefix(1) {
                            results.append(val)
                        }
                    }

                    searchResultsEmptyStateProvider.simulateEvent(false)
                    await task.value

                    #expect(results == [false])
                }
            }

            @Test("Non-nil parentNode with disabled access display modes yields `[false]`",
                  arguments: TestInput.allNodeAccessLevels, TestInput.disabledDisplayModes)
            @MainActor func nonNilParentNodeWithDisabledDisplayMode(nodeAccessLevel: NodeAccessTypeEntity, displayMode: DisplayMode) async {
                for isFromViewInFolder in TestInput.allIsFromViewInFolder {
                    let searchResultsEmptyStateProvider = MockSearchResultsEmptyStateProvider()
                    let sut = await Test.makeSUT(
                        parentNode: TestInput.parentNode,
                        displayMode: displayMode,
                        isFromViewInFolder: isFromViewInFolder,
                        nodeAccessLevel: nodeAccessLevel,
                        searchResultsEmptyStateProvider: searchResultsEmptyStateProvider
                    )
                    var results = [Bool]()
                    let task = Task {
                        for await val in sut.floatingButtonVisibility.prefix(1) {
                            results.append(val)
                        }
                    }

                    searchResultsEmptyStateProvider.simulateEvent(false)
                    await task.value

                    #expect(results == [false])
                }
            }

            @Test("Non-nil parentNode with disabled isFromViewInFolder yields `[false]`",
                  arguments: TestInput.allNodeAccessLevels, TestInput.allDisplayModes)
            @MainActor func nonNilParentNodeWithDisabledIsFromViewInFolder(nodeAccessLevel: NodeAccessTypeEntity, displayMode: DisplayMode) async {
                for isFromViewInFolder in TestInput.disabledIsFromViewInFolder {
                    let searchResultsEmptyStateProvider = MockSearchResultsEmptyStateProvider()
                    let sut = await Test.makeSUT(
                        parentNode: TestInput.parentNode,
                        displayMode: displayMode,
                        isFromViewInFolder: isFromViewInFolder,
                        nodeAccessLevel: nodeAccessLevel,
                        searchResultsEmptyStateProvider: searchResultsEmptyStateProvider
                    )
                    var results = [Bool]()
                    let task = Task {
                        for await val in sut.floatingButtonVisibility.prefix(1) {
                            results.append(val)
                        }
                    }

                    searchResultsEmptyStateProvider.simulateEvent(false)
                    await task.value

                    #expect(results == [false])
                }
            }
        }

        @Suite("Multiple emissions of `floatingButtonVisibility`", .serialized)
        struct MultipleValues {
            @Test("Multiple updates should toggle values")
            @MainActor func multipleNodesUpdates() async {
                let browserConfig = Test.makeBrowserConfig(
                    displayMode: TestInput.enabledDisplayModes.randomElement()!,
                    isFromViewInFolder: TestInput.enabledIsFromViewInFolder.randomElement()!
                )
                let randomNodes = [UInt64.random(in: 1...100)].map { NodeEntity(handle: $0) } + [TestInput.parentNode]
                let nodeUpdateSequence = Array(repeating: randomNodes, count: 5)
                let nodeUpdatesProvider = MockNodeUpdatesProvider(nodeUpdates: nodeUpdateSequence.async.eraseToAnyAsyncSequence())
                let searchResultsEmptyStateProvider = MockSearchResultsEmptyStateProvider()
                var results = [Bool]()

                let nodeUseCase = MockNodeUseCase(nodeAccessLevel: { results.count % 2 == 0 ? .read : .full })
                let sut = FloatingAddButtonVisibilityDataSource(
                    parentNode: TestInput.parentNode,
                    nodeBrowserConfig: browserConfig,
                    nodeUpdatesProvider: nodeUpdatesProvider,
                    nodeUseCase: nodeUseCase,
                    searchResultsEmptyStateProvider: searchResultsEmptyStateProvider
                )

                let nodeUpdateTask = Task {
                    for await val in sut.floatingButtonVisibility.prefix(1 + nodeUpdateSequence.count) {
                        results.append(val)
                    }
                }

                searchResultsEmptyStateProvider.simulateEvent(false)
                await nodeUpdateTask.value

                #expect(results == [false, true, false, true, false, true])
            }
        }
    }

    @Suite("Test emission of `floatingButtonVisibility` from node searchResultsEmptyStateProvider.emptyStateSequence", .serialized)
    struct EmptyStatesTests {
        @Test("Changes of empty states should lead to new values of floatingButtonVisibility")
        @MainActor func multipleNodesUpdates() async {
            let searchResultsEmptyStateProvider = MockSearchResultsEmptyStateProvider()
            let sut = await Test.makeSUT(
                parentNode: TestInput.parentNode,
                displayMode: .cloudDrive,
                isFromViewInFolder: false,
                nodeAccessLevel: .full,
                searchResultsEmptyStateProvider: searchResultsEmptyStateProvider
            )

            let emptyStateValues = [false, true, false, true, false]
            var results = [Bool]()
            let nodeUpdateTask = Task {
                for await val in sut.floatingButtonVisibility.prefix(emptyStateValues.count) {
                    results.append(val)
                }
            }

            await Task.megaYield()

            for isEmpty in emptyStateValues {
                searchResultsEmptyStateProvider.simulateEvent(isEmpty)
                await Task.megaYield()
            }

            await nodeUpdateTask.value

            #expect(results == emptyStateValues.map { !$0 })
        }
    }
}

private class MockSearchResultsEmptyStateProvider: @unchecked Sendable, SearchResultsEmptyStateProviding {
    private let stream: AsyncStream<Bool>
    private let continuation: AsyncStream<Bool>.Continuation

    init() {
        (stream, continuation) = AsyncStream.makeStream(of: Bool.self, bufferingPolicy: .bufferingNewest(1))
    }

    var emptyStateSequence: AnyAsyncSequence<Bool> {
        stream.eraseToAnyAsyncSequence()
    }

    func simulateEvent(_ event: Bool) {
        continuation.yield(event)
    }
}
