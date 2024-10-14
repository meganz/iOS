@testable import MEGA
import MEGADomainMock
import MEGAPresentationMock
import MEGASDKRepoMock
import XCTest

final class NodeInfoViewControllerTests: XCTestCase {

    func testDisplay_whenTeardown_doesNotHaveMemoryLeak() {
        let anyMegaNode = MockNode(handle: 1)
        let anyViewController = UIViewController()
        let nodeActionDelegate = NodeActionViewControllerGenericDelegate(
            viewController: anyViewController,
            moveToRubbishBinViewModel: MockMoveToRubbishBinViewModel()
        )
        let viewModel = NodeInfoViewModel(
            withNode: anyMegaNode,
            nodeUseCase: MockNodeDataUseCase(),
            backupUseCase: MockBackupsUseCase()
        )

        let sut = UIStoryboard(name: "Node", bundle: nil).instantiateViewController(
            identifier: "NodeInfoViewControllerID"
        ) { coder in
            NodeInfoViewController(coder: coder, viewModel: viewModel, delegate: nodeActionDelegate)
        }

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
