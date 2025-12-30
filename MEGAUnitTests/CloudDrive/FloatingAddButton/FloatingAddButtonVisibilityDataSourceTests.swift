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

    actor ResultCollector {
        var results = [Bool]()
        func collecValue(_ value: Bool) {
            results.append(value)
        }
    }

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
        nodeUpdatesProvider: some NodeUpdatesProviderProtocol = MockNodeUpdatesProvider(),
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

    @Suite("Test emission of `floatingButtonVisibility` from node NodeUpdateProvider.nodeUpdates")
    struct NodeUpdatesTests {
        @Suite("Single emission of `floatingButtonVisibility`", .serialized)
        struct SingleValue {
            @Test("Nil parentNode always yields `[false]`",
                  arguments: TestInput.allNodeAccessLevels, TestInput.allDisplayModes)
            func nilParentNode(nodeAccessLevel: NodeAccessTypeEntity, displayMode: DisplayMode) async {
                for isFromViewInFolder in TestInput.allIsFromViewInFolder {
                    let sut = await Test.makeSUT(
                        parentNode: nil,
                        displayMode: displayMode,
                        isFromViewInFolder: isFromViewInFolder,
                        nodeAccessLevel: nodeAccessLevel
                    )

                    let collector = ResultCollector()
                    for await val in sut.floatingButtonVisibility {
                       await collector.collecValue(val)
                    }
                    #expect(await collector.results == [false])
                }
            }

            @Test("Non-nil parentNode with enabled inputs yields `[true]`",
                  arguments: TestInput.enabledNodeAccessLevels, TestInput.enabledDisplayModes)
            func nonNilParentNodeEnabled(nodeAccessLevel: NodeAccessTypeEntity, displayMode: DisplayMode) async {

                for isFromViewInFolder in TestInput.enabledIsFromViewInFolder {
                    let searchResultsEmptyStateProvider = MockSearchResultsEmptyStateProvider()
                    let sut = await Test.makeSUT(
                        parentNode: TestInput.parentNode,
                        displayMode: displayMode,
                        isFromViewInFolder: isFromViewInFolder,
                        nodeAccessLevel: nodeAccessLevel,
                        searchResultsEmptyStateProvider: searchResultsEmptyStateProvider
                    )

                    let collector = ResultCollector()
                    let task = Task {
                        for await val in sut.floatingButtonVisibility.prefix(1) {
                           await collector.collecValue(val)
                        }

                    }

                    searchResultsEmptyStateProvider.simulateEvent(false)

                    await task.value

                    #expect(await collector.results == [true])
                }
            }

            @Test("Non-nil parentNode with disabled access levels yields `[false]`",
                  arguments: TestInput.disabledNodeAccesslevels, TestInput.allDisplayModes)
            func nonNilParentNodeWithDisabledNodeAccessLevels(nodeAccessLevel: NodeAccessTypeEntity, displayMode: DisplayMode) async {
                for isFromViewInFolder in TestInput.allIsFromViewInFolder {
                    let searchResultsEmptyStateProvider = MockSearchResultsEmptyStateProvider()
                    let sut = await Test.makeSUT(
                        parentNode: TestInput.parentNode,
                        displayMode: displayMode,
                        isFromViewInFolder: isFromViewInFolder,
                        nodeAccessLevel: nodeAccessLevel,
                        searchResultsEmptyStateProvider: searchResultsEmptyStateProvider
                    )

                    let collector = ResultCollector()
                    let task = Task {
                        for await val in sut.floatingButtonVisibility.prefix(1) {
                           await collector.collecValue(val)
                        }
                    }

                    searchResultsEmptyStateProvider.simulateEvent(false)
                    await task.value

                    #expect(await collector.results == [false])
                }
            }

            @Test("Non-nil parentNode with disabled access display modes yields `[false]`",
                  arguments: TestInput.allNodeAccessLevels, TestInput.disabledDisplayModes)
            func nonNilParentNodeWithDisabledDisplayMode(nodeAccessLevel: NodeAccessTypeEntity, displayMode: DisplayMode) async {
                for isFromViewInFolder in TestInput.allIsFromViewInFolder {
                    let searchResultsEmptyStateProvider = MockSearchResultsEmptyStateProvider()
                    let sut = await Test.makeSUT(
                        parentNode: TestInput.parentNode,
                        displayMode: displayMode,
                        isFromViewInFolder: isFromViewInFolder,
                        nodeAccessLevel: nodeAccessLevel,
                        searchResultsEmptyStateProvider: searchResultsEmptyStateProvider
                    )
                    let collector = ResultCollector()
                    let task = Task {
                        for await val in sut.floatingButtonVisibility.prefix(1) {
                           await collector.collecValue(val)
                        }
                    }

                    searchResultsEmptyStateProvider.simulateEvent(false)
                    await task.value

                    #expect(await collector.results == [false])
                }
            }

            @Test("Non-nil parentNode with disabled isFromViewInFolder yields `[false]`",
                  arguments: TestInput.allNodeAccessLevels, TestInput.allDisplayModes)
            func nonNilParentNodeWithDisabledIsFromViewInFolder(nodeAccessLevel: NodeAccessTypeEntity, displayMode: DisplayMode) async {
                for isFromViewInFolder in TestInput.disabledIsFromViewInFolder {
                    let searchResultsEmptyStateProvider = MockSearchResultsEmptyStateProvider()
                    let sut = await Test.makeSUT(
                        parentNode: TestInput.parentNode,
                        displayMode: displayMode,
                        isFromViewInFolder: isFromViewInFolder,
                        nodeAccessLevel: nodeAccessLevel,
                        searchResultsEmptyStateProvider: searchResultsEmptyStateProvider
                    )
                    let collector = ResultCollector()
                    let task = Task {
                        for await val in sut.floatingButtonVisibility.prefix(1) {
                           await collector.collecValue(val)
                        }
                    }

                    searchResultsEmptyStateProvider.simulateEvent(false)
                    await task.value

                    #expect(await collector.results == [false])
                }
            }
        }

        @Suite("Multiple emissions of `floatingButtonVisibility`", .serialized)
        struct MultipleValues {
            @Test("Multiple updates should toggle values", .disabled("Disabled due to flakiness"))
            func multipleNodesUpdates() async throws {
                let browserConfig = await Test.makeBrowserConfig(
                    displayMode: TestInput.enabledDisplayModes.randomElement()!,
                    isFromViewInFolder: TestInput.enabledIsFromViewInFolder.randomElement()!
                )
                let randomNodes = [UInt64.random(in: 1...100)].map { NodeEntity(handle: $0) } + [TestInput.parentNode]
                let nodeUpdateSequence = Array(repeating: randomNodes, count: 5)
                let nodeUpdatesProvider = ControllableMockNodeUpdatesProvider()
                let searchResultsEmptyStateProvider = MockSearchResultsEmptyStateProvider()

                let collector = ResultCollector()

                var nodeAccessLevelCalls = 0
                let nodeUseCase = MockNodeUseCase(nodeAccessLevel: {
                    defer {
                        nodeAccessLevelCalls += 1
                    }
                    return nodeAccessLevelCalls % 2 == 0 ? .read : .full
                })
                let sut = FloatingAddButtonVisibilityDataSource(
                    parentNode: TestInput.parentNode,
                    nodeBrowserConfig: browserConfig,
                    nodeUpdatesProvider: nodeUpdatesProvider,
                    nodeUseCase: nodeUseCase,
                    searchResultsEmptyStateProvider: searchResultsEmptyStateProvider
                )

                let nodeUpdateTask = Task(priority: .high) { @Sendable in
                    for await val in sut.floatingButtonVisibility.prefix(1 + nodeUpdateSequence.count) {
                        await collector.collecValue(val)
                    }
                }

                searchResultsEmptyStateProvider.simulateEvent(false)

                let simulateEventTask = Task(priority: .low) {
                    for nodeUpdate in nodeUpdateSequence {
                        nodeUpdatesProvider.simulateEvent(nodeUpdate)
                        try await Task.sleep(nanoseconds: 100_000_000)
                    }
                }

                _ = await (nodeUpdateTask.value, try simulateEventTask.value)

                #expect(await collector.results == [false, true, false, true, false, true])
            }
        }
    }

    @Suite("Test emission of `floatingButtonVisibility` from node searchResultsEmptyStateProvider.emptyStateSequence", .serialized)
    struct EmptyStatesTests {
        @Test("Changes of empty states should lead to new values of floatingButtonVisibility")
        func emptyStateNodeUpdates() async {
            let searchResultsEmptyStateProvider = MockSearchResultsEmptyStateProvider()
            let sut = await Test.makeSUT(
                parentNode: TestInput.parentNode,
                displayMode: .cloudDrive,
                isFromViewInFolder: false,
                nodeAccessLevel: .full,
                searchResultsEmptyStateProvider: searchResultsEmptyStateProvider
            )

            let emptyStateValues = [false, true, false, true, false]
            let collector = ResultCollector()
            let nodeUpdateTask = Task {
                for await val in sut.floatingButtonVisibility.prefix(emptyStateValues.count) {
                   await collector.collecValue(val)
                }
            }

            await Task.megaYield()

            for isEmpty in emptyStateValues {
                searchResultsEmptyStateProvider.simulateEvent(isEmpty)
                await Task.megaYield()
            }

            await nodeUpdateTask.value

            #expect(await collector.results == emptyStateValues.map { !$0 })
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

private struct ControllableMockNodeUpdatesProvider: NodeUpdatesProviderProtocol {
    private let stream: AsyncStream<[NodeEntity]>
    private let continuation: AsyncStream<[NodeEntity]>.Continuation

    init() {
        (stream, continuation) = AsyncStream.makeStream(of: [NodeEntity].self, bufferingPolicy: .bufferingNewest(1))
    }

    var nodeUpdates: AnyAsyncSequence<[NodeEntity]> {
        stream.eraseToAnyAsyncSequence()
    }

    func simulateEvent(_ event: [NodeEntity]) {
        continuation.yield(event)
    }
}
