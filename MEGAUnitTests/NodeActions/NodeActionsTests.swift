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
    
    func containsExact(nodeActionTypes types: [MegaNodeActionType]) -> Bool {
        guard actions.count == types.count else {
            return false
        }
        let actionTypes = actions.map{ $0.type }
        return actionTypes == types
    }
    
    // MARK: - Cloud Drive tests

    func testCloudDriveNodeMediaFile() {
        actions = NodeActionBuilder()
            .setDisplayMode(.cloudDrive)
            .setAccessLevel(.accessOwner)
            .setIsMediaFile(true)
            .setIsFile(true)
            .build()
        
        XCTAssertTrue(contains(nodeActionTypes: [.info, .favourite, .label, .saveToPhotos, .download, .shareLink, .exportFile, .sendToChat, .rename, .move, .copy, .moveToRubbishBin]))
    }
    
    func testCloudDriveNodeMediaFileExported() {
        actions = NodeActionBuilder()
            .setDisplayMode(.cloudDrive)
            .setAccessLevel(.accessOwner)
            .setIsMediaFile(true)
            .setIsFile(true)
            .setIsExported(true)
            .build()
        
        XCTAssertTrue(contains(nodeActionTypes: [.info, .saveToPhotos, .download, .manageLink, .removeLink, .exportFile, .sendToChat, .rename, .move, .copy, .moveToRubbishBin]))
    }
    
    func testCloudDriveNodeFolder() {
        actions = NodeActionBuilder()
            .setDisplayMode(.cloudDrive)
            .setAccessLevel(.accessOwner)
            .setIsFile(false)
            .build()
        
        XCTAssertTrue(contains(nodeActionTypes: [.info, .favourite, .label, .download, .shareLink, .shareFolder, .rename, .move, .copy, .moveToRubbishBin]))
    }
    
    func testCloudDriveNodeFolderExported() {
        actions = NodeActionBuilder()
            .setDisplayMode(.cloudDrive)
            .setAccessLevel(.accessOwner)
            .setIsFile(false)
            .setIsExported(true)
            .build()
        
        XCTAssertTrue(contains(nodeActionTypes: [.info, .favourite, .label, .download, .manageLink, .removeLink, .shareFolder, .rename, .move, .copy, .moveToRubbishBin]))
    }
    
    func testCloudDriveNodeFolderShared() {
        actions = NodeActionBuilder()
            .setDisplayMode(.cloudDrive)
            .setAccessLevel(.accessOwner)
            .setIsFile(false)
            .setIsOutshare(true)
            .build()
        
        XCTAssertTrue(contains(nodeActionTypes: [.info, .favourite, .label, .download, .shareLink, .manageShare, .rename, .move, .copy, .moveToRubbishBin]))
    }
    
    func testCloudDriveNodeFolderSharedExported() {
        actions = NodeActionBuilder()
            .setDisplayMode(.cloudDrive)
            .setAccessLevel(.accessOwner)
            .setIsFile(false)
            .setIsOutshare(true)
            .setIsExported(true)
            .build()
        
        XCTAssertTrue(contains(nodeActionTypes: [.info, .favourite, .label, .download, .manageLink, .removeLink, .manageShare, .rename, .move, .copy, .moveToRubbishBin]))
    }
    
    func testCloudDriveNodeFile() {
        actions = NodeActionBuilder()
            .setDisplayMode(.cloudDrive)
            .setAccessLevel(.accessOwner)
            .setIsFile(true)
            .build()
        
        XCTAssertTrue(contains(nodeActionTypes: [.info, .favourite, .label, .download, .shareLink, .exportFile, .sendToChat, .rename, .move, .copy, .moveToRubbishBin]))
    }
    
    func testCloudDriveNodeExportedFile() {
        actions = NodeActionBuilder()
            .setDisplayMode(.cloudDrive)
            .setAccessLevel(.accessOwner)
            .setIsFile(true)
            .setIsExported(true)
            .build()
        
        XCTAssertTrue(contains(nodeActionTypes: [.info, .favourite, .label, .download, .manageLink, .removeLink, .exportFile, .sendToChat, .rename, .move, .copy, .moveToRubbishBin]))
    }
    
    func testCloudDriveNodeTextFile() {
        actions = NodeActionBuilder()
            .setDisplayMode(.cloudDrive)
            .setAccessLevel(.accessOwner)
            .setIsEditableTextFile(true)
            .setIsFile(true)
            .build()
        
        XCTAssertTrue(contains(nodeActionTypes: [.editTextFile, .info, .favourite, .label, .download, .shareLink, .exportFile, .sendToChat, .rename, .move, .copy, .moveToRubbishBin]))
    }
    
    func testCloudDriveNodeTextFileExported() {
        actions = NodeActionBuilder()
            .setDisplayMode(.cloudDrive)
            .setAccessLevel(.accessOwner)
            .setIsEditableTextFile(true)
            .setIsFile(true)
            .setIsExported(true)
            .build()
        
        XCTAssertTrue(contains(nodeActionTypes: [.editTextFile, .info, .favourite, .label, .download, .manageLink, .removeLink, .exportFile, .sendToChat, .rename, .move, .copy, .moveToRubbishBin]))
    }
        
        func testCloudDriveNodeWithNoVersion() {
            actions = NodeActionBuilder()
                .setDisplayMode(.cloudDrive)
                .setAccessLevel(.accessOwner)
                .setIsFile(true)
                .setVersionCount(0)
                .build()
            
            XCTAssertFalse(contains(nodeActionType: .viewVersions))
        }
        
        func testCloudDriveNodeWithMultiVersions() {
            actions = NodeActionBuilder()
                .setDisplayMode(.cloudDrive)
                .setAccessLevel(.accessOwner)
                .setIsFile(true)
                .setVersionCount(2)
                .build()
            
            XCTAssertTrue(contains(nodeActionType: .viewVersions))
        }
    
    func testFileFolderNodeDoNotShowInfoAction() {
        actions = NodeActionBuilder()
            .setDisplayMode(.nodeInfo)
            .build()
        XCTAssertFalse(contains(nodeActionType: .info))
    }
    
    //MARK: - Rubbish Bin
    func testRubbishBinNodeRestorableFolder() {
        actions = NodeActionBuilder()
            .setDisplayMode(.rubbishBin)
            .setAccessLevel(.accessOwner)
            .setIsFile(false)
            .setIsRestorable(true)
            .build()
        
        XCTAssertTrue(containsExact(nodeActionTypes: [.restore, .info, .remove]))
    }
    
    func testRubbishBinNodeUnrestorableFolder() {
        actions = NodeActionBuilder()
            .setDisplayMode(.rubbishBin)
            .setAccessLevel(.accessOwner)
            .setIsFile(false)
            .setIsRestorable(false)
            .build()
        
        XCTAssertTrue(containsExact(nodeActionTypes: [.info, .remove]))
    }
    
    func testRubbishBinNodeRestorableFile() {
        actions = NodeActionBuilder()
            .setDisplayMode(.rubbishBin)
            .setAccessLevel(.accessOwner)
            .setIsFile(true)
            .setIsRestorable(true)
            .setIsInVersionsView(false)
            .build()
        
        XCTAssertTrue(containsExact(nodeActionTypes: [.restore, .info, .remove]))
    }
    
    func testRubbishBinNodeUnrestorableFile() {
        actions = NodeActionBuilder()
            .setDisplayMode(.rubbishBin)
            .setAccessLevel(.accessOwner)
            .setIsFile(true)
            .setIsRestorable(false)
            .build()
        
        XCTAssertTrue(containsExact(nodeActionTypes: [.info, .remove]))
    }
    
    func testRubbishBinNodeVersionPreview() {
        actions = NodeActionBuilder()
            .setDisplayMode(.rubbishBin)
            .setAccessLevel(.accessOwner)
            .setIsFile(true)
            .setIsRestorable(true)
            .setIsInVersionsView(true)
            .build()
        
        XCTAssertTrue(containsExact(nodeActionTypes: [.info]))
    }

    //MARK: - Recent Items tests
    
    func testRecentNodeNoVersion() {
        actions = NodeActionBuilder()
            .setDisplayMode(.recents)
            .setAccessLevel(.accessOwner)
            .setIsFile(true)
            .setVersionCount(0)
            .build()
        
        XCTAssertFalse(contains(nodeActionType: .viewVersions))
    }
    
    func testRecentNodeWithMultiVersion() {
        actions = NodeActionBuilder()
            .setDisplayMode(.recents)
            .setAccessLevel(.accessOwner)
            .setIsFile(true)
            .setVersionCount(2)
            .build()
        
        XCTAssertTrue(contains(nodeActionType: .viewVersions))
    }
    
    // MARK: - Shared Items tests

    func testIncomingFullSharedFolder() {
        actions = NodeActionBuilder()
            .setDisplayMode(.sharedItem)
            .setAccessLevel(.accessFull)
            .setIsFile(false)
            .setisIncomingShareChildView(true)
            .build()
        
        XCTAssertTrue(contains(nodeActionTypes: [.info, .favourite, .label, .download, .rename, .copy, .leaveSharing]))
    }
    
    func testIncomingFullSharedFolderTextFile() {
        actions = NodeActionBuilder()
            .setDisplayMode(.sharedItem)
            .setAccessLevel(.accessFull)
            .setIsEditableTextFile(true)
            .setIsFile(true)
            .build()
        
        XCTAssertTrue(contains(nodeActionTypes: [.editTextFile, .info, .favourite, .label, .download, .copy]))
    }
    
    func testIncomingFullSharedFolderNodeNoVersion() {
        actions = NodeActionBuilder()
            .setDisplayMode(.sharedItem)
            .setAccessLevel(.accessFull)
            .setIsFile(true)
            .setVersionCount(0)
            .build()
        
        XCTAssertFalse(contains(nodeActionType: .viewVersions))
    }
    
    func testIncomingFullSharedFolderNodeWithMultiVersion() {
        actions = NodeActionBuilder()
            .setDisplayMode(.sharedItem)
            .setAccessLevel(.accessFull)
            .setIsFile(true)
            .setVersionCount(2)
            .build()
        
        XCTAssertTrue(contains(nodeActionType: .viewVersions))
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
    
    func testIncomingReadAndReadWriteSharedFolderTextFile() {
        actions = NodeActionBuilder()
            .setDisplayMode(.sharedItem)
            .setAccessLevel(.accessReadWrite)
            .setIsEditableTextFile(true)
            .setIsFile(true)
            .build()
        
        XCTAssertTrue(contains(nodeActionTypes: [.editTextFile, .info, .download, .copy]))
    }
    
    func testIncomingReadAndReadWriteSharedFolderNodeNoVersion() {
        actions = NodeActionBuilder()
            .setDisplayMode(.sharedItem)
            .setAccessLevel(.accessReadWrite)
            .setIsFile(true)
            .setVersionCount(0)
            .build()
        
        XCTAssertFalse(contains(nodeActionType: .viewVersions))
    }
    
    func testIncomingReadAndReadWriteSharedFolderNodeWithMultiVersion() {
        actions = NodeActionBuilder()
            .setDisplayMode(.sharedItem)
            .setAccessLevel(.accessReadWrite)
            .setIsFile(true)
            .setVersionCount(2)
            .build()
        
        XCTAssertTrue(contains(nodeActionType: .viewVersions))
    }

    func testOutgoingSharedFolder() {
        actions = NodeActionBuilder()
            .setDisplayMode(.sharedItem)
            .setAccessLevel(.accessOwner)
            .setIsFile(false)
            .setIsOutshare(true)
            .build()
        
        XCTAssertTrue(contains(nodeActionTypes: [.info, .favourite, .label, .download, .shareLink, .manageShare, .rename, .copy, .removeSharing]))
    }
    
    func testOutgoingSharedFolderExported() {
        actions = NodeActionBuilder()
            .setDisplayMode(.sharedItem)
            .setAccessLevel(.accessOwner)
            .setIsFile(false)
            .setIsOutshare(true)
            .setIsExported(true)
            .build()
        
        XCTAssertTrue(contains(nodeActionTypes: [.info, .favourite, .label, .download, .manageLink, .removeLink, .manageShare, .rename, .copy, .removeSharing]))
    }
    
    // MARK: - Links tests
    
    func testFileMediaLink() {
        actions = NodeActionBuilder()
            .setDisplayMode(.fileLink)
            .setIsFile(true)
            .setIsMediaFile(true)
            .build()
        
        XCTAssertTrue(contains(nodeActionTypes: [.import, .download, .shareLink, .sendToChat, .saveToPhotos]))
    }
    
    func testFileLink() {
        actions = NodeActionBuilder()
            .setDisplayMode(.fileLink)
            .setIsFile(true)
            .build()
        
        XCTAssertTrue(contains(nodeActionTypes: [.import, .download, .shareLink, .sendToChat]))
    }
    
    func testFolderLinkList() {
        actions = NodeActionBuilder()
            .setDisplayMode(.folderLink)
            .setIsFile(false)
            .build()
        
        XCTAssertTrue(contains(nodeActionTypes: [.import, .download, .shareLink, .sendToChat, .select, .thumbnail]))
    }
    
    func testFolderLinkThumbnail() {
        actions = NodeActionBuilder()
            .setDisplayMode(.folderLink)
            .setIsFile(false)
            .build()
        
        XCTAssertTrue(contains(nodeActionTypes: [.import, .download, .shareLink, .sendToChat, .select, .thumbnail]))
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
    
    // MARK: - Text Editor
    
    func testTextEditorAcessUnknown() {
        actions = NodeActionBuilder()
            .setDisplayMode(.textEditor)
            .setAccessLevel(.accessUnknown)
            .build()
        
        XCTAssertTrue(contains(nodeActionTypes: [.download, .import, .sendToChat]))
    }
    
    func testTextEditorAcessRead() {
        actions = NodeActionBuilder()
            .setDisplayMode(.textEditor)
            .setAccessLevel(.accessRead)
            .build()
        
        XCTAssertTrue(contains(nodeActionTypes: [.download, .import, .sendToChat]))
    }
    
    func testTextEditorAcessReadWrite() {
        actions = NodeActionBuilder()
            .setDisplayMode(.textEditor)
            .setAccessLevel(.accessReadWrite)
            .build()
        
        XCTAssertTrue(contains(nodeActionTypes: [.editTextFile, .download, .import, .sendToChat]))
    }
    
    func testTextEditorAcessFull() {
        actions = NodeActionBuilder()
            .setDisplayMode(.textEditor)
            .setAccessLevel(.accessFull)
            .build()
        
        XCTAssertTrue(contains(nodeActionTypes: [.editTextFile, .download, .import, .sendToChat]))
    }
    
    func testTextEditorAcessOwner() {
        actions = NodeActionBuilder()
            .setDisplayMode(.textEditor)
            .setAccessLevel(.accessOwner)
            .build()
        
        XCTAssertTrue(contains(nodeActionTypes: [.editTextFile, .download, .shareLink, .exportFile, .sendToChat]))
    }

    // MARK: - Preview Documents
    
    func testDocumentPreviewFileLink() {
        actions = NodeActionBuilder()
            .setDisplayMode(.previewDocument)
            .setIsLink(true)
            .build()
        
        XCTAssertTrue(contains(nodeActionTypes: [.import, .download, .shareLink, .sendToChat]))
    }
    
    func testDocumentPreviewPdfPageViewLink() {
        actions = NodeActionBuilder()
            .setDisplayMode(.previewDocument)
            .setIsPdf(true)
            .setIsPageView(true)
            .setIsLink(true)
            .build()
        
        XCTAssertTrue(contains(nodeActionTypes: [.import, .download, .shareLink, .sendToChat, .search, .pdfThumbnailView]))
    }
    
    func testDocumentPreviewPdfThumbnailLink() {
        actions = NodeActionBuilder()
            .setDisplayMode(.previewDocument)
            .setIsPdf(true)
            .setIsLink(true)
            .setIsPageView(false)
            .build()
        
        XCTAssertTrue(contains(nodeActionTypes: [.import, .download, .shareLink, .sendToChat, .search, .pdfPageView]))
    }
        
    func testPreviewDocument() {
        actions = NodeActionBuilder()
            .setDisplayMode(.previewDocument)
            .build()
        
        XCTAssertTrue(contains(nodeActionTypes: [.download, .sendToChat]))
    }
    
    func testPreviewDocumentOwner() {
        actions = NodeActionBuilder()
            .setDisplayMode(.previewDocument)
            .setAccessLevel(.accessOwner)
            .build()
        
        XCTAssertTrue(contains(nodeActionTypes: [.download, .shareLink, .exportFile, .sendToChat]))
    }
    
    func testPreviewPdfPageViewDocument() {
        actions = NodeActionBuilder()
            .setDisplayMode(.previewDocument)
            .setIsPdf(true)
            .setIsPageView(true)
            .build()
        
        XCTAssertTrue(contains(nodeActionTypes: [.download, .sendToChat, .search, .pdfThumbnailView]))
    }
    
    func testPreviewPdfPageViewDocumentLink() {
        actions = NodeActionBuilder()
            .setDisplayMode(.previewDocument)
            .setIsPdf(true)
            .setIsPageView(true)
            .setIsLink(true)
            .build()
        
        XCTAssertTrue(contains(nodeActionTypes: [.download, .shareLink, .sendToChat, .search, .pdfThumbnailView]))
    }
    
    func testPreviewPdfPageViewDocumentOwner() {
        actions = NodeActionBuilder()
            .setDisplayMode(.previewDocument)
            .setIsPdf(true)
            .setIsPageView(true)
            .setAccessLevel(.accessOwner)
            .build()
        
        XCTAssertTrue(contains(nodeActionTypes: [.download, .shareLink, .exportFile, .sendToChat, .search, .pdfThumbnailView]))
    }
    
    func testPreviewPdfThumbnailDocument() {
        actions = NodeActionBuilder()
            .setDisplayMode(.previewDocument)
            .setIsPdf(true)
            .setIsPageView(false)
            .build()
        
        XCTAssertTrue(contains(nodeActionTypes: [.download, .sendToChat, .search, .pdfPageView]))
    }
    
    func testPreviewPdfThumbnailDocumentLink() {
        actions = NodeActionBuilder()
            .setDisplayMode(.previewDocument)
            .setIsPdf(true)
            .setIsPageView(false)
            .setIsLink(true)
            .build()
        
        XCTAssertTrue(contains(nodeActionTypes: [.download, .shareLink, .sendToChat, .search, .pdfPageView]))
    }
    
    func testPreviewPdfThumbnailDocumentOwner() {
        actions = NodeActionBuilder()
            .setDisplayMode(.previewDocument)
            .setIsPdf(true)
            .setIsPageView(false)
            .setAccessLevel(.accessOwner)
            .build()
        
        XCTAssertTrue(contains(nodeActionTypes: [.download, .shareLink, .exportFile, .sendToChat, .search, .pdfPageView]))
    }
    
    // MARK: - Chat tests
    
    func testChatSharedMediaFile() {
        actions = NodeActionBuilder()
            .setDisplayMode(.chatSharedFiles)
            .setIsFile(true)
            .setIsMediaFile(true)
            .build()

        XCTAssertTrue(contains(nodeActionTypes: [.forward, .saveToPhotos, .download, .exportFile, .import, .copy]))
    }
    
    func testChatSharedFile() {
        actions = NodeActionBuilder()
            .setDisplayMode(.chatSharedFiles)
            .setIsFile(true)
            .setIsMediaFile(false)
            .build()
        
        XCTAssertTrue(contains(nodeActionTypes: [.forward, .download, .exportFile, .import, .copy]))
    }
    
    func testChatAttachmentMediaFile() {
        actions = NodeActionBuilder()
            .setDisplayMode(.chatAttachment)
            .setIsFile(true)
            .setIsMediaFile(true)
            .build()

        XCTAssertTrue(contains(nodeActionTypes: [.forward, .saveToPhotos, .download, .exportFile, .import, .copy]))
    }
    
    func testChatAttachmentFile() {
        actions = NodeActionBuilder()
            .setDisplayMode(.chatAttachment)
            .setIsFile(true)
            .setIsMediaFile(false)
            .build()
        
        XCTAssertTrue(contains(nodeActionTypes: [.forward, .download, .exportFile, .import, .copy]))
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
    
    
    // MARK: - Versions in Incoming Shared Items tests
    
    func testNodeVersionFileIncomingFullSharedFolder() {
        actions = NodeActionBuilder()
            .setDisplayMode(.nodeVersions)
            .setAccessLevel(.accessFull)
            .setIsFile(true)
            .setIsChildVersion(true)
            .build()
        
        XCTAssertTrue(contains(nodeActionTypes: [.download, .revertVersion, .remove]))
    }
    
    func testNodeVersionFileIncomingReadWriteSharedFolder() {
        actions = NodeActionBuilder()
            .setDisplayMode(.nodeVersions)
            .setAccessLevel(.accessReadWrite)
            .setIsFile(true)
            .setIsChildVersion(true)
            .build()
        
        XCTAssertTrue(contains(nodeActionTypes: [.download, .revertVersion]))
    }
    
    func testNodeVersionFileIncomingReadOnlySharedFolder() {
        actions = NodeActionBuilder()
            .setDisplayMode(.nodeVersions)
            .setAccessLevel(.accessRead)
            .setIsFile(true)
            .setIsChildVersion(true)
            .build()
        
        XCTAssertTrue(contains(nodeActionTypes: [.download]))
    }
    
    func testMultiselectFiles() {
        actions = NodeActionBuilder()
            .setNodeSelectionType(.files)
            .multiselectBuild()
        
        XCTAssertTrue(contains(nodeActionTypes: [.download, .shareLink, .exportFile, .sendToChat, .move, .copy, .moveToRubbishBin]))
    }
    
    func testMultiselectFolders() {
        actions = NodeActionBuilder()
            .setNodeSelectionType(.folders)
            .multiselectBuild()
        
        XCTAssertTrue(contains(nodeActionTypes: [.download, .shareLink, .shareFolder, .move, .copy, .moveToRubbishBin]))
    }
    
    func testMultiselectFilesAndFolders() {
        actions = NodeActionBuilder()
            .setNodeSelectionType(.filesAndFolders)
            .multiselectBuild()
        
        XCTAssertTrue(contains(nodeActionTypes: [.download, .shareLink, .move, .copy, .moveToRubbishBin]))
    }
}
