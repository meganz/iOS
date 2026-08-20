import MEGAAppPresentation
import MEGAAppPresentationMock
import MEGADomain
import MEGADomainMock
import Testing

@Suite("OfflineAwareNodeSelectionHandler Tests")
@MainActor
struct OfflineAwareNodeSelectionHandlerTests {

    @Suite("While nothing can be blocked")
    @MainActor
    struct InactiveGuard {
        /// A tap must not be deferred while the guard is inactive — awaiting anything here would
        /// add a delay to every file tap made online, or with the offline mode flag off.
        @Test("forwards the tap synchronously")
        func forwardsSynchronously() {
            let harness = Harness(isActive: false, shouldBlock: true)

            harness.sut.handle(selection: .file)

            #expect(harness.wrapped.selections.count == 1)
        }

        @Test("forwards the selection unchanged")
        func forwardsTheSelectionUnchanged() {
            let harness = Harness(isActive: false)

            harness.sut.handle(selection: NodeSelection(handle: 1, siblings: [2, 3], isSearchActive: true))

            let forwarded = harness.wrapped.selections.first
            #expect(forwarded?.handle == 1)
            #expect(forwarded?.siblings == [2, 3])
            #expect(forwarded?.isSearchActive == true)
        }
    }

    @Suite("While the guard is active")
    @MainActor
    struct ActiveGuard {
        @Test("forwards a folder tap synchronously, so folders keep browsing offline")
        func folderTapIsForwardedSynchronously() {
            let harness = Harness(shouldBlock: true)

            harness.sut.handle(selection: .folder)

            #expect(harness.wrapped.selections.count == 1)
        }

        @Test("reports a blocked file instead of forwarding it")
        func blockedFileIsNotForwarded() async {
            let harness = Harness(shouldBlock: true)
            var blockedTapWasReported = false
            harness.tapDispatcher.showFileUnavailableSnackBar = { blockedTapWasReported = true }

            harness.sut.handle(selection: .file)

            await waitUntil { blockedTapWasReported }
            #expect(harness.wrapped.selections.isEmpty)
        }

        @Test("forwards a file it does not block, with the siblings the opener needs")
        func allowedFileIsForwardedOnce() async {
            let harness = Harness(shouldBlock: false)
            var blockedTapWasReported = false
            harness.tapDispatcher.showFileUnavailableSnackBar = { blockedTapWasReported = true }

            harness.sut.handle(selection: .file)

            await waitUntil { !harness.wrapped.selections.isEmpty }
            #expect(harness.wrapped.selections.count == 1)
            #expect(harness.wrapped.selections.first?.siblings == [2, 3])
            #expect(!blockedTapWasReported)
        }
    }
}

// MARK: - Harness

@MainActor
private struct Harness {
    let sut: OfflineAwareNodeSelectionHandler
    let wrapped = SpyNodeSelectionHandler()
    let tapDispatcher: OfflineAwareNodeTapDispatcher

    init(isActive: Bool = true, shouldBlock: Bool = false) {
        tapDispatcher = OfflineAwareNodeTapDispatcher(
            offlineFileOpenGuard: MockOfflineFileOpenGuard(isActive: isActive, shouldBlock: shouldBlock),
            nodeUseCase: MockNodeDataUseCase(nodes: [NodeEntity(name: "report.pdf", handle: 1, isFile: true)])
        )
        sut = OfflineAwareNodeSelectionHandler(wrapping: wrapped, tapDispatcher: tapDispatcher)
    }
}

@MainActor
private final class SpyNodeSelectionHandler: NodeSelectionHandling {
    private(set) var selections: [NodeSelection] = []

    func handle(selection: NodeSelection) {
        selections.append(selection)
    }
}

private extension NodeSelection {
    // Computed rather than stored: `NodeSelection` is not `Sendable`, so a static constant of it
    // would be shared mutable state.
    static var file: NodeSelection { NodeSelection(handle: 1, siblings: [2, 3]) }
    static var folder: NodeSelection { NodeSelection(handle: 1, siblings: [], isFolder: true) }
}

/// Yields the main actor until `condition` holds, so the guard's asynchronous check — and only it —
/// gets to run. Bounded, so a regression fails on the assertion that follows instead of hanging.
@MainActor
private func waitUntil(iterations: Int = 1_000, _ condition: () -> Bool) async {
    for _ in 0..<iterations {
        if condition() { return }
        await Task.yield()
    }
}
