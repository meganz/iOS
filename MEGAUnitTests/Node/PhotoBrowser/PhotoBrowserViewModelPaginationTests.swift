import ContentLibraries
@testable import MEGA
import MEGAAppPresentation
import MEGAAppPresentationMock
import MEGADomain
import MEGADomainMock
import MEGATest
import XCTest

@MainActor
final class PhotoBrowserViewModelPaginationTests: XCTestCase {

    // MARK: - Prefetching

    func testDidMoveToIndex_nearTheEndOfTheLoadedRange_appendsTheNextPage() async {
        let (sut, _) = makeSUT(loaded: nodes(1...25), forwardPage: [node(26), node(27)])

        await test(
            viewModel: sut,
            action: .didMoveToIndex(24),
            expectedCommands: [.photosAppended([node(26), node(27)])])
    }

    func testDidMoveToIndex_atTheStartOfTheLoadedRange_prependsThePreviousPage() async {
        let (sut, _) = makeSUT(loaded: nodes(11...35), backwardPage: [node(9), node(10)])

        await test(
            viewModel: sut,
            action: .didMoveToIndex(0),
            expectedCommands: [.photosPrepended([node(9), node(10)])])
    }

    func testDidMoveToIndex_farFromEitherEnd_requestsNothing() async {
        let (sut, _) = makeSUT(
            loaded: nodes(1...40),
            forwardPage: [node(41)],
            backwardPage: [node(0)])

        await test(
            viewModel: sut,
            action: .didMoveToIndex(20),
            expectedCommands: [],
            timeout: 0.3)
    }

    func testDidMoveToIndex_repeatedly_issuesOneRequestPerDirection() async {
        let (sut, _) = makeSUT(loaded: nodes(1...25), forwardPage: [node(26)])

        // A page already in flight is never replaced: a second request would ask the same cursor
        // the same question.
        await test(
            viewModel: sut,
            actions: [.didMoveToIndex(24), .didMoveToIndex(24), .didMoveToIndex(24)],
            expectedCommands: [.photosAppended([node(26)])])
    }

    func testDidMoveToIndex_afterAnExhaustedDirection_stopsRequesting() async {
        let (sut, _) = makeSUT(loaded: nodes(1...25), forwardPage: [])

        // An empty page exhausts the side; asking again would spend a query to be told the same.
        await test(
            viewModel: sut,
            actions: [.didMoveToIndex(24), .didMoveToIndex(24)],
            expectedCommands: [],
            timeout: 0.3)
    }

    // MARK: - Holding a prepend while the scroll view moves

    func testPrepend_whileTheScrollViewIsMoving_isHeldUntilItSettles() async {
        let (sut, _) = makeSUT(loaded: nodes(11...35), backwardPage: [node(9), node(10)])

        // The page is held, but the count it brought is not: the title moves even though nothing
        // has been inserted on screen yet.
        await test(
            viewModel: sut,
            actions: [.didBeginScrolling, .didMoveToIndex(0)],
            expectedCommands: [.titleNeedsRefresh])

        await test(
            viewModel: sut,
            action: .didSettleScrolling,
            expectedCommands: [.photosPrepended([node(9), node(10)])])
    }

    func testAppend_whileTheScrollViewIsMoving_isNotHeld() async {
        let (sut, _) = makeSUT(loaded: nodes(1...25), forwardPage: [node(26)])

        // An append only extends the content size; nothing already laid out moves.
        await test(
            viewModel: sut,
            actions: [.didBeginScrolling, .didMoveToIndex(24)],
            expectedCommands: [.photosAppended([node(26)])])
    }

    func testHeldPrepend_withANodeDeletedWhileHeld_doesNotPutItBackOnScreen() async {
        let (sut, paginator) = makeSUT(loaded: nodes(11...35), backwardPage: [node(9), node(10)])

        await test(
            viewModel: sut,
            actions: [.didBeginScrolling, .didMoveToIndex(0)],
            expectedCommands: [.titleNeedsRefresh])

        // What a node event does while the page waits. Only identities are held, so the entities
        // are read back from the paginator and the deleted one is simply not there any more.
        paginator.applyRemovals(of: [NodeEntity(changeTypes: .removed, handle: 9)])

        await test(
            viewModel: sut,
            action: .didSettleScrolling,
            expectedCommands: [.photosPrepended([node(10)])])
    }

    func testHeldPrepend_whenTheBrowserGoesAway_isMergedRatherThanCarriedAcross() async {
        let (sut, _) = makeSUT(loaded: nodes(11...35), backwardPage: [node(9), node(10)])

        await test(
            viewModel: sut,
            actions: [.didBeginScrolling, .didMoveToIndex(0)],
            expectedCommands: [.titleNeedsRefresh])

        // Nothing may be carried across a cover: node events stop being watched here, so a page
        // still held would be merged on the way back from a sequence that never saw what was
        // deleted meanwhile.
        await test(
            viewModel: sut,
            action: .onViewWillDisappear,
            expectedCommands: [.photosPrepended([node(9), node(10)])])
    }

    // MARK: - Title

    func testTitlePosition_withoutPagination_isNil() {
        let sut = PhotoBrowserViewModel(photoBrowserUseCase: MockPhotoBrowserUseCase())

        XCTAssertNil(sut.titlePosition(forIndex: 0), "Every other entry point holds the whole sequence")
    }

    func testTitlePosition_withPagination_countsFromTheHandedOverStart() {
        let (sut, _) = makeSUT(loaded: [node(1), node(2)], globalStartIndex: 49, totalCount: 300)

        XCTAssertEqual(sut.titlePosition(forIndex: 1)?.index, 51)
        XCTAssertEqual(sut.titlePosition(forIndex: 1)?.total, 300)
    }

    func testTitlePosition_afterAppendingAPage_movesWithTheSequence() async {
        let (sut, _) = makeSUT(
            loaded: nodes(1...25),
            globalStartIndex: 0,
            totalCount: 300,
            forwardPage: [node(26), node(27)])

        await test(
            viewModel: sut,
            action: .didMoveToIndex(24),
            expectedCommands: [.photosAppended([node(26), node(27)])])

        XCTAssertEqual(sut.titlePosition(forIndex: 26)?.index, 27)
        XCTAssertEqual(sut.titlePosition(forIndex: 26)?.total, 300)
    }

    func testTitlePosition_whileAPrependIsHeld_stillPointsAtTheSamePhoto() async {
        let (sut, _) = makeSUT(
            loaded: nodes(11...35),
            globalStartIndex: 10,
            totalCount: 100,
            backwardPage: [node(9), node(10)],
            // A full page rather than a short one: a short page would mean the sequence starts
            // here, and the start would be calibrated to 0 instead of moving back by two.
            pageSize: 2)

        await test(
            viewModel: sut,
            actions: [.didBeginScrolling, .didMoveToIndex(0)],
            expectedCommands: [.titleNeedsRefresh])

        // The paginator has grown at the front and the view has not. Index 0 on screen is still the
        // eleventh photo of the sequence, and the title has to say so.
        XCTAssertEqual(sut.titlePosition(forIndex: 0)?.index, 11)
    }

    func testReachingBothEnds_withoutInsertingAnything_asksForATitleRefresh() async {
        let (sut, _) = makeSUT(loaded: [node(1), node(2)], totalCount: 300)

        // Both pages come back empty: nothing is inserted, but the count normalises from 300 to the
        // two photos the sequence actually holds, and the user stays on the same photo. One refresh,
        // not one per page — whichever side lands second is the one that moves the number.
        await test(
            viewModel: sut,
            action: .didMoveToIndex(0),
            expectedCommands: [.titleNeedsRefresh])

        XCTAssertEqual(sut.titlePosition(forIndex: 1)?.total, 2)
    }

    // MARK: - Node updates

    func testNodeRemoval_reachesThePaginator() async {
        let removed = NodeEntity(changeTypes: .removed, name: "node-2", handle: 2)
        let (sut, _) = makeSUT(
            loaded: [node(1), node(2)],
            totalCount: 300,
            nodeUpdates: [[removed]])

        await test(
            viewModel: sut,
            action: .onViewWillAppear,
            expectedCommands: [.nodesUpdate([removed])])

        // The paginator has to see the removal itself: it is what keeps the total honest, and what
        // stops a page already in flight from putting the node straight back.
        XCTAssertEqual(sut.titlePosition(forIndex: 0)?.total, 299)
    }

    // MARK: - Helpers

    private func makeSUT(
        loaded: [NodeEntity],
        globalStartIndex: Int = 0,
        totalCount: Int = 0,
        forwardPage: [NodeEntity] = [],
        backwardPage: [NodeEntity] = [],
        nodeUpdates: [[NodeEntity]] = [],
        pageSize: Int = PhotoBrowserPaginator.defaultPageSize
    ) -> (PhotoBrowserViewModel, PhotoBrowserPaginator) {
        let paginator = PhotoBrowserPaginator(
            context: PhotoBrowserPaginationContext(
                nodes: loaded,
                globalStartIndex: globalStartIndex,
                totalCount: totalCount,
                filter: MediaTimelineFilterEntity(mediaType: .allMedia, location: .allLocations),
                sortOrder: .newest),
            useCase: MockMediaTimelineUseCase(
                mediaPageResult: .success(forwardPage),
                mediaPageBeforeResult: .success(backwardPage)),
            pageSize: pageSize)
        let viewModel = PhotoBrowserViewModel(
            photoBrowserUseCase: MockPhotoBrowserUseCase(
                nodeRepository: MockNodeRepository(
                    nodeUpdates: nodeUpdates.async.eraseToAnyAsyncSequence())),
            paginator: paginator)
        return (viewModel, paginator)
    }

    /// `XCTestCase+ActionCommand` only has an `async` multi-action overload that takes an explicit
    /// comparator, so without this the calls above bind to the synchronous one — which *fulfils*
    /// the expectation when no commands are expected instead of inverting it, leaving the
    /// "nothing is emitted" assertions passing without ever waiting.
    private func test(
        viewModel: PhotoBrowserViewModel,
        actions: [PhotoBrowserViewModel.Action],
        expectedCommands: [PhotoBrowserViewModel.Command],
        timeout: TimeInterval = 3.0
    ) async {
        await test(
            viewModel: viewModel,
            actions: actions,
            expectedCommands: expectedCommands,
            timeout: timeout,
            expectationValidation: { $0 == $1 })
    }

    /// A loaded range longer than the prefetch reach, so a case can put the current photo within
    /// reach of one end only. With both ends in reach a single move issues two requests whose
    /// completion order is undefined — not what any of these cases is about, and the shared helper
    /// turns one unexpected command into a fatal error rather than a failed assertion.
    private func nodes(_ handles: ClosedRange<HandleEntity>) -> [NodeEntity] {
        handles.map(node)
    }

    private func node(_ handle: HandleEntity) -> NodeEntity {
        NodeEntity(name: "node-\(handle)", handle: handle)
    }
}
