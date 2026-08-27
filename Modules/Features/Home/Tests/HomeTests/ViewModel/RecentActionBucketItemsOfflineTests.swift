@testable import Home
import MEGAAppPresentation
import MEGAAppPresentationMock
import MEGADomain
import MEGASwift
import Search
import SwiftUI
import Testing

/// The select-mode bulk actions on a Recents bucket, while the offline guard blocks (IOS-12410).
@Suite("RecentActionBucketItemsViewModel offline Tests")
@MainActor
struct RecentActionBucketItemsOfflineTests {

    /// The blocked action must not reach `$nodesAction`: the view dispatches that publisher to the
    /// action handler, and the view model leaves edit mode off the same publisher, so anything less
    /// would still throw the user's selection away.
    @Test("a bulk action the offline guard blocks keeps edit mode")
    func blockedBulkActionKeepsEditMode() async {
        let sut = makeSUT(allowsAction: false)
        sut.editMode = .active

        sut.bottomBarAction = .download

        await yieldMainActor()
        #expect(sut.nodesAction == nil)
        #expect(sut.editMode == .active)
    }

    @Test("a bulk action the offline guard allows still runs")
    func allowedBulkActionIsForwarded() async {
        let sut = makeSUT(allowsAction: true)

        sut.bottomBarAction = .download

        await yieldMainActor()
        guard case .download = sut.nodesAction else {
            Issue.record("Expected a download action, got \(String(describing: sut.nodesAction))")
            return
        }
    }
}

// MARK: - Helpers

@MainActor
private func makeSUT(allowsAction: Bool) -> RecentActionBucketItemsViewModel {
    RecentActionBucketItemsViewModel(
        dependency: .init(
            bucket: makeBucket(),
            resultMapper: StubResultMapper(),
            downloadedNodesListener: StubDownloadedNodesListener(),
            offlineActionGuard: MockOfflineActionGuard(allowsAction: allowsAction)
        )
    )
}

/// Qualified: `MEGADomain` declares a `RecentActionBucketEntity` of its own, and Home's internal
/// one is what this view model takes.
private func makeBucket() -> Home.RecentActionBucketEntity {
    Home.RecentActionBucketEntity(
        id: "bucket",
        date: Date(timeIntervalSince1970: 0),
        parent: nil,
        type: .mixedFiles([NodeEntity(name: "report.pdf", handle: 1, isFile: true)]),
        changesType: .newFiles,
        changesOwnerType: .currentUser,
        shareOriginType: .none,
        nodeAccessType: .owner
    )
}

/// The results list is never rendered here — these tests only drive the bottom bar publisher — so
/// both stubs just have to satisfy the dependency.
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

/// Lets the Combine subscriptions set up in `init` run before the assertions.
@MainActor
private func yieldMainActor(iterations: Int = 100) async {
    for _ in 0..<iterations {
        await Task.yield()
    }
}
