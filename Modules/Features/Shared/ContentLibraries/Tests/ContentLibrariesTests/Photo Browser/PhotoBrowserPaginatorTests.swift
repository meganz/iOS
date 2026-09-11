@testable import ContentLibraries
import MEGADomain
import MEGADomainMock
import Testing

@Suite("PhotoBrowserPaginator paging")
@MainActor
struct PhotoBrowserPaginatorTests {

    // MARK: - Both directions

    @Test("A forward page is appended in order and the next request continues from its last node")
    func forwardPagingAppendsAndAdvances() async {
        let (sut, script) = makePaginatorSUT(
            initial: [.photoA, .photoB],
            forward: [.success([.photoC, .photoD]), .success([.photoE, .photoF])],
            pageSize: 2)

        #expect(await sut.loadMore(.forward) == .loaded(insertedCount: 2))
        #expect(await sut.loadMore(.forward) == .loaded(insertedCount: 2))

        #expect(sut.nodes.map(\.handle) == [1, 2, 3, 4, 5, 6])
        #expect(await script.forwardAnchors.map { $0?.handle } == [2, 4])
    }

    @Test("A backward page is prepended and the next request continues from its first node")
    func backwardPagingPrependsAndAdvances() async {
        let (sut, script) = makePaginatorSUT(
            initial: [.photoE, .photoF],
            backward: [.success([.photoC, .photoD]), .success([.photoA, .photoB])],
            pageSize: 2)

        #expect(await sut.loadMore(.backward) == .loaded(insertedCount: 2))
        #expect(await sut.loadMore(.backward) == .loaded(insertedCount: 2))

        #expect(sut.nodes.map(\.handle) == [1, 2, 3, 4, 5, 6])
        #expect(await script.backwardAnchors.map(\.handle) == [5, 3])
    }

    @Test("Paging in both directions from one handover keeps the run contiguous")
    func pagingBothWays() async {
        let (sut, _) = makePaginatorSUT(
            initial: [.photoC, .photoD],
            forward: [.success([.photoE, .photoF])],
            backward: [.success([.photoA, .photoB])],
            pageSize: 2)

        await sut.loadMore(.forward)
        await sut.loadMore(.backward)

        #expect(sut.nodes.map(\.handle) == [1, 2, 3, 4, 5, 6])
    }

    // MARK: - Exhaustion

    @Test("Only a short page exhausts a direction")
    func shortPageExhausts() async {
        let (sut, script) = makePaginatorSUT(initial: [.photoA], forward: [.success([.photoB])], pageSize: 2)

        #expect(await sut.loadMore(.forward) == .loaded(insertedCount: 1))
        #expect(sut.availability(for: .forward) == .exhausted)

        #expect(await sut.loadMore(.forward) == .notNeeded)
        #expect(await script.forwardCallCount == 1)
    }

    @Test("An empty page reaches the boundary and inserts nothing")
    func emptyPageReachesBoundary() async {
        let (sut, _) = makePaginatorSUT(initial: [.photoA], forward: [.success([])], pageSize: 2)

        #expect(await sut.loadMore(.forward) == .reachedBoundary)
        #expect(sut.nodes.map(\.handle) == [1])
        #expect(sut.availability(for: .forward) == .exhausted)
    }

    @Test("A full page that is entirely already loaded does not exhaust the direction")
    func fullDuplicatePageDoesNotExhaust() async {
        let (sut, _) = makePaginatorSUT(initial: [.photoA, .photoB], forward: [.success([.photoA, .photoB])], pageSize: 2)

        #expect(await sut.loadMore(.forward) == .loaded(insertedCount: 0))
        #expect(sut.availability(for: .forward) == .available)
    }

    @Test("A whole page de-duplicated away is not the end, and the next request still makes progress")
    func duplicatePageStillMakesProgress() async {
        // What a node that changed sort position and is met again looks like: a full page of
        // handles already in the run. The cursor follows the returned page rather than what was
        // inserted, so the next request moves on instead of asking the same question forever.
        let (sut, script) = makePaginatorSUT(
            initial: [.photoA, .photoB],
            forward: [.success([.photoA, .photoB]), .success([.photoC, .photoD])],
            pageSize: 2)

        await sut.loadMore(.forward)
        await sut.loadMore(.forward)

        #expect(await script.forwardAnchors.map { $0?.handle } == [2, 2])
        #expect(sut.nodes.map(\.handle) == [1, 2, 3, 4])
    }

    @Test("A failure leaves the direction unresolved and retryable")
    func failureIsRetryable() async {
        let (sut, _) = makePaginatorSUT(
            initial: [.photoA],
            forward: [.failure(PaginationTestError.pageFailed), .success([.photoB, .photoC])],
            pageSize: 2)

        #expect(await sut.loadMore(.forward) == .failed)
        #expect(sut.availability(for: .forward) == .unresolved)

        #expect(await sut.loadMore(.forward) == .loaded(insertedCount: 2))
        #expect(sut.availability(for: .forward) == .available)
    }

    @Test("A second request on the same side while one is in flight issues no query")
    func concurrentRequestsOnOneSideCoalesce() async {
        let (sut, script) = makePaginatorSUT(initial: [.photoA], forward: [.success([.photoB, .photoC])], pageSize: 2)

        async let first = sut.loadMore(.forward)
        async let second = sut.loadMore(.forward)
        let outcomes = await [first, second]

        #expect(outcomes.filter { $0 == .notNeeded }.count == 1)
        #expect(await script.forwardCallCount == 1)
        #expect(sut.nodes.map(\.handle) == [1, 2, 3])
    }

    // MARK: - Removals against in-flight pages

    @Test("A node removed while a page was in flight is not restored by that page")
    func removalDuringRequestIsNotUndone() async {
        let (sut, script) = makePaginatorSUT(initial: [.photoA, .photoB], forward: [.success([.photoC, .photoD])], pageSize: 2)
        // The page is already fetched and carries value copies whose isRemoved is still false;
        // B is gone from the run by the time it commits, so handle de-duplication would let it in.
        await script.setOnForwardFetch { @MainActor in
            sut.applyRemovals(of: [.photoB, .photoC])
        }

        await sut.loadMore(.forward)

        #expect(sut.nodes.map(\.handle) == [1, 4])
    }

    @Test("A handle removed with nothing in flight is not blacklisted — a move can bring it back")
    func removedHandleMayReturnWhenIdle() async {
        let (sut, _) = makePaginatorSUT(initial: [.photoA, .photoB], forward: [.success([.photoB, .photoC])], pageSize: 2)

        sut.applyRemovals(of: [.photoB])
        await sut.loadMore(.forward)

        #expect(sut.nodes.map(\.handle) == [1, 2, 3])
    }

    @Test("Removing the boundary node leaves the cursor usable")
    func removingBoundaryNodeKeepsCursor() async {
        let (sut, script) = makePaginatorSUT(initial: [.photoA, .photoB], forward: [.success([.photoC])], pageSize: 2)

        sut.applyRemovals(of: [.photoB])
        await sut.loadMore(.forward)

        // The cursor is a keyset value built from B's own sort key. Whether that row still exists
        // server-side is irrelevant: the position it names is still well defined.
        #expect(await script.forwardAnchors.map { $0?.handle } == [2])
        #expect(sut.nodes.map(\.handle) == [1, 3])
    }

    // MARK: - Sort key changes

    @Test("A metadata update replaces the displayed entity without moving the cursor")
    func metadataUpdateDoesNotMoveCursor() async {
        let (sut, script) = makePaginatorSUT(initial: [.photoA, .photoB], forward: [.success([.photoC])], pageSize: 2)
        // B's sort time moves to the far end of the order. Re-reading the cursor from the updated
        // entity would ask for what follows the new position and skip C and D for good.
        let reordered = NodeEntity(name: NodeEntity.photoB.name, handle: 2, modificationTime: .distantPast)

        sut.applyMetadataUpdates(of: [reordered])
        await sut.loadMore(.forward)

        // The page appended C, so the updated node has to be found by handle rather than by position.
        #expect(sut.nodes.first { $0.handle == 2 }?.modificationTime == .distantPast)
        #expect(sut.nodes.map(\.handle) == [1, 2, 3])
        #expect(await script.forwardAnchors.first??.modificationTime == NodeEntity.photoB.modificationTime)
    }

    // MARK: - Reset

    @Test("A page that returns after a reset is discarded")
    func resetDiscardsInFlightPage() async {
        let (sut, script) = makePaginatorSUT(initial: [.photoA, .photoB], forward: [.success([.photoC, .photoD])], pageSize: 2)
        await script.setOnForwardFetch { @MainActor in
            sut.reset(to: makePaginationContext(nodes: [.photoE, .photoF], globalStartIndex: 10, totalCount: 20))
        }

        #expect(await sut.loadMore(.forward) == .cancelled)
        #expect(sut.nodes.map(\.handle) == [5, 6])
        #expect(sut.globalStartIndex == 10)
    }

    @Test("A reset re-opens an exhausted direction")
    func resetReopensExhaustion() async {
        let (sut, _) = makePaginatorSUT(initial: [.photoA], forward: [.success([])], pageSize: 2)

        await sut.loadMore(.forward)
        #expect(sut.availability(for: .forward) == .exhausted)

        sut.reset(to: makePaginationContext(nodes: [.photoA], globalStartIndex: 0, totalCount: 1))
        #expect(sut.availability(for: .forward) == .available)
    }

    @Test("Nothing handed over means there is nothing to page backwards from")
    func emptyHandoverExhaustsBackward() async {
        let (sut, script) = makePaginatorSUT(initial: [], forward: [.success([.photoA, .photoB])], pageSize: 2)

        #expect(await sut.loadMore(.backward) == .notNeeded)
        #expect(await script.backwardCallCount == 0)
        #expect(await sut.loadMore(.forward) == .loaded(insertedCount: 2))
        #expect(await script.forwardAnchors.map { $0?.handle } == [nil])
    }

    @Test("A page that arrives after the task was cancelled is not committed")
    func cancelledRequestDoesNotCommit() async {
        let (sut, script) = makePaginatorSUT(
            initial: [.photoA],
            forward: [.success([.photoB, .photoC])],
            pageSize: 2)
        let gate = TestGate()
        await script.setOnForwardFetch { await gate.wait() }

        let request = Task { @MainActor in await sut.loadMore(.forward) }
        await yieldUntil { await script.forwardCallCount == 1 }
        request.cancel()
        await gate.open()

        // The stub returns a full page rather than throwing, which is what the SDK layer is
        // allowed to do: cancellation must be caught after the await, before anything commits.
        #expect(await request.value == .cancelled)
        #expect(sut.nodes.map(\.handle) == [1])
        #expect(sut.availability(for: .forward) == .unresolved)
    }

    @Test("An empty page that arrives after cancellation does not exhaust the direction")
    func cancelledEmptyPageDoesNotExhaust() async {
        let (sut, script) = makePaginatorSUT(initial: [.photoA], forward: [.success([])], pageSize: 2)
        let gate = TestGate()
        await script.setOnForwardFetch { await gate.wait() }

        let request = Task { @MainActor in await sut.loadMore(.forward) }
        await yieldUntil { await script.forwardCallCount == 1 }
        request.cancel()
        await gate.open()

        #expect(await request.value == .cancelled)
        #expect(sut.availability(for: .forward) != .exhausted)
    }

    @Test("A removal does not veto a query issued after it")
    func vetoDoesNotReachLaterRequests() async {
        let (sut, script) = makePaginatorSUT(
            initial: [.photoC, .photoD],
            forward: [.success([.photoB])],
            backward: [.success([.photoA])],
            pageSize: 2)
        let gate = TestGate()
        await script.setOnBackwardFetch { await gate.wait() }

        let slowBackward = Task { @MainActor in await sut.loadMore(.backward) }
        await yieldUntil { await script.backwardCallCount == 1 }

        // A move is reported as a removal. It has to veto the page already in the air, but the
        // forward query below starts afterwards and legitimately finds the node again: vetoing it
        // too would drop B while the cursor moved past it, losing it for the session.
        sut.applyRemovals(of: [.photoB])
        await sut.loadMore(.forward)

        #expect(sut.nodes.map(\.handle).contains(2))

        await gate.open()
        _ = await slowBackward.value
    }

    @Test("A reset lets a new request start while the old one is still in flight")
    func resetReleasesTheOldRequestsSlot() async {
        let (sut, script) = makePaginatorSUT(
            initial: [.photoA, .photoB],
            forward: [.success([.photoC, .photoD]), .success([.photoF])],
            pageSize: 2)
        let gate = TestGate()
        await script.setOnForwardFetch { await gate.wait() }

        let stale = Task { @MainActor in await sut.loadMore(.forward) }
        await yieldUntil { await script.forwardCallCount == 1 }
        sut.reset(to: makePaginationContext(nodes: [.photoE], globalStartIndex: 5, totalCount: 10))

        // Without releasing the stale registration this would answer .notNeeded and the refreshed
        // sequence could never load.
        #expect(await sut.loadMore(.forward) == .loaded(insertedCount: 1))
        #expect(await script.forwardCallCount == 2)
        #expect(sut.nodes.map(\.handle) == [5, 6])

        await gate.open()
        #expect(await stale.value == .cancelled)
        #expect(sut.nodes.map(\.handle) == [5, 6])
    }

    @Test("The page size is passed as the limit, never zero")
    func limitIsThePageSize() async {
        // Zero means no limit to the SDK. Sending it here would pull the whole library in one page.
        let (sut, script) = makePaginatorSUT(initial: [.photoA], forward: [.success([.photoB, .photoC])], pageSize: 2)

        await sut.loadMore(.forward)

        #expect(await script.limits == [2])
    }

    @Test("Duplicates in the handover are dropped once")
    func handoverIsDeduplicated() {
        let (sut, _) = makePaginatorSUT(initial: [.photoA, .photoB, .photoA], pageSize: 2)

        #expect(sut.nodes.map(\.handle) == [1, 2])
    }
}
