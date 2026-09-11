@testable import ContentLibraries
import MEGADomain
import MEGADomainMock
import Testing

@Suite("PhotoBrowserPaginator i of n")
@MainActor
struct PhotoBrowserPaginatorPositionTests {

    // MARK: - Local arithmetic

    @Test("Prepending k items moves the start back by exactly k")
    func prependMovesStartBack() async {
        let (sut, _) = makePaginatorSUT(
            initial: [.photoC, .photoD],
            globalStartIndex: 50,
            totalCount: 200,
            backward: [.success([.photoA, .photoB])],
            pageSize: 2)

        await sut.loadMore(.backward)

        #expect(sut.globalStartIndex == 48)
        #expect(sut.totalCount == 200)
    }

    @Test("The start never goes below zero, and hitting the floor is not a claim of reaching the start")
    func prependFloorsAtZero() async {
        let (sut, _) = makePaginatorSUT(
            initial: [.photoE],
            globalStartIndex: 1,
            totalCount: 10,
            backward: [.success([.photoC, .photoD])],
            pageSize: 2)

        await sut.loadMore(.backward)

        #expect(sut.globalStartIndex == 0)
        #expect(sut.availability(for: .backward) == .available)
    }

    @Test("Appending keeps the start and raises the total only to the count the sequence can reach")
    func appendRaisesTotalToLowerBound() async {
        let (sut, _) = makePaginatorSUT(
            initial: [.photoA, .photoB],
            globalStartIndex: 0,
            totalCount: 2,
            forward: [.success([.photoC, .photoD])],
            pageSize: 2)

        await sut.loadMore(.forward)

        #expect(sut.globalStartIndex == 0)
        #expect(sut.totalCount == 4)
    }

    @Test("A freshly queried total is not overwritten by the appended lower bound")
    func appendDoesNotLowerAKnownTotal() async {
        let (sut, _) = makePaginatorSUT(
            initial: [.photoA, .photoB],
            globalStartIndex: 0,
            totalCount: 900,
            forward: [.success([.photoC, .photoD])],
            pageSize: 2)

        await sut.loadMore(.forward)

        #expect(sut.totalCount == 900)
    }

    @Test("Reaching the backward boundary calibrates the start to zero")
    func backwardExhaustionCalibratesStart() async {
        let (sut, _) = makePaginatorSUT(
            initial: [.photoC, .photoD],
            globalStartIndex: 50,
            totalCount: 200,
            backward: [.success([.photoA, .photoB])],
            pageSize: 4)

        // A short backward page: nothing precedes what came back, so the run starts at the source's
        // start. Exact at this moment only — an item added above it drifts the start again.
        #expect(await sut.loadMore(.backward) == .loaded(insertedCount: 2))
        #expect(sut.availability(for: .backward) == .exhausted)
        #expect(sut.globalStartIndex == 0)
    }

    @Test("Reaching both ends normalises the title to the browsing sequence")
    func bothEndsExhaustedNormalisesTheTitle() async {
        let (sut, _) = makePaginatorSUT(
            initial: [.photoC, .photoD],
            globalStartIndex: 50,
            totalCount: 200,
            forward: [.success([.photoE])],
            backward: [.success([.photoA, .photoB])],
            pageSize: 4)

        await sut.loadMore(.backward)
        await sut.loadMore(.forward)

        // Self-consistency, not source truth: without this the user reaches the last photo and the
        // title still claims 200, with 195 of them unreachable.
        #expect(sut.nodes.map(\.handle) == [1, 2, 3, 4, 5])
        #expect(sut.totalCount == 5)
        #expect(sut.displayPosition(forIndex: 4).map { [$0.index, $0.total] } == [5, 5])
    }

    @Test("Reaching only the forward end never lowers the count")
    func forwardExhaustionAloneDoesNotLowerTheCount() async {
        let (sut, _) = makePaginatorSUT(
            initial: [.photoC, .photoD],
            globalStartIndex: 2,
            totalCount: 900,
            forward: [.success([.photoE])],
            pageSize: 4)

        // Forward exhaustion says nothing about where the run starts, so it cannot validate a
        // total: an item added above an uncalibrated start would make the sum too small.
        await sut.loadMore(.forward)

        #expect(sut.availability(for: .forward) == .exhausted)
        #expect(sut.totalCount == 900)
    }

    @Test("Reaching the forward boundary does not calibrate the start")
    func forwardExhaustionDoesNotCalibrateStart() async {
        let (sut, _) = makePaginatorSUT(
            initial: [.photoC, .photoD],
            globalStartIndex: 2,
            totalCount: 4,
            forward: [.success([.photoE])],
            pageSize: 4)

        // Forward exhaustion only says nothing follows this cursor. The start may still be wrong —
        // an item inserted before the run would make the total 6, not 5.
        await sut.loadMore(.forward)

        #expect(sut.globalStartIndex == 2)
        #expect(sut.totalCount == 5)
    }

    // MARK: - Removals

    @Test("The total drops by the handles actually removed from the run, not by the events received")
    func removalCountsHandlesInTheRun() {
        let (sut, _) = makePaginatorSUT(initial: [.photoA, .photoB, .photoC], globalStartIndex: 10, totalCount: 100)

        // A move reported twice, plus a node that was never in the run: one item left the sequence.
        let removedCount = sut.applyRemovals(of: [.photoB, .photoB, .testNode(handle: 99)])

        #expect(removedCount == 1)
        #expect(sut.totalCount == 99)
        #expect(sut.globalStartIndex == 10)
        #expect(sut.nodes.map(\.handle) == [1, 3])
    }

    @Test("Removing the first item leaves the start where it was")
    func removingFirstItemKeepsStart() {
        let (sut, _) = makePaginatorSUT(initial: [.photoA, .photoB, .photoC], globalStartIndex: 10, totalCount: 100)

        // What followed slides up into the same positions, so the new first item sits exactly
        // where the old one did.
        sut.applyRemovals(of: [.photoA])

        #expect(sut.globalStartIndex == 10)
        #expect(sut.displayPosition(forIndex: 0)?.index == 11)
    }

    @Test("The total never falls below what the sequence can reach")
    func removalKeepsTotalAboveReachableCount() {
        let (sut, _) = makePaginatorSUT(initial: [.photoA, .photoB, .photoC], globalStartIndex: 10, totalCount: 11)

        sut.applyRemovals(of: [.photoA])

        #expect(sut.totalCount >= sut.globalStartIndex + sut.nodes.count)
    }

    // MARK: - Rendering invariant

    @Test("The title is a position in the browsing sequence")
    func displayPositionUsesTheStart() {
        let (sut, _) = makePaginatorSUT(initial: [.photoA, .photoB, .photoC], globalStartIndex: 49, totalCount: 300)

        #expect(sut.displayPosition(forIndex: 0)?.index == 50)
        #expect(sut.displayPosition(forIndex: 2)?.index == 52)
        #expect(sut.displayPosition(forIndex: 2)?.total == 300)
    }

    @Test("The position never leaves 1...n even when the total is stale")
    func displayPositionStaysWithinTheInvariant() {
        // A total that underestimates: the start alone already exceeds it.
        let (sut, _) = makePaginatorSUT(initial: [.photoA, .photoB], globalStartIndex: 100, totalCount: 3)

        let last = sut.displayPosition(forIndex: 1)
        #expect(last?.index == 102)
        #expect(last?.total == 102)
        #expect(last.map { $0.index >= 1 && $0.index <= $0.total } == true)
    }

    @Test("There is no title for an index outside the run")
    func noPositionOutsideTheRun() {
        let (sut, _) = makePaginatorSUT(initial: [.photoA], globalStartIndex: 0, totalCount: 1)

        #expect(sut.displayPosition(forIndex: 1) == nil)
        #expect(sut.displayPosition(forIndex: -1) == nil)
    }

    @Test("An empty sequence has no title")
    func noPositionWhenEmpty() {
        let (sut, _) = makePaginatorSUT(initial: [], globalStartIndex: 0, totalCount: 0)

        #expect(sut.displayPosition(forIndex: 0) == nil)
    }

    @Test("The handed-over total is raised to fit the handed-over run")
    func handoverTotalCoversTheRun() {
        let (sut, _) = makePaginatorSUT(initial: [.photoA, .photoB, .photoC], globalStartIndex: 10, totalCount: 2)

        #expect(sut.totalCount == 13)
    }
}
