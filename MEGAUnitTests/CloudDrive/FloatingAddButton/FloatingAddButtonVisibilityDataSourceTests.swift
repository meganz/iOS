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
        searchResultsViewStateProvider: MockSearchResultsViewStateProvider = MockSearchResultsViewStateProvider()
    ) async -> FloatingAddButtonVisibilityDataSource {
        FloatingAddButtonVisibilityDataSource(
            nodeSource: .node { parentNode },
            nodeBrowserConfig: makeBrowserConfig(displayMode: displayMode, isFromViewInFolder: isFromViewInFolder),
            nodeUpdatesProvider: nodeUpdatesProvider,
            nodeUseCase: MockNodeUseCase(nodeAccessLevel: { nodeAccessLevel }),
            searchResultsViewStateProvider: searchResultsViewStateProvider
        )
    }

    private static func makeSUT(
        parentNodeProvider: MockParentNodeProvider,
        nodeUpdatesProvider: some NodeUpdatesProviderProtocol = MockNodeUpdatesProvider(),
        searchResultsViewStateProvider: MockSearchResultsViewStateProvider
    ) async -> FloatingAddButtonVisibilityDataSource {
        FloatingAddButtonVisibilityDataSource(
            nodeSource: .node { parentNodeProvider.lookUpNode() },
            nodeBrowserConfig: makeBrowserConfig(displayMode: .cloudDrive, isFromViewInFolder: false),
            nodeUpdatesProvider: nodeUpdatesProvider,
            nodeUseCase: MockNodeUseCase(nodeAccessLevel: { .owner }),
            searchResultsViewStateProvider: searchResultsViewStateProvider
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
                    let searchResultsViewStateProvider = MockSearchResultsViewStateProvider()
                    let sut = await Test.makeSUT(
                        parentNode: nil,
                        displayMode: displayMode,
                        isFromViewInFolder: isFromViewInFolder,
                        nodeAccessLevel: nodeAccessLevel,
                        searchResultsViewStateProvider: searchResultsViewStateProvider
                    )

                    let collector = ResultCollector()
                    let task = Task {
                        for await val in sut.floatingButtonVisibility.prefix(1) {
                           await collector.collecValue(val)
                        }
                    }

                    searchResultsViewStateProvider.simulateEvent(false)
                    await task.value

                    #expect(await collector.results == [false])
                }
            }

            @Test("Non-nil parentNode with enabled inputs yields `[true]`",
                  arguments: TestInput.enabledNodeAccessLevels, TestInput.enabledDisplayModes)
            func nonNilParentNodeEnabled(nodeAccessLevel: NodeAccessTypeEntity, displayMode: DisplayMode) async {

                for isFromViewInFolder in TestInput.enabledIsFromViewInFolder {
                    let searchResultsViewStateProvider = MockSearchResultsViewStateProvider()
                    let sut = await Test.makeSUT(
                        parentNode: TestInput.parentNode,
                        displayMode: displayMode,
                        isFromViewInFolder: isFromViewInFolder,
                        nodeAccessLevel: nodeAccessLevel,
                        searchResultsViewStateProvider: searchResultsViewStateProvider
                    )

                    let collector = ResultCollector()
                    let task = Task {
                        for await val in sut.floatingButtonVisibility.prefix(1) {
                           await collector.collecValue(val)
                        }

                    }

                    searchResultsViewStateProvider.simulateEvent(false)

                    await task.value

                    #expect(await collector.results == [true])
                }
            }

            @Test("Non-nil parentNode with disabled access levels yields `[false]`",
                  arguments: TestInput.disabledNodeAccesslevels, TestInput.allDisplayModes)
            func nonNilParentNodeWithDisabledNodeAccessLevels(nodeAccessLevel: NodeAccessTypeEntity, displayMode: DisplayMode) async {
                for isFromViewInFolder in TestInput.allIsFromViewInFolder {
                    let searchResultsViewStateProvider = MockSearchResultsViewStateProvider()
                    let sut = await Test.makeSUT(
                        parentNode: TestInput.parentNode,
                        displayMode: displayMode,
                        isFromViewInFolder: isFromViewInFolder,
                        nodeAccessLevel: nodeAccessLevel,
                        searchResultsViewStateProvider: searchResultsViewStateProvider
                    )

                    let collector = ResultCollector()
                    let task = Task {
                        for await val in sut.floatingButtonVisibility.prefix(1) {
                           await collector.collecValue(val)
                        }
                    }

                    searchResultsViewStateProvider.simulateEvent(false)
                    await task.value

                    #expect(await collector.results == [false])
                }
            }

            @Test("Non-nil parentNode with disabled access display modes yields `[false]`",
                  arguments: TestInput.allNodeAccessLevels, TestInput.disabledDisplayModes)
            func nonNilParentNodeWithDisabledDisplayMode(nodeAccessLevel: NodeAccessTypeEntity, displayMode: DisplayMode) async {
                for isFromViewInFolder in TestInput.allIsFromViewInFolder {
                    let searchResultsViewStateProvider = MockSearchResultsViewStateProvider()
                    let sut = await Test.makeSUT(
                        parentNode: TestInput.parentNode,
                        displayMode: displayMode,
                        isFromViewInFolder: isFromViewInFolder,
                        nodeAccessLevel: nodeAccessLevel,
                        searchResultsViewStateProvider: searchResultsViewStateProvider
                    )
                    let collector = ResultCollector()
                    let task = Task {
                        for await val in sut.floatingButtonVisibility.prefix(1) {
                           await collector.collecValue(val)
                        }
                    }

                    searchResultsViewStateProvider.simulateEvent(false)
                    await task.value

                    #expect(await collector.results == [false])
                }
            }

            @Test("Non-nil parentNode with disabled isFromViewInFolder yields `[false]`",
                  arguments: TestInput.allNodeAccessLevels, TestInput.allDisplayModes)
            func nonNilParentNodeWithDisabledIsFromViewInFolder(nodeAccessLevel: NodeAccessTypeEntity, displayMode: DisplayMode) async {
                for isFromViewInFolder in TestInput.disabledIsFromViewInFolder {
                    let searchResultsViewStateProvider = MockSearchResultsViewStateProvider()
                    let sut = await Test.makeSUT(
                        parentNode: TestInput.parentNode,
                        displayMode: displayMode,
                        isFromViewInFolder: isFromViewInFolder,
                        nodeAccessLevel: nodeAccessLevel,
                        searchResultsViewStateProvider: searchResultsViewStateProvider
                    )
                    let collector = ResultCollector()
                    let task = Task {
                        for await val in sut.floatingButtonVisibility.prefix(1) {
                           await collector.collecValue(val)
                        }
                    }

                    searchResultsViewStateProvider.simulateEvent(false)
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
                let searchResultsViewStateProvider = MockSearchResultsViewStateProvider()

                let collector = ResultCollector()

                var nodeAccessLevelCalls = 0
                let nodeUseCase = MockNodeUseCase(nodeAccessLevel: {
                    defer {
                        nodeAccessLevelCalls += 1
                    }
                    return nodeAccessLevelCalls % 2 == 0 ? .read : .full
                })
                let sut = FloatingAddButtonVisibilityDataSource(
                    nodeSource: .node { TestInput.parentNode },
                    nodeBrowserConfig: browserConfig,
                    nodeUpdatesProvider: nodeUpdatesProvider,
                    nodeUseCase: nodeUseCase,
                    searchResultsViewStateProvider: searchResultsViewStateProvider
                )

                let nodeUpdateTask = Task(priority: .high) { @Sendable in
                    for await val in sut.floatingButtonVisibility.prefix(1 + nodeUpdateSequence.count) {
                        await collector.collecValue(val)
                    }
                }

                searchResultsViewStateProvider.simulateEvent(false)

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

    @Suite("Parent node unavailable when the data source is created", .serialized)
    struct LateParentNodeTests {
        @Test("Yields `true` once the list is populated after the parent node becomes available")
        func parentNodeAvailableOnListUpdate() async {
            let parentNodeProvider = MockParentNodeProvider()
            let searchResultsViewStateProvider = MockSearchResultsViewStateProvider()
            let sut = await Test.makeSUT(
                parentNodeProvider: parentNodeProvider,
                searchResultsViewStateProvider: searchResultsViewStateProvider
            )
            var iterator = sut.floatingButtonVisibility.makeAsyncIterator()

            searchResultsViewStateProvider.simulateEvent(true)
            #expect(await iterator.next() == false)

            parentNodeProvider.node = TestInput.parentNode
            searchResultsViewStateProvider.simulateEvent(false)
            #expect(await iterator.next() == true)
        }

        @Test("Yields `true` once the parent node becomes available and is updated")
        func parentNodeAvailableOnNodeUpdate() async {
            let parentNodeProvider = MockParentNodeProvider()
            let nodeUpdatesProvider = ControllableMockNodeUpdatesProvider()
            let searchResultsViewStateProvider = MockSearchResultsViewStateProvider()
            let sut = await Test.makeSUT(
                parentNodeProvider: parentNodeProvider,
                nodeUpdatesProvider: nodeUpdatesProvider,
                searchResultsViewStateProvider: searchResultsViewStateProvider
            )
            var iterator = sut.floatingButtonVisibility.makeAsyncIterator()

            searchResultsViewStateProvider.simulateEvent(false)
            #expect(await iterator.next() == false)

            parentNodeProvider.node = TestInput.parentNode
            nodeUpdatesProvider.simulateEvent([TestInput.parentNode])
            #expect(await iterator.next() == true)
        }

        @Test("Looks up the parent node only until the first successful lookup")
        func parentNodeLookupIsCached() async {
            let parentNodeProvider = MockParentNodeProvider()
            let searchResultsViewStateProvider = MockSearchResultsViewStateProvider()
            let sut = await Test.makeSUT(
                parentNodeProvider: parentNodeProvider,
                searchResultsViewStateProvider: searchResultsViewStateProvider
            )
            var iterator = sut.floatingButtonVisibility.makeAsyncIterator()

            parentNodeProvider.node = TestInput.parentNode
            searchResultsViewStateProvider.simulateEvent(false)
            #expect(await iterator.next() == true)

            searchResultsViewStateProvider.simulateEvent(true)
            #expect(await iterator.next() == false)

            searchResultsViewStateProvider.simulateEvent(false)
            #expect(await iterator.next() == true)

            #expect(parentNodeProvider.lookupCount == 1)
        }
    }

    @Suite("Test emission of `floatingButtonVisibility` from node searchResultsViewStateProvider.emptyStateSequence", .serialized)
    struct EmptyStatesTests {
        @Test(
            "Changes of empty states should lead to new values of floatingButtonVisibility",
            .disabled("Disabled due to flakiness")
        )
        func emptyStateNodeUpdates() async {
            let searchResultsViewStateProvider = MockSearchResultsViewStateProvider()
            let sut = await Test.makeSUT(
                parentNode: TestInput.parentNode,
                displayMode: .cloudDrive,
                isFromViewInFolder: false,
                nodeAccessLevel: .full,
                searchResultsViewStateProvider: searchResultsViewStateProvider
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
                searchResultsViewStateProvider.simulateEvent(isEmpty)
                await Task.megaYield()
            }

            await nodeUpdateTask.value

            #expect(await collector.results == emptyStateValues.map { !$0 })
        }
    }
}

private class MockSearchResultsViewStateProvider: @unchecked Sendable, SearchResultsViewStateProviding {
    private let stream: AsyncStream<Bool>
    private let continuation: AsyncStream<Bool>.Continuation

    init() {
        (stream, continuation) = AsyncStream.makeStream(of: Bool.self, bufferingPolicy: .bufferingNewest(1))
    }

    var isEditingOrEmpty: AnyAsyncSequence<Bool> {
        stream.eraseToAnyAsyncSequence()
    }

    func simulateEvent(_ event: Bool) {
        continuation.yield(event)
    }
}

private final class MockParentNodeProvider: @unchecked Sendable {
    var node: NodeEntity?
    private(set) var lookupCount = 0

    func lookUpNode() -> NodeEntity? {
        lookupCount += 1
        return node
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
