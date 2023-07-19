@testable import MEGA
@testable import MEGADataMock
import XCTest

final class CloudDriveViewControllerTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        cleanTestArtifacts()
    }
    
    override func tearDown() {
        super.tearDown()
        cleanTestArtifacts()
    }
    
    func testNodeAction_whenSelectFavoriteOnViewModePreferenceThumbnail_reloadCollectionAtIndexPath() {
        simulateUserHasThumbnailViewModePreference()
        let selectedNode = anyNode()
        let mockNodeActionViewController = makeNodeActionViewController(nodes: [selectedNode], displayMode: .cloudDrive)
        let sut = makeSUT(nodeList: MockNodeList(nodes: [selectedNode]))
        setNoEditingState(on: sut)
        
        sut.simulateUserSelectFavorite(mockNodeActionViewController, selectedNode)
        sut.simulateOnNodesUpdateReloadUI(nodeList: sut.nodes)
        
        XCTAssertEqual(sut.collectionView().messages, [ .reloadDataAt([ IndexPath(item: 0, section: 1) ]) ])
    }
    
    func testReloadUI_whenUpdatesOnOneNodeOnViewModePreferenceThumbnail_reloadCollectionAtIndexPath() {
        simulateUserHasThumbnailViewModePreference()
        let sampleNode = anyNode()
        let sut = makeSUT(nodeList: MockNodeList(nodes: [sampleNode]))
        setNoEditingState(on: sut)
        
        sut.simulateOnNodesUpdateReloadUI(nodeList: sut.nodes)
        
        XCTAssertEqual(sut.collectionView().messages, [ .reloadDataAt([ IndexPath(item: 0, section: 1) ]) ])
    }
    
    func testReloadUI_whenUpdatesMoreThanOneNodeOnViewModePreferenceThumbnail_reloadCollection() {
        simulateUserHasThumbnailViewModePreference()
        let sampleNode = anyNode()
        let sut = makeSUT(nodeList: MockNodeList(nodes: [sampleNode, sampleNode, sampleNode]))
        setNoEditingState(on: sut)
        
        sut.simulateOnNodesUpdateReloadUI(nodeList: sut.nodes)
        
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
    
    private func makeNodeActionViewController(nodes: [MockNode], displayMode: DisplayMode) -> NodeActionViewController {
        let mockNodeActionViewController = NodeActionViewController(
            nodes: nodes,
            delegate: MockNodeActionViewController(),
            displayMode: displayMode,
            sender: "any-sender"
        )
        return mockNodeActionViewController
    }
    
    private func makeSUT(nodeList: MockNodeList) -> CloudDriveViewController {
        let storyboard = UIStoryboard(name: "Cloud", bundle: .main)
        let sut = storyboard.instantiateViewController(withIdentifier: "CloudDriveID") as! CloudDriveViewController
        sut.cdTableView = storyboard.instantiateViewController(withIdentifier: "CloudDriveTableID") as? CloudDriveTableViewController
        sut.loadView()
        sut.viewDidLoad()
        sut.cdCollectionView = MockCloudDriveCollectionViewController()
        sut.cdTableView?.loadView()
        sut.cdCollectionView?.loadView()
        sut.nodes = nodeList
        return (sut)
    }
    
    private func simulateUserHasThumbnailViewModePreference() {
        UserDefaults.standard.setValue(ViewModePreference.thumbnail.rawValue, forKey: MEGAViewModePreference)
    }
    
    private func cleanTestArtifacts() {
        clearViewModePreference()
    }
    
    private func clearViewModePreference() {
        UserDefaults.standard.removeObject(forKey: MEGAViewModePreference)
    }
}

private extension CloudDriveViewController {
    func simulateUserSelectFavorite(_ nodeActionViewController: NodeActionViewController, _ selectedNode: MockNode) {
        nodeAction(nodeActionViewController, didSelect: .favourite, for: selectedNode, from: "any-sender")
    }
    
    func simulateOnNodesUpdateReloadUI(nodeList: MEGANodeList?) {
        reloadUI(nodeList)
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
        case reloadDataAt([IndexPath])
        
        var description: String {
            switch self {
            case .setCollectionViewEditing: return "setCollectionViewEditing"
            case .reloadData: return "reloadData"
            case let .reloadDataAt(indexPaths): return "reloadDataAtIndexPaths:\(indexPaths)"
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
    
    override func reloadData(at indexPaths: [IndexPath]) {
        messages.append(.reloadDataAt(indexPaths))
    }
}
