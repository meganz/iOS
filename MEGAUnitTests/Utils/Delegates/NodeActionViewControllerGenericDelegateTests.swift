@testable import MEGA
import MEGADataMock
import XCTest

final class NodeActionViewControllerGenericDelegateTests: XCTestCase {

    func testInit_whenTearDown_doesNotHaveMemoryLeak() {
        let sut = makeSUT(viewController: anyViewController())
        
        trackForMemoryLeaks(on: sut)
    }
    
    func testNodeActionDidSelectInfo_whenTeardown_doesNotHaveMemoryLeak() {
        let sut = makeSUT(viewController: anyViewController())
        
        sut.nodeAction(anyNodeActionViewController(), didSelect: .info, for: anyMegaNode(), from: anySender())
        
        trackForMemoryLeaks(on: sut)
    }
    
    // MARK: - Helpers
    
    private func makeSUT(viewController: UIViewController) -> NodeActionViewControllerGenericDelegate {
        let sut = NodeActionViewControllerGenericDelegate(viewController: viewController)
        return sut
    }
    
    private func anyNodeActionViewController() -> NodeActionViewController {
        NodeActionViewController(node: anyMegaNode(), delegate: MockNodeActionViewController(), displayMode: .nodeInfo,
                                 viewMode: .thumbnail, isBackupNode: false, containsMediaFiles: false, sender: anySender())
    }
    
    private func anySender() -> Any {
        "any"
    }
    
    private func anyMegaNode() -> MockNode {
        MockNode(handle: 1)
    }
    
    private func anyViewController() -> UIViewController {
        UIViewController()
    }
    
    final class MockNodeActionViewController: NodeActionViewControllerDelegate {
        
        func nodeAction(_ nodeAction: NodeActionViewController, didSelect action: MegaNodeActionType, for node: MEGANode, from sender: Any) {
            
        }
        
        func nodeAction(_ nodeAction: NodeActionViewController, didSelect action: MegaNodeActionType, forNodes nodes: [MEGANode], from sender: Any) {
            
        }
    }

}
