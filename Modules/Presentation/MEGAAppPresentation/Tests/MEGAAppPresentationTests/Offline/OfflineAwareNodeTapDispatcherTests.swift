import MEGAAppPresentation
import MEGAAppPresentationMock
import MEGADomain
import MEGADomainMock
import XCTest

@MainActor
final class OfflineAwareNodeTapDispatcherTests: XCTestCase {

    private let node = NodeEntity(name: "report.pdf", handle: 1, isFile: true)

    private func makeSUT(
        isActive: Bool = true,
        shouldBlock: Bool = false,
        nodes: [NodeEntity]? = nil
    ) -> OfflineAwareNodeTapDispatcher {
        OfflineAwareNodeTapDispatcher(
            offlineFileOpenGuard: MockOfflineFileOpenGuard(isActive: isActive, shouldBlock: shouldBlock),
            nodeUseCase: MockNodeDataUseCase(nodes: nodes ?? [node])
        )
    }

    func testDispatch_whenGuardIsInactive_opensSynchronouslyExactlyOnce() {
        let sut = makeSUT(isActive: false)
        var openCount = 0

        sut.dispatch(nodeHandle: node.handle, isFolder: false) { _ in openCount += 1 }

        // No awaiting: the tap must not be deferred while nothing can be blocked
        XCTAssertEqual(openCount, 1)
    }

    func testDispatch_whenGuardIsInactive_doesNotResolveTheNode() {
        let sut = makeSUT(isActive: false)
        var resolvedNode: NodeEntity?

        sut.dispatch(nodeHandle: node.handle, isFolder: false) { resolvedNode = $0 }

        XCTAssertNil(resolvedNode, "the router should resolve it, keeping the tap synchronous")
    }

    func testDispatch_folderTap_opensSynchronouslyEvenWhenTheGuardIsActive() {
        let sut = makeSUT(isActive: true, shouldBlock: true)
        var openCount = 0

        sut.dispatch(nodeHandle: node.handle, isFolder: true) { _ in openCount += 1 }

        XCTAssertEqual(openCount, 1)
    }

    func testDispatch_whenFileIsBlocked_showsSnackBarAndDoesNotOpen() async {
        let sut = makeSUT(shouldBlock: true)
        let snackBarShown = expectation(description: "snack bar shown")
        sut.showFileUnavailableSnackBar = { snackBarShown.fulfill() }
        var openCount = 0

        sut.dispatch(nodeHandle: node.handle, isFolder: false) { _ in openCount += 1 }

        await fulfillment(of: [snackBarShown], timeout: 1)
        XCTAssertEqual(openCount, 0)
    }

    func testDispatch_whenFileIsNotBlocked_opensOnceWithTheResolvedNode() async {
        let sut = makeSUT(shouldBlock: false)
        let opened = expectation(description: "open called")
        var openCount = 0
        var resolvedNode: NodeEntity?

        sut.dispatch(nodeHandle: node.handle, isFolder: false) {
            resolvedNode = $0
            openCount += 1
            opened.fulfill()
        }

        await fulfillment(of: [opened], timeout: 1)
        XCTAssertEqual(openCount, 1)
        // Handing the entity over lets the router skip a second lookup
        XCTAssertEqual(resolvedNode, node)
    }

    func testDispatch_whenNodeCannotBeResolved_opensWithoutEntityAndShowsNoSnackBar() async {
        let sut = makeSUT(shouldBlock: true, nodes: [])
        let opened = expectation(description: "open called")
        var resolvedNode: NodeEntity?
        var snackBarShownCount = 0
        sut.showFileUnavailableSnackBar = { snackBarShownCount += 1 }

        sut.dispatch(nodeHandle: 999, isFolder: false) {
            resolvedNode = $0
            opened.fulfill()
        }

        await fulfillment(of: [opened], timeout: 1)
        XCTAssertNil(resolvedNode)
        XCTAssertEqual(snackBarShownCount, 0, "folder navigation must not be blocked by an unresolvable handle")
    }

    func testDispatch_repeatTapsOnTheSameNodeWhileChecking_areDroppedUntilTheCheckFinishes() async {
        let sut = makeSUT(shouldBlock: true)
        let snackBarShown = expectation(description: "snack bar shown once")
        // A regression should fail on the count below, not crash the runner on over-fulfilment
        snackBarShown.assertForOverFulfill = false
        var snackBarShownCount = 0
        sut.showFileUnavailableSnackBar = {
            snackBarShownCount += 1
            snackBarShown.fulfill()
        }

        // Both taps land before the first check can finish, since it awaits the node lookup
        sut.dispatch(nodeHandle: node.handle, isFolder: false) { _ in }
        sut.dispatch(nodeHandle: node.handle, isFolder: false) { _ in }

        await fulfillment(of: [snackBarShown], timeout: 1)
        XCTAssertEqual(snackBarShownCount, 1)
    }

    func testDispatch_tapsOnDifferentNodesWhileChecking_areAllProcessed() async {
        let other = NodeEntity(name: "other.pdf", handle: 2, isFile: true)
        let sut = makeSUT(shouldBlock: true, nodes: [node, other])
        let bothShown = expectation(description: "snack bar shown for both nodes")
        bothShown.expectedFulfillmentCount = 2
        sut.showFileUnavailableSnackBar = { bothShown.fulfill() }

        sut.dispatch(nodeHandle: node.handle, isFolder: false) { _ in }
        sut.dispatch(nodeHandle: other.handle, isFolder: false) { _ in }

        await fulfillment(of: [bothShown], timeout: 1)
    }

    func testDispatch_tappingTheSameNodeAgainAfterTheCheckFinished_isProcessed() async {
        let sut = makeSUT(shouldBlock: true)
        // The handle is released right after this closure runs, with no suspension in between,
        // so observing the first call means the first dispatch has finished bookkeeping
        let firstCheckDone = expectation(description: "first check done")
        let secondCheckDone = expectation(description: "second check done")
        var callCount = 0
        sut.showFileUnavailableSnackBar = {
            callCount += 1
            if callCount == 1 {
                firstCheckDone.fulfill()
            } else {
                secondCheckDone.fulfill()
            }
        }

        sut.dispatch(nodeHandle: node.handle, isFolder: false) { _ in }
        await fulfillment(of: [firstCheckDone], timeout: 1)
        sut.dispatch(nodeHandle: node.handle, isFolder: false) { _ in }

        await fulfillment(of: [secondCheckDone], timeout: 1)
        XCTAssertEqual(callCount, 2)
    }
}
