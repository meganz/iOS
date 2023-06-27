@testable import MEGA
@testable import MEGADataMock
import XCTest

final class CloudDriveViewControllerTests: XCTestCase {
    
    func testNodeAction_whenSelectFavorite_reloadCollectionOnlyOnce() {
        let selectedNode = anyNode()
        let mockNodeActionViewController = makeNodeActionViewController(node: selectedNode, displayMode: .cloudDrive)
        let sut = makeSUT()
        setNoEditingState(on: sut)
        
        sut.simulateUserSelectFavorite(mockNodeActionViewController, selectedNode)
        sut.simulateOnNodesUpdateReloadUI()
        
        XCTAssertEqual(sut.collectionView().messages, [ .reloadData ])
    }
    
    // MARK: - Helpers
    
    private func setNoEditingState(on sut: CloudDriveViewController) {
        sut.cdTableView?.tableView?.isEditing = false
        sut.cdCollectionView?.collectionView?.allowsMultipleSelection = false
    }
    
    private func anyNode() -> MockNode {
        MockNode.init(handle: .invalidHandle, isFavourite: false)
    }
    
    private func makeNodeActionViewController(node: MockNode, displayMode: DisplayMode) -> NodeActionViewController {
        let mockNodeActionViewController = NodeActionViewController(
            node: node,
            delegate: MockNodeActionViewController(),
            displayMode: displayMode,
            isInVersionsView: false,
            isBackupNode: false,
            sender: "any-sender"
        )
        return mockNodeActionViewController
    }
    
    private func makeSUT() -> CloudDriveViewController {
        let storyboard = UIStoryboard(name: "Cloud", bundle: .main)
        let sut = storyboard.instantiateViewController(withIdentifier: "CloudDriveID") as! CloudDriveViewController
        sut.cdTableView = storyboard.instantiateViewController(withIdentifier: "CloudDriveTableID") as? CloudDriveTableViewController
        sut.cdCollectionView = MockCloudDriveCollectionViewController()
        sut.loadView()
        sut.cdTableView?.loadView()
        sut.cdCollectionView?.loadView()
        return (sut)
    }
}

private extension CloudDriveViewController {
    func simulateUserSelectFavorite(_ nodeActionViewController: NodeActionViewController, _ selectedNode: MockNode) {
        nodeAction(nodeActionViewController, didSelect: .favourite, for: selectedNode, from: "any-sender")
    }
    
    func simulateOnNodesUpdateReloadUI() {
        reloadUI()
    }
    
    func collectionView() -> MockCloudDriveCollectionViewController {
        cdCollectionView as! MockCloudDriveCollectionViewController
    }
}

private final class MockNodeActionViewController: NodeActionViewControllerDelegate {
    
    func nodeAction(_ nodeAction: NodeActionViewController, didSelect action: MegaNodeActionType, for node: MEGANode, from sender: Any) { }
    
    func nodeAction(_ nodeAction: NodeActionViewController, didSelect action: MegaNodeActionType, forNodes nodes: [MEGANode], from sender: Any) { }
}

private final class MockCloudDriveCollectionViewController: CloudDriveCollectionViewController {
    enum Message: Equatable, CustomStringConvertible {
        case setCollectionViewEditing
        case reloadData
        
        var description: String {
            switch self {
            case .setCollectionViewEditing: return "setCollectionViewEditing"
            case .reloadData: return "reloadData"
            }
        }
    }
    
    private(set) var messages = [Message]()
    
    override func setCollectionViewEditing(_ editing: Bool, animated: Bool) {
        messages.append(.setCollectionViewEditing)
    }
    
    override func reloadData() {
        messages.append(.reloadData)
    }
}
