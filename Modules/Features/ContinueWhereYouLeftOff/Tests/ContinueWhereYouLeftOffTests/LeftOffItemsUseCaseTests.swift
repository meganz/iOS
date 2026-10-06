import ContinueWhereYouLeftOff
import ContinueWhereYouLeftOffMock
import Foundation
import MEGADomain
import MEGADomainMock
import MEGASwift
import Testing

@Suite("LeftOffItemsUseCase")
struct LeftOffItemsUseCaseTests {

    // MARK: - Helpers

    private func makeSUT(
        stored: [LeftOffItemEntity] = [],
        fetchBatches: [[LeftOffItemEntity]] = [],
        nodes: [HandleEntity: NodeEntity] = [:],
        rootNode: NodeEntity? = NodeEntity(handle: 999),
        nodeUpdates: AnyAsyncSequence<[NodeEntity]> = EmptyAsyncSequence<[NodeEntity]>().eraseToAnyAsyncSequence(),
        repositoryChanges: AnyAsyncSequence<Void> = EmptyAsyncSequence<Void>().eraseToAnyAsyncSequence(),
        isNodeInRubbishBin: Bool = false,
        repositoryError: LeftOffItemErrorEntity? = nil,
        excludeSensitives: Bool = false,
        isAccessible: Bool = true,
        inheritedSensitivity: [HandleEntity: Result<Bool, any Error>] = [:],
        requestFinishUpdates: AnyAsyncSequence<RequestResponseEntity> = EmptyAsyncSequence<RequestResponseEntity>().eraseToAnyAsyncSequence()
    ) -> (LeftOffItemsUseCase, MockLeftOffItemsRepository) {
        let repository = MockLeftOffItemsRepository(fetchItemsResult: stored, errorToThrow: repositoryError)
        repository.fetchItemsBatches = fetchBatches
        repository.changesSignalSequenceResult = repositoryChanges
        let sut = LeftOffItemsUseCase(
            repository: repository,
            nodeUseCase: MockNodeUseCase(
                isNodeInRubbishBin: isNodeInRubbishBin,
                nodes: nodes,
                rootNode: rootNode,
                nodeUpdates: nodeUpdates
            ),
            sensitiveDisplayPreferenceUseCase: MockSensitiveDisplayPreferenceUseCase(excludeSensitives: excludeSensitives),
            sensitiveNodeUseCase: MockSensitiveNodeUseCase(
                isAccessible: isAccessible,
                isInheritingSensitivityResult: .success(false),
                isInheritingSensitivityResults: inheritedSensitivity
            ),
            requestStatesRepository: MockRequestStatesRepository(requestFinishUpdates: requestFinishUpdates)
        )
        return (sut, repository)
    }

    private func finiteSignal(count: Int) -> AnyAsyncSequence<Void> {
        AsyncStream<Void> { continuation in
            for _ in 0..<count { continuation.yield(()) }
            continuation.finish()
        }.eraseToAnyAsyncSequence()
    }

    private func item(_ handle: HandleEntity, name: String = "stored") -> LeftOffItemEntity {
        LeftOffItemEntity(handle: handle, name: name, lastAccessed: Date(timeIntervalSince1970: TimeInterval(handle)))
    }

    // MARK: - Read path

    @Test("items refreshes name and fills duration from the resolved node")
    func itemsRefreshesFromNode() async throws {
        let (sut, _) = makeSUT(
            stored: [item(1, name: "old name")],
            nodes: [1: NodeEntity(name: "new name.mp4", handle: 1, duration: 120)]
        )

        let result = try await sut.items(sortedBy: .lastAccessed, ascending: false)

        #expect(result.count == 1)
        #expect(result[0].item.name == "new name.mp4")
        #expect(result[0].node.duration == 120)
    }

    @Test("items keeps the stored name when the live node name is blank")
    func itemsKeepsStoredNameWhenLiveNameIsBlank() async throws {
        let (sut, _) = makeSUT(
            stored: [item(1, name: "stored name")],
            nodes: [1: NodeEntity(name: "", handle: 1)]
        )

        let result = try await sut.items(sortedBy: .lastAccessed, ascending: false)

        #expect(result[0].item.name == "stored name")
    }

    @Test("items requests the stored item cap from the repository")
    func itemsRequestsStoredItemCap() async throws {
        let (sut, repository) = makeSUT()

        _ = try await sut.items(sortedBy: .lastAccessed, ascending: false)

        #expect(repository.lastLimit == 50)
    }

    @Test("items sorted by name uses the refreshed node name")
    func itemsSortedByNameUsesRefreshedName() async throws {
        let (sut, _) = makeSUT(
            stored: [item(1, name: "a"), item(2, name: "b")],
            nodes: [1: NodeEntity(name: "z", handle: 1), 2: NodeEntity(name: "c", handle: 2)]
        )

        let result = try await sut.items(sortedBy: .name, ascending: true)

        #expect(result.map(\.item.name) == ["c", "z"])
    }

    @Test("items returns empty and never touches the store when the node tree is not loaded")
    func itemsReturnsEmptyWhenTreeNotLoaded() async throws {
        let (sut, repository) = makeSUT(
            stored: [item(1), item(2)],
            rootNode: nil
        )

        let result = try await sut.items(sortedBy: .lastAccessed, ascending: false)

        #expect(result.isEmpty)
        #expect(repository.fetchItemsCallCount == 0)
        #expect(repository.removedUnavailableHandles.isEmpty)
    }

    // MARK: - Pruning

    @Test("items drops and prunes a row whose node no longer resolves")
    func itemsPrunesDeadRows() async throws {
        let (sut, repository) = makeSUT(
            stored: [item(1), item(2)],
            nodes: [1: NodeEntity(handle: 1)]
        )

        let result = try await sut.items(sortedBy: .lastAccessed, ascending: false)

        #expect(result.map(\.item.handle) == [1])
        #expect(repository.removedUnavailableHandles == [2])
    }

    @Test("items prunes every row when no node resolves at all")
    func itemsPrunesAllWhenNoNodeResolves() async throws {
        let (sut, repository) = makeSUT(stored: [item(1), item(2)])

        let result = try await sut.items(sortedBy: .lastAccessed, ascending: false)

        #expect(result.isEmpty)
        #expect(repository.removedUnavailableHandles == [1, 2])
    }

    @Test("items drops and prunes a row whose node is in the rubbish bin")
    func itemsPrunesRubbishBinRows() async throws {
        let (sut, repository) = makeSUT(
            stored: [item(1)],
            nodes: [1: NodeEntity(handle: 1), 2: NodeEntity(handle: 2)],
            isNodeInRubbishBin: true
        )

        let result = try await sut.items(sortedBy: .lastAccessed, ascending: false)

        #expect(result.isEmpty)
        #expect(repository.removedUnavailableHandles == [1])
    }

    // MARK: - Sensitivity

    @Test("items drops and prunes a marked-sensitive node when the preference is on")
    func itemsExcludesMarkedSensitive() async throws {
        let (sut, repository) = makeSUT(
            stored: [item(1), item(2)],
            nodes: [1: NodeEntity(handle: 1, isMarkedSensitive: true), 2: NodeEntity(handle: 2)],
            excludeSensitives: true
        )

        let result = try await sut.items(sortedBy: .lastAccessed, ascending: false)

        #expect(result.map(\.item.handle) == [2])
        #expect(repository.removedUnavailableHandles == [1])
    }

    @Test("items excludes an inherited-sensitive node when the preference is on")
    func itemsExcludesInheritedSensitive() async throws {
        let (sut, _) = makeSUT(
            stored: [item(1)],
            nodes: [1: NodeEntity(handle: 1, isMarkedSensitive: false)],
            excludeSensitives: true,
            inheritedSensitivity: [1: .success(true)]
        )

        let result = try await sut.items(sortedBy: .lastAccessed, ascending: false)

        #expect(result.isEmpty)
    }

    @Test("items keeps and flags sensitive nodes when the preference is off")
    func itemsKeepsSensitiveWhenPreferenceOff() async throws {
        let (sut, repository) = makeSUT(
            stored: [item(1)],
            nodes: [1: NodeEntity(handle: 1, isMarkedSensitive: true)],
            excludeSensitives: false
        )

        let result = try await sut.items(sortedBy: .lastAccessed, ascending: false)

        #expect(result.map(\.item.handle) == [1])
        #expect(result[0].isSensitive)
        #expect(repository.removedUnavailableHandles.isEmpty)
    }

    @Test("items does not flag sensitivity when hidden nodes are not accessible")
    func itemsIgnoresSensitivityWhenNotAccessible() async throws {
        let (sut, _) = makeSUT(
            stored: [item(1)],
            nodes: [1: NodeEntity(handle: 1, isMarkedSensitive: true)],
            excludeSensitives: true,
            isAccessible: false
        )

        let result = try await sut.items(sortedBy: .lastAccessed, ascending: false)

        #expect(result.map(\.item.handle) == [1])
        #expect(result[0].isSensitive == false)
    }

    @Test("items keeps a node whose inherited sensitivity check fails")
    func itemsKeepsNodeWhenInheritedSensitivityFails() async throws {
        let (sut, _) = makeSUT(
            stored: [item(1)],
            nodes: [1: NodeEntity(handle: 1)],
            excludeSensitives: true,
            inheritedSensitivity: [1: .failure(GenericErrorEntity())]
        )

        let result = try await sut.items(sortedBy: .lastAccessed, ascending: false)

        #expect(result.map(\.item.handle) == [1])
        #expect(result[0].isSensitive == false)
    }

    // MARK: - topItems

    @Test("topItems pushes the limit down to the repository")
    func topItemsPushesLimitDown() async throws {
        let (sut, repository) = makeSUT(
            stored: [item(1), item(2)],
            nodes: [1: NodeEntity(handle: 1), 2: NodeEntity(handle: 2)]
        )

        _ = try await sut.topItems(limit: 9)

        #expect(repository.lastLimit == 9)
        #expect(repository.lastSortKey == .lastAccessed)
        #expect(repository.lastAscending == false)
    }

    @Test("topItems refetches after pruning until the limit is filled")
    func topItemsRefetchesUntilLimitFilled() async throws {
        let (sut, repository) = makeSUT(
            fetchBatches: [
                [item(1), item(2)],
                [item(1), item(3)]
            ],
            nodes: [1: NodeEntity(handle: 1), 3: NodeEntity(handle: 3)]
        )

        let result = try await sut.topItems(limit: 2)

        #expect(result.map(\.item.handle) == [1, 3])
        #expect(repository.fetchItemsCallCount == 2)
    }

    @Test("topItems stops after one fetch when the store holds fewer than the limit")
    func topItemsStopsWhenStoreExhausted() async throws {
        let (sut, repository) = makeSUT(
            fetchBatches: [[item(1), item(2)]],
            nodes: [1: NodeEntity(handle: 1)]
        )

        let result = try await sut.topItems(limit: 5)

        #expect(result.map(\.item.handle) == [1])
        #expect(repository.fetchItemsCallCount == 1)
    }

    @Test("topItems stops after one fetch when nothing is pruned")
    func topItemsStopsWhenNothingPruned() async throws {
        let (sut, repository) = makeSUT(
            fetchBatches: [[item(1), item(2)]],
            nodes: [1: NodeEntity(handle: 1), 2: NodeEntity(handle: 2)]
        )

        let result = try await sut.topItems(limit: 2)

        #expect(result.map(\.item.handle) == [1, 2])
        #expect(repository.fetchItemsCallCount == 1)
    }

    @Test("topItems stops at the attempt cap when every fetch still prunes")
    func topItemsStopsAtAttemptCap() async throws {
        let (sut, repository) = makeSUT(
            stored: [item(1), item(2)],
            nodes: [1: NodeEntity(handle: 1)]
        )

        let result = try await sut.topItems(limit: 2)

        #expect(result.map(\.item.handle) == [1])
        #expect(repository.fetchItemsCallCount == 5)
    }

    @Test("topItems returns nothing for a non-positive limit")
    func topItemsRejectsNonPositiveLimit() async throws {
        let (sut, repository) = makeSUT(stored: [item(1)])

        let result = try await sut.topItems(limit: 0)

        #expect(result.isEmpty)
        #expect(repository.lastLimit == nil)
    }

    @Test("items propagates a repository error")
    func itemsPropagatesRepositoryError() async {
        let (sut, _) = makeSUT(repositoryError: .persistenceFailure)

        await #expect(throws: LeftOffItemErrorEntity.persistenceFailure) {
            try await sut.items(sortedBy: .lastAccessed, ascending: false)
        }
    }

    // MARK: - Change signal

    @Test("changesSignalSequence emits a tick for each node update")
    func changesSignalSequenceTicks() async {
        let updates = AsyncStream<[NodeEntity]> { continuation in
            continuation.yield([NodeEntity(handle: 1)])
            continuation.yield([NodeEntity(handle: 2)])
            continuation.finish()
        }.eraseToAnyAsyncSequence()
        let (sut, _) = makeSUT(nodeUpdates: updates)

        var ticks = 0
        for await _ in sut.changesSignalSequence() {
            ticks += 1
        }

        #expect(ticks == 2)
    }

    @Test("changesSignalSequence emits a tick for each store change")
    func changesSignalSequenceTicksOnStoreChanges() async {
        let (sut, _) = makeSUT(repositoryChanges: finiteSignal(count: 3))

        var ticks = 0
        for await _ in sut.changesSignalSequence() {
            ticks += 1
        }

        #expect(ticks == 3)
    }

    /// Both arms are finite on purpose: the merged sequence only finishes once every base finishes.
    @Test("changesSignalSequence merges store changes with node updates")
    func changesSignalSequenceMergesBothSources() async {
        let updates = AsyncStream<[NodeEntity]> { continuation in
            continuation.yield([NodeEntity(handle: 1)])
            continuation.yield([NodeEntity(handle: 2)])
            continuation.finish()
        }.eraseToAnyAsyncSequence()
        let (sut, _) = makeSUT(nodeUpdates: updates, repositoryChanges: finiteSignal(count: 3))

        var ticks = 0
        for await _ in sut.changesSignalSequence() {
            ticks += 1
        }

        #expect(ticks == 5)
    }

    @Test("changesSignalSequence emits a tick only for a successful fetch nodes completion")
    func changesSignalSequenceTicksOnFetchNodesCompletion() async {
        let finished = [
            RequestResponseEntity(requestEntity: .init(type: .fetchNodes), error: .init(type: .ok)),
            RequestResponseEntity(requestEntity: .init(type: .login), error: .init(type: .ok)),
            RequestResponseEntity(requestEntity: .init(type: .fetchNodes), error: .init(type: .badArguments))
        ]
        let (sut, _) = makeSUT(requestFinishUpdates: finished.async.eraseToAnyAsyncSequence())

        var ticks = 0
        for await _ in sut.changesSignalSequence() {
            ticks += 1
        }

        #expect(ticks == 1)
    }

    @Test("items carries the resolved node")
    func itemsCarriesResolvedNode() async throws {
        let (sut, _) = makeSUT(
            stored: [item(1)],
            nodes: [1: NodeEntity(name: "clip.mp4", handle: 1, hasThumbnail: true)]
        )

        let result = try await sut.items(sortedBy: .lastAccessed, ascending: false)

        #expect(result.first?.node.handle == 1)
        #expect(result.first?.node.hasThumbnail == true)
    }

    // MARK: - Writes

    @Test("record forwards to the repository")
    func recordForwards() async throws {
        let (sut, repository) = makeSUT()
        let recorded = item(7)

        try await sut.record(recorded)

        #expect(repository.recordedItems == [recorded])
    }

    @Test("remove forwards to the repository")
    func removeForwards() async throws {
        let (sut, repository) = makeSUT()
        let removed = [item(1), item(2)]

        try await sut.remove(removed)

        #expect(repository.removedItems == [removed])
    }

    @Test("removeUnavailable forwards to the repository")
    func removeUnavailableForwards() async throws {
        let (sut, repository) = makeSUT()

        try await sut.removeUnavailable(item(9))

        #expect(repository.removedUnavailableHandles == [9])
    }

    @Test("clearHistory forwards to the repository")
    func clearHistoryForwards() async throws {
        let (sut, repository) = makeSUT()

        try await sut.clearHistory()

        #expect(repository.clearHistoryCallCount == 1)
    }
}
