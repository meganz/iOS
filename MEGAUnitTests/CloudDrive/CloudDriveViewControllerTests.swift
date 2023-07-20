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
    
    // MARK: - NodeAction favorite
    
    func testNodeAction_whenSelectFavoriteOnViewModePreferenceThumbnailAndHasFolderTypeOnly_reloadCollectionAtIndexPath() {
        simulateUserHasThumbnailViewModePreference()
        let displayMode = cloudDriveDisplayMode()
        let selectedNode = anyNode(handle: .min, nodeType: .folder)
        let mockNodeActionViewController = makeNodeActionViewController(nodes: [selectedNode], displayMode: displayMode)
        let sut = makeSUT(nodes: [selectedNode], displayMode: displayMode)
        setNoEditingState(on: sut)
        
        sut.simulateUserSelectFavorite(mockNodeActionViewController, selectedNode)
        sut.simulateOnNodesUpdateReloadUI(nodeList: sut.nodes)
        
        XCTAssertEqual(sut.collectionView().messages, [ .reloadDataAt([ IndexPath(item: 0, section: 0) ]) ])
    }
    
    func testNodeAction_whenSelectFavoriteOnViewModePreferenceThumbnailAndHasFileTypeOnly_reloadCollectionAtIndexPath() {
        simulateUserHasThumbnailViewModePreference()
        let displayMode = cloudDriveDisplayMode()
        let selectedNode = anyNode(handle: .min, nodeType: .file)
        let mockNodeActionViewController = makeNodeActionViewController(nodes: [selectedNode], displayMode: displayMode)
        let sut = makeSUT(nodes: [selectedNode], displayMode: displayMode)
        setNoEditingState(on: sut)
        
        sut.simulateUserSelectFavorite(mockNodeActionViewController, selectedNode)
        sut.simulateOnNodesUpdateReloadUI(nodeList: sut.nodes)
        
        XCTAssertEqual(sut.collectionView().messages, [ .reloadDataAt([ IndexPath(item: 0, section: 1) ]) ])
    }
    
    // MARK: - NodeAction Remove
    
    func testNodeAction_whenSelectRubbishBinOnRubbishBinPage_reloadCollection() {
        simulateUserHasThumbnailViewModePreference()
        let displayMode = rubbishBinDisplayMode()
        let selectedNode = anyNode(handle: .min, nodeType: .file)
        let mockNodeActionViewController = makeNodeActionViewController(nodes: [selectedNode], displayMode: displayMode)
        let sut = makeSUT(nodes: [selectedNode], displayMode: displayMode)
        setNoEditingState(on: sut)
        
        sut.simulateUserSelectDelete(mockNodeActionViewController, selectedNode)
        sut.simulateOnNodesUpdateReloadUI(nodeList: sut.nodes)
        
        XCTAssertEqual(sut.collectionView().messages, [ .reloadData ])
    }
    
    // MARK: - ReloadUI
    
    func testReloadUI_whenUpdatesOnOneNodeOnViewModePreferenceThumbnailHasFileTypeOnly_reloadCollectionAtIndexPath() {
        simulateUserHasThumbnailViewModePreference()
        let displayMode = cloudDriveDisplayMode()
        let sampleNode = anyNode(handle: anyHandle(), nodeType: .file)
        let sut = makeSUT(nodes: [sampleNode], displayMode: displayMode)
        setNoEditingState(on: sut)
        
        sut.simulateOnNodesUpdateReloadUI(nodeList: sut.nodes)
        
        XCTAssertEqual(sut.collectionView().messages, [ .reloadDataAt([ IndexPath(item: 0, section: 1) ]) ])
    }
    
    func testReloadUI_whenUpdatesMoreThanOneNodeOnViewModePreferenceThumbnail_reloadCollection() {
        simulateUserHasThumbnailViewModePreference()
        let displayMode = cloudDriveDisplayMode()
        let firstNode = anyNode(handle: anyHandle(), nodeType: .file)
        let secondNode = anyNode(handle: anyHandle() + 1, nodeType: .file)
        let thirdNode = anyNode(handle: anyHandle() + 2, nodeType: .file)
        let sut = makeSUT(nodes: [firstNode, secondNode, thirdNode], displayMode: displayMode)
        setNoEditingState(on: sut)
        
        sut.simulateOnNodesUpdateReloadUI(nodeList: sut.nodes)
        
        XCTAssertEqual(sut.collectionView().messages, [ .reloadData ])
    }
    
    // MARK: - findIndexPathForNode
    
    func testfindIndexPathForNode_whenHasFolderOnly_deliversCorrrectIndexPathForFolderNode() {
        let folderNode = anyNode(handle: anyHandle(), nodeType: .folder)
        let nodes = [folderNode]
        let sut = makeSUT(nodes: nodes)
        
        let indexPath = sut.findIndexPath(for: folderNode, source: nodes)
        
        XCTAssertEqual(indexPath.section, 0)
        XCTAssertEqual(indexPath.item, 0)
    }
    
    func testfindIndexPathForNode_whenHasMoreThanOneFolders_deliversCorrrectIndexPathForFirstFolderNode() {
        let firstFolderNode = anyNode(handle: anyHandle(), nodeType: .folder)
        let secondFolderNode = anyNode(handle: anyHandle() + 1, nodeType: .folder)
        let nodes = [firstFolderNode, secondFolderNode]
        let sut = makeSUT(nodes: nodes)
        
        let indexPath = sut.findIndexPath(for: firstFolderNode, source: nodes)
        
        XCTAssertEqual(indexPath.section, 0)
        XCTAssertEqual(indexPath.item, 0)
    }
    
    func testfindIndexPathForNode_whenHasTwoFolders_deliversCorrrectIndexPathForLastFolderNode() {
        let firstFolderNode = anyNode(handle: anyHandle(), nodeType: .folder)
        let secondFolderNode = anyNode(handle: anyHandle() + 1, nodeType: .folder)
        let nodes = [firstFolderNode, secondFolderNode]
        let sut = makeSUT(nodes: nodes)
        
        let indexPath = sut.findIndexPath(for: secondFolderNode, source: nodes)
        
        XCTAssertEqual(indexPath.section, 0)
        XCTAssertEqual(indexPath.item, 1)
    }
    
    func testfindIndexPathForNode_whenHasMoreThanTwoFolders_deliversCorrrectIndexPathForNonFirstAndLastFolderNode() {
        let firstFolderNode = anyNode(handle: anyHandle(), nodeType: .folder)
        let secondFolderNode = anyNode(handle: anyHandle() + 1, nodeType: .folder)
        let thirdFolderNode = anyNode(handle: anyHandle() + 2, nodeType: .folder)
        let nodes = [firstFolderNode, secondFolderNode, thirdFolderNode]
        let sut = makeSUT(nodes: nodes)
        
        let indexPath = sut.findIndexPath(for: secondFolderNode, source: nodes)
        
        XCTAssertEqual(indexPath.section, 0)
        XCTAssertEqual(indexPath.item, 1)
    }
    
    func testfindIndexPathForNode_whenHasFolderAndFile_deliversCorrrectIndexPathForFolderNode() {
        let folderNode = anyNode(handle: anyHandle(), nodeType: .folder)
        let fileNode = anyNode(handle: anyHandle() + 1, nodeType: .file)
        let nodes = [folderNode, fileNode]
        let sut = makeSUT(nodes: nodes)
        
        let indexPath = sut.findIndexPath(for: folderNode, source: nodes)
        
        XCTAssertEqual(indexPath.section, 0)
        XCTAssertEqual(indexPath.item, 0)
    }
    
    func testfindIndexPathForNode_whenHasFolderAndFile_deliversCorrrectIndexPathForFileNode() {
        let folderNode = anyNode(handle: anyHandle(), nodeType: .folder)
        let fileNode = anyNode(handle: anyHandle() + 1, nodeType: .file)
        let nodes = [folderNode, fileNode]
        let sut = makeSUT(nodes: nodes)
        
        let indexPath = sut.findIndexPath(for: fileNode, source: nodes)
        
        XCTAssertEqual(indexPath.section, 1)
        XCTAssertEqual(indexPath.item, 0)
    }
    
    func testfindIndexPathForNode_whenHasFolderAndMoreThanOneFiles_deliversCorrrectIndexPathForFolderNode() {
        let folderNode = anyNode(handle: anyHandle(), nodeType: .folder)
        let fileNode1 = anyNode(handle: anyHandle() + 1, nodeType: .file)
        let fileNode2 = anyNode(handle: anyHandle() + 2, nodeType: .file)
        let nodes = [folderNode, fileNode1, fileNode2]
        let sut = makeSUT(nodes: nodes)
        
        let indexPath = sut.findIndexPath(for: folderNode, source: nodes)
        
        XCTAssertEqual(indexPath.section, 0)
        XCTAssertEqual(indexPath.item, 0)
    }
    
    func testfindIndexPathForNode_whenHasFolderAndMoreThanOneFiles_deliversCorrrectIndexPathForLastFileNode() {
        let folderNode = anyNode(handle: anyHandle(), nodeType: .folder)
        let fileNode1 = anyNode(handle: anyHandle() + 1, nodeType: .file)
        let fileNode2 = anyNode(handle: anyHandle() + 2, nodeType: .file)
        let nodes = [folderNode, fileNode1, fileNode2]
        let sut = makeSUT(nodes: nodes)
        
        let indexPath = sut.findIndexPath(for: fileNode2, source: nodes)
        
        XCTAssertEqual(indexPath.section, 1)
        XCTAssertEqual(indexPath.item, 1)
    }
    
    func testfindIndexPathForNode_whenHasMoreThanOneFoldersAndOneFile_deliversCorrrectIndexPathForFirstFolderNode() {
        let folderNode1 = anyNode(handle: anyHandle(), nodeType: .folder)
        let folderNode2 = anyNode(handle: anyHandle() + 1, nodeType: .folder)
        let fileNode1 = anyNode(handle: anyHandle() + 2, nodeType: .file)
        let nodes = [folderNode1, folderNode2, fileNode1]
        let sut = makeSUT(nodes: nodes)
        
        let indexPath = sut .findIndexPath(for: folderNode1, source: nodes)
        
        XCTAssertEqual(indexPath.section, 0)
        XCTAssertEqual(indexPath.item, 0)
    }
    
    func testfindIndexPathForNode_whenHasMoreThanOneFoldersAndOneFile_deliversCorrrectIndexPathForFirstFileNode() {
        let folderNode1 = anyNode(handle: anyHandle(), nodeType: .folder)
        let folderNode2 = anyNode(handle: anyHandle() + 1, nodeType: .folder)
        let fileNode1 = anyNode(handle: anyHandle() + 2, nodeType: .file)
        let fileNode2 = anyNode(handle: anyHandle() + 3, nodeType: .file)
        let nodes = [folderNode1, folderNode2, fileNode1, fileNode2]
        let sut = makeSUT(nodes: nodes)
        
        let indexPath = sut.findIndexPath(for: fileNode2, source: nodes)
        
        XCTAssertEqual(indexPath.section, 1)
        XCTAssertEqual(indexPath.item, 1)
    }
    
    func testfindIndexPathForNode_whenHasMoreThanOneFoldersAndMoreThanOneFiles_deliversCorrrectIndexPathForLastFileNode() {
        let folderNode1 = anyNode(handle: anyHandle(), nodeType: .folder)
        let folderNode2 = anyNode(handle: anyHandle() + 1, nodeType: .folder)
        let fileNode1 = anyNode(handle: anyHandle() + 2, nodeType: .file)
        let nodes = [folderNode1, folderNode2, fileNode1]
        let sut = makeSUT(nodes: nodes)
        
        let indexPath = sut.findIndexPath(for: fileNode1, source: nodes)
        
        XCTAssertEqual(indexPath.section, 1)
        XCTAssertEqual(indexPath.item, 0)
    }
    
    func testfindIndexPathForNode_whenHasFileOnly_deliversCorrrectIndexPathForFileNode() {
        let fileNode = anyNode(handle: anyHandle(), nodeType: .file)
        let nodes = [fileNode]
        let sut = makeSUT(nodes: nodes)
        
        let indexPath = sut.findIndexPath(for: fileNode, source: nodes)
        
        XCTAssertEqual(indexPath.section, 1)
        XCTAssertEqual(indexPath.item, 0)
    }
    
    func testfindIndexPathForNode_whenHasTwoFiles_deliversCorrrectIndexPathForLastFileNode() {
        let firstFileNode = anyNode(handle: anyHandle(), nodeType: .file)
        let secondFileNode = anyNode(handle: anyHandle() + 1, nodeType: .file)
        let nodes = [firstFileNode, secondFileNode]
        let sut = makeSUT(nodes: nodes)
        
        let indexPath = sut.findIndexPath(for: secondFileNode, source: nodes)
        
        XCTAssertEqual(indexPath.section, 1)
        XCTAssertEqual(indexPath.item, 1)
    }
    
    func testfindIndexPathForNode_whenHasMoreThanTwoFiles_deliversCorrrectIndexPathForNonFirstAndLastFileNode() {
        let firstFileNode = anyNode(handle: anyHandle(), nodeType: .file)
        let secondFileNode = anyNode(handle: anyHandle() + 1, nodeType: .file)
        let thirdFileNode = anyNode(handle: anyHandle() + 2, nodeType: .file)
        let nodes = [firstFileNode, secondFileNode, thirdFileNode]
        let sut = makeSUT(nodes: nodes)
        
        let indexPath = sut.findIndexPath(for: secondFileNode, source: nodes)
        
        XCTAssertEqual(indexPath.section, 1)
        XCTAssertEqual(indexPath.item, 1)
    }
    
    // MARK: - Helpers
    
    private func setNoEditingState(on sut: CloudDriveViewController) {
        sut.cdTableView?.tableView?.isEditing = false
        sut.cdCollectionView?.collectionView?.allowsMultipleSelection = false
    }
    
    private func anyNode(handle: MEGAHandle, nodeType: MEGANodeType) -> MockNode {
        MockNode.init(handle: handle, nodeType: nodeType, isFavourite: false)
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
    
    private func makeSUT(nodes: [MEGANode], displayMode: DisplayMode = .cloudDrive) -> CloudDriveViewController {
        let storyboard = UIStoryboard(name: "Cloud", bundle: .main)
        let sut = storyboard.instantiateViewController(withIdentifier: "CloudDriveID") as! CloudDriveViewController
        sut.cdTableView = storyboard.instantiateViewController(withIdentifier: "CloudDriveTableID") as? CloudDriveTableViewController
        sut.loadView()
        sut.viewDidLoad()
        sut.cdCollectionView = MockCloudDriveCollectionViewController()
        sut.cdTableView?.loadView()
        sut.cdCollectionView?.loadView()
        sut.nodes = MockNodeList(nodes: nodes)
        sut.displayMode = displayMode
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
    
    private func anyHandle() -> MEGAHandle {
        .min
    }
    
    private func cloudDriveDisplayMode() -> DisplayMode {
        .cloudDrive
    }
    
    private func rubbishBinDisplayMode() -> DisplayMode {
        .rubbishBin
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
    
    func simulateUserSelectDelete(_ nodeActionViewController: NodeActionViewController, _ selectedNode: MockNode) {
        nodeAction(nodeActionViewController, didSelect: .remove, for: selectedNode, from: "any-sender")
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
