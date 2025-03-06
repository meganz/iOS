@testable import MEGA
import MEGASDKRepoMock
import Testing

@Suite("OverDiskQuotaNodeActionViewControllerDelegate Tests")
struct OverDiskQuotaNodeActionViewControllerDelegateTests {
    @Suite("Not Paywalled")
    @MainActor
    struct NotPaywalled {
        @Test("when over disk quota not reached it should allow the action")
        func overDiskQuotaNotReached() {
            let delegate = MockNodeActionViewControllerDelegate()
            let sut = makeSUT(delegate: delegate)
            let action = MegaNodeActionType.download
            let nodes = makeNodes()
            
            sut.nodeAction(makeNodeActionViewController(), didSelect: action, forNodes: nodes, from: self)
            
            #expect(delegate.action == action)
            #expect(delegate.nodes == nodes)
        }
    }
    
    @Suite("Paywalled")
    @MainActor
    struct Paywalled {
        @Test("when paywalled and action should be checked it should show over disk quota and not allow the action")
        func overDiskQuotaNotReached() {
            let overDiskQuotaChecker = MockOverDiskQuotaChecker(isPaywalled: true)
            let delegate = MockNodeActionViewControllerDelegate()
            let action = MegaNodeActionType.download
            let sut = makeSUT(
                delegate: delegate,
                overDiskQuotaChecker: overDiskQuotaChecker,
                overDiskActions: [action])
            let nodes = makeNodes()
            
            sut.nodeAction(makeNodeActionViewController(), didSelect: action, forNodes: nodes, from: self)
            
            #expect(delegate.action == nil)
            #expect(delegate.nodes == nil)
        }
        
        @Test("when paywalled it should allow action if not specified in the constructor")
        func allowAction() {
            let overDiskQuotaChecker = MockOverDiskQuotaChecker(isPaywalled: true)
            let delegate = MockNodeActionViewControllerDelegate()
            let action = MegaNodeActionType.download
            let sut = makeSUT(
                delegate: delegate,
                overDiskQuotaChecker: overDiskQuotaChecker,
                overDiskActions: [])
            let nodes = makeNodes()
            
            sut.nodeAction(makeNodeActionViewController(), didSelect: action, forNodes: nodes, from: self)
            
            #expect(delegate.action == action)
            #expect(delegate.nodes == nodes)
        }
    }

    @MainActor
    private static func makeSUT(
        delegate: some NodeActionViewControllerDelegate = MockNodeActionViewControllerDelegate(),
        overDiskQuotaChecker: some OverDiskQuotaChecking = MockOverDiskQuotaChecker(),
        overDiskActions: Set<MegaNodeActionType> = []
    ) -> OverDiskQuotaNodeActionViewControllerDelegate {
        .init(
            delegate: delegate,
            overDiskQuotaChecker: overDiskQuotaChecker,
            overDiskActions: overDiskActions)
    }
    
    @MainActor
    private static func makeNodeActionViewController() -> NodeActionViewController {
        NodeActionViewController(
            node: MockNode(handle: 1),
            delegate: MockNodeActionViewControllerDelegate(),
            displayMode: .cloudDrive,
            isInVersionsView: false,
            isBackupNode: false,
            sender: "any-sender"
        )
    }
    
    private static func makeNodes() -> [MEGANode] {
        [MockNode(handle: 1), MockNode(handle: 2)]
    }
}

private final class MockNodeActionViewControllerDelegate: NodeActionViewControllerDelegate {
    private(set) var action: MegaNodeActionType?
    private(set) var nodes: [MEGANode]?
    
    nonisolated init() { }
    
    func nodeAction(_ nodeAction: NodeActionViewController, didSelect action: MegaNodeActionType, for node: MEGANode, from sender: Any) {
        self.nodeAction(nodeAction, didSelect: action, forNodes: [node], from: sender)
    }
    
    func nodeAction(_ nodeAction: NodeActionViewController, didSelect action: MegaNodeActionType, forNodes nodes: [MEGANode], from sender: Any) {
        self.action = action
        self.nodes = nodes
    }
}
