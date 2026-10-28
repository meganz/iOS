import Foundation
@testable import Home
import MEGAAppPresentation
import MEGAAppPresentationMock
import MEGADomain
import MEGAL10n
import MEGASwift
import Search
import Testing

/// The navigation title of a Recents bucket follows the bucket updates (IOS-12087).
@Suite("RecentActionBucketItemsViewModel bucket updates Tests")
@MainActor
struct RecentActionBucketItemsBucketUpdatesTests {

    @Test("an available update with fewer nodes refreshes the title count")
    func availableUpdateRefreshesTitle() async {
        let sut = makeSUT(updates: [.available(makeBucket(nodeCount: 2))])

        await sut.monitorBucketUpdates()

        #expect(sut.navigationTitle == Strings.Localizable.General.Format.Count.file(2))
        #expect(sut.isBucketEmpty == false)
    }

    @Test("an available update with more nodes refreshes the title count")
    func availableUpdateWithMoreNodesRefreshesTitle() async {
        let sut = makeSUT(updates: [.available(makeBucket(nodeCount: 4))])

        await sut.monitorBucketUpdates()

        #expect(sut.navigationTitle == Strings.Localizable.General.Format.Count.file(4))
    }

    @Test("an unavailable update marks the bucket empty and shows the snackbar")
    func unavailableUpdateMarksBucketEmpty() async {
        let sut = makeSUT(updates: [.unavailable])

        await sut.monitorBucketUpdates()

        #expect(sut.isBucketEmpty)
        #expect(sut.fileNoLongerAvailableSnackBar != nil)
    }

    @Test("a stream that ends without an update leaves the bucket as it is")
    func endedStreamKeepsBucket() async {
        let sut = makeSUT(updates: [])

        await sut.monitorBucketUpdates()

        #expect(sut.navigationTitle == Strings.Localizable.General.Format.Count.file(3))
        #expect(sut.isBucketEmpty == false)
        #expect(sut.fileNoLongerAvailableSnackBar == nil)
    }

    /// The task restarts when the screen comes back (for example after a tab switch), so the
    /// count must catch up with changes made while the screen was away.
    @Test("monitoring starts with a fresh fetch of the bucket")
    func monitoringStartsWithFreshBucket() async {
        let sut = makeSUT(fetchedBucket: makeBucket(nodeCount: 2), updates: [])

        await sut.monitorBucketUpdates()

        #expect(sut.navigationTitle == Strings.Localizable.General.Format.Count.file(2))
    }

    @Test("a later update wins over the fresh fetch")
    func laterUpdateWinsOverFreshFetch() async {
        let sut = makeSUT(fetchedBucket: makeBucket(nodeCount: 2), updates: [.available(makeBucket(nodeCount: 4))])

        await sut.monitorBucketUpdates()

        #expect(sut.navigationTitle == Strings.Localizable.General.Format.Count.file(4))
    }

    @Test("a fresh fetch that finds no bucket marks the bucket empty")
    func missingBucketOnFreshFetchMarksBucketEmpty() async {
        let sut = makeSUT(fetchedBucket: nil, updates: [.available(makeBucket(nodeCount: 4))])

        await sut.monitorBucketUpdates()

        #expect(sut.isBucketEmpty)
        #expect(sut.fileNoLongerAvailableSnackBar != nil)
        #expect(sut.navigationTitle == Strings.Localizable.General.Format.Count.file(3))
    }

    /// A cancelled fetch returns nil too. The screen left (for example a tab switch),
    /// so the bucket must not be marked empty.
    @Test("a cancelled fresh fetch leaves the bucket as it is")
    func cancelledFreshFetchKeepsBucket() async {
        let sut = makeSUT(fetchedBucket: nil, updates: [])

        let task = Task { await sut.monitorBucketUpdates() }
        task.cancel()
        await task.value

        #expect(sut.isBucketEmpty == false)
        #expect(sut.fileNoLongerAvailableSnackBar == nil)
    }
}

// MARK: - Helpers

@MainActor
private func makeSUT(
    fetchedBucket: Home.RecentActionBucketEntity? = makeBucket(nodeCount: 3),
    updates: [RecentActionBucketUpdatesEntity]
) -> RecentActionBucketItemsViewModel {
    RecentActionBucketItemsViewModel(
        dependency: .init(
            bucket: makeBucket(nodeCount: 3),
            resultMapper: StubResultMapper(),
            downloadedNodesListener: StubDownloadedNodesListener(),
            offlineActionGuard: MockOfflineActionGuard(allowsAction: true)
        ),
        bucketItemsUseCase: StubBucketItemsUseCase(bucket: fetchedBucket),
        bucketItemsUpdateUseCase: StubBucketItemsUpdateUseCase(updates: updates)
    )
}

private struct StubBucketItemsUseCase: RecentActionBucketItemsUseCaseProtocol {
    let bucket: Home.RecentActionBucketEntity?

    func fetchBucketContent(forId id: String) async -> Home.RecentActionBucketEntity? {
        bucket
    }
}

/// Qualified: `MEGADomain` declares a `RecentActionBucketEntity` of its own, and Home's internal
/// one is what this view model takes. The id stays the same, only the node list changes.
private func makeBucket(nodeCount: Int) -> Home.RecentActionBucketEntity {
    let nodes = (1...nodeCount).map { NodeEntity(name: "file\($0).txt", handle: HandleEntity($0), isFile: true) }
    return Home.RecentActionBucketEntity(
        id: "bucket",
        date: Date(timeIntervalSince1970: 0),
        parent: nil,
        type: .mixedFiles(nodes),
        changesType: .newFiles,
        changesOwnerType: .currentUser,
        shareOriginType: .none,
        nodeAccessType: .owner
    )
}

private struct StubBucketItemsUpdateUseCase: RecentActionBucketItemsUpdateUseCaseProtocol {
    let updates: [RecentActionBucketUpdatesEntity]

    func bucketUpdates(forId id: String) -> AnyAsyncSequence<RecentActionBucketUpdatesEntity> {
        AsyncStream { continuation in
            updates.forEach { continuation.yield($0) }
            continuation.finish()
        }
        .eraseToAnyAsyncSequence()
    }
}

private struct StubResultMapper: RecentActionBucketItemResultMapping {
    func map(node: NodeEntity) -> SearchResult {
        SearchResult(
            id: node.handle,
            isFolder: false,
            backgroundDisplayMode: .preview,
            title: node.name,
            note: nil,
            tags: [],
            isSensitive: false,
            hasThumbnail: false,
            description: { _ in "" },
            type: .node,
            properties: [],
            thumbnailImageData: { Data() },
            swipeActions: { _ in [] }
        )
    }
}

private struct StubDownloadedNodesListener: DownloadedNodesListening {
    var downloadedNodes: AnyAsyncSequence<NodeEntity> {
        EmptyAsyncSequence<NodeEntity>().eraseToAnyAsyncSequence()
    }
}
