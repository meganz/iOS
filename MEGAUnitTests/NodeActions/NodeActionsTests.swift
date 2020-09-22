import XCTest
@testable import MEGA

class NodeActionsTests: XCTestCase {

    var actions: [NodeAction] = []

    override func setUp() {
        super.setUp()
    }

    override func tearDown() {
        super .tearDown()
        actions.removeAll()
    }

    //MARK: - Private methods
    
    func contains(nodeActionType type: MegaNodeActionType) -> Bool {
        return !(actions.filter { $0.type == type }).isEmpty
    }
    
    func contains(nodeActionTypes types: [MegaNodeActionType]) -> Bool {
        var containsAllActions = true
        types.forEach { (type) in
            if !contains(nodeActionType: type) {
                containsAllActions = false
            }
        }
        return containsAllActions
    }
    
    // MARK: - Cloud Drive tests

    func testCloudDriveNodeMediaFile() {
        actions = NodeActionBuilder()
            .setDisplayMode(.cloudDrive)
            .setAccessLevel(.accessOwner)
            .setIsMediaFile(true)
            .setIsFile(true)
            .build()
        
        XCTAssertTrue(contains(nodeActionTypes: [.info, .saveToPhotos, .download, .getLink, .share, .sendToChat, .rename, .move, .copy, .moveToRubbishBin]))
    }
    
    func testCloudDriveNodeMediaFileExported() {
        actions = NodeActionBuilder()
            .setDisplayMode(.cloudDrive)
            .setAccessLevel(.accessOwner)
            .setIsMediaFile(true)
            .setIsFile(true)
            .setIsExported(true)
            .build()
        
        XCTAssertTrue(contains(nodeActionTypes: [.info, .saveToPhotos, .download, .manageLink, .removeLink, .share, .sendToChat, .rename, .move, .copy, .moveToRubbishBin]))
    }
    
    func testCloudDriveNodeFolder() {
        actions = NodeActionBuilder()
            .setDisplayMode(.cloudDrive)
            .setAccessLevel(.accessOwner)
            .setIsFile(false)
            .build()
        
        XCTAssertTrue(contains(nodeActionTypes: [.info, .download, .getLink, .shareFolder, .share, . rename, .move, .copy, .moveToRubbishBin]))
    }
    
    func testCloudDriveNodeFolderExported() {
        actions = NodeActionBuilder()
            .setDisplayMode(.cloudDrive)
            .setAccessLevel(.accessOwner)
            .setIsFile(false)
            .setIsExported(true)
            .build()
        
        XCTAssertTrue(contains(nodeActionTypes: [.info, .download, .manageLink, .removeLink, .shareFolder, .share, . rename, .move, .copy, .moveToRubbishBin]))
    }
    
    func testCloudDriveNodeFolderShared() {
        actions = NodeActionBuilder()
            .setDisplayMode(.cloudDrive)
            .setAccessLevel(.accessOwner)
            .setIsFile(false)
            .setIsOutshare(true)
            .build()
        
        XCTAssertTrue(contains(nodeActionTypes: [.info, .download,  .getLink, .manageShare, .share, . rename, .move, .copy, .moveToRubbishBin]))
    }
    
    func testCloudDriveNodeFolderSharedExported() {
        actions = NodeActionBuilder()
            .setDisplayMode(.cloudDrive)
            .setAccessLevel(.accessOwner)
            .setIsFile(false)
            .setIsOutshare(true)
            .setIsExported(true)
            .build()
        
        XCTAssertTrue(contains(nodeActionTypes: [.info, .download,  .manageLink, .removeLink, .manageShare, .share, . rename, .move, .copy, .moveToRubbishBin]))
    }
    
    func testCloudDriveNodeFile() {
        actions = NodeActionBuilder()
            .setDisplayMode(.cloudDrive)
            .setAccessLevel(.accessOwner)
            .setIsFile(true)
            .build()
        
        XCTAssertTrue(contains(nodeActionTypes: [.info, .download, .getLink, .share, .sendToChat, .rename, .move, .copy, .moveToRubbishBin]))
    }
    
    func testCloudDriveNodeExportedFile() {
        actions = NodeActionBuilder()
            .setDisplayMode(.cloudDrive)
            .setAccessLevel(.accessOwner)
            .setIsFile(true)
            .setIsExported(true)
            .build()
        
        XCTAssertTrue(contains(nodeActionTypes: [.info, .download, .manageLink, .removeLink, .share, .sendToChat, .rename, .move, .copy, .moveToRubbishBin]))
    }
    
    func testRubbishBinNodeFolder() {
        actions = NodeActionBuilder()
            .setDisplayMode(.rubbishBin)
            .setAccessLevel(.accessOwner)
            .setIsFile(false)
            .setIsRestorable(true)
            .build()
        
        XCTAssertTrue(contains(nodeActionTypes: [.restore, .info, .rename, .move, .copy, .remove]))
    }
    
    func testRubbishBinNodeFile() {
        actions = NodeActionBuilder()
            .setDisplayMode(.rubbishBin)
            .setAccessLevel(.accessOwner)
            .setIsFile(true)
            .setIsRestorable(true)
            .build()
        
        XCTAssertTrue(contains(nodeActionTypes: [.restore, .info, .sendToChat, .rename, .move, .copy, .remove]))
    }
    
    func testFileFolderNodeDoNotShowInfoAction() {
        actions = NodeActionBuilder()
            .setDisplayMode(.nodeInfo)
            .build()
        XCTAssertFalse(contains(nodeActionType: .info))
    }

    // MARK: - Shared Items tests

    func testIncomingFullSharedFolder() {
        actions = NodeActionBuilder()
            .setDisplayMode(.sharedItem)
            .setAccessLevel(.accessFull)
            .setIsFile(false)
            .setisIncomingShareChildView(true)
            .build()
        
        XCTAssertTrue(contains(nodeActionTypes: [.info, .download, .rename, .copy, .leaveSharing]))
    }
    
    func testIncomingReadAndReadWriteSharedFolder() {
        actions = NodeActionBuilder()
            .setDisplayMode(.sharedItem)
            .setAccessLevel(.accessReadWrite)
            .setIsFile(false)
            .setisIncomingShareChildView(true)
            .build()
        
        XCTAssertTrue(contains(nodeActionTypes: [.info, .download, .copy, .leaveSharing]))
    }
    
    func testOutgoingSharedFolder() {
        actions = NodeActionBuilder()
            .setDisplayMode(.sharedItem)
            .setAccessLevel(.accessOwner)
            .setIsFile(false)
            .build()
        
        XCTAssertTrue(contains(nodeActionTypes: [.info, .download, .manageShare, .share, .rename, .copy, .removeSharing]))
    }
    
    // MARK: - Links tests
    
    func testFileMediaLink() {
        actions = NodeActionBuilder()
            .setDisplayMode(.fileLink)
            .setIsFile(true)
            .setIsMediaFile(true)
            .build()
        
        XCTAssertTrue(contains(nodeActionTypes: [.import, .download, .sendToChat, .saveToPhotos, .share]))
    }
    
    func testFileLink() {
        actions = NodeActionBuilder()
            .setDisplayMode(.fileLink)
            .setIsFile(true)
            .build()
        
        XCTAssertTrue(contains(nodeActionTypes: [.import, .download, .sendToChat, .share]))
    }
    
    func testFolderLink() {
        actions = NodeActionBuilder()
            .setDisplayMode(.folderLink)
            .setIsFile(false)
            .build()
        
        XCTAssertTrue(contains(nodeActionTypes: [.import, .download, .sendToChat, .select, .share]))
    }
    
    func testFolderLinkChildMediaFile() {
        actions = NodeActionBuilder()
            .setDisplayMode(.nodeInsideFolderLink)
            .setIsFile(true)
            .setIsMediaFile(true)
            .build()

        XCTAssertTrue(contains(nodeActionTypes: [.import, .download, .saveToPhotos]))
    }
    
    func testFolderLinkChildFile() {
        actions = NodeActionBuilder()
            .setDisplayMode(.nodeInsideFolderLink)
            .setIsFile(true)
            .build()
        
        XCTAssertTrue(contains(nodeActionTypes: [.import, .download]))
    }
    
    func testPreviewFileLink() {
        actions = NodeActionBuilder()
            .setDisplayMode(.previewLink)
            .build()
        
        XCTAssertTrue(contains(nodeActionTypes: [.import, .download, .sendToChat, .share]))
    }
    
    func testPreviewPdfPageViewFileLink() {
        actions = NodeActionBuilder()
            .setDisplayMode(.previewLink)
            .setIsPdf(true)
            .setIsPageView(true)
            .build()
        
        XCTAssertTrue(contains(nodeActionTypes: [.import, .download, .sendToChat, .share, .search, .pdfThumbnailView]))
    }
    
    func testPreviewPdfThumbnailFileLink() {
        actions = NodeActionBuilder()
            .setDisplayMode(.previewLink)
            .setIsPdf(true)
            .setIsPageView(false)
            .build()
        
        XCTAssertTrue(contains(nodeActionTypes: [.import, .download, .sendToChat, .share, .search, .pdfPageView]))
    }
    
    // MARK: - Chat tests
    
    func testChatSharedMediaFile() {
        actions = NodeActionBuilder()
            .setDisplayMode(.chatSharedFiles)
            .setIsFile(true)
            .setIsMediaFile(true)
            .build()

        XCTAssertTrue(contains(nodeActionTypes: [.forward, .saveToPhotos, .download, .import]))
    }
    
    func testChatSharedFile() {
        actions = NodeActionBuilder()
            .setDisplayMode(.chatSharedFiles)
            .setIsFile(true)
            .setIsMediaFile(true)
            .build()
        
        XCTAssertTrue(contains(nodeActionTypes: [.forward, .download, .import]))
    }
    
    func testChatAttachmentFile() {
        actions = NodeActionBuilder()
            .setDisplayMode(.chatAttachment)
            .setAccessLevel(.accessOwner)
            .setIsFile(true)
            .build()
        
        XCTAssertTrue(contains(nodeActionTypes: [.info, .download, .share]))
    }
    
    func testChatAttachmentMediaFile() {
        actions = NodeActionBuilder()
            .setDisplayMode(.chatAttachment)
            .setAccessLevel(.accessOwner)
            .setIsFile(true)
            .setIsMediaFile(true)
            .build()
        
        XCTAssertTrue(contains(nodeActionTypes: [.info, .saveToPhotos, .download, .share]))
    }
    
    // MARK: - Versions tests

    func testNodeVersionChildMediaFile() {
        actions = NodeActionBuilder()
            .setDisplayMode(.nodeVersions)
            .setAccessLevel(.accessOwner)
            .setIsFile(true)
            .setIsMediaFile(true)
            .setIsChildVersion(true)
            .build()
        
        XCTAssertTrue(contains(nodeActionTypes: [.saveToPhotos, .download, .revertVersion, .remove]))
    }
    
    func testNodeVersionMediaFile() {
        actions = NodeActionBuilder()
            .setDisplayMode(.nodeVersions)
            .setAccessLevel(.accessOwner)
            .setIsFile(true)
            .setIsMediaFile(true)
            .build()
        
        XCTAssertTrue(contains(nodeActionTypes: [.saveToPhotos, .download, .remove]))
    }
    
    func testNodeVersionChildFile() {
        actions = NodeActionBuilder()
            .setDisplayMode(.nodeVersions)
            .setAccessLevel(.accessOwner)
            .setIsFile(true)
            .setIsChildVersion(true)
            .build()
        
        XCTAssertTrue(contains(nodeActionTypes: [.download, .revertVersion, .remove]))
    }
    
    func testNodeVersionFile() {
        actions = NodeActionBuilder()
            .setDisplayMode(.nodeVersions)
            .setAccessLevel(.accessOwner)
            .setIsFile(true)
            .build()
        
        XCTAssertTrue(contains(nodeActionTypes: [.download, .remove]))
    }
}
