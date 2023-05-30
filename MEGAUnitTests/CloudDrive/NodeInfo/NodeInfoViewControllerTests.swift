import XCTest
import MEGADataMock
@testable import MEGA

final class NodeInfoViewControllerTests: XCTestCase {

    func testDisplay_whenTeardown_doesNotHaveMemoryLeak() {
        let storyboard =  UIStoryboard(name: "Node", bundle: nil)
        guard let nodeInfoNavigationController = storyboard.instantiateViewController(withIdentifier: "NodeInfoNavigationControllerID") as? UINavigationController,
              let sut = nodeInfoNavigationController.viewControllers.first as? NodeInfoViewController else {
            XCTFail("Expect to create \(type(of: NodeInfoViewController.self)) instance, but fail.")
            return
        }
        let anyMegaNode = MockNode(handle: 1)
        let anyViewController = UIViewController()
        let nodeActionDelegate = NodeActionViewControllerGenericDelegate(viewController: anyViewController)
        
        sut.display(anyMegaNode, withDelegate: nodeActionDelegate)
        
        trackForMemoryLeaks(on: sut)
    }
    
    // MARK: - Helpers
    
    final class MockNodeActionViewController: NodeActionViewControllerDelegate, NodeInfoViewControllerDelegate {
        
        func nodeAction(_ nodeAction: NodeActionViewController, didSelect action: MegaNodeActionType, for node: MEGANode, from sender: Any) {
            
        }
        
        func nodeAction(_ nodeAction: NodeActionViewController, didSelect action: MegaNodeActionType, forNodes nodes: [MEGANode], from sender: Any) {
            
        }
        
        func nodeInfoViewController(_ nodeInfoViewController: NodeInfoViewController, presentParentNode node: MEGANode) {
            
        }
    }

}
