@testable import MEGA
import MEGADomain
import MEGADomainMock
import MEGAPresentation
import MEGAPresentationMock
import MEGASDKRepoMock
import MEGATest
import XCTest

extension NodeActionsDelegateHandler {
    /// used by harness, creates a instance that then each test can override wit a specific closure
    /// to intercept arguments passed in without need of creating this with all but one empty closure each time
    static var testingInstance: Self {
        .init(
            download: {_  in },
            browserAction: { _, _ in },
            moveToRubbishBin: { _ in },
            exportFiles: { _, _ in },
            shareFolders: { _ in },
            shareOrManageLink: { _ in },
            sendToChat: { _ in },
            removeLink: { _ in },
            removeFromRubbishBin: { _ in },
            saveToPhotos: { _ in },
            showNodeInfo: { _ in },
            toggleNodeFavourite: { _ in },
            assignLabel: { _ in },
            leaveSharing: { _ in },
            rename: { _, _ in },
            removeSharing: { _ in },
            viewVersions: { _ in },
            restore: { _ in },
            manageShare: { _ in },
            shareFolder: { _ in },
            editTextFile: { _ in },
            disputeTakedown: { _ in },
            hide: { _ in },
            unhide: { _ in },
            toggleEditMode: { _ in }
        )
    }
}

final class CloudDriveBottomToolbarItemsFactoryTests: XCTestCase {
    class Harness {
        class MockToolbarActionFactory: ToolbarActionFactoryProtocol {
            var receivedAccessType: NodeAccessTypeEntity?
            var receivedIsBackupNode: Bool?
            var receivedDisplayMode: DisplayMode?
            var actionsToReturn: [BottomToolbarAction] = []
            
            func buildActions(
                accessType: NodeAccessTypeEntity,
                isBackupNode: Bool,
                displayMode: DisplayMode
            ) -> [BottomToolbarAction] {
                receivedAccessType = accessType
                receivedIsBackupNode = isBackupNode
                receivedDisplayMode = displayMode
                return actionsToReturn
            }
        }
        class MockNodeAccessoryActionDelegate: NodeAccessoryActionDelegate {
            nonisolated init() {}
        }

        let sut: CloudDriveBottomToolbarItemsFactory
        let actionFactory = MockToolbarActionFactory()
        let actionHandler: NodeActionsDelegateHandler
        let nodeUseCase: any NodeUseCaseProtocol
        let parent = UIViewController()

        init(
            actionHandler: NodeActionsDelegateHandler = .testingInstance,
            nodeUseCase: some NodeUseCaseProtocol = MockNodeDataUseCase()
        ) {
            self.actionHandler = actionHandler
            self.nodeUseCase = nodeUseCase
            sut = CloudDriveBottomToolbarItemsFactory(
                sdk: MockSdk(),
                nodeActionHandler: actionHandler,
                actionFactory: actionFactory,
                nodeUseCase: nodeUseCase,
                nodeAccessoryActionDelegate: MockNodeAccessoryActionDelegate()
            )
        }
        
        func build(
            accessType: NodeAccessTypeEntity,
            displayMode: DisplayMode,
            isBackupNode: Bool,
            selectedNodes: [NodeEntity]
        ) -> [UIBarButtonItem] {
            sut.buildToolbarItems(
                config: .init(
                    accessType: accessType,
                    displayMode: displayMode,
                    isBackupNode: isBackupNode,
                    selectedNodes: selectedNodes,
                    isIncomingShareChildView: false,
                    onActionCompleted: { _ in }
                ),
                parent: parent,
                browseDelegate: BrowserViewControllerDelegateHandler()
            )
        }
        
        func buildOwnerCloudDrive() -> [UIBarButtonItem] {
            build(accessType: .owner, displayMode: .cloudDrive, isBackupNode: false, selectedNodes: [])
        }
        
        func buildOwnerBackups() -> [UIBarButtonItem] {
            build(accessType: .owner, displayMode: .backup, isBackupNode: true, selectedNodes: [])
        }
        
        func buildOwnerRubbishBin() -> [UIBarButtonItem] {
            build(accessType: .owner, displayMode: .rubbishBin, isBackupNode: false, selectedNodes: [])
        }
        
        func buildAnyWithSelectedNodes() -> [UIBarButtonItem] {
            return build(accessType: .full, displayMode: .cloudDrive, isBackupNode: false, selectedNodes: selectedNodes)
        }
        
        func buildAny(with selectedNodes: [NodeEntity]) -> [UIBarButtonItem] {
            build(accessType: .full, displayMode: .cloudDrive, isBackupNode: false, selectedNodes: selectedNodes)
        }
        
        var selectedNodes: [NodeEntity] {
            return [NodeEntity(handle: 1)]
        }
        
        func triggerFirstAction() throws {
            try XCTUnwrap(buildAnyWithSelectedNodes().first).triggerPrimaryAction()
        }
      }
    
    func testCloudDriveActions_requestsCorrectButtonFromFactory() {
        let harness = Harness()
        _ = harness.buildOwnerCloudDrive()
        XCTAssertEqual(harness.actionFactory.receivedAccessType, .owner)
        XCTAssertEqual(harness.actionFactory.receivedIsBackupNode, false)
        XCTAssertEqual(harness.actionFactory.receivedDisplayMode, .cloudDrive)
    }
    
    func testRubbishBinActions_requestsCorrectButtonFromFactory() {
        let harness = Harness()
        _ = harness.buildOwnerRubbishBin()
        XCTAssertEqual(harness.actionFactory.receivedAccessType, .owner)
        XCTAssertEqual(harness.actionFactory.receivedIsBackupNode, false)
        XCTAssertEqual(harness.actionFactory.receivedDisplayMode, .rubbishBin)
    }
    
    func testBackupsActions_requestsCorrectButtonFromFactory() {
        let harness = Harness()
        _ = harness.buildOwnerBackups()
        XCTAssertEqual(harness.actionFactory.receivedAccessType, .owner)
        XCTAssertEqual(harness.actionFactory.receivedIsBackupNode, true)
        XCTAssertEqual(harness.actionFactory.receivedDisplayMode, .backup)
    }
    
    func testDownloadAction_whenTriggered_CallsCorrectNodeActionClosure() throws {
        let harness = Harness()
        var downloadCalled = false
        var passedInNodes = [NodeEntity]()
        let exp = expectation(description: "action tapped")
        harness.actionHandler.download = { nodes in
            downloadCalled = true
            passedInNodes = nodes
            exp.fulfill()
        }
        harness.actionFactory.actionsToReturn = [.download]
        try harness.triggerFirstAction()
        wait(for: [exp], timeout: 1)
        XCTAssertTrue(downloadCalled)
        XCTAssertEqual(passedInNodes, harness.selectedNodes)
    }
    
    func testShareLinkAction_whenTriggered_CallsCorrectNodeActionClosure() throws {
        let harness = Harness()
        var shareOrManageLinkCalled = false
        var passedInNodes = [NodeEntity]()
        let exp = expectation(description: "action tapped")
        harness.actionHandler.shareOrManageLink = { nodes in
            shareOrManageLinkCalled = true
            passedInNodes = nodes
            exp.fulfill()
        }
        harness.actionFactory.actionsToReturn = [.shareLink]
        try harness.triggerFirstAction()
        wait(for: [exp], timeout: 1)
        XCTAssertTrue(shareOrManageLinkCalled)
        XCTAssertEqual(passedInNodes, harness.selectedNodes)
    }
    
    func testMoveAction_whenTriggered_CallsCorrectNodeActionClosure() throws {
        let harness = Harness()
        var browserAction: BrowserActionEntity?
        var passedInNodes = [NodeEntity]()
        let exp = expectation(description: "action tapped")
        harness.actionHandler.browserAction = { action, nodes in
            browserAction = action
            passedInNodes = nodes
            exp.fulfill()
        }
        harness.actionFactory.actionsToReturn = [.move]
        try harness.triggerFirstAction()
        wait(for: [exp], timeout: 1)
        XCTAssertEqual(browserAction, .move)
        XCTAssertEqual(passedInNodes, harness.selectedNodes)
    }
    
    func testCopyAction_whenTriggered_CallsCorrectNodeActionClosure() throws {
        let harness = Harness()
        var browserAction: BrowserActionEntity?
        var passedInNodes = [NodeEntity]()
        let exp = expectation(description: "action tapped")
        harness.actionHandler.browserAction = { action, nodes in
            browserAction = action
            passedInNodes = nodes
            exp.fulfill()
        }
        harness.actionFactory.actionsToReturn = [.copy]
        try harness.triggerFirstAction()
        wait(for: [exp], timeout: 1)
        XCTAssertEqual(browserAction, .copy)
        XCTAssertEqual(passedInNodes, harness.selectedNodes)
    }
    
    func testRestoreAction_whenTriggered_CallsCorrectNodeActionClosure() throws {
        let harness = Harness()
        var restoreCalled = false
        var passedInNodes = [NodeEntity]()
        let exp = expectation(description: "action tapped")
        harness.actionHandler.restore = { nodes in
            restoreCalled = true
            passedInNodes = nodes
            exp.fulfill()
        }
        harness.actionFactory.actionsToReturn = [.restore]
        try harness.triggerFirstAction()
        wait(for: [exp], timeout: 1)
        XCTAssertTrue(restoreCalled)
        XCTAssertEqual(passedInNodes, harness.selectedNodes)
    }
    
    func testDeleteAction_whenTriggered_CallsRemoveFromRubbishBinIfInRubbishBin() throws {
        let harness = Harness()
        var removeFromRubbishBinCalled = false
        var passedInNodes = [NodeEntity]()
        let exp = expectation(description: "action tapped")
        harness.actionHandler.removeFromRubbishBin = { nodes in
            removeFromRubbishBinCalled = true
            passedInNodes = nodes
            exp.fulfill()
        }
        harness.actionFactory.actionsToReturn = [.delete]
        let allItems = harness.build(
            accessType: .full,
            displayMode: .rubbishBin,
            isBackupNode: false,
            selectedNodes: harness.selectedNodes
        )
        let restore = try XCTUnwrap(allItems.first)
        try restore.triggerPrimaryAction()
        wait(for: [exp], timeout: 1)
        XCTAssertTrue(removeFromRubbishBinCalled)
        XCTAssertEqual(passedInNodes, harness.selectedNodes)
    }
    
    func testDeleteAction_whenTriggered_CallsMoveToRubbishBinCalledIfInCloudDrive() throws {
        let harness = Harness()
        var moveToRubbishBinCalled = false
        var passedInNodes = [NodeEntity]()
        let exp = expectation(description: "action tapped")
        harness.actionHandler.moveToRubbishBin = { nodes in
            moveToRubbishBinCalled = true
            passedInNodes = nodes
            exp.fulfill()
        }
        harness.actionFactory.actionsToReturn = [.delete]
        let allItems = harness.build(
            accessType: .full,
            displayMode: .cloudDrive,
            isBackupNode: false,
            selectedNodes: harness.selectedNodes
        )
        let restore = try XCTUnwrap(allItems.first)
        try restore.triggerPrimaryAction()
        wait(for: [exp], timeout: 1)
        XCTAssertTrue(moveToRubbishBinCalled)
        XCTAssertEqual(passedInNodes, harness.selectedNodes)
    }
    
    func testBarButtonItem_whenSelectedNodesIsEmpty_itShouldBeDisabled() {
        // given
        let harness = Harness()
        harness.actionFactory.actionsToReturn = [
            .download, .shareLink, .move, .copy, .delete, .restore, .actions
        ]
        let selectedNodes: [NodeEntity] = []
        
        // when
        let items = harness.buildAny(with: selectedNodes)
        
        // then
        XCTAssertEqual(
            items.map { $0.isEnabled },
            [
                false, // download
                false, // shareLink
                false, // move
                false, // copy
                false, // delete
                false, // restore
                false // actions
            ]
        )
    }
    
    func testBarButton_whenSelectedNodesContainDisputedNode_itShouldBeDisabled() {
        // given
        let harness = Harness()
        harness.actionFactory.actionsToReturn = [
            .download, .shareLink, .move, .copy, .delete, .restore, .actions
        ]
        let selectedNodes: [NodeEntity] = [
            NodeEntity(isTakenDown: false),
            NodeEntity(isTakenDown: true)
        ]
        
        // when
        let items = harness.buildAny(with: selectedNodes)
        
        // then
        XCTAssertEqual(
            items.map { $0.isEnabled },
            [
                false, // download
                false, // shareLink
                false, // move
                false, // copy
                true, // delete
                false, // restore
                true // actions
            ]
        )
    }
    
    func testBarButton_whenSelectedNodesAreNotDisputed_itShouldBeEnabled() {
        // given
        let harness = Harness()
        harness.actionFactory.actionsToReturn = [
            .download, .shareLink, .move, .copy, .delete, .restore, .actions
        ]
        let selectedNodes: [NodeEntity] = [
            NodeEntity(isTakenDown: false),
            NodeEntity(isTakenDown: false)
        ]
        
        // when
        let items = harness.buildAny(with: selectedNodes)
        
        // then
        XCTAssertEqual(
            items.map { $0.isEnabled },
            [
                true, // download
                true, // shareLink
                true, // move
                true, // copy
                true, // delete
                true, // restore
                true // actions
            ]
        )
    }
    
    func testBarButton_whenDisplayModeIsRubbishBin_andNodeIsNotDisputedButNotRestorable_itShouldBeDisable() throws {
        // given
        let harness = Harness(
            nodeUseCase: MockNodeDataUseCase(isNodeRestorable: false)
        )
        harness.actionFactory.actionsToReturn = [.restore]
        
        let selectedNodes: [NodeEntity] = [
            NodeEntity(isTakenDown: false)
        ]
        
        // when
        let items = harness.build(accessType: .owner, displayMode: .rubbishBin, isBackupNode: false, selectedNodes: selectedNodes)
        
        // then
        XCTAssertEqual(items.count, 1)
        let item = try XCTUnwrap(items.first)
        XCTAssertFalse(item.isEnabled)
    }
    
    func testBarButton_whenDisplayModeIsRubbishBin_andNodeIsNotDisputedAndIsRestorable_itShouldBeEnabled() throws {
        // given
        let harness = Harness(
            nodeUseCase: MockNodeDataUseCase(isNodeRestorable: true)
        )
        harness.actionFactory.actionsToReturn = [.restore]
        
        let selectedNodes: [NodeEntity] = [
            NodeEntity(isTakenDown: false)
        ]
        
        // when
        let items = harness.build(accessType: .owner, displayMode: .rubbishBin, isBackupNode: false, selectedNodes: selectedNodes)
        
        // then
        XCTAssertEqual(items.count, 1)
        let item = try XCTUnwrap(items.first)
        XCTAssertTrue(item.isEnabled)
    }
}

extension UIAction {
    // unit-test-only way of triggering a primary action of the UIBarButtonItem
    var handler: UIActionHandler {
        typealias ActionHandlerBlock = @convention(block) (UIAction) -> Void
        let handler = value(forKey: "handler") as AnyObject
        return unsafeBitCast(handler, to: ActionHandlerBlock.self)
    }
}

extension UIBarButtonItem {
    func triggerPrimaryAction() throws {
        let action = try XCTUnwrap(self.primaryAction)
        action.handler(action)
    }
}
