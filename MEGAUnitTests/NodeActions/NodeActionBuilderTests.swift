@testable import MEGA
import MEGASDKRepoMock
import Testing

@MainActor
class NodeActionBuilderTests {
    
    var actions: [NodeAction] = []
    
    // MARK: - Private methods
    
    func isEqual(nodeActionTypes types: [MegaNodeActionType]) -> Bool {
        guard actions.count == types.count else {
            return false
        }
        let actionTypes = actions.map { $0.type }
        return actionTypes == types
    }
    
    // MARK: - Cloud Drive tests
    
    @Test
    func testCloudDriveNodeMediaFile() {
        actions = NodeActionBuilder()
            .setDisplayMode(.cloudDrive)
            .setAccessLevel(.accessOwner)
            .setIsMediaFile(true)
            .setIsFile(true)
            .build()
        
        #expect(isEqual(nodeActionTypes: [.info, .favourite, .label, .saveToPhotos, .download, .shareLink, .exportFile, .sendToChat, .rename, .move, .copy, .moveToRubbishBin]) == true)
    }
    
    @Test
    func testCloudDriveNodeMediaFileExported() {
        actions = NodeActionBuilder()
            .setDisplayMode(.cloudDrive)
            .setAccessLevel(.accessOwner)
            .setIsMediaFile(true)
            .setIsFile(true)
            .setIsExported(true)
            .build()
        
        #expect(isEqual(nodeActionTypes: [.info, .favourite, .label, .saveToPhotos, .download, .manageLink, .removeLink, .exportFile, .sendToChat, .rename, .move, .copy, .moveToRubbishBin]) == true)
    }
    
    @Test
    func testCloudDriveNodeFolder() {
        actions = NodeActionBuilder()
            .setDisplayMode(.cloudDrive)
            .setAccessLevel(.accessOwner)
            .setIsFile(false)
            .build()
        
        #expect(isEqual(nodeActionTypes: [.info, .favourite, .label, .download, .shareLink, .shareFolder, .rename, .move, .copy, .moveToRubbishBin]) == true)
    }
    
    @Test
    func testCloudDriveNodeFolderExported() {
        actions = NodeActionBuilder()
            .setDisplayMode(.cloudDrive)
            .setAccessLevel(.accessOwner)
            .setIsFile(false)
            .setIsExported(true)
            .build()
        
        #expect(isEqual(nodeActionTypes: [.info, .favourite, .label, .download, .manageLink, .removeLink, .shareFolder, .rename, .move, .copy, .moveToRubbishBin]) == true)
    }
    
    @Test
    func testCloudDriveNodeFolderShared() {
        actions = NodeActionBuilder()
            .setDisplayMode(.cloudDrive)
            .setAccessLevel(.accessOwner)
            .setIsFile(false)
            .setIsOutshare(true)
            .build()
        
        #expect(isEqual(nodeActionTypes: [.info, .favourite, .label, .download, .shareLink, .manageShare, .rename, .move, .copy, .moveToRubbishBin]) == true)
    }
    
    @Test
    func testCloudDriveNodeFolderSharedExported() {
        actions = NodeActionBuilder()
            .setDisplayMode(.cloudDrive)
            .setAccessLevel(.accessOwner)
            .setIsFile(false)
            .setIsOutshare(true)
            .setIsExported(true)
            .build()
        
        #expect(isEqual(nodeActionTypes: [.info, .favourite, .label, .download, .manageLink, .removeLink, .manageShare, .rename, .move, .copy, .moveToRubbishBin]) == true)
    }
    
    @Test
    func testCloudDriveNodeFile() {
        actions = NodeActionBuilder()
            .setDisplayMode(.cloudDrive)
            .setAccessLevel(.accessOwner)
            .setIsFile(true)
            .build()
        
        #expect(isEqual(nodeActionTypes: [.info, .favourite, .label, .download, .shareLink, .exportFile, .sendToChat, .rename, .move, .copy, .moveToRubbishBin]) == true)
    }
    
    @Test
    func testCloudDriveNodeExportedFile() {
        actions = NodeActionBuilder()
            .setDisplayMode(.cloudDrive)
            .setAccessLevel(.accessOwner)
            .setIsFile(true)
            .setIsExported(true)
            .build()
        
        #expect(isEqual(nodeActionTypes: [.info, .favourite, .label, .download, .manageLink, .removeLink, .exportFile, .sendToChat, .rename, .move, .copy, .moveToRubbishBin]) == true)
    }
    
    @Test
    func testCloudDriveNodeTextFile() {
        actions = NodeActionBuilder()
            .setDisplayMode(.cloudDrive)
            .setAccessLevel(.accessOwner)
            .setIsEditableTextFile(true)
            .setIsFile(true)
            .build()
        
        #expect(isEqual(nodeActionTypes: [.editTextFile, .info, .favourite, .label, .download, .shareLink, .exportFile, .sendToChat, .rename, .move, .copy, .moveToRubbishBin]) == true)
    }
    
    @Test
    func testCloudDriveNodeTextFileExported() {
        actions = NodeActionBuilder()
            .setDisplayMode(.cloudDrive)
            .setAccessLevel(.accessOwner)
            .setIsEditableTextFile(true)
            .setIsFile(true)
            .setIsExported(true)
            .build()
        
        #expect(isEqual(nodeActionTypes: [.editTextFile, .info, .favourite, .label, .download, .manageLink, .removeLink, .exportFile, .sendToChat, .rename, .move, .copy, .moveToRubbishBin]) == true)
    }
    
    @Test
    func testCloudDriveNodeWithNoVersion() {
        actions = NodeActionBuilder()
            .setDisplayMode(.cloudDrive)
            .setAccessLevel(.accessOwner)
            .setIsFile(true)
            .setVersionCount(0)
            .build()
        
        #expect(isEqual(nodeActionTypes: [.info, .favourite, .label, .download, .shareLink, .exportFile, .sendToChat, .rename, .move, .copy, .moveToRubbishBin]) == true)
    }
    
    @Test
    func testCloudDriveNodeWithMultiVersions() {
        actions = NodeActionBuilder()
            .setDisplayMode(.cloudDrive)
            .setAccessLevel(.accessOwner)
            .setIsFile(true)
            .setVersionCount(2)
            .build()
        
        #expect(isEqual(nodeActionTypes: [.info, .viewVersions, .favourite, .label, .download, .shareLink, .exportFile, .sendToChat, .rename, .move, .copy, .moveToRubbishBin]) == true)
    }
    
    @Test
    func testCloudDriveTextFileNodeWithMultiVersions() {
        actions = NodeActionBuilder()
            .setDisplayMode(.cloudDrive)
            .setAccessLevel(.accessOwner)
            .setIsEditableTextFile(true)
            .setIsFile(true)
            .setVersionCount(2)
            .build()
        
        #expect(isEqual(nodeActionTypes: [.editTextFile, .info, .viewVersions, .favourite, .label, .download, .shareLink, .exportFile, .sendToChat, .rename, .move, .copy, .moveToRubbishBin]) == true)
    }
    
    @Test
    func testBuild_cloudDriveHiddenFalseValidAccountType_shouldReturnCorrectActions() {
        actions = NodeActionBuilder()
            .setDisplayMode(.cloudDrive)
            .setAccessLevel(.accessOwner)
            .setIsHiddenNodesFeatureEnabled(true)
            .setHasValidProOrUnexpiredBusinessAccount(true)
            .setIsHidden(false)
            .build()
        
        #expect(isEqual(nodeActionTypes: [.info, .favourite, .label, .download, .shareLink, .shareFolder, .rename, .hide, .move, .copy, .moveToRubbishBin]) == true)
    }
    
    @Test
    func testBuild_cloudDriveHiddenTrueValidAccountType_shouldReturnCorrectActions() {
        actions = NodeActionBuilder()
            .setDisplayMode(.cloudDrive)
            .setAccessLevel(.accessOwner)
            .setIsHiddenNodesFeatureEnabled(true)
            .setHasValidProOrUnexpiredBusinessAccount(true)
            .setIsHidden(true)
            .build()
        
        #expect(isEqual(nodeActionTypes: [.info, .favourite, .label, .download, .shareLink, .shareFolder, .rename, .unhide, .move, .copy, .moveToRubbishBin]) == true)
    }
    
    @Test
    func testFileFolderNodeDoNotShowInfoAction() {
        actions = NodeActionBuilder()
            .setDisplayMode(.nodeInfo)
            .build()
        
        #expect(isEqual(nodeActionTypes: [.import, .download]) == true)
    }
    
    @Test
    func testCloudDriveTakedownNode() {
        actions = NodeActionBuilder()
            .setDisplayMode(.cloudDrive)
            .setIsTakedown(true)
            .build()
        
        #expect(isEqual(nodeActionTypes: [.info, .disputeTakedown, .rename, .moveToRubbishBin]) == true)
    }
    
    @Test
    func testTakeDownNode_onSingleFileSelection_shouldHaveDisputedActions() {
        actions = NodeActionBuilder()
            .setNodeSelectionType(.files, selectedNodeCount: 1)
            .setIsTakedown(true)
            .multiselectBuild()
        
        #expect(isEqual(nodeActionTypes: [.info, .disputeTakedown, .rename, .moveToRubbishBin]) == true)
    }
    
    @Test
    func testTakeDownNode_onMultipleFilesSelection_shouldHaveOnlyMoveToBinAction() {
        actions = NodeActionBuilder()
            .setNodeSelectionType(.files, selectedNodeCount: 2)
            .setIsTakedown(true)
            .multiselectBuild()
        
        #expect(isEqual(nodeActionTypes: [.moveToRubbishBin]) == true)
    }
    
    @Test
    func testTakeDownNode_onSingleFolderSelection_shouldHaveDisputedActions() {
        actions = NodeActionBuilder()
            .setNodeSelectionType(.folders, selectedNodeCount: 1)
            .setIsTakedown(true)
            .multiselectBuild()
        
        #expect(isEqual(nodeActionTypes: [.info, .disputeTakedown, .rename, .moveToRubbishBin]) == true)
    }
    
    @Test
    func testTakeDownNode_onMultipleFoldersSelection_shouldHaveOnlyMoveToBinAction() {
        actions = NodeActionBuilder()
            .setNodeSelectionType(.folders, selectedNodeCount: 2)
            .setIsTakedown(true)
            .multiselectBuild()
        
        #expect(isEqual(nodeActionTypes: [.moveToRubbishBin]) == true)
    }
    
    @Test
    func testTakeDownNode_onMultipleFilesAndFoldersSelection_shouldHaveOnlyMoveToBinAction() {
        actions = NodeActionBuilder()
            .setNodeSelectionType(.filesAndFolders, selectedNodeCount: 2)
            .setIsTakedown(true)
            .multiselectBuild()
        
        #expect(isEqual(nodeActionTypes: [.moveToRubbishBin]) == true)
    }
    
    // MARK: - Backup
    @Test
    func testBackupNodeWithNoVersion() {
        actions = NodeActionBuilder()
            .setDisplayMode(.backup)
            .setAccessLevel(.accessOwner)
            .setIsFile(true)
            .setVersionCount(0)
            .build()
        
        #expect(isEqual(nodeActionTypes: [.info, .download, .shareLink, .exportFile, .sendToChat, .copy]) == true)
    }
    
    @Test
    func testBackupNodeWithVersions() {
        actions = NodeActionBuilder()
            .setDisplayMode(.backup)
            .setAccessLevel(.accessOwner)
            .setIsFile(true)
            .setVersionCount(3)
            .build()
        
        #expect(isEqual(nodeActionTypes: [.info, .viewVersions, .download, .shareLink, .exportFile, .sendToChat, .copy]) == true)
    }
    
    // MARK: - Rubbish Bin
    @Test
    func testRubbishBinNodeRestorableFolder() {
        actions = NodeActionBuilder()
            .setDisplayMode(.rubbishBin)
            .setAccessLevel(.accessOwner)
            .setIsFile(false)
            .setIsRestorable(true)
            .build()
        
        #expect(isEqual(nodeActionTypes: [.restore, .info, .remove]) == true)
    }
    
    @Test
    func testRubbishBinNodeUnrestorableFolder() {
        actions = NodeActionBuilder()
            .setDisplayMode(.rubbishBin)
            .setAccessLevel(.accessOwner)
            .setIsFile(false)
            .setIsRestorable(false)
            .build()
        
        #expect(isEqual(nodeActionTypes: [.info, .remove]) == true)
    }
    
    @Test
    func testRubbishBinNodeRestorableFile() {
        actions = NodeActionBuilder()
            .setDisplayMode(.rubbishBin)
            .setAccessLevel(.accessOwner)
            .setIsFile(true)
            .setIsRestorable(true)
            .setIsInVersionsView(false)
            .build()
        
        #expect(isEqual(nodeActionTypes: [.restore, .info, .remove]) == true)
    }
    
    @Test
    func testRubbishBinNodeUnrestorableFile() {
        actions = NodeActionBuilder()
            .setDisplayMode(.rubbishBin)
            .setAccessLevel(.accessOwner)
            .setIsFile(true)
            .setIsRestorable(false)
            .build()
        
        #expect(isEqual(nodeActionTypes: [.info, .remove]) == true)
    }
    
    @Test
    func testRubbishBinNodeVersionPreview() {
        actions = NodeActionBuilder()
            .setDisplayMode(.rubbishBin)
            .setAccessLevel(.accessOwner)
            .setIsFile(true)
            .setIsRestorable(true)
            .setIsInVersionsView(true)
            .build()
        
        #expect(isEqual(nodeActionTypes: [.info]) == true)
    }
    
    @Test
    func testRubbishBinTakedownNode() {
        actions = NodeActionBuilder()
            .setDisplayMode(.rubbishBin)
            .setIsTakedown(true)
            .build()
        #expect(isEqual(nodeActionTypes: [.info, .disputeTakedown, .rename, .remove]) == true)
    }
    
    @Test
    func testRubbishBin_BackupNode() {
        actions = NodeActionBuilder()
            .setDisplayMode(.rubbishBin)
            .setAccessLevel(.accessOwner)
            .setIsBackupNode(true)
            .build()
        #expect(isEqual(nodeActionTypes: [.restoreBackup, .info, .remove]) == true)
    }
    
    // MARK: - Recent Items tests
    
    @Test
    func testRecentNodeNoVersion() {
        actions = NodeActionBuilder()
            .setDisplayMode(.recents)
            .setAccessLevel(.accessOwner)
            .setIsFile(true)
            .setVersionCount(0)
            .build()
        
        #expect(isEqual(nodeActionTypes: [.info, .favourite, .label, .download, .shareLink, .exportFile, .sendToChat, .rename, .move, .copy, .moveToRubbishBin]) == true)
    }
    
    @Test
    func testRecentNodeWithMultiVersion() {
        actions = NodeActionBuilder()
            .setDisplayMode(.recents)
            .setAccessLevel(.accessOwner)
            .setIsFile(true)
            .setVersionCount(2)
            .build()
        
        #expect(isEqual(nodeActionTypes: [.info, .viewVersions, .favourite, .label, .download, .shareLink, .exportFile, .sendToChat, .rename, .move, .copy, .moveToRubbishBin]) == true)
    }
    
    @Test
    func testRecentNode_withHiddenNodesFalse_shouldReturnNoHiddenActions() {
        actions = NodeActionBuilder()
            .setDisplayMode(.recents)
            .setIsFile(true)
            .setVersionCount(2)
            .setIsHidden(false)
            .build()
        
        #expect(isEqual(nodeActionTypes: [.import, .download]) == true)
    }
    
    @Test
    func testRecentNode_withHiddenNodeFalse_shouldReturnHiddenActions() {
        actions = NodeActionBuilder()
            .setDisplayMode(.recents)
            .setAccessLevel(.accessOwner)
            .setIsFile(true)
            .setVersionCount(2)
            .setIsHiddenNodesFeatureEnabled(true)
            .setIsHidden(false)
            .build()
        
        #expect(isEqual(nodeActionTypes: [.info, .viewVersions, .favourite, .label, .download, .shareLink, .exportFile, .sendToChat, .rename, .hide, .move, .copy, .moveToRubbishBin]) == true)
    }
    
    @Test
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
        
        #expect(isEqual(nodeActionTypes: [.info, .viewVersions, .favourite, .label, .download, .shareLink, .exportFile, .sendToChat, .rename, .unhide, .move, .copy, .moveToRubbishBin]) == true)
    }
    
    // MARK: - Shared Items tests
    
    @Test
    func testIncomingFullSharedFolder() {
        actions = NodeActionBuilder()
            .setDisplayMode(.sharedItem)
            .setAccessLevel(.accessFull)
            .setIsFile(false)
            .setisIncomingShareChildView(true)
            .build()
        
        #expect(isEqual(nodeActionTypes: [.info, .download, .rename, .copy, .leaveSharing]) == true)
    }
    
    @Test
    func testIncomingFullSharedFolder_verifyContact_enabled() {
        actions = NodeActionBuilder()
            .setDisplayMode(.sharedItem)
            .setAccessLevel(.accessFull)
            .setIsFile(false)
            .setisIncomingShareChildView(true)
            .setIsVerifyContact(true, sharedFolderReceiverEmail: "", sharedFolderContact: MockUser())
            .build()
        
        #expect(isEqual(nodeActionTypes: [.verifyContact, .info, .label, .leaveSharing]) == true)
    }
    
    @Test
    func testIncomingFullSharedFolderTextFile() {
        actions = NodeActionBuilder()
            .setDisplayMode(.sharedItem)
            .setAccessLevel(.accessFull)
            .setIsEditableTextFile(true)
            .setIsFile(true)
            .build()
        
        #expect(isEqual(nodeActionTypes: [.editTextFile, .info, .download, .rename, .copy, .move, .moveToRubbishBin]) == true)
    }
    
    @Test
    func testIncomingFullSharedFolderNodeNoVersion() {
        actions = NodeActionBuilder()
            .setDisplayMode(.sharedItem)
            .setAccessLevel(.accessFull)
            .setIsFile(true)
            .setVersionCount(0)
            .build()
        
        #expect(isEqual(nodeActionTypes: [.info, .download, .rename, .copy, .move, .moveToRubbishBin]) == true)
    }
    
    @Test
    func testIncomingFullSharedFolderNodeWithMultiVersion() {
        actions = NodeActionBuilder()
            .setDisplayMode(.sharedItem)
            .setAccessLevel(.accessFull)
            .setIsFile(true)
            .setVersionCount(2)
            .build()
        
        #expect(isEqual(nodeActionTypes: [.info, .viewVersions, .download, .rename, .copy, .move, .moveToRubbishBin]) == true)
    }
    
    @Test
    func testIncomingReadAndReadWriteSharedFolder() {
        actions = NodeActionBuilder()
            .setDisplayMode(.sharedItem)
            .setAccessLevel(.accessReadWrite)
            .setIsFile(false)
            .setisIncomingShareChildView(true)
            .build()
        
        #expect(isEqual(nodeActionTypes: [.info, .download, .copy, .leaveSharing]) == true)
    }
    
    @Test
    func testIncomingReadAndReadWriteSharedFolder_verifyContact_enabled() {
        actions = NodeActionBuilder()
            .setDisplayMode(.sharedItem)
            .setAccessLevel(.accessReadWrite)
            .setIsFile(false)
            .setisIncomingShareChildView(true)
            .setIsVerifyContact(true, sharedFolderReceiverEmail: "", sharedFolderContact: MockUser())
            .build()
        
        #expect(isEqual(nodeActionTypes: [.verifyContact, .info, .leaveSharing]) == true)
    }
    
    @Test
    func testIncomingReadAndReadWriteSharedFolderTextFile() {
        actions = NodeActionBuilder()
            .setDisplayMode(.sharedItem)
            .setAccessLevel(.accessReadWrite)
            .setIsEditableTextFile(true)
            .setIsFile(true)
            .build()
        
        #expect(isEqual(nodeActionTypes: [.editTextFile, .info, .download, .copy]) == true)
    }
    
    @Test
    func testIncomingReadAndReadWriteSharedFolderNodeNoVersion() {
        actions = NodeActionBuilder()
            .setDisplayMode(.sharedItem)
            .setAccessLevel(.accessReadWrite)
            .setIsFile(true)
            .setVersionCount(0)
            .build()
        
        #expect(isEqual(nodeActionTypes: [.info, .download, .copy]) == true)
    }
    
    @Test
    func testIncomingReadAndReadWriteSharedFolderNodeWithMultiVersion() {
        actions = NodeActionBuilder()
            .setDisplayMode(.sharedItem)
            .setAccessLevel(.accessReadWrite)
            .setIsFile(true)
            .setVersionCount(2)
            .build()
        
        #expect(isEqual(nodeActionTypes: [.info, .viewVersions, .download, .copy]) == true)
    }
    
    @Test
    func testOutgoingSharedFolder() {
        actions = NodeActionBuilder()
            .setDisplayMode(.sharedItem)
            .setAccessLevel(.accessOwner)
            .setIsFile(false)
            .setIsOutshare(true)
            .build()
        
        #expect(isEqual(nodeActionTypes: [.info, .favourite, .label, .download, .shareLink, .manageShare, .rename, .copy, .removeSharing]) == true)
    }
    
    @Test
    func testOutgoingSharedFolder_verifyContact_enabled() {
        actions = NodeActionBuilder()
            .setDisplayMode(.sharedItem)
            .setAccessLevel(.accessOwner)
            .setIsFile(false)
            .setIsOutshare(true)
            .setIsVerifyContact(true, sharedFolderReceiverEmail: "", sharedFolderContact: MockUser())
            .build()
        
        #expect(isEqual(nodeActionTypes: [.verifyContact, .info, .favourite, .label, .download, .shareLink, .manageShare, .rename, .copy, .removeSharing]) == true)
    }
    
    @Test
    func testOutgoingSharedFolderExported() {
        actions = NodeActionBuilder()
            .setDisplayMode(.sharedItem)
            .setAccessLevel(.accessOwner)
            .setIsFile(false)
            .setIsOutshare(true)
            .setIsExported(true)
            .build()
        
        #expect(isEqual(nodeActionTypes: [.info, .favourite, .label, .download, .manageLink, .removeLink, .manageShare, .rename, .copy, .removeSharing]) == true)
    }
    
    @Test
    func testOutgoingSharedFolder_verifyContactAndExported_enabled() {
        actions = NodeActionBuilder()
            .setDisplayMode(.sharedItem)
            .setAccessLevel(.accessOwner)
            .setIsFile(false)
            .setIsOutshare(true)
            .setIsExported(true)
            .setIsVerifyContact(true, sharedFolderReceiverEmail: "", sharedFolderContact: MockUser())
            .build()
        
        #expect(isEqual(nodeActionTypes: [.verifyContact, .info, .favourite, .label, .download, .manageLink, .removeLink, .manageShare, .rename, .copy, .removeSharing]) == true)
    }
    
    @Test
    func testOutgoingSharedFolder_hidden_shouldNotContainHideAction() {
        actions = NodeActionBuilder()
            .setDisplayMode(.sharedItem)
            .setIsHidden(true)
            .build()
        
        #expect(actions.map(\.type).notContains(.hide) == true)
    }
    
    // MARK: - Links tests
    
    @Test
    func testFileMediaLink() {
        actions = NodeActionBuilder()
            .setDisplayMode(.fileLink)
            .setIsFile(true)
            .setIsMediaFile(true)
            .build()
        
        #expect(isEqual(nodeActionTypes: [.import, .download, .shareLink, .sendToChat, .saveToPhotos]) == true)
    }
    
    @Test
    func testFileLink() {
        actions = NodeActionBuilder()
            .setDisplayMode(.fileLink)
            .setIsFile(true)
            .build()
        
        #expect(isEqual(nodeActionTypes: [.import, .download, .shareLink, .sendToChat]) == true)
    }
    
    @Test
    func testFolderLinkList() {
        actions = NodeActionBuilder()
            .setDisplayMode(.folderLink)
            .setIsFile(false)
            .build()
        
        #expect(isEqual(nodeActionTypes: [.import, .download, .select, .shareLink, .sendToChat, .sort, .thumbnail]) == true)
    }
    
    @Test
    func testFolderLinkThumbnail() {
        actions = NodeActionBuilder()
            .setDisplayMode(.folderLink)
            .setIsFile(false)
            .build()
        
        #expect(isEqual(nodeActionTypes: [.import, .download, .select, .shareLink, .sendToChat, .sort, .thumbnail]) == true)
    }
    
    @Test
    func testFolderLinkMediaDiscovery() {
        actions = NodeActionBuilder()
            .setDisplayMode(.folderLink)
            .setContainsMediaFiles(true)
            .build()
        
        #expect(isEqual(nodeActionTypes: [.import, .download, .select, .shareLink, .sendToChat, .sort, .mediaDiscovery, .thumbnail]) == true)
    }
    
    @Test
    func testFolderLinkChildMediaFile() {
        actions = NodeActionBuilder()
            .setDisplayMode(.nodeInsideFolderLink)
            .setIsFile(true)
            .setIsMediaFile(true)
            .build()
        
        #expect(isEqual(nodeActionTypes: [.import, .download, .saveToPhotos]) == true)
    }
    
    @Test
    func testFolderLinkChildFile() {
        actions = NodeActionBuilder()
            .setDisplayMode(.nodeInsideFolderLink)
            .setIsFile(true)
            .build()
        
        #expect(isEqual(nodeActionTypes: [.import, .download]) == true)
    }
    
    @Test
    func testFileLinkArrayWithPublicLink() {
        actions = NodeActionBuilder()
            .setNodeSelectionType(.files, selectedNodeCount: 2)
            .setLinkedNodeCount(2)
            .multiselectBuild()
        
        #expect(isEqual(nodeActionTypes: [.download, .shareLink, .removeLink, .exportFile, .sendToChat, .move, .copy, .moveToRubbishBin]) == true)
    }
    
    @Test
    func testFolderLinkArrayWithPublicLink() {
        actions = NodeActionBuilder()
            .setNodeSelectionType(.folders, selectedNodeCount: 2)
            .setLinkedNodeCount(2)
            .multiselectBuild()
        
        #expect(isEqual(nodeActionTypes: [.download, .shareLink, .removeLink, .shareFolder, .move, .copy, .moveToRubbishBin]) == true)
    }
    
    @Test
    func testFileAndFolderLinkArrayWithPublicLink() {
        actions = NodeActionBuilder()
            .setNodeSelectionType(.filesAndFolders, selectedNodeCount: 2)
            .setLinkedNodeCount(2)
            .multiselectBuild()
        
        #expect(isEqual(nodeActionTypes: [.download, .shareLink, .removeLink, .move, .copy, .moveToRubbishBin]) == true)
    }
    
    @Test
    func testFileLinkArrayWithoutPublicLink() {
        actions = NodeActionBuilder()
            .setNodeSelectionType(.files, selectedNodeCount: 2)
            .setLinkedNodeCount(0)
            .multiselectBuild()
        
        #expect(isEqual(nodeActionTypes: [.download, .shareLink, .exportFile, .sendToChat, .move, .copy, .moveToRubbishBin]) == true)
    }
    
    @Test
    func testFolderLinkArrayWithoutPublicLink() {
        actions = NodeActionBuilder()
            .setNodeSelectionType(.folders, selectedNodeCount: 2)
            .setLinkedNodeCount(0)
            .multiselectBuild()
        
        #expect(isEqual(nodeActionTypes: [.download, .shareLink, .shareFolder, .move, .copy, .moveToRubbishBin]) == true)
    }
    
    @Test
    func testFileAndFolderLinkArrayWithoutPublicLink() {
        actions = NodeActionBuilder()
            .setNodeSelectionType(.filesAndFolders, selectedNodeCount: 2)
            .setLinkedNodeCount(0)
            .multiselectBuild()
        
        #expect(isEqual(nodeActionTypes: [.download, .shareLink, .move, .copy, .moveToRubbishBin]) == true)
    }
    
    // MARK: - Text Editor
    
    @Test
    func testTextEditorAcessUnknown() {
        actions = NodeActionBuilder()
            .setDisplayMode(.textEditor)
            .setAccessLevel(.accessUnknown)
            .build()
        
        #expect(isEqual(nodeActionTypes: [.download, .import, .exportFile, .sendToChat]) == true)
    }
    
    @Test
    func testTextEditorAcessRead() {
        actions = NodeActionBuilder()
            .setDisplayMode(.textEditor)
            .setAccessLevel(.accessRead)
            .build()
        
        #expect(isEqual(nodeActionTypes: [.download, .import, .exportFile, .sendToChat]) == true)
    }
    
    @Test
    func testTextEditorAcessReadWrite() {
        actions = NodeActionBuilder()
            .setDisplayMode(.textEditor)
            .setAccessLevel(.accessReadWrite)
            .build()
        
        #expect(isEqual(nodeActionTypes: [.editTextFile, .download, .import, .exportFile, .sendToChat]) == true)
    }
    
    @Test
    func testTextEditorAcessFull() {
        actions = NodeActionBuilder()
            .setDisplayMode(.textEditor)
            .setAccessLevel(.accessFull)
            .build()
        
        #expect(isEqual(nodeActionTypes: [.editTextFile, .download, .import, .exportFile, .sendToChat]) == true)
    }
    
    @Test
    func testTextEditorAcessOwner() {
        actions = NodeActionBuilder()
            .setDisplayMode(.textEditor)
            .setAccessLevel(.accessOwner)
            .build()
        
        #expect(isEqual(nodeActionTypes: [.editTextFile, .download, .shareLink, .exportFile, .sendToChat]) == true)
    }
    
    @Test
    func testTextEditor_hasAccessOwnerAndIsHiddenTrueValidAccountType_returnsNodeActions() {
        actions = NodeActionBuilder()
            .setDisplayMode(.textEditor)
            .setAccessLevel(.accessOwner)
            .setIsHiddenNodesFeatureEnabled(true)
            .setHasValidProOrUnexpiredBusinessAccount(true)
            .setIsHidden(true)
            .build()
        
        #expect(isEqual(nodeActionTypes: [.editTextFile, .download, .shareLink, .exportFile, .sendToChat, .unhide]) == true)
    }
    
    @Test
    func testTextEditor_hasAccessOwnerAndIsHiddenFalseValidAccountType_returnsNodeActions() {
        actions = NodeActionBuilder()
            .setDisplayMode(.textEditor)
            .setAccessLevel(.accessOwner)
            .setIsHiddenNodesFeatureEnabled(true)
            .setHasValidProOrUnexpiredBusinessAccount(true)
            .setIsHidden(false)
            .build()
        
        #expect(isEqual(nodeActionTypes: [.editTextFile, .download, .shareLink, .exportFile, .sendToChat, .hide]) == true)
    }
    
    // MARK: - Preview Documents
    
    @Test
    func testDocumentPreviewFileLink() {
        actions = NodeActionBuilder()
            .setDisplayMode(.previewDocument)
            .setIsLink(true)
            .build()
        
        #expect(isEqual(nodeActionTypes: [.import, .download, .shareLink, .sendToChat]) == true)
    }
    
    @Test
    func testDocumentPreviewPdfPageViewLink() {
        actions = NodeActionBuilder()
            .setDisplayMode(.previewPdfPage)
            .setIsPdf(true)
            .setIsLink(true)
            .build()
        
        #expect(isEqual(nodeActionTypes: [.import, .download, .shareLink, .sendToChat, .search, .pdfThumbnailView]) == true)
    }
    
    @Test
    func testDocumentPreviewPdfPageView_isExported_isLink() {
        actions = NodeActionBuilder()
            .setDisplayMode(.previewPdfPage)
            .setIsPdf(true)
            .setIsLink(true)
            .setIsExported(true)
            .build()
        
        #expect(isEqual(nodeActionTypes: [.import, .download, .manageLink, .removeLink, .sendToChat, .search, .pdfThumbnailView]) == true)
    }
    
    @Test
    func testDocumentPreviewPdfPageView_isNotExported_isLink() {
        actions = NodeActionBuilder()
            .setDisplayMode(.previewPdfPage)
            .setIsPdf(true)
            .setIsLink(true)
            .setIsExported(false)
            .build()
        
        #expect(isEqual(nodeActionTypes: [.import, .download, .shareLink, .sendToChat, .search, .pdfThumbnailView]) == true)
    }
    
    @Test
    func testDocumentPreviewPdfPageView_isNotExported_isNotLink() {
        actions = NodeActionBuilder()
            .setDisplayMode(.previewPdfPage)
            .setIsPdf(true)
            .setIsLink(false)
            .setIsExported(false)
            .build()
        
        #expect(isEqual(nodeActionTypes: [.download, .sendToChat, .search, .pdfThumbnailView]) == true)
    }
    
    @Test
    func testDocumentPreviewPdfThumbnail_isExported_isLink() {
        actions = NodeActionBuilder()
            .setDisplayMode(.previewDocument)
            .setIsPdf(true)
            .setIsLink(true)
            .setIsExported(true)
            .build()
        
        #expect(isEqual(nodeActionTypes: [.import, .download, .manageLink, .removeLink, .sendToChat, .search, .pdfPageView]) == true)
    }
    
    @Test
    func testDocumentPreviewPdfThumbnail_isNotExported_isLink() {
        actions = NodeActionBuilder()
            .setDisplayMode(.previewDocument)
            .setIsPdf(true)
            .setIsLink(true)
            .setIsExported(false)
            .build()
        
        #expect(isEqual(nodeActionTypes: [.import, .download, .shareLink, .sendToChat, .search, .pdfPageView]) == true)
    }
    
    @Test
    func testDocumentPreviewPdfThumbnail_isNotExported_isNotLink() {
        actions = NodeActionBuilder()
            .setDisplayMode(.previewDocument)
            .setIsPdf(true)
            .setIsLink(false)
            .setIsExported(false)
            .build()
        
        #expect(isEqual(nodeActionTypes: [.download, .sendToChat, .search, .pdfPageView]) == true)
    }
    
    @Test
    func testDocumentPreviewPdfThumbnailLink() {
        actions = NodeActionBuilder()
            .setDisplayMode(.previewDocument)
            .setIsPdf(true)
            .setIsLink(true)
            .build()
        
        #expect(isEqual(nodeActionTypes: [.import, .download, .shareLink, .sendToChat, .search, .pdfPageView]) == true)
    }
    
    @Test
    func testPreviewDocument() {
        actions = NodeActionBuilder()
            .setDisplayMode(.previewDocument)
            .build()
        
        #expect(isEqual(nodeActionTypes: [.download, .sendToChat]) == true)
    }
    
    @Test
    func testPreviewDocumentOwner() {
        actions = NodeActionBuilder()
            .setDisplayMode(.previewDocument)
            .setAccessLevel(.accessOwner)
            .build()
        
        #expect(isEqual(nodeActionTypes: [.download, .shareLink, .exportFile, .sendToChat]) == true)
    }
    
    @Test
    func testPreviewPdfPageViewDocument() {
        actions = NodeActionBuilder()
            .setDisplayMode(.previewPdfPage)
            .setIsPdf(true)
            .build()
        
        #expect(isEqual(nodeActionTypes: [.download, .sendToChat, .search, .pdfThumbnailView]) == true)
    }
    
    @Test
    func testPreviewPdfPageViewDocumentLink() {
        actions = NodeActionBuilder()
            .setDisplayMode(.previewPdfPage)
            .setIsPdf(true)
            .setIsLink(true)
            .build()
        
        #expect(isEqual(nodeActionTypes: [.import, .download, .shareLink, .sendToChat, .search, .pdfThumbnailView]) == true)
    }
    
    @Test
    func testPreviewPdfPageViewDocumentOwner() {
        actions = NodeActionBuilder()
            .setDisplayMode(.previewPdfPage)
            .setIsPdf(true)
            .setAccessLevel(.accessOwner)
            .build()
        
        #expect(isEqual(nodeActionTypes: [.download, .shareLink, .exportFile, .sendToChat, .search, .pdfThumbnailView]) == true)
    }
    
    @Test
    func testPreviewPdfPageViewDocumentOwner_isExported() {
        actions = NodeActionBuilder()
            .setDisplayMode(.previewPdfPage)
            .setIsPdf(true)
            .setAccessLevel(.accessOwner)
            .setIsExported(true)
            .build()
        #expect(isEqual(nodeActionTypes: [.download, .manageLink, .removeLink, .exportFile, .sendToChat, .search, .pdfThumbnailView]) == true)
    }
    
    @Test
    func testPreviewPdfThumbnailDocument() {
        actions = NodeActionBuilder()
            .setDisplayMode(.previewDocument)
            .setIsPdf(true)
            .build()
        
        #expect(isEqual(nodeActionTypes: [.download, .sendToChat, .search, .pdfPageView]) == true)
    }
    
    @Test
    func testPreviewPdfThumbnailDocumentLink() {
        actions = NodeActionBuilder()
            .setDisplayMode(.previewDocument)
            .setIsPdf(true)
            .setIsLink(true)
            .build()
        
        #expect(isEqual(nodeActionTypes: [.import, .download, .shareLink, .sendToChat, .search, .pdfPageView]) == true)
    }
    
    @Test
    func testPreviewPdfThumbnailDocumentOwner() {
        actions = NodeActionBuilder()
            .setDisplayMode(.previewDocument)
            .setIsPdf(true)
            .setAccessLevel(.accessOwner)
            .build()
        
        #expect(isEqual(nodeActionTypes: [.download, .shareLink, .exportFile, .sendToChat, .search, .pdfPageView]) == true)
    }
    
    @Test
    func testPreviewPdfThumbnailDocumentOwner_isExported() {
        actions = NodeActionBuilder()
            .setDisplayMode(.previewDocument)
            .setIsPdf(true)
            .setAccessLevel(.accessOwner)
            .setIsExported(true)
            .build()
        #expect(isEqual(nodeActionTypes: [.download, .manageLink, .removeLink, .exportFile, .sendToChat, .search, .pdfPageView]) == true)
    }
    
    @Test
    func testPreviewPdf_isHiddenFalse_hiddenAction() {
        actions = NodeActionBuilder()
            .setAccessLevel(.accessOwner)
            .setDisplayMode(.previewDocument)
            .setIsPdf(true)
            .setIsHiddenNodesFeatureEnabled(true)
            .setIsHidden(false)
            .build()
        
        #expect(isEqual(nodeActionTypes: [.download, .shareLink, .exportFile, .sendToChat, .search, .pdfPageView, .hide]) == true)
    }
    
    @Test
    func testPreviewPdf_isHiddenTrueValidAccountType_hiddenAction() {
        actions = NodeActionBuilder()
            .setAccessLevel(.accessOwner)
            .setDisplayMode(.previewDocument)
            .setIsPdf(true)
            .setIsHiddenNodesFeatureEnabled(true)
            .setHasValidProOrUnexpiredBusinessAccount(true)
            .setIsHidden(true)
            .build()
        
        #expect(isEqual(nodeActionTypes: [.download, .shareLink, .exportFile, .sendToChat, .search, .pdfPageView, .unhide]) == true)
    }
    
    @Test
    func testPreviewPdf_isHiddenNil_notContainHideOrUnhide() {
        actions = NodeActionBuilder()
            .setDisplayMode(.previewDocument)
            .setIsPdf(true)
            .setIsHidden(nil)
            .build()
        
        #expect(actions.notContains(where: { $0.type == .hide }) == true,
                      "Actions should not contain hide action")
        #expect(actions.notContains(where: { $0.type == .unhide }) == true,
                      "Actions should not contain unhide action")
    }
    
    // MARK: - Chat tests
    
    @Test
    func testChatSharedMediaFile() {
        actions = NodeActionBuilder()
            .setDisplayMode(.chatSharedFiles)
            .setIsFile(true)
            .setIsMediaFile(true)
            .build()
        
        #expect(isEqual(nodeActionTypes: [.forward, .download, .exportFile, .saveToPhotos, .import]) == true)
    }
    
    @Test
    func testChatSharedMediaFile_accessOwner() {
        actions = NodeActionBuilder()
            .setDisplayMode(.chatSharedFiles)
            .setIsFile(true)
            .setIsMediaFile(true)
            .setAccessLevel(.accessOwner)
            .build()
        
        #expect(isEqual(nodeActionTypes: [.forward, .download, .exportFile, .saveToPhotos]) == true)
    }
    
    @Test
    func testChatSharedFile() {
        actions = NodeActionBuilder()
            .setDisplayMode(.chatSharedFiles)
            .setIsFile(true)
            .setIsMediaFile(false)
            .build()
        
        #expect(isEqual(nodeActionTypes: [.forward, .download, .exportFile, .import]) == true)
    }
    
    @Test
    func testChatSharedFile_accessOwner() {
        actions = NodeActionBuilder()
            .setDisplayMode(.chatSharedFiles)
            .setIsFile(true)
            .setIsMediaFile(false)
            .setAccessLevel(.accessOwner)
            .build()
        
        #expect(isEqual(nodeActionTypes: [.forward, .download, .exportFile]) == true)
    }
    
    @Test
    func testChatAttachmentMediaFile() {
        actions = NodeActionBuilder()
            .setDisplayMode(.chatAttachment)
            .setIsFile(true)
            .setIsMediaFile(true)
            .build()
        
        #expect(isEqual(nodeActionTypes: [.forward, .download, .exportFile, .saveToPhotos, .import]) == true)
    }
    
    @Test
    func testChatAttachmentMediaFile_accessOwner() {
        actions = NodeActionBuilder()
            .setDisplayMode(.chatAttachment)
            .setIsFile(true)
            .setIsMediaFile(true)
            .setAccessLevel(.accessOwner)
            .build()
        
        #expect(isEqual(nodeActionTypes: [.forward, .download, .exportFile, .saveToPhotos]) == true)
    }
    
    @Test
    func testChatAttachmentFile() {
        actions = NodeActionBuilder()
            .setDisplayMode(.chatAttachment)
            .setIsFile(true)
            .setIsMediaFile(false)
            .build()
        
        #expect(isEqual(nodeActionTypes: [.forward, .download, .exportFile, .import]) == true)
    }
    
    @Test
    func testChatAttachmentFile_accessOwner() {
        actions = NodeActionBuilder()
            .setDisplayMode(.chatAttachment)
            .setIsFile(true)
            .setIsMediaFile(false)
            .setAccessLevel(.accessOwner)
            .build()
        
        #expect(isEqual(nodeActionTypes: [.forward, .download, .exportFile]) == true)
    }
    
    // MARK: - Versions tests
    
    @Test
    func testNodeVersionChildMediaFile() {
        actions = NodeActionBuilder()
            .setDisplayMode(.nodeVersions)
            .setAccessLevel(.accessOwner)
            .setIsFile(true)
            .setIsMediaFile(true)
            .setIsChildVersion(true)
            .build()
        
        #expect(isEqual(nodeActionTypes: [.saveToPhotos, .download, .exportFile, .revertVersion, .remove]) == true)
    }
    
    @Test
    func testNodeVersionMediaFile() {
        actions = NodeActionBuilder()
            .setDisplayMode(.nodeVersions)
            .setAccessLevel(.accessOwner)
            .setIsFile(true)
            .setIsMediaFile(true)
            .build()
        
        #expect(isEqual(nodeActionTypes: [.saveToPhotos, .download, .exportFile, .remove]) == true)
    }
    
    @Test
    func testNodeVersionChildFile() {
        actions = NodeActionBuilder()
            .setDisplayMode(.nodeVersions)
            .setAccessLevel(.accessOwner)
            .setIsFile(true)
            .setIsChildVersion(true)
            .build()
        
        #expect(isEqual(nodeActionTypes: [.download, .exportFile, .revertVersion, .remove]) == true)
    }
    
    @Test
    func testBackupNodeVersionChildFile() {
        actions = NodeActionBuilder()
            .setDisplayMode(.nodeVersions)
            .setAccessLevel(.accessOwner)
            .setIsFile(true)
            .setIsChildVersion(true)
            .setIsBackupNode(true)
            .build()
        
        #expect(isEqual(nodeActionTypes: [.download, .exportFile, .copy, .remove]) == true)
    }
    
    @Test
    func testNodeVersionFile() {
        actions = NodeActionBuilder()
            .setDisplayMode(.nodeVersions)
            .setAccessLevel(.accessOwner)
            .setIsFile(true)
            .build()
        
        #expect(isEqual(nodeActionTypes: [.download, .exportFile, .remove]) == true)
    }
    
    @Test
    func testBackupNodeVersionFile() {
        actions = NodeActionBuilder()
            .setDisplayMode(.nodeVersions)
            .setAccessLevel(.accessOwner)
            .setIsFile(true)
            .setIsBackupNode(true)
            .build()
        
        #expect(isEqual(nodeActionTypes: [.download, .exportFile]) == true)
    }
    
    // MARK: - Versions in Incoming Shared Items tests
    
    @Test
    func testNodeVersionFileIncomingFullSharedFolder() {
        actions = NodeActionBuilder()
            .setDisplayMode(.nodeVersions)
            .setAccessLevel(.accessFull)
            .setIsFile(true)
            .setIsChildVersion(true)
            .build()
        
        #expect(isEqual(nodeActionTypes: [.download, .revertVersion, .remove]) == true)
    }
    
    @Test
    func testNodeVersionFileIncomingReadWriteSharedFolder() {
        actions = NodeActionBuilder()
            .setDisplayMode(.nodeVersions)
            .setAccessLevel(.accessReadWrite)
            .setIsFile(true)
            .setIsChildVersion(true)
            .build()
        
        #expect(isEqual(nodeActionTypes: [.download, .revertVersion]) == true)
    }
    
    @Test
    func testNodeVersionFileIncomingReadOnlySharedFolder() {
        actions = NodeActionBuilder()
            .setDisplayMode(.nodeVersions)
            .setAccessLevel(.accessRead)
            .setIsFile(true)
            .setIsChildVersion(true)
            .build()
        
        #expect(isEqual(nodeActionTypes: [.download]) == true)
    }
    
    @Test
    func testMultiselectFiles_noLinkedNodes() {
        actions = NodeActionBuilder()
            .setNodeSelectionType(.files, selectedNodeCount: 2)
            .multiselectBuild()
        
        #expect(isEqual(nodeActionTypes: [.download, .shareLink, .exportFile, .sendToChat, .move, .copy, .moveToRubbishBin]) == true)
    }
    
    @Test
    func testMultiselectFiles_allLinkedNodes() {
        actions = NodeActionBuilder()
            .setNodeSelectionType(.files, selectedNodeCount: 2)
            .setLinkedNodeCount(2)
            .setIsAllLinkedNode(true)
            .multiselectBuild()
        
        #expect(isEqual(nodeActionTypes: [.download, .manageLink, .removeLink, .exportFile, .sendToChat, .move, .copy, .moveToRubbishBin]) == true)
    }
    
    @Test
    func testMultiselectFiles_withSomeLinkedNodes() {
        actions = NodeActionBuilder()
            .setNodeSelectionType(.files, selectedNodeCount: 2)
            .setLinkedNodeCount(2)
            .setIsAllLinkedNode(false)
            .multiselectBuild()
        
        #expect(isEqual(nodeActionTypes: [.download, .shareLink, .removeLink, .exportFile, .sendToChat, .move, .copy, .moveToRubbishBin]) == true)
    }
    
    @Test
    func testMultiselectFolders_noLinkedNodes() {
        actions = NodeActionBuilder()
            .setNodeSelectionType(.folders, selectedNodeCount: 2)
            .multiselectBuild()
        
        #expect(isEqual(nodeActionTypes: [.download, .shareLink, .shareFolder, .move, .copy, .moveToRubbishBin]) == true)
    }
    
    @Test
    func testMultiselectFolders_allLinkedNodes() {
        actions = NodeActionBuilder()
            .setNodeSelectionType(.folders, selectedNodeCount: 2)
            .setLinkedNodeCount(2)
            .setIsAllLinkedNode(true)
            .multiselectBuild()
        
        #expect(isEqual(nodeActionTypes: [.download, .manageLink, .removeLink, .shareFolder, .move, .copy, .moveToRubbishBin]) == true)
    }
    
    @Test
    func testMultiselectFolders_withSomeLinkedNodes() {
        actions = NodeActionBuilder()
            .setNodeSelectionType(.folders, selectedNodeCount: 2)
            .setLinkedNodeCount(2)
            .setIsAllLinkedNode(false)
            .multiselectBuild()
        
        #expect(isEqual(nodeActionTypes: [.download, .shareLink, .removeLink, .shareFolder, .move, .copy, .moveToRubbishBin]) == true)
    }
    
    @Test
    func testMultiselectFilesAndFolders_noLinkedNodes() {
        actions = NodeActionBuilder()
            .setNodeSelectionType(.filesAndFolders, selectedNodeCount: 2)
            .multiselectBuild()
        
        #expect(isEqual(nodeActionTypes: [.download, .shareLink, .move, .copy, .moveToRubbishBin]) == true)
    }
    
    @Test
    func testMultiselectFilesAndFolders_allLinkedNodes() {
        actions = NodeActionBuilder()
            .setNodeSelectionType(.filesAndFolders, selectedNodeCount: 2)
            .setLinkedNodeCount(2)
            .setIsAllLinkedNode(true)
            .multiselectBuild()
        
        #expect(isEqual(nodeActionTypes: [.download, .manageLink, .removeLink, .move, .copy, .moveToRubbishBin]) == true)
    }
    
    @Test
    func testMultiselectFilesAndFolders_withSomeLinkedNodes() {
        actions = NodeActionBuilder()
            .setNodeSelectionType(.filesAndFolders, selectedNodeCount: 2)
            .setLinkedNodeCount(2)
            .setIsAllLinkedNode(false)
            .multiselectBuild()
        
        #expect(isEqual(nodeActionTypes: [.download, .shareLink, .removeLink, .move, .copy, .moveToRubbishBin]) == true)
    }
    
    @Test
    func testMultiselectMediaFiles() {
        actions = NodeActionBuilder()
            .setNodeSelectionType(.files, selectedNodeCount: 4)
            .setAreMediaFiles(true)
            .multiselectBuild()
        
        #expect(isEqual(nodeActionTypes: [.download, .shareLink, .exportFile, .sendToChat, .saveToPhotos, .move, .copy, .moveToRubbishBin]) == true)
    }
    
    @Test
    func testMultiselectMediaFiles_photosFavouriteAlbum_shouldReturnCorrrectActions() {
        actions = NodeActionBuilder()
            .setNodeSelectionType(.files, selectedNodeCount: 4)
            .setIsFavourite(true)
            .setAreMediaFiles(true)
            .setDisplayMode(.photosFavouriteAlbum)
            .multiselectBuild()
        
        #expect(isEqual(nodeActionTypes: [.favourite, .download, .shareLink, .exportFile, .sendToChat]) == true)
    }
    
    @Test
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
            
            #expect(isEqual(nodeActionTypes: expectedActionTypes) == true,
                          "NodeActions invalid for isHidden: \(String(describing: isHidden))")
        }
    }
    
    @Test
    func testMultiselectMediaFiles_MediaDiscovery() {
        actions = NodeActionBuilder()
            .setNodeSelectionType(.files, selectedNodeCount: 4)
            .setAreMediaFiles(true)
            .setDisplayMode(.mediaDiscovery)
            .multiselectBuild()
        
        #expect(isEqual(nodeActionTypes: [.download, .shareLink, .exportFile, .sendToChat, .saveToPhotos, .move, .copy, .moveToRubbishBin]) == true)
    }
    
    @Test
    func testExportedNodeActions_nodeExported() {
        actions = NodeActionBuilder()
            .setDisplayMode(.cloudDrive)
            .setAccessLevel(.accessOwner)
            .setIsExported(true)
            .build()
        
        #expect(isEqual(nodeActionTypes: [.info, .favourite, .label, .download, .manageLink, .removeLink, .shareFolder, .rename, .move, .copy, .moveToRubbishBin]) == true)
    }
    
    @Test
    func testExportedNodeActions_nodeNotExported() {
        actions = NodeActionBuilder()
            .setDisplayMode(.cloudDrive)
            .setAccessLevel(.accessOwner)
            .build()
        
        #expect(isEqual(nodeActionTypes: [.info, .favourite, .label, .download, .shareLink, .shareFolder, .rename, .move, .copy, .moveToRubbishBin]) == true)
    }
    
    @Test
    func testAlbumLink() {
        actions = NodeActionBuilder()
            .setDisplayMode(.albumLink)
            .setAccessLevel(.accessRead)
            .build()
        
        #expect(isEqual(nodeActionTypes: [.saveToPhotos]) == true)
    }
    
    @Test
    func testMultiselectBuild_cloudDriveContainsHiddenFolderForFolderDisplayMode_shouldReturnCorrectActions() {
        actions = NodeActionBuilder()
            .setNodeSelectionType(.folders, selectedNodeCount: 4)
            .setDisplayMode(.cloudDrive)
            .setIsHiddenNodesFeatureEnabled(true)
            .setIsHidden(false)
            .multiselectBuild()
        
        #expect(isEqual(nodeActionTypes: [.download, .shareLink, .shareFolder, .hide, .move, .copy, .moveToRubbishBin]) == true)
    }
    
    @Test
    func testMultiselectBuild_cloudDriveContainsHiddenFileForFileDisplayModeValidAccountType_shouldReturnCorrectActions() {
        actions = NodeActionBuilder()
            .setNodeSelectionType(.files, selectedNodeCount: 4)
            .setDisplayMode(.cloudDrive)
            .setIsHiddenNodesFeatureEnabled(true)
            .setHasValidProOrUnexpiredBusinessAccount(true)
            .setIsHidden(false)
            .multiselectBuild()
        
        #expect(isEqual(nodeActionTypes: [.download, .shareLink, .exportFile, .sendToChat, .hide, .move, .copy, .moveToRubbishBin]) == true)
    }
    
    @Test
    func testMultiselectBuild_cloudDriveContainsHiddenFileOrFolderForFileAndFolderDisplayMode_shouldReturnCorrectActions() {
        actions = NodeActionBuilder()
            .setAccessLevel(.accessOwner)
            .setNodeSelectionType(.filesAndFolders, selectedNodeCount: 4)
            .setDisplayMode(.cloudDrive)
            .setIsHiddenNodesFeatureEnabled(true)
            .setHasValidProOrUnexpiredBusinessAccount(true)
            .setIsHidden(false)
            .multiselectBuild()
        
        #expect(isEqual(nodeActionTypes: [.download, .shareLink, .hide, .move, .copy, .moveToRubbishBin]) == true)
    }
    
    @Test
    func testMultiselectBuild_cloudDriveForDisplayModesHiddenValueNilValidAccountType_shouldNotContainHideAction() {
        [NodeSelectionType.folders, .files, .filesAndFolders].forEach {
            actions = NodeActionBuilder()
                .setNodeSelectionType($0, selectedNodeCount: 4)
                .setDisplayMode(.cloudDrive)
                .setIsHiddenNodesFeatureEnabled(true)
                .setHasValidProOrUnexpiredBusinessAccount(true)
                .setIsHidden(nil)
                .multiselectBuild()
            
            #expect(actions.notContains(where: { $0.type == .hide }) == true)
        }
    }
    
    @Test
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
        
        #expect(isEqual(nodeActionTypes: [.download, .shareLink, .shareFolder, .unhide, .move, .copy, .moveToRubbishBin]) == true)
    }
    
    @Test
    func testMultiselectBuild_cloudDriveFileDisplayModeHideTrueWithValidAccountType_shouldReturnCorrectActions() {
        actions = NodeActionBuilder()
            .setAccessLevel(.accessOwner)
            .setNodeSelectionType(.files, selectedNodeCount: 4)
            .setDisplayMode(.cloudDrive)
            .setIsHiddenNodesFeatureEnabled(true)
            .setHasValidProOrUnexpiredBusinessAccount(true)
            .setIsHidden(true)
            .multiselectBuild()
        
        #expect(isEqual(nodeActionTypes: [.download, .shareLink, .exportFile, .sendToChat, .unhide, .move, .copy, .moveToRubbishBin]) == true)
    }
    
    @Test
    func testMultiselectBuild_cloudDriveFileAndFolderDisplayModeHiddenTrueValidAccountType_shouldReturnCorrectActions() {
        actions = NodeActionBuilder()
            .setAccessLevel(.accessOwner)
            .setNodeSelectionType(.filesAndFolders, selectedNodeCount: 4)
            .setDisplayMode(.cloudDrive)
            .setIsHiddenNodesFeatureEnabled(true)
            .setHasValidProOrUnexpiredBusinessAccount(true)
            .setIsHidden(true)
            .multiselectBuild()
        
        #expect(isEqual(nodeActionTypes: [.download, .shareLink, .unhide, .move, .copy, .moveToRubbishBin]) == true)
    }
    
    @Test
    func testMultiselectBuild_hiddenNodesFeatureFlagOff_shouldNotReturnHiddenAction() {
        actions = NodeActionBuilder()
            .setAccessLevel(.accessOwner)
            .setNodeSelectionType(.filesAndFolders, selectedNodeCount: 4)
            .setDisplayMode(.cloudDrive)
            .setIsHiddenNodesFeatureEnabled(false)
            .setHasValidProOrUnexpiredBusinessAccount(true)
            .setIsHidden(true)
            .multiselectBuild()
        
        #expect(actions.notContains(where: { $0.type == .hide }) == true)
    }
    
    @Test
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
            
            #expect(actions.contains(where: { $0.type == .hide }) == true, "Should contain hide action for hidden \(isHidden)")
        }
    }
    
    @Test
    func testMultiselectBuild_hiddenNodesFeatureFlagOnNotValidProAccountHiddenNotSet_shouldNotReturnHiddenAction() {
        actions = NodeActionBuilder()
            .setAccessLevel(.accessOwner)
            .setNodeSelectionType(.filesAndFolders, selectedNodeCount: 4)
            .setDisplayMode(.cloudDrive)
            .setIsHiddenNodesFeatureEnabled(true)
            .setHasValidProOrUnexpiredBusinessAccount(false)
            .setIsHidden(nil)
            .multiselectBuild()
        
        #expect(actions.notContains(where: { $0.type == .hide }) == true)
    }
    
    // MARK: - videoPlaylistContent
    
    @Test
    func testBuild_displayModeVideoPlaylistContent_shouldReturnCorrectActions() {
        actions = NodeActionBuilder()
            .setDisplayMode(.videoPlaylistContent)
            .build()
        
        #expect(isEqual(nodeActionTypes: [
            .shareLink,
            .saveToPhotos,
            .removeVideoFromVideoPlaylist,
            .sendToChat,
            .exportFile,
            .moveVideoInVideoPlaylistContentToRubbishBin]) == true)
    }
    
    @Test
    func testBuild_displayModeVideoPlaylistContentAndSetIsHiddenTrue_shouldReturnCorrectActions() {
        actions = NodeActionBuilder()
            .setDisplayMode(.videoPlaylistContent)
            .setIsHiddenNodesFeatureEnabled(true)
            .setHasValidProOrUnexpiredBusinessAccount(true)
            .setIsHidden(true)
            .build()
        
        #expect(isEqual(nodeActionTypes: [
            .shareLink,
            .saveToPhotos,
            .removeVideoFromVideoPlaylist,
            .sendToChat,
            .exportFile,
            .unhide,
            .moveVideoInVideoPlaylistContentToRubbishBin
        ]) == true)
    }
    
    @Test
    func testBuild_displayModeVideoPlaylistContentAndSetIsHiddenFalse_shouldReturnCorrectActions() {
        actions = NodeActionBuilder()
            .setDisplayMode(.videoPlaylistContent)
            .setIsHiddenNodesFeatureEnabled(true)
            .setHasValidProOrUnexpiredBusinessAccount(true)
            .setIsHidden(false)
            .build()
        
        #expect(isEqual(nodeActionTypes: [
            .shareLink,
            .saveToPhotos,
            .removeVideoFromVideoPlaylist,
            .sendToChat,
            .exportFile,
            .hide,
            .moveVideoInVideoPlaylistContentToRubbishBin
        ]) == true)
    }
    
    @Test
    func testMultiselectBuild_displayModeVideoPlaylistContent_shouldReturnCorrectActions() {
        actions = NodeActionBuilder()
            .setDisplayMode(.videoPlaylistContent)
            .multiselectBuild()
        
        #expect(isEqual(nodeActionTypes: [
            .shareLink,
            .saveToPhotos,
            .removeVideoFromVideoPlaylist,
            .sendToChat,
            .exportFile,
            .moveVideoInVideoPlaylistContentToRubbishBin]) == true)
    }
}
