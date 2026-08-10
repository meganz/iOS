@testable import MEGA
import XCTest

@MainActor
final class OfflineAwareNodeActionDelegateTests: XCTestCase {

    func testSingleNodeAction_whenActionNeedsNoConnection_forwardsWithoutConsultingTheGuard() {
        let wrapped = MockNodeActionViewControllerDelegate()
        let offlineActionGuard = MockOfflineActionGuard(allowsAction: false)
        let sut = OfflineAwareNodeActionDelegate(wrapping: wrapped, offlineActionGuard: offlineActionGuard)

        sut.nodeAction(.mockSheet(), didSelect: .info, for: MEGANode(), from: UIView())

        XCTAssertEqual(wrapped.singleNodeActions, [.info])
        XCTAssertEqual(offlineActionGuard.allowsActionRequiringConnectionCallCount, 0)
    }

    func testSingleNodeAction_whenActionNeedsConnectionAndGuardAllows_forwards() {
        let wrapped = MockNodeActionViewControllerDelegate()
        let sut = OfflineAwareNodeActionDelegate(
            wrapping: wrapped,
            offlineActionGuard: MockOfflineActionGuard(allowsAction: true)
        )

        sut.nodeAction(.mockSheet(), didSelect: .rename, for: MEGANode(), from: UIView())

        XCTAssertEqual(wrapped.singleNodeActions, [.rename])
    }

    func testSingleNodeAction_whenActionNeedsConnectionAndGuardBlocks_doesNotForward() {
        let wrapped = MockNodeActionViewControllerDelegate()
        let sut = OfflineAwareNodeActionDelegate(
            wrapping: wrapped,
            offlineActionGuard: MockOfflineActionGuard(allowsAction: false)
        )

        sut.nodeAction(.mockSheet(), didSelect: .rename, for: MEGANode(), from: UIView())

        XCTAssertTrue(wrapped.singleNodeActions.isEmpty)
    }

    func testMultipleNodesAction_whenGuardBlocks_doesNotForward() {
        let wrapped = MockNodeActionViewControllerDelegate()
        let sut = OfflineAwareNodeActionDelegate(
            wrapping: wrapped,
            offlineActionGuard: MockOfflineActionGuard(allowsAction: false)
        )

        sut.nodeAction(.mockSheet(), didSelect: .moveToRubbishBin, forNodes: [MEGANode()], from: UIView())

        XCTAssertTrue(wrapped.multipleNodesActions.isEmpty)
    }

    func testMultipleNodesAction_whenGuardAllows_forwards() {
        let wrapped = MockNodeActionViewControllerDelegate()
        let sut = OfflineAwareNodeActionDelegate(
            wrapping: wrapped,
            offlineActionGuard: MockOfflineActionGuard(allowsAction: true)
        )

        sut.nodeAction(.mockSheet(), didSelect: .moveToRubbishBin, forNodes: [MEGANode()], from: UIView())

        XCTAssertEqual(wrapped.multipleNodesActions, [.moveToRubbishBin])
    }
}

private final class MockNodeActionViewControllerDelegate: NSObject, NodeActionViewControllerDelegate {
    private(set) var singleNodeActions: [MegaNodeActionType] = []
    private(set) var multipleNodesActions: [MegaNodeActionType] = []

    func nodeAction(_ nodeAction: NodeActionViewController, didSelect action: MegaNodeActionType, for node: MEGANode, from sender: Any) {
        singleNodeActions.append(action)
    }

    func nodeAction(_ nodeAction: NodeActionViewController, didSelect action: MegaNodeActionType, forNodes nodes: [MEGANode], from sender: Any) {
        multipleNodesActions.append(action)
    }
}

private extension NodeActionViewController {
    /// The sheet is only passed through to the wrapped delegate, never read by the decorator.
    static func mockSheet() -> NodeActionViewController {
        NodeActionViewController(
            nodes: [MEGANode()],
            delegate: MockNodeActionViewControllerDelegate(),
            displayMode: .cloudDrive,
            sender: UIView()
        )
    }
}
