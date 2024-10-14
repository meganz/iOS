@testable import MEGA
import MEGASDKRepoMock
import Testing
import XCTest

class NodeActionBuilderTests: XCTestCase {
    
    var actions: [NodeAction] = []
    
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super .tearDown()
        actions.removeAll()
    }
    
    // MARK: - Private methods
    
    func isEqual(nodeActionTypes types: [MegaNodeActionType]) -> Bool {
        guard actions.count == types.count else {
            return false
        }
        let actionTypes = actions.map { $0.type }
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
        
        XCTAssertTrue(isEqual(nodeActionTypes: [.info, .favourite, .label, .saveToPhotos, .download, .shareLink, .exportFile, .sendToChat, .rename, .move, .copy, .moveToRubbishBin]))
    }
    
    func testCloudDriveNodeMediaFileExported() {
        actions = NodeActionBuilder()
            .setDisplayMode(.cloudDrive)
            .setAccessLevel(.accessOwner)
            .setIsMediaFile(true)
            .setIsFile(true)
            .setIsExported(true)
            .build()
        
        XCTAssertTrue(isEqual(nodeActionTypes: [.info, .favourite, .label, .saveToPhotos, .download, .manageLink, .removeLink, .exportFile, .sendToChat, .rename, .move, .copy, .moveToRubbishBin]))
    }
    
    func testCloudDriveNodeFolder() {
        actions = NodeActionBuilder()
            .setDisplayMode(.cloudDrive)
            .setAccessLevel(.accessOwner)
            .setIsFile(false)
            .build()
        
        XCTAssertTrue(isEqual(nodeActionTypes: [.info, .favourite, .label, .download, .shareLink, .shareFolder, .rename, .move, .copy, .moveToRubbishBin]))
    }
    
    func testCloudDriveNodeFolderExported() {
        actions = NodeActionBuilder()
            .setDisplayMode(.cloudDrive)
            .setAccessLevel(.accessOwner)
            .setIsFile(false)
            .setIsExported(true)
            .build()
        
        XCTAssertTrue(isEqual(nodeActionTypes: [.info, .favourite, .label, .download, .manageLink, .removeLink, .shareFolder, .rename, .move, .copy, .moveToRubbishBin]))
    }
    
    func testCloudDriveNodeFolderShared() {
        actions = NodeActionBuilder()
            .setDisplayMode(.cloudDrive)
            .setAccessLevel(.accessOwner)
            .setIsFile(false)
            .setIsOutshare(true)
            .build()
        
        XCTAssertTrue(isEqual(nodeActionTypes: [.info, .favourite, .label, .download, .shareLink, .manageShare, .rename, .move, .copy, .moveToRubbishBin]))
    }
    
    func testCloudDriveNodeFolderSharedExported() {
        actions = NodeActionBuilder()
            .setDisplayMode(.cloudDrive)
            .setAccessLevel(.accessOwner)
            .setIsFile(false)
            .setIsOutshare(true)
            .setIsExported(true)
            .build()
        
        XCTAssertTrue(isEqual(nodeActionTypes: [.info, .favourite, .label, .download, .manageLink, .removeLink, .manageShare, .rename, .move, .copy, .moveToRubbishBin]))
    }
    
    func testCloudDriveNodeFile() {
        actions = NodeActionBuilder()
            .setDisplayMode(.cloudDrive)
            .setAccessLevel(.accessOwner)
            .setIsFile(true)
            .build()
        
        XCTAssertTrue(isEqual(nodeActionTypes: [.info, .favourite, .label, .download, .shareLink, .exportFile, .sendToChat, .rename, .move, .copy, .moveToRubbishBin]))
    }
    
    func testCloudDriveNodeExportedFile() {
        actions = NodeActionBuilder()
            .setDisplayMode(.cloudDrive)
            .setAccessLevel(.accessOwner)
            .setIsFile(true)
            .setIsExported(true)
            .build()
        
        XCTAssertTrue(isEqual(nodeActionTypes: [.info, .favourite, .label, .download, .manageLink, .removeLink, .exportFile, .sendToChat, .rename, .move, .copy, .moveToRubbishBin]))
    }
    
    func testCloudDriveNodeTextFile() {
        actions = NodeActionBuilder()
            .setDisplayMode(.cloudDrive)
            .setAccessLevel(.accessOwner)
            .setIsEditableTextFile(true)
            .setIsFile(true)
            .build()
        
        XCTAssertTrue(isEqual(nodeActionTypes: [.editTextFile, .info, .favourite, .label, .download, .shareLink, .exportFile, .sendToChat, .rename, .move, .copy, .moveToRubbishBin]))
    }
    
    func testCloudDriveNodeTextFileExported() {
        actions = NodeActionBuilder()
            .setDisplayMode(.cloudDrive)
            .setAccessLevel(.accessOwner)
            .setIsEditableTextFile(true)
            .setIsFile(true)
            .setIsExported(true)
            .build()
        
        XCTAssertTrue(isEqual(nodeActionTypes: [.editTextFile, .info, .favourite, .label, .download, .manageLink, .removeLink, .exportFile, .sendToChat, .rename, .move, .copy, .moveToRubbishBin]))
    }
    
    func testCloudDriveNodeWithNoVersion() {
        actions = NodeActionBuilder()
            .setDisplayMode(.cloudDrive)
            .setAccessLevel(.accessOwner)
            .setIsFile(true)
            .setVersionCount(0)
            .build()
        
        XCTAssertTrue(isEqual(nodeActionTypes: [.info, .favourite, .label, .download, .shareLink, .exportFile, .sendToChat, .rename, .move, .copy, .moveToRubbishBin]))
    }
    
    func testCloudDriveNodeWithMultiVersions() {
        actions = NodeActionBuilder()
            .setDisplayMode(.cloudDrive)
            .setAccessLevel(.accessOwner)
            .setIsFile(true)
            .setVersionCount(2)
            .build()
        
        XCTAssertTrue(isEqual(nodeActionTypes: [.info, .viewVersions, .favourite, .label, .download, .shareLink, .exportFile, .sendToChat, .rename, .move, .copy, .moveToRubbishBin]))
    }
    
    func testCloudDriveTextFileNodeWithMultiVersions() {
        actions = NodeActionBuilder()
            .setDisplayMode(.cloudDrive)
            .setAccessLevel(.accessOwner)
            .setIsEditableTextFile(true)
            .setIsFile(true)
            .setVersionCount(2)
            .build()
        
        XCTAssertTrue(isEqual(nodeActionTypes: [.editTextFile, .info, .viewVersions, .favourite, .label, .download, .shareLink, .exportFile, .sendToChat, .rename, .move, .copy, .moveToRubbishBin]))
    }
    
    func testBuild_cloudDriveHiddenFalseValidAccountType_shouldReturnCorrectActions() {
        actions = NodeActionBuilder()
            .setDisplayMode(.cloudDrive)
            .setAccessLevel(.accessOwner)
            .setIsHiddenNodesFeatureEnabled(true)
            .setHasValidProOrUnexpiredBusinessAccount(true)
            .setIsHidden(false)
            .build()
        
        XCTAssertTrue(isEqual(nodeActionTypes: [.info, .favourite, .label, .download, .shareLink,
                                                .shareFolder, .rename, .hide, .move, .copy, .moveToRubbishBin]))
    }
    
    func testBuild_cloudDriveHiddenTrueValidAccountType_shouldReturnCorrectActions() {
        actions = NodeActionBuilder()
            .setDisplayMode(.cloudDrive)
            .setAccessLevel(.accessOwner)
            .setIsHiddenNodesFeatureEnabled(true)
            .setHasValidProOrUnexpiredBusinessAccount(true)
            .setIsHidden(true)
            .build()
        
        XCTAssertTrue(isEqual(nodeActionTypes: [.info, .favourite, .label, .download, .shareLink,
                                                .shareFolder, .rename, .unhide, .move, .copy, .moveToRubbishBin]))
    }
    
    func testFileFolderNodeDoNotShowInfoAction() {
        actions = NodeActionBuilder()
            .setDisplayMode(.nodeInfo)
            .build()
        
        XCTAssertTrue(isEqual(nodeActionTypes: [.import, .download]))
    }
    
    func testCloudDriveTakedownNode() {
        actions = NodeActionBuilder()
            .setDisplayMode(.cloudDrive)
            .setIsTakedown(true)
            .build()
        
        XCTAssertTrue(isEqual(nodeActionTypes: [.info, .disputeTakedown, .rename, .moveToRubbishBin]))
    }
    
    func testTakeDownNode_onSingleFileSelection_shouldHaveDisputedActions() {
        actions = NodeActionBuilder()
            .setNodeSelectionType(.files, selectedNodeCount: 1)
            .setIsTakedown(true)
            .multiselectBuild()
        
        XCTAssertTrue(isEqual(nodeActionTypes: [.info, .disputeTakedown, .rename, .moveToRubbishBin]))
    }
    
    func testTakeDownNode_onMultipleFilesSelection_shouldHaveOnlyMoveToBinAction() {
        actions = NodeActionBuilder()
            .setNodeSelectionType(.files, selectedNodeCount: 2)
            .setIsTakedown(true)
            .multiselectBuild()
        
        XCTAssertTrue(isEqual(nodeActionTypes: [.moveToRubbishBin]))
    }
    
    func testTakeDownNode_onSingleFolderSelection_shouldHaveDisputedActions() {
        actions = NodeActionBuilder()
            .setNodeSelectionType(.folders, selectedNodeCount: 1)
            .setIsTakedown(true)
            .multiselectBuild()
        
        XCTAssertTrue(isEqual(nodeActionTypes: [.info, .disputeTakedown, .rename, .moveToRubbishBin]))
    }
    
    func testTakeDownNode_onMultipleFoldersSelection_shouldHaveOnlyMoveToBinAction() {
        actions = NodeActionBuilder()
            .setNodeSelectionType(.folders, selectedNodeCount: 2)
            .setIsTakedown(true)
            .multiselectBuild()
        
        XCTAssertTrue(isEqual(nodeActionTypes: [.moveToRubbishBin]))
    }
    
    func testTakeDownNode_onMultipleFilesAndFoldersSelection_shouldHaveOnlyMoveToBinAction() {
        actions = NodeActionBuilder()
            .setNodeSelectionType(.filesAndFolders, selectedNodeCount: 2)
            .setIsTakedown(true)
            .multiselectBuild()
        
        XCTAssertTrue(isEqual(nodeActionTypes: [.moveToRubbishBin]))
    }
    
    // MARK: - Backup
    func testBackupNodeWithNoVersion() {
        actions = NodeActionBuilder()
            .setDisplayMode(.backup)
            .setAccessLevel(.accessOwner)
            .setIsFile(true)
            .setVersionCount(0)
            .build()
        
        XCTAssertTrue(isEqual(nodeActionTypes: [.info, .download, .shareLink, .exportFile, .sendToChat, .copy]))
    }
    
    func testBackupNodeWithVersions() {
        actions = NodeActionBuilder()
            .setDisplayMode(.backup)
            .setAccessLevel(.accessOwner)
            .setIsFile(true)
            .setVersionCount(3)
            .build()
        
        XCTAssertTrue(isEqual(nodeActionTypes: [.info, .viewVersions, .download, .shareLink, .exportFile, .sendToChat, .copy]))
    }
    
    // MARK: - Rubbish Bin
    func testRubbishBinNodeRestorableFolder() {
        actions = NodeActionBuilder()
            .setDisplayMode(.rubbishBin)
            .setAccessLevel(.accessOwner)
            .setIsFile(false)
            .setIsRestorable(true)
            .build()
        
        XCTAssertTrue(isEqual(nodeActionTypes: [.restore, .info, .remove]))
    }
    
    func testRubbishBinNodeUnrestorableFolder() {
        actions = NodeActionBuilder()
            .setDisplayMode(.rubbishBin)
            .setAccessLevel(.accessOwner)
            .setIsFile(false)
            .setIsRestorable(false)
            .build()
        
        XCTAssertTrue(isEqual(nodeActionTypes: [.info, .remove]))
    }
    
    func testRubbishBinNodeRestorableFile() {
        actions = NodeActionBuilder()
            .setDisplayMode(.rubbishBin)
            .setAccessLevel(.accessOwner)
            .setIsFile(true)
            .setIsRestorable(true)
            .setIsInVersionsView(false)
            .build()
        
        XCTAssertTrue(isEqual(nodeActionTypes: [.restore, .info, .remove]))
    }
    
    func testRubbishBinNodeUnrestorableFile() {
        actions = NodeActionBuilder()
            .setDisplayMode(.rubbishBin)
            .setAccessLevel(.accessOwner)
            .setIsFile(true)
            .setIsRestorable(false)
            .build()
        
        XCTAssertTrue(isEqual(nodeActionTypes: [.info, .remove]))
    }
    
    func testRubbishBinNodeVersionPreview() {
        actions = NodeActionBuilder()
            .setDisplayMode(.rubbishBin)
            .setAccessLevel(.accessOwner)
            .setIsFile(true)
            .setIsRestorable(true)
            .setIsInVersionsView(true)
            .build()
        
        XCTAssertTrue(isEqual(nodeActionTypes: [.info]))
    }
    
    func testRubbishBinTakedownNode() {
        actions = NodeActionBuilder()
            .setDisplayMode(.rubbishBin)
            .setIsTakedown(true)
            .build()
        XCTAssertTrue(isEqual(nodeActionTypes: [.info, .disputeTakedown, .rename, .remove]))
    }
    
    func testRubbishBin_BackupNode() {
        actions = NodeActionBuilder()
            .setDisplayMode(.rubbishBin)
            .setAccessLevel(.accessOwner)
            .setIsBackupNode(true)
            .build()
        XCTAssertTrue(isEqual(nodeActionTypes: [.restoreBackup, .info, .remove]))
    }
    
    // MARK: - Recent Items tests
    
    func testRecentNodeNoVersion() {
        actions = NodeActionBuilder()
            .setDisplayMode(.recents)
            .setAccessLevel(.accessOwner)
            .setIsFile(true)
            .setVersionCount(0)
            .build()
        
        XCTAssertTrue(isEqual(nodeActionTypes: [.info, .favourite, .label, .download, .shareLink, .exportFile, .sendToChat, .rename, .move, .copy, .moveToRubbishBin]))
    }
    
    func testRecentNodeWithMultiVersion() {
        actions = NodeActionBuilder()
            .setDisplayMode(.recents)
            .setAccessLevel(.accessOwner)
            .setIsFile(true)
            .setVersionCount(2)
            .build()
        
        XCTAssertTrue(isEqual(nodeActionTypes: [.info, .viewVersions, .favourite, .label, .download, .shareLink, .exportFile, .sendToChat, .rename, .move, .copy, .moveToRubbishBin]))
    }
    
    func testRecentNode_withHiddenNodesFalse_shouldReturnNoHiddenActions() {
        actions = NodeActionBuilder()
            .setDisplayMode(.recents)
            .setIsFile(true)
            .setVersionCount(2)
            .setIsHidden(false)
            .build()
        
        XCTAssertTrue(isEqual(nodeActionTypes: [.import, .download]))
    }
    
    func testRecentNode_withHiddenNodeFalse_shouldReturnHiddenActions() {
        actions = NodeActionBuilder()
            .setDisplayMode(.recents)
            .setAccessLevel(.accessOwner)
            .setIsFile(true)
            .setVersionCount(2)
            .setIsHiddenNodesFeatureEnabled(true)
            .setIsHidden(false)
            .build()
        
        XCTAssertTrue(isEqual(nodeActionTypes: [.info, .viewVersions, .favourite, .label, .download, .shareLink, .exportFile, .sendToChat, .rename, .hide, .move, .copy, .moveToRubbishBin]))
    }
    
    func testRecentNode_withHiddenNodeTrueValidAccountType_shouldReturnUnhideActions() {
        actions = NodeActionBuilder()
            .setDisplayMode(.recents)
            .setAccessLevel(.accessOwner)
            .setIsFile(true)
            .setVersionCount(2)
            .setIsHiddenNodesFeatureEnabled(true)
            .setHasValidProOrUnexpiredBusinessAccount(true)
            .setIsHidden(true)
            .build()
        
        XCTAssertTrue(isEqual(nodeActionTypes: [.info, .viewVersions, .favourite, .label, .download, .shareLink, .exportFile, .sendToChat, .rename, .unhide, .move, .copy, .moveToRubbishBin]))
    }
    
    // MARK: - Shared Items tests
    
    func testIncomingFullSharedFolder() {
        actions = NodeActionBuilder()
            .setDisplayMode(.sharedItem)
            .setAccessLevel(.accessFull)
            .setIsFile(false)
            .setisIncomingShareChildView(true)
            .build()
        
        XCTAssertTrue(isEqual(nodeActionTypes: [.info, .download, .rename, .copy, .leaveSharing]))
    }
    
    func testIncomingFullSharedFolder_verifyContact_enabled() {
        actions = NodeActionBuilder()
            .setDisplayMode(.sharedItem)
            .setAccessLevel(.accessFull)
            .setIsFile(false)
            .setisIncomingShareChildView(true)
            .setIsVerifyContact(true, sharedFolderReceiverEmail: "", sharedFolderContact: MockUser())
            .build()
        
        XCTAssertTrue(isEqual(nodeActionTypes: [.verifyContact, .info, .label, .leaveSharing]))
    }
    
    func testIncomingFullSharedFolderTextFile() {
        actions = NodeActionBuilder()
            .setDisplayMode(.sharedItem)
            .setAccessLevel(.accessFull)
            .setIsEditableTextFile(true)
            .setIsFile(true)
            .build()
        
        XCTAssertTrue(isEqual(nodeActionTypes: [.editTextFile, .info, .download, .rename, .copy, .move, .moveToRubbishBin]))
    }
    
    func testIncomingFullSharedFolderNodeNoVersion() {
        actions = NodeActionBuilder()
            .setDisplayMode(.sharedItem)
            .setAccessLevel(.accessFull)
            .setIsFile(true)
            .setVersionCount(0)
            .build()
        
        XCTAssertTrue(isEqual(nodeActionTypes: [.info, .download, .rename, .copy, .move, .moveToRubbishBin]))
    }
    
    func testIncomingFullSharedFolderNodeWithMultiVersion() {
        actions = NodeActionBuilder()
            .setDisplayMode(.sharedItem)
            .setAccessLevel(.accessFull)
            .setIsFile(true)
            .setVersionCount(2)
            .build()
        
        XCTAssertTrue(isEqual(nodeActionTypes: [.info, .viewVersions, .download, .rename, .copy, .move, .moveToRubbishBin]))
    }
    
    func testIncomingReadAndReadWriteSharedFolder() {
        actions = NodeActionBuilder()
            .setDisplayMode(.sharedItem)
            .setAccessLevel(.accessReadWrite)
            .setIsFile(false)
            .setisIncomingShareChildView(true)
            .build()
        
        XCTAssertTrue(isEqual(nodeActionTypes: [.info, .download, .copy, .leaveSharing]))
    }
    
    func testIncomingReadAndReadWriteSharedFolder_verifyContact_enabled() {
        actions = NodeActionBuilder()
            .setDisplayMode(.sharedItem)
            .setAccessLevel(.accessReadWrite)
            .setIsFile(false)
            .setisIncomingShareChildView(true)
            .setIsVerifyContact(true, sharedFolderReceiverEmail: "", sharedFolderContact: MockUser())
            .build()
        
        XCTAssertTrue(isEqual(nodeActionTypes: [.verifyContact, .info, .leaveSharing]))
    }
    
    func testIncomingReadAndReadWriteSharedFolderTextFile() {
        actions = NodeActionBuilder()
            .setDisplayMode(.sharedItem)
            .setAccessLevel(.accessReadWrite)
            .setIsEditableTextFile(true)
            .setIsFile(true)
            .build()
        
        XCTAssertTrue(isEqual(nodeActionTypes: [.editTextFile, .info, .download, .copy]))
    }
    
    func testIncomingReadAndReadWriteSharedFolderNodeNoVersion() {
        actions = NodeActionBuilder()
            .setDisplayMode(.sharedItem)
            .setAccessLevel(.accessReadWrite)
            .setIsFile(true)
            .setVersionCount(0)
            .build()
        
        XCTAssertTrue(isEqual(nodeActionTypes: [.info, .download, .copy]))
    }
    
    func testIncomingReadAndReadWriteSharedFolderNodeWithMultiVersion() {
        actions = NodeActionBuilder()
            .setDisplayMode(.sharedItem)
            .setAccessLevel(.accessReadWrite)
            .setIsFile(true)
            .setVersionCount(2)
            .build()
        
        XCTAssertTrue(isEqual(nodeActionTypes: [.info, .viewVersions, .download, .copy]))
    }
    
    func testOutgoingSharedFolder() {
        actions = NodeActionBuilder()
            .setDisplayMode(.sharedItem)
            .setAccessLevel(.accessOwner)
            .setIsFile(false)
            .setIsOutshare(true)
            .build()
        
        XCTAssertTrue(isEqual(nodeActionTypes: [.info, .favourite, .label, .download, .shareLink, .manageShare, .rename, .copy, .removeSharing]))
    }
    
    func testOutgoingSharedFolder_verifyContact_enabled() {
        actions = NodeActionBuilder()
            .setDisplayMode(.sharedItem)
            .setAccessLevel(.accessOwner)
            .setIsFile(false)
            .setIsOutshare(true)
            .setIsVerifyContact(true, sharedFolderReceiverEmail: "", sharedFolderContact: MockUser())
            .build()
        
        XCTAssertTrue(isEqual(nodeActionTypes: [.verifyContact, .info, .favourite, .label, .download, .shareLink, .manageShare, .rename, .copy, .removeSharing]))
    }
    
    func testOutgoingSharedFolderExported() {
        actions = NodeActionBuilder()
            .setDisplayMode(.sharedItem)
            .setAccessLevel(.accessOwner)
            .setIsFile(false)
            .setIsOutshare(true)
            .setIsExported(true)
            .build()
        
        XCTAssertTrue(isEqual(nodeActionTypes: [.info, .favourite, .label, .download, .manageLink, .removeLink, .manageShare, .rename, .copy, .removeSharing]))
    }
    
    func testOutgoingSharedFolder_verifyContactAndExported_enabled() {
        actions = NodeActionBuilder()
            .setDisplayMode(.sharedItem)
            .setAccessLevel(.accessOwner)
            .setIsFile(false)
            .setIsOutshare(true)
            .setIsExported(true)
            .setIsVerifyContact(true, sharedFolderReceiverEmail: "", sharedFolderContact: MockUser())
            .build()
        
        XCTAssertTrue(isEqual(nodeActionTypes: [.verifyContact, .info, .favourite, .label, .download, .manageLink, .removeLink, .manageShare, .rename, .copy, .removeSharing]))
    }
    
    func testOutgoingSharedFolder_hidden_shouldNotContainHideAction() {
        actions = NodeActionBuilder()
            .setDisplayMode(.sharedItem)
            .setIsHidden(true)
            .build()
        
        XCTAssertTrue(actions.map(\.type).notContains(.hide))
    }
    
    // MARK: - Links tests
    
    func testFileMediaLink() {
        actions = NodeActionBuilder()
            .setDisplayMode(.fileLink)
            .setIsFile(true)
            .setIsMediaFile(true)
            .build()
        
        XCTAssertTrue(isEqual(nodeActionTypes: [.import, .download, .shareLink, .sendToChat, .saveToPhotos]))
    }
    
    func testFileLink() {
        actions = NodeActionBuilder()
            .setDisplayMode(.fileLink)
            .setIsFile(true)
            .build()
        
        XCTAssertTrue(isEqual(nodeActionTypes: [.import, .download, .shareLink, .sendToChat]))
    }
    
    func testFolderLinkList() {
        actions = NodeActionBuilder()
            .setDisplayMode(.folderLink)
            .setIsFile(false)
            .build()
        
        XCTAssertTrue(isEqual(nodeActionTypes: [.import, .download, .select, .shareLink, .sendToChat, .sort, .thumbnail]))
    }
    
    func testFolderLinkThumbnail() {
        actions = NodeActionBuilder()
            .setDisplayMode(.folderLink)
            .setIsFile(false)
            .build()
        
        XCTAssertTrue(isEqual(nodeActionTypes: [.import, .download, .select, .shareLink, .sendToChat, .sort, .thumbnail]))
    }
    
    func testFolderLinkMediaDiscovery() {
        actions = NodeActionBuilder()
            .setDisplayMode(.folderLink)
            .setContainsMediaFiles(true)
            .build()
        
        XCTAssertTrue(isEqual(nodeActionTypes: [.import, .download, .select, .shareLink, .sendToChat, .sort, .mediaDiscovery, .thumbnail]))
    }
    
    func testFolderLinkChildMediaFile() {
        actions = NodeActionBuilder()
            .setDisplayMode(.nodeInsideFolderLink)
            .setIsFile(true)
            .setIsMediaFile(true)
            .build()
        
        XCTAssertTrue(isEqual(nodeActionTypes: [.import, .download, .saveToPhotos]))
    }
    
    func testFolderLinkChildFile() {
        actions = NodeActionBuilder()
            .setDisplayMode(.nodeInsideFolderLink)
            .setIsFile(true)
            .build()
        
        XCTAssertTrue(isEqual(nodeActionTypes: [.import, .download]))
    }
    
    func testFileLinkArrayWithPublicLink() {
        actions = NodeActionBuilder()
            .setNodeSelectionType(.files, selectedNodeCount: 2)
            .setLinkedNodeCount(2)
            .multiselectBuild()
        
        XCTAssertTrue(isEqual(nodeActionTypes: [.download, .shareLink, .removeLink, .exportFile, .sendToChat, .move, .copy, .moveToRubbishBin]))
    }
    
    func testFolderLinkArrayWithPublicLink() {
        actions = NodeActionBuilder()
            .setNodeSelectionType(.folders, selectedNodeCount: 2)
            .setLinkedNodeCount(2)
            .multiselectBuild()
        
        XCTAssertTrue(isEqual(nodeActionTypes: [.download, .shareLink, .removeLink, .shareFolder, .move, .copy, .moveToRubbishBin]))
    }
    
    func testFileAndFolderLinkArrayWithPublicLink() {
        actions = NodeActionBuilder()
            .setNodeSelectionType(.filesAndFolders, selectedNodeCount: 2)
            .setLinkedNodeCount(2)
            .multiselectBuild()
        
        XCTAssertTrue(isEqual(nodeActionTypes: [.download, .shareLink, .removeLink, .move, .copy, .moveToRubbishBin]))
    }
    
    func testFileLinkArrayWithoutPublicLink() {
        actions = NodeActionBuilder()
            .setNodeSelectionType(.files, selectedNodeCount: 2)
            .setLinkedNodeCount(0)
            .multiselectBuild()
        
        XCTAssertTrue(isEqual(nodeActionTypes: [.download, .shareLink, .exportFile, .sendToChat, .move, .copy, .moveToRubbishBin]))
    }
    
    func testFolderLinkArrayWithoutPublicLink() {
        actions = NodeActionBuilder()
            .setNodeSelectionType(.folders, selectedNodeCount: 2)
            .setLinkedNodeCount(0)
            .multiselectBuild()
        
        XCTAssertTrue(isEqual(nodeActionTypes: [.download, .shareLink, .shareFolder, .move, .copy, .moveToRubbishBin]))
    }
    
    func testFileAndFolderLinkArrayWithoutPublicLink() {
        actions = NodeActionBuilder()
            .setNodeSelectionType(.filesAndFolders, selectedNodeCount: 2)
            .setLinkedNodeCount(0)
            .multiselectBuild()
        
        XCTAssertTrue(isEqual(nodeActionTypes: [.download, .shareLink, .move, .copy, .moveToRubbishBin]))
    }
    
    // MARK: - Text Editor
    
    func testTextEditorAcessUnknown() {
        actions = NodeActionBuilder()
            .setDisplayMode(.textEditor)
            .setAccessLevel(.accessUnknown)
            .build()
        
        XCTAssertTrue(isEqual(nodeActionTypes: [.download, .import, .exportFile, .sendToChat]))
    }
    
    func testTextEditorAcessRead() {
        actions = NodeActionBuilder()
            .setDisplayMode(.textEditor)
            .setAccessLevel(.accessRead)
            .build()
        
        XCTAssertTrue(isEqual(nodeActionTypes: [.download, .import, .exportFile, .sendToChat]))
    }
    
    func testTextEditorAcessReadWrite() {
        actions = NodeActionBuilder()
            .setDisplayMode(.textEditor)
            .setAccessLevel(.accessReadWrite)
            .build()
        
        XCTAssertTrue(isEqual(nodeActionTypes: [.editTextFile, .download, .import, .exportFile, .sendToChat]))
    }
    
    func testTextEditorAcessFull() {
        actions = NodeActionBuilder()
            .setDisplayMode(.textEditor)
            .setAccessLevel(.accessFull)
            .build()
        
        XCTAssertTrue(isEqual(nodeActionTypes: [.editTextFile, .download, .import, .exportFile, .sendToChat]))
    }
    
    func testTextEditorAcessOwner() {
        actions = NodeActionBuilder()
            .setDisplayMode(.textEditor)
            .setAccessLevel(.accessOwner)
            .build()
        
        XCTAssertTrue(isEqual(nodeActionTypes: [.editTextFile, .download, .shareLink, .exportFile, .sendToChat]))
    }
    
    func testTextEditor_hasAccessOwnerAndIsHiddenTrueValidAccountType_returnsNodeActions() {
        actions = NodeActionBuilder()
            .setDisplayMode(.textEditor)
            .setAccessLevel(.accessOwner)
            .setIsHiddenNodesFeatureEnabled(true)
            .setHasValidProOrUnexpiredBusinessAccount(true)
            .setIsHidden(true)
            .build()
        
        XCTAssertTrue(isEqual(nodeActionTypes: [.editTextFile, .download, .shareLink, .exportFile, .sendToChat, .unhide]))
    }
    
    func testTextEditor_hasAccessOwnerAndIsHiddenFalseValidAccountType_returnsNodeActions() {
        actions = NodeActionBuilder()
            .setDisplayMode(.textEditor)
            .setAccessLevel(.accessOwner)
            .setIsHiddenNodesFeatureEnabled(true)
            .setHasValidProOrUnexpiredBusinessAccount(true)
            .setIsHidden(false)
            .build()
        
        XCTAssertTrue(isEqual(nodeActionTypes: [.editTextFile, .download, .shareLink, .exportFile, .sendToChat, .hide]))
    }
    
    // MARK: - Preview Documents
    
    func testDocumentPreviewFileLink() {
        actions = NodeActionBuilder()
            .setDisplayMode(.previewDocument)
            .setIsLink(true)
            .build()
        
        XCTAssertTrue(isEqual(nodeActionTypes: [.import, .download, .shareLink, .sendToChat]))
    }
    
    func testDocumentPreviewPdfPageViewLink() {
        actions = NodeActionBuilder()
            .setDisplayMode(.previewPdfPage)
            .setIsPdf(true)
            .setIsLink(true)
            .build()
        
        XCTAssertTrue(isEqual(nodeActionTypes: [.import, .download, .shareLink, .sendToChat, .search, .pdfThumbnailView]))
    }
    
    func testDocumentPreviewPdfPageView_isExported_isLink() {
        actions = NodeActionBuilder()
            .setDisplayMode(.previewPdfPage)
            .setIsPdf(true)
            .setIsLink(true)
            .setIsExported(true)
            .build()
        
        XCTAssertTrue(isEqual(nodeActionTypes: [.import, .download, .manageLink, .removeLink, .sendToChat, .search, .pdfThumbnailView]))
    }
    
    func testDocumentPreviewPdfPageView_isNotExported_isLink() {
        actions = NodeActionBuilder()
            .setDisplayMode(.previewPdfPage)
            .setIsPdf(true)
            .setIsLink(true)
            .setIsExported(false)
            .build()
        
        XCTAssertTrue(isEqual(nodeActionTypes: [.import, .download, .shareLink, .sendToChat, .search, .pdfThumbnailView]))
    }
    
    func testDocumentPreviewPdfPageView_isNotExported_isNotLink() {
        actions = NodeActionBuilder()
            .setDisplayMode(.previewPdfPage)
            .setIsPdf(true)
            .setIsLink(false)
            .setIsExported(false)
            .build()
        
        XCTAssertTrue(isEqual(nodeActionTypes: [.download, .sendToChat, .search, .pdfThumbnailView]))
    }
    
    func testDocumentPreviewPdfThumbnail_isExported_isLink() {
        actions = NodeActionBuilder()
            .setDisplayMode(.previewDocument)
            .setIsPdf(true)
            .setIsLink(true)
            .setIsExported(true)
            .build()
        
        XCTAssertTrue(isEqual(nodeActionTypes: [.import, .download, .manageLink, .removeLink, .sendToChat, .search, .pdfPageView]))
    }
    
    func testDocumentPreviewPdfThumbnail_isNotExported_isLink() {
        actions = NodeActionBuilder()
            .setDisplayMode(.previewDocument)
            .setIsPdf(true)
            .setIsLink(true)
            .setIsExported(false)
            .build()
        
        XCTAssertTrue(isEqual(nodeActionTypes: [.import, .download, .shareLink, .sendToChat, .search, .pdfPageView]))
    }
    
    func testDocumentPreviewPdfThumbnail_isNotExported_isNotLink() {
        actions = NodeActionBuilder()
            .setDisplayMode(.previewDocument)
            .setIsPdf(true)
            .setIsLink(false)
            .setIsExported(false)
            .build()
        
        XCTAssertTrue(isEqual(nodeActionTypes: [.download, .sendToChat, .search, .pdfPageView]))
    }
    
    func testDocumentPreviewPdfThumbnailLink() {
        actions = NodeActionBuilder()
            .setDisplayMode(.previewDocument)
            .setIsPdf(true)
            .setIsLink(true)
            .build()
        
        XCTAssertTrue(isEqual(nodeActionTypes: [.import, .download, .shareLink, .sendToChat, .search, .pdfPageView]))
    }
    
    func testPreviewDocument() {
        actions = NodeActionBuilder()
            .setDisplayMode(.previewDocument)
            .build()
        
        XCTAssertTrue(isEqual(nodeActionTypes: [.download, .sendToChat]))
    }
    
    func testPreviewDocumentOwner() {
        actions = NodeActionBuilder()
            .setDisplayMode(.previewDocument)
            .setAccessLevel(.accessOwner)
            .build()
        
        XCTAssertTrue(isEqual(nodeActionTypes: [.download, .shareLink, .exportFile, .sendToChat]))
    }
    
    func testPreviewPdfPageViewDocument() {
        actions = NodeActionBuilder()
            .setDisplayMode(.previewPdfPage)
            .setIsPdf(true)
            .build()
        
        XCTAssertTrue(isEqual(nodeActionTypes: [.download, .sendToChat, .search, .pdfThumbnailView]))
    }
    
    func testPreviewPdfPageViewDocumentLink() {
        actions = NodeActionBuilder()
            .setDisplayMode(.previewPdfPage)
            .setIsPdf(true)
            .setIsLink(true)
            .build()
        
        XCTAssertTrue(isEqual(nodeActionTypes: [.import, .download, .shareLink, .sendToChat, .search, .pdfThumbnailView]))
    }
    
    func testPreviewPdfPageViewDocumentOwner() {
        actions = NodeActionBuilder()
            .setDisplayMode(.previewPdfPage)
            .setIsPdf(true)
            .setAccessLevel(.accessOwner)
            .build()
        
        XCTAssertTrue(isEqual(nodeActionTypes: [.download, .shareLink, .exportFile, .sendToChat, .search, .pdfThumbnailView]))
    }
    
    func testPreviewPdfPageViewDocumentOwner_isExported() {
        actions = NodeActionBuilder()
            .setDisplayMode(.previewPdfPage)
            .setIsPdf(true)
            .setAccessLevel(.accessOwner)
            .setIsExported(true)
            .build()
        XCTAssertTrue(isEqual(nodeActionTypes: [.download, .manageLink, .removeLink, .exportFile, .sendToChat, .search, .pdfThumbnailView]))
    }
    
    func testPreviewPdfThumbnailDocument() {
        actions = NodeActionBuilder()
            .setDisplayMode(.previewDocument)
            .setIsPdf(true)
            .build()
        
        XCTAssertTrue(isEqual(nodeActionTypes: [.download, .sendToChat, .search, .pdfPageView]))
    }
    
    func testPreviewPdfThumbnailDocumentLink() {
        actions = NodeActionBuilder()
            .setDisplayMode(.previewDocument)
            .setIsPdf(true)
            .setIsLink(true)
            .build()
        
        XCTAssertTrue(isEqual(nodeActionTypes: [.import, .download, .shareLink, .sendToChat, .search, .pdfPageView]))
    }
    
    func testPreviewPdfThumbnailDocumentOwner() {
        actions = NodeActionBuilder()
            .setDisplayMode(.previewDocument)
            .setIsPdf(true)
            .setAccessLevel(.accessOwner)
            .build()
        
        XCTAssertTrue(isEqual(nodeActionTypes: [.download, .shareLink, .exportFile, .sendToChat, .search, .pdfPageView]))
    }
    
    func testPreviewPdfThumbnailDocumentOwner_isExported() {
        actions = NodeActionBuilder()
            .setDisplayMode(.previewDocument)
            .setIsPdf(true)
            .setAccessLevel(.accessOwner)
            .setIsExported(true)
            .build()
        XCTAssertTrue(isEqual(nodeActionTypes: [.download, .manageLink, .removeLink, .exportFile, .sendToChat, .search, .pdfPageView]))
    }
    
    func testPreviewPdf_isHiddenFalse_hiddenAction() {
        actions = NodeActionBuilder()
            .setAccessLevel(.accessOwner)
            .setDisplayMode(.previewDocument)
            .setIsPdf(true)
            .setIsHiddenNodesFeatureEnabled(true)
            .setIsHidden(false)
            .build()
        
        XCTAssertTrue(isEqual(nodeActionTypes: [.download, .shareLink, .exportFile, .sendToChat, .search, .pdfPageView, .hide]))
    }
    
    func testPreviewPdf_isHiddenTrueValidAccountType_hiddenAction() {
        actions = NodeActionBuilder()
            .setAccessLevel(.accessOwner)
            .setDisplayMode(.previewDocument)
            .setIsPdf(true)
            .setIsHiddenNodesFeatureEnabled(true)
            .setHasValidProOrUnexpiredBusinessAccount(true)
            .setIsHidden(true)
            .build()
        
        XCTAssertTrue(isEqual(nodeActionTypes: [.download, .shareLink, .exportFile, .sendToChat, .search, .pdfPageView, .unhide]))
    }
    
    func testPreviewPdf_isHiddenNil_notContainHideOrUnhide() {
        actions = NodeActionBuilder()
            .setDisplayMode(.previewDocument)
            .setIsPdf(true)
            .setIsHidden(nil)
            .build()
        
        XCTAssertTrue(actions.notContains(where: { $0.type == .hide }),
                      "Actions should not contain hide action")
        XCTAssertTrue(actions.notContains(where: { $0.type == .unhide }),
                      "Actions should not contain unhide action")
    }
    
    // MARK: - Chat tests
    
    func testChatSharedMediaFile() {
        actions = NodeActionBuilder()
            .setDisplayMode(.chatSharedFiles)
            .setIsFile(true)
            .setIsMediaFile(true)
            .build()
        
        XCTAssertTrue(isEqual(nodeActionTypes: [.forward, .download, .exportFile, .saveToPhotos, .import]))
    }
    
    func testChatSharedMediaFile_accessOwner() {
        actions = NodeActionBuilder()
            .setDisplayMode(.chatSharedFiles)
            .setIsFile(true)
            .setIsMediaFile(true)
            .setAccessLevel(.accessOwner)
            .build()
        
        XCTAssertTrue(isEqual(nodeActionTypes: [.forward, .download, .exportFile, .saveToPhotos]))
    }
    
    func testChatSharedFile() {
        actions = NodeActionBuilder()
            .setDisplayMode(.chatSharedFiles)
            .setIsFile(true)
            .setIsMediaFile(false)
            .build()
        
        XCTAssertTrue(isEqual(nodeActionTypes: [.forward, .download, .exportFile, .import]))
    }
    
    func testChatSharedFile_accessOwner() {
        actions = NodeActionBuilder()
            .setDisplayMode(.chatSharedFiles)
            .setIsFile(true)
            .setIsMediaFile(false)
            .setAccessLevel(.accessOwner)
            .build()
        
        XCTAssertTrue(isEqual(nodeActionTypes: [.forward, .download, .exportFile]))
    }
    
    func testChatAttachmentMediaFile() {
        actions = NodeActionBuilder()
            .setDisplayMode(.chatAttachment)
            .setIsFile(true)
            .setIsMediaFile(true)
            .build()
        
        XCTAssertTrue(isEqual(nodeActionTypes: [.forward, .download, .exportFile, .saveToPhotos, .import]))
    }
    
    func testChatAttachmentMediaFile_accessOwner() {
        actions = NodeActionBuilder()
            .setDisplayMode(.chatAttachment)
            .setIsFile(true)
            .setIsMediaFile(true)
            .setAccessLevel(.accessOwner)
            .build()
        
        XCTAssertTrue(isEqual(nodeActionTypes: [.forward, .download, .exportFile, .saveToPhotos]))
    }
    
    func testChatAttachmentFile() {
        actions = NodeActionBuilder()
            .setDisplayMode(.chatAttachment)
            .setIsFile(true)
            .setIsMediaFile(false)
            .build()
        
        XCTAssertTrue(isEqual(nodeActionTypes: [.forward, .download, .exportFile, .import]))
    }
    
    func testChatAttachmentFile_accessOwner() {
        actions = NodeActionBuilder()
            .setDisplayMode(.chatAttachment)
            .setIsFile(true)
            .setIsMediaFile(false)
            .setAccessLevel(.accessOwner)
            .build()
        
        XCTAssertTrue(isEqual(nodeActionTypes: [.forward, .download, .exportFile]))
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
        
        XCTAssertTrue(isEqual(nodeActionTypes: [.saveToPhotos, .download, .exportFile, .revertVersion, .remove]))
    }
    
    func testNodeVersionMediaFile() {
        actions = NodeActionBuilder()
            .setDisplayMode(.nodeVersions)
            .setAccessLevel(.accessOwner)
            .setIsFile(true)
            .setIsMediaFile(true)
            .build()
        
        XCTAssertTrue(isEqual(nodeActionTypes: [.saveToPhotos, .download, .exportFile, .remove]))
    }
    
    func testNodeVersionChildFile() {
        actions = NodeActionBuilder()
            .setDisplayMode(.nodeVersions)
            .setAccessLevel(.accessOwner)
            .setIsFile(true)
            .setIsChildVersion(true)
            .build()
        
        XCTAssertTrue(isEqual(nodeActionTypes: [.download, .exportFile, .revertVersion, .remove]))
    }
    
    func testBackupNodeVersionChildFile() {
        actions = NodeActionBuilder()
            .setDisplayMode(.nodeVersions)
            .setAccessLevel(.accessOwner)
            .setIsFile(true)
            .setIsChildVersion(true)
            .setIsBackupNode(true)
            .build()
        
        XCTAssertTrue(isEqual(nodeActionTypes: [.download, .exportFile, .copy, .remove]))
    }
    
    func testNodeVersionFile() {
        actions = NodeActionBuilder()
            .setDisplayMode(.nodeVersions)
            .setAccessLevel(.accessOwner)
            .setIsFile(true)
            .build()
        
        XCTAssertTrue(isEqual(nodeActionTypes: [.download, .exportFile, .remove]))
    }
    
    func testBackupNodeVersionFile() {
        actions = NodeActionBuilder()
            .setDisplayMode(.nodeVersions)
            .setAccessLevel(.accessOwner)
            .setIsFile(true)
            .setIsBackupNode(true)
            .build()
        
        XCTAssertTrue(isEqual(nodeActionTypes: [.download, .exportFile]))
    }
    
    // MARK: - Versions in Incoming Shared Items tests
    
    func testNodeVersionFileIncomingFullSharedFolder() {
        actions = NodeActionBuilder()
            .setDisplayMode(.nodeVersions)
            .setAccessLevel(.accessFull)
            .setIsFile(true)
            .setIsChildVersion(true)
            .build()
        
        XCTAssertTrue(isEqual(nodeActionTypes: [.download, .revertVersion, .remove]))
    }
    
    func testNodeVersionFileIncomingReadWriteSharedFolder() {
        actions = NodeActionBuilder()
            .setDisplayMode(.nodeVersions)
            .setAccessLevel(.accessReadWrite)
            .setIsFile(true)
            .setIsChildVersion(true)
            .build()
        
        XCTAssertTrue(isEqual(nodeActionTypes: [.download, .revertVersion]))
    }
    
    func testNodeVersionFileIncomingReadOnlySharedFolder() {
        actions = NodeActionBuilder()
            .setDisplayMode(.nodeVersions)
            .setAccessLevel(.accessRead)
            .setIsFile(true)
            .setIsChildVersion(true)
            .build()
        
        XCTAssertTrue(isEqual(nodeActionTypes: [.download]))
    }
    
    func testMultiselectFiles_noLinkedNodes() {
        actions = NodeActionBuilder()
            .setNodeSelectionType(.files, selectedNodeCount: 2)
            .multiselectBuild()
        
        XCTAssertTrue(isEqual(nodeActionTypes: [.download, .shareLink, .exportFile, .sendToChat, .move, .copy, .moveToRubbishBin]))
    }
    
    func testMultiselectFiles_allLinkedNodes() {
        actions = NodeActionBuilder()
            .setNodeSelectionType(.files, selectedNodeCount: 2)
            .setLinkedNodeCount(2)
            .setIsAllLinkedNode(true)
            .multiselectBuild()
        
        XCTAssertTrue(isEqual(nodeActionTypes: [.download, .manageLink, .removeLink, .exportFile, .sendToChat, .move, .copy, .moveToRubbishBin]))
    }
    
    func testMultiselectFiles_withSomeLinkedNodes() {
        actions = NodeActionBuilder()
            .setNodeSelectionType(.files, selectedNodeCount: 2)
            .setLinkedNodeCount(2)
            .setIsAllLinkedNode(false)
            .multiselectBuild()
        
        XCTAssertTrue(isEqual(nodeActionTypes: [.download, .shareLink, .removeLink, .exportFile, .sendToChat, .move, .copy, .moveToRubbishBin]))
    }
    
    func testMultiselectFolders_noLinkedNodes() {
        actions = NodeActionBuilder()
            .setNodeSelectionType(.folders, selectedNodeCount: 2)
            .multiselectBuild()
        
        XCTAssertTrue(isEqual(nodeActionTypes: [.download, .shareLink, .shareFolder, .move, .copy, .moveToRubbishBin]))
    }
    
    func testMultiselectFolders_allLinkedNodes() {
        actions = NodeActionBuilder()
            .setNodeSelectionType(.folders, selectedNodeCount: 2)
            .setLinkedNodeCount(2)
            .setIsAllLinkedNode(true)
            .multiselectBuild()
        
        XCTAssertTrue(isEqual(nodeActionTypes: [.download, .manageLink, .removeLink, .shareFolder, .move, .copy, .moveToRubbishBin]))
    }
    
    func testMultiselectFolders_withSomeLinkedNodes() {
        actions = NodeActionBuilder()
            .setNodeSelectionType(.folders, selectedNodeCount: 2)
            .setLinkedNodeCount(2)
            .setIsAllLinkedNode(false)
            .multiselectBuild()
        
        XCTAssertTrue(isEqual(nodeActionTypes: [.download, .shareLink, .removeLink, .shareFolder, .move, .copy, .moveToRubbishBin]))
    }
    
    func testMultiselectFilesAndFolders_noLinkedNodes() {
        actions = NodeActionBuilder()
            .setNodeSelectionType(.filesAndFolders, selectedNodeCount: 2)
            .multiselectBuild()
        
        XCTAssertTrue(isEqual(nodeActionTypes: [.download, .shareLink, .move, .copy, .moveToRubbishBin]))
    }
    
    func testMultiselectFilesAndFolders_allLinkedNodes() {
        actions = NodeActionBuilder()
            .setNodeSelectionType(.filesAndFolders, selectedNodeCount: 2)
            .setLinkedNodeCount(2)
            .setIsAllLinkedNode(true)
            .multiselectBuild()
        
        XCTAssertTrue(isEqual(nodeActionTypes: [.download, .manageLink, .removeLink, .move, .copy, .moveToRubbishBin]))
    }
    
    func testMultiselectFilesAndFolders_withSomeLinkedNodes() {
        actions = NodeActionBuilder()
            .setNodeSelectionType(.filesAndFolders, selectedNodeCount: 2)
            .setLinkedNodeCount(2)
            .setIsAllLinkedNode(false)
            .multiselectBuild()
        
        XCTAssertTrue(isEqual(nodeActionTypes: [.download, .shareLink, .removeLink, .move, .copy, .moveToRubbishBin]))
    }
    
    func testMultiselectMediaFiles() {
        actions = NodeActionBuilder()
            .setNodeSelectionType(.files, selectedNodeCount: 4)
            .setAreMediaFiles(true)
            .multiselectBuild()
        
        XCTAssertTrue(isEqual(nodeActionTypes: [.download, .shareLink, .exportFile, .sendToChat, .saveToPhotos, .move, .copy, .moveToRubbishBin]))
    }
    
    func testMultiselectMediaFiles_photosFavouriteAlbum_shouldReturnCorrrectActions() {
        actions = NodeActionBuilder()
            .setNodeSelectionType(.files, selectedNodeCount: 4)
            .setIsFavourite(true)
            .setAreMediaFiles(true)
            .setDisplayMode(.photosFavouriteAlbum)
            .multiselectBuild()
        
        XCTAssertTrue(isEqual(nodeActionTypes: [.favourite, .download, .shareLink, .exportFile, .sendToChat]))
    }
    
    func testMultiselectMediaFiles_hiddenForPhotosFavouriteAlbum_shouldReturnCorrrectActions() {
        let expectations: [(isHidden: Bool?, nodeAction: MegaNodeActionType?)] = [
            (isHidden: true, nodeAction: .unhide),
            (isHidden: false, nodeAction: .hide),
            (isHidden: nil, nodeAction: nil)
        ]
        
        expectations.forEach { (isHidden, hiddenNodeActionType) in
            actions = NodeActionBuilder()
                .setNodeSelectionType(.files, selectedNodeCount: 4)
                .setIsFavourite(true)
                .setAreMediaFiles(true)
                .setDisplayMode(.photosFavouriteAlbum)
                .setIsHiddenNodesFeatureEnabled(true)
                .setHasValidProOrUnexpiredBusinessAccount(true)
                .setIsHidden(isHidden)
                .multiselectBuild()
            
            let expectedActionTypes = [.favourite, .download, .shareLink,
                                       .exportFile, .sendToChat, hiddenNodeActionType]
                .compactMap { $0 }
            
            XCTAssertTrue(isEqual(nodeActionTypes: expectedActionTypes),
                          "NodeActions invalid for isHidden: \(String(describing: isHidden))")
        }
    }
    
    func testMultiselectMediaFiles_MediaDiscovery() {
        actions = NodeActionBuilder()
            .setNodeSelectionType(.files, selectedNodeCount: 4)
            .setAreMediaFiles(true)
            .setDisplayMode(.mediaDiscovery)
            .multiselectBuild()
        
        XCTAssertTrue(isEqual(nodeActionTypes: [.download, .shareLink, .exportFile, .sendToChat, .saveToPhotos, .move, .copy, .moveToRubbishBin]))
    }
    
    func testExportedNodeActions_nodeExported() {
        actions = NodeActionBuilder()
            .setDisplayMode(.cloudDrive)
            .setAccessLevel(.accessOwner)
            .setIsExported(true)
            .build()
        
        XCTAssertTrue(isEqual(nodeActionTypes: [.info, .favourite, .label, .download, .manageLink, .removeLink, .shareFolder, .rename, .move, .copy, .moveToRubbishBin]))
    }
    
    func testExportedNodeActions_nodeNotExported() {
        actions = NodeActionBuilder()
            .setDisplayMode(.cloudDrive)
            .setAccessLevel(.accessOwner)
            .build()
        
        XCTAssertTrue(isEqual(nodeActionTypes: [.info, .favourite, .label, .download, .shareLink, .shareFolder, .rename, .move, .copy, .moveToRubbishBin]))
    }
    
    func testAlbumLink() {
        actions = NodeActionBuilder()
            .setDisplayMode(.albumLink)
            .setAccessLevel(.accessRead)
            .build()
        
        XCTAssertTrue(isEqual(nodeActionTypes: [.saveToPhotos]))
    }
    
    func testMultiselectBuild_cloudDriveContainsHiddenFolderForFolderDisplayMode_shouldReturnCorrectActions() {
        actions = NodeActionBuilder()
            .setNodeSelectionType(.folders, selectedNodeCount: 4)
            .setDisplayMode(.cloudDrive)
            .setIsHiddenNodesFeatureEnabled(true)
            .setIsHidden(false)
            .multiselectBuild()
        
        XCTAssertTrue(isEqual(nodeActionTypes: [.download, .shareLink, .shareFolder,
                                                .hide, .move, .copy, .moveToRubbishBin]))
    }
    
    func testMultiselectBuild_cloudDriveContainsHiddenFileForFileDisplayModeValidAccountType_shouldReturnCorrectActions() {
        actions = NodeActionBuilder()
            .setNodeSelectionType(.files, selectedNodeCount: 4)
            .setDisplayMode(.cloudDrive)
            .setIsHiddenNodesFeatureEnabled(true)
            .setHasValidProOrUnexpiredBusinessAccount(true)
            .setIsHidden(false)
            .multiselectBuild()
        
        XCTAssertTrue(isEqual(nodeActionTypes: [.download, .shareLink, .exportFile, .sendToChat,
                                                .hide, .move, .copy, .moveToRubbishBin]))
    }
    
    func testMultiselectBuild_cloudDriveContainsHiddenFileOrFolderForFileAndFolderDisplayMode_shouldReturnCorrectActions() {
        actions = NodeActionBuilder()
            .setAccessLevel(.accessOwner)
            .setNodeSelectionType(.filesAndFolders, selectedNodeCount: 4)
            .setDisplayMode(.cloudDrive)
            .setIsHiddenNodesFeatureEnabled(true)
            .setHasValidProOrUnexpiredBusinessAccount(true)
            .setIsHidden(false)
            .multiselectBuild()
        
        XCTAssertTrue(isEqual(nodeActionTypes: [.download, .shareLink, .hide,
                                                .move, .copy, .moveToRubbishBin]))
    }
    
    func testMultiselectBuild_cloudDriveForDisplayModesHiddenValueNilValidAccountType_shouldNotContainHideAction() {
        [NodeSelectionType.folders, .files, .filesAndFolders].forEach {
            actions = NodeActionBuilder()
                .setNodeSelectionType($0, selectedNodeCount: 4)
                .setDisplayMode(.cloudDrive)
                .setIsHiddenNodesFeatureEnabled(true)
                .setHasValidProOrUnexpiredBusinessAccount(true)
                .setIsHidden(nil)
                .multiselectBuild()
            
            XCTAssertTrue(actions.notContains(where: { $0.type == .hide }))
        }
    }
    
    func testMultiselectBuild_cloudDriveFolderDisplayModeHiddenTrueForValidProAccount_shouldReturnCorrectActions() {
        actions = NodeActionBuilder()
            .setAccessLevel(.accessOwner)
            .setIsHiddenNodesFeatureEnabled(true)
            .setNodeSelectionType(.folders, selectedNodeCount: 4)
            .setDisplayMode(.cloudDrive)
            .setIsHiddenNodesFeatureEnabled(true)
            .setHasValidProOrUnexpiredBusinessAccount(true)
            .setIsHidden(true)
            .multiselectBuild()
        
        XCTAssertTrue(isEqual(nodeActionTypes: [.download, .shareLink, .shareFolder,
                                                .unhide, .move, .copy, .moveToRubbishBin]))
    }
    
    func testMultiselectBuild_cloudDriveFileDisplayModeHideTrueWithValidAccountType_shouldReturnCorrectActions() {
        actions = NodeActionBuilder()
            .setAccessLevel(.accessOwner)
            .setNodeSelectionType(.files, selectedNodeCount: 4)
            .setDisplayMode(.cloudDrive)
            .setIsHiddenNodesFeatureEnabled(true)
            .setHasValidProOrUnexpiredBusinessAccount(true)
            .setIsHidden(true)
            .multiselectBuild()
        
        XCTAssertTrue(isEqual(nodeActionTypes: [.download, .shareLink, .exportFile, .sendToChat,
                                                .unhide, .move, .copy, .moveToRubbishBin]))
    }
    
    func testMultiselectBuild_cloudDriveFileAndFolderDisplayModeHiddenTrueValidAccountType_shouldReturnCorrectActions() {
        actions = NodeActionBuilder()
            .setAccessLevel(.accessOwner)
            .setNodeSelectionType(.filesAndFolders, selectedNodeCount: 4)
            .setDisplayMode(.cloudDrive)
            .setIsHiddenNodesFeatureEnabled(true)
            .setHasValidProOrUnexpiredBusinessAccount(true)
            .setIsHidden(true)
            .multiselectBuild()
        
        XCTAssertTrue(isEqual(nodeActionTypes: [.download, .shareLink, .unhide,
                                                .move, .copy, .moveToRubbishBin]))
    }
    
    func testMultiselectBuild_hiddenNodesFeatureFlagOff_shouldNotReturnHiddenAction() {
        actions = NodeActionBuilder()
            .setAccessLevel(.accessOwner)
            .setNodeSelectionType(.filesAndFolders, selectedNodeCount: 4)
            .setDisplayMode(.cloudDrive)
            .setIsHiddenNodesFeatureEnabled(false)
            .setHasValidProOrUnexpiredBusinessAccount(true)
            .setIsHidden(true)
            .multiselectBuild()
        
        XCTAssertTrue(actions.notContains(where: { $0.type == .hide }))
    }
    
    func testMultiselectBuild_hiddenNodesFeatureFlagOnNotValidProAccountHiddenSet_shouldReturnHiddenAction() {
        [true, false].forEach { isHidden in
            actions = NodeActionBuilder()
                .setAccessLevel(.accessOwner)
                .setNodeSelectionType(.filesAndFolders, selectedNodeCount: 4)
                .setDisplayMode(.cloudDrive)
                .setIsHiddenNodesFeatureEnabled(true)
                .setHasValidProOrUnexpiredBusinessAccount(false)
                .setIsHidden(isHidden)
                .multiselectBuild()
            
            XCTAssertTrue(actions.contains(where: { $0.type == .hide }), "Should contain hide action for hidden \(isHidden)")
        }
    }
    
    func testMultiselectBuild_hiddenNodesFeatureFlagOnNotValidProAccountHiddenNotSet_shouldNotReturnHiddenAction() {
        actions = NodeActionBuilder()
            .setAccessLevel(.accessOwner)
            .setNodeSelectionType(.filesAndFolders, selectedNodeCount: 4)
            .setDisplayMode(.cloudDrive)
            .setIsHiddenNodesFeatureEnabled(true)
            .setHasValidProOrUnexpiredBusinessAccount(false)
            .setIsHidden(nil)
            .multiselectBuild()
        
        XCTAssertTrue(actions.notContains(where: { $0.type == .hide }))
    }
    
    // MARK: - videoPlaylistContent
    
    func testBuild_displayModeVideoPlaylistContent_shouldReturnCorrectActions() {
        actions = NodeActionBuilder()
            .setDisplayMode(.videoPlaylistContent)
            .build()
        
        XCTAssertTrue(isEqual(nodeActionTypes: [
            .shareLink,
            .saveToPhotos,
            .removeVideoFromVideoPlaylist,
            .sendToChat,
            .exportFile,
            .moveVideoInVideoPlaylistContentToRubbishBin ]))
    }
    
    func testBuild_displayModeVideoPlaylistContentAndSetIsHiddenTrue_shouldReturnCorrectActions() {
        actions = NodeActionBuilder()
            .setDisplayMode(.videoPlaylistContent)
            .setIsHiddenNodesFeatureEnabled(true)
            .setHasValidProOrUnexpiredBusinessAccount(true)
            .setIsHidden(true)
            .build()
        
        XCTAssertTrue(isEqual(nodeActionTypes: [
            .shareLink,
            .saveToPhotos,
            .removeVideoFromVideoPlaylist,
            .sendToChat,
            .exportFile,
            .unhide,
            .moveVideoInVideoPlaylistContentToRubbishBin
        ]))
    }
    
    func testBuild_displayModeVideoPlaylistContentAndSetIsHiddenFalse_shouldReturnCorrectActions() {
        actions = NodeActionBuilder()
            .setDisplayMode(.videoPlaylistContent)
            .setIsHiddenNodesFeatureEnabled(true)
            .setHasValidProOrUnexpiredBusinessAccount(true)
            .setIsHidden(false)
            .build()
        
        XCTAssertTrue(isEqual(nodeActionTypes: [
            .shareLink,
            .saveToPhotos,
            .removeVideoFromVideoPlaylist,
            .sendToChat,
            .exportFile,
            .hide,
            .moveVideoInVideoPlaylistContentToRubbishBin
        ]))
    }
    
    func testMultiselectBuild_displayModeVideoPlaylistContent_shouldReturnCorrectActions() {
        actions = NodeActionBuilder()
            .setDisplayMode(.videoPlaylistContent)
            .multiselectBuild()
        
        XCTAssertTrue(isEqual(nodeActionTypes: [
            .shareLink,
            .saveToPhotos,
            .removeVideoFromVideoPlaylist,
            .sendToChat,
            .exportFile,
            .moveVideoInVideoPlaylistContentToRubbishBin ]))
    }
}
