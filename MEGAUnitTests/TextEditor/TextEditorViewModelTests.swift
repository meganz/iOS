@testable import MEGA
import MEGAAnalyticsiOS
import MEGAAppPresentationMock
import MEGAAppSDKRepoMock
import MEGAAssets
import MEGADomain
import MEGADomainMock
import MEGAL10n
import XCTest

final class TextEditorViewModelTests: XCTestCase {
    
    @MainActor func testAction_setUpView_View_Create_Edit() {
        let textFile = TextFile(fileName: "testAction_setUpView_View_Create_Edit")
        let mockRouter = MockTextEditorViewRouter()
        let mockUploadFileUC = MockUploadFileUseCase()
        let mockDownloadNodeUC = MockDownloadNodeUseCase()
        let mockBackupsUC = MockBackupsUseCase()
        
        let nodeAccessLevel: NodeAccessTypeEntity = .owner
        let mockNodeDataUC = MockNodeDataUseCase(nodeAccessLevelVariable: nodeAccessLevel)
        
        var textEditorModel: TextEditorModel
        var navbarItemsModel: TextEditorNavbarItemsModel
        
        let testModes: [TextEditorMode] = [.view, .create, .edit]
        for textEditorMode in testModes {
            if textEditorMode == .view {
                textEditorModel = TextEditorModel(
                    textFile: textFile,
                    textEditorMode: textEditorMode,
                    accessLevel: nodeAccessLevel,
                    resumeReadingOffset: nil
                )
            } else {
                textEditorModel = TextEditorModel(
                    textFile: textFile,
                    textEditorMode: textEditorMode,
                    accessLevel: nil,
                    resumeReadingOffset: nil
                )
            }
            
            if textEditorMode == .view {
                navbarItemsModel = TextEditorNavbarItemsModel(
                    leftItem: NavbarItemModel(title: Strings.Localizable.close, image: nil),
                    rightItem: NavbarItemModel(title: nil, image: MEGAAssets.UIImage.moreNavigationBar),
                    textEditorMode: textEditorMode
                )
            } else {
                navbarItemsModel = TextEditorNavbarItemsModel(
                    leftItem: NavbarItemModel(title: Strings.Localizable.cancel, image: nil),
                    rightItem: NavbarItemModel(title: Strings.Localizable.save, image: nil),
                    textEditorMode: textEditorMode
                )
            }
            
            let viewModel = TextEditorViewModel(
                router: mockRouter,
                textFile: textFile,
                textEditorMode: textEditorMode,
                uploadFileUseCase: mockUploadFileUC,
                downloadNodeUseCase: mockDownloadNodeUC,
                nodeUseCase: mockNodeDataUC,
                backupsUseCase: mockBackupsUC,
                networkMonitorUseCase: MockNetworkMonitorUseCase(),
                resumeTextPositionUseCase: MockResumeTextPositionUseCase()
            )
            test(viewModel: viewModel,
                 action: .setUpView,
                 expectedCommands: [
                    .configView(textEditorModel, shallUpdateContent: true, isInRubbishBin: false, isBackupNode: false),
                    .setupNavbarItems(navbarItemsModel)
                 ]
            )
        }
    }
    
    @MainActor func testAction_setUpView_Load_tempDownload_success_read_success() {
        let textFile = TextFile(fileName: "testAction_setUpView_Load_tempDownload_success_read_success")
        let mockRouter = MockTextEditorViewRouter()
        let mockUploadFileUC = MockUploadFileUseCase()
        
        let testPath = (NSTemporaryDirectory() as NSString).appendingPathComponent(textFile.fileName)
        let transferEntity = mockTransferEntity(transferTypeEntity: .download, path: testPath)
        let mockDownloadNodeUC = MockDownloadNodeUseCase(transferEntity: transferEntity, result: .success(transferEntity))
        
        let mockBackupsUC = MockBackupsUseCase()
        let nodeAccessLevel: NodeAccessTypeEntity = .owner
        let mockNodeDataUC = MockNodeDataUseCase(nodeAccessLevelVariable: nodeAccessLevel)
        
        let textEditorMode: TextEditorMode = .load
        
        let textEditorLoadModel = TextEditorModel(
            textFile: textFile,
            textEditorMode: textEditorMode,
            accessLevel: nil,
            resumeReadingOffset: nil
        )
        
        let navbarItemsLoadModel = TextEditorNavbarItemsModel(
            leftItem: NavbarItemModel(title: Strings.Localizable.close, image: nil),
            rightItem: nil,
            textEditorMode: textEditorMode
        )
        
        let textEditorViewModel = TextEditorModel(
            textFile: textFile,
            textEditorMode: .view,
            accessLevel: nodeAccessLevel,
            resumeReadingOffset: nil
        )
        
        let navbarItemsViewModel = TextEditorNavbarItemsModel(
            leftItem: NavbarItemModel(title: Strings.Localizable.close, image: nil),
            rightItem: NavbarItemModel(title: nil, image: MEGAAssets.UIImage.moreNavigationBar),
            textEditorMode: .view
        )
        
        let mockNode = NodeEntity(handle: 123, isFile: true)
        let tracker = MockTracker()
        
        let viewModel = TextEditorViewModel(
            router: mockRouter,
            textFile: textFile,
            textEditorMode: textEditorMode,
            uploadFileUseCase: mockUploadFileUC,
            downloadNodeUseCase: mockDownloadNodeUC,
            nodeUseCase: mockNodeDataUC,
            backupsUseCase: mockBackupsUC,
            networkMonitorUseCase: MockNetworkMonitorUseCase(),
            resumeTextPositionUseCase: MockResumeTextPositionUseCase(),
            nodeEntity: mockNode,
            tracker: tracker
        )
        
        let percentage = Float(transferEntity.transferredBytes) / Float(transferEntity.totalBytes)
        
        let content = "test"
        do {
            try content.write(toFile: testPath, atomically: true, encoding: .utf8)
            
            test(viewModel: viewModel,
                 action: .setUpView,
                 expectedCommands: [
                    .setupLoadViews,
                    .configView(textEditorLoadModel, shallUpdateContent: false, isInRubbishBin: false, isBackupNode: false),
                    .setupNavbarItems(navbarItemsLoadModel),
                    .updateProgressView(progress: percentage),
                    .configView(textEditorViewModel, shallUpdateContent: true, isInRubbishBin: false, isBackupNode: false),
                    .setupNavbarItems(navbarItemsViewModel)
                 ]
            )
            
            assertTrackAnalyticsEventCalled(trackedEventIdentifiers: tracker.trackedEventIdentifiers,
                                            with: [TextEditorScreenEvent(), TextEditorScreenEvent()])
            
            try FileManager.default.removeItem(atPath: testPath)
        } catch {
            return
        }
    }
    
    @MainActor func testAction_setUpView_Load_tempDownload_success_read_failed() async {
        let textFile = TextFile(fileName: "testAction_setUpView_Load_tempDownload_success_read_failed")
        let mockRouter = MockTextEditorViewRouter()
        let mockUploadFileUC = MockUploadFileUseCase()
        
        let testPath = (NSTemporaryDirectory() as NSString).appendingPathComponent(textFile.fileName)
        let transferEntity = mockTransferEntity(transferTypeEntity: .download, path: testPath)
        let mockDownloadNodeUC = MockDownloadNodeUseCase(transferEntity: transferEntity, result: .success(transferEntity))
        
        let mockBackupsUC = MockBackupsUseCase()
        let nodeAccessLevel: NodeAccessTypeEntity = .owner
        let mockNodeDataUC = MockNodeDataUseCase(nodeAccessLevelVariable: nodeAccessLevel)
        
        let textEditorMode: TextEditorMode = .load
        
        let textEditorLoadModel = TextEditorModel(
            textFile: textFile,
            textEditorMode: textEditorMode,
            accessLevel: nil,
            resumeReadingOffset: nil
        )
        
        let navbarItemsModel = TextEditorNavbarItemsModel(
            leftItem: NavbarItemModel(title: Strings.Localizable.close, image: nil),
            rightItem: nil,
            textEditorMode: textEditorMode
        )
        
        let mockNode = NodeEntity(handle: 123, isFile: true)
        
        let viewModel = TextEditorViewModel(
            router: mockRouter,
            textFile: textFile,
            textEditorMode: textEditorMode,
            uploadFileUseCase: mockUploadFileUC,
            downloadNodeUseCase: mockDownloadNodeUC,
            nodeUseCase: mockNodeDataUC,
            backupsUseCase: mockBackupsUC,
            networkMonitorUseCase: MockNetworkMonitorUseCase(),
            resumeTextPositionUseCase: MockResumeTextPositionUseCase(),
            nodeEntity: mockNode
        )
        
        let percentage = Float(transferEntity.transferredBytes) / Float(transferEntity.totalBytes)
        
        await test(viewModel: viewModel,
                   action: .setUpView,
                   expectedCommands: [
                    .setupLoadViews,
                    .configView(textEditorLoadModel, shallUpdateContent: false, isInRubbishBin: false, isBackupNode: false),
                    .setupNavbarItems(navbarItemsModel),
                    .updateProgressView(progress: percentage)
                   ]
        )
    }
    
    @MainActor func testAction_setUpView_Load_tempDownload_success_extensionlessBinary_showsPreview() async throws {
        let textFile = TextFile(fileName: "binary")
        let mockRouter = MockTextEditorViewRouter()

        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let testPath = directory.appendingPathComponent(textFile.fileName).path
        // Valid UTF-8, so decoding alone would open it as text; the NUL byte marks it as binary.
        try Data([0x68, 0x69, 0x00]).write(to: URL(fileURLWithPath: testPath))

        let transferEntity = mockTransferEntity(transferTypeEntity: .download, path: testPath)
        let textEditorMode: TextEditorMode = .load

        let viewModel = TextEditorViewModel(
            router: mockRouter,
            textFile: textFile,
            textEditorMode: textEditorMode,
            uploadFileUseCase: MockUploadFileUseCase(),
            downloadNodeUseCase: MockDownloadNodeUseCase(transferEntity: transferEntity, result: .success(transferEntity)),
            nodeUseCase: MockNodeDataUseCase(nodeAccessLevelVariable: .owner),
            backupsUseCase: MockBackupsUseCase(),
            networkMonitorUseCase: MockNetworkMonitorUseCase(),
            resumeTextPositionUseCase: MockResumeTextPositionUseCase(),
            nodeEntity: NodeEntity(handle: 123, isFile: true)
        )

        await test(viewModel: viewModel,
                   action: .setUpView,
                   expectedCommands: [
                    .setupLoadViews,
                    .configView(
                        TextEditorModel(textFile: textFile, textEditorMode: textEditorMode, accessLevel: nil, resumeReadingOffset: nil),
                        shallUpdateContent: false,
                        isInRubbishBin: false,
                        isBackupNode: false
                    ),
                    .setupNavbarItems(TextEditorNavbarItemsModel(
                        leftItem: NavbarItemModel(title: Strings.Localizable.close, image: nil),
                        rightItem: nil,
                        textEditorMode: textEditorMode
                    )),
                    .updateProgressView(progress: Float(transferEntity.transferredBytes) / Float(transferEntity.totalBytes))
                   ]
        )
        await Task.megaYield()

        XCTAssertEqual(mockRouter.presentPreviewDocVC_calledTimes, 1)
    }

    @MainActor func testAction_dismissTextEditorVC_whileLoading_downloadEndDoesNothing() async throws {
        let textFile = TextFile(fileName: "binary")
        let mockRouter = MockTextEditorViewRouter()

        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let testPath = directory.appendingPathComponent(textFile.fileName).path
        // A binary file opens the document preview when its download ends.
        try Data([0x68, 0x69, 0x00]).write(to: URL(fileURLWithPath: testPath))
        let transferEntity = mockTransferEntity(transferTypeEntity: .download, path: testPath)

        let viewModel = TextEditorViewModel(
            router: mockRouter,
            textFile: textFile,
            textEditorMode: .load,
            uploadFileUseCase: MockUploadFileUseCase(),
            downloadNodeUseCase: MockDownloadNodeUseCase(transferEntity: transferEntity, result: .success(transferEntity)),
            nodeUseCase: MockNodeDataUseCase(nodeAccessLevelVariable: .owner),
            backupsUseCase: MockBackupsUseCase(),
            networkMonitorUseCase: MockNetworkMonitorUseCase(),
            resumeTextPositionUseCase: MockResumeTextPositionUseCase(),
            nodeEntity: NodeEntity(handle: 123, isFile: true)
        )

        viewModel.dispatch(.setUpView)
        viewModel.dispatch(.dismissTextEditorVC)
        await Task.megaYield()

        XCTAssertEqual(mockRouter.dismissTextEditorVC_calledTimes, 1)
        XCTAssertEqual(mockRouter.presentPreviewDocVC_calledTimes, 0)
    }

    @MainActor func testAction_setUpView_Load_tempDownload_failed() async {
        let textFile = TextFile(fileName: "testAction_setUpView_Load_tempDownload_failed")
        let mockRouter = MockTextEditorViewRouter()
        let mockUploadFileUC = MockUploadFileUseCase()
        
        let transferEntity = mockTransferEntity(transferTypeEntity: .download)
        let mockDownloadNodeUC = MockDownloadNodeUseCase(transferEntity: transferEntity, result: .failure(TransferErrorEntity.download))
        
        let mockBackupsUC = MockBackupsUseCase()
        let nodeAccessLevel: NodeAccessTypeEntity = .owner
        let mockNodeDataUC = MockNodeDataUseCase(nodeAccessLevelVariable: nodeAccessLevel)
        
        let textEditorMode: TextEditorMode = .load
        
        let textEditorLoadModel = TextEditorModel(
            textFile: textFile,
            textEditorMode: textEditorMode,
            accessLevel: nil,
            resumeReadingOffset: nil
        )
        
        let navbarItemsModel = TextEditorNavbarItemsModel(
            leftItem: NavbarItemModel(title: Strings.Localizable.close, image: nil),
            rightItem: nil,
            textEditorMode: textEditorMode
        )
        
        let mockNode = NodeEntity(handle: 123, isFile: true)
        
        let viewModel = TextEditorViewModel(
            router: mockRouter,
            textFile: textFile,
            textEditorMode: textEditorMode,
            uploadFileUseCase: mockUploadFileUC,
            downloadNodeUseCase: mockDownloadNodeUC,
            nodeUseCase: mockNodeDataUC,
            backupsUseCase: mockBackupsUC,
            networkMonitorUseCase: MockNetworkMonitorUseCase(),
            resumeTextPositionUseCase: MockResumeTextPositionUseCase(),
            nodeEntity: mockNode
        )
        
        await test(viewModel: viewModel,
                   action: .setUpView,
                   expectedCommands: [
                    .setupLoadViews,
                    .configView(textEditorLoadModel, shallUpdateContent: false, isInRubbishBin: false, isBackupNode: false),
                    .setupNavbarItems(navbarItemsModel),
                    .showError(message: Strings.Localizable.transferFailed + " " + Strings.Localizable.download)
                   ]
        )
    }
    
    @MainActor func testAction_saveText_edit_success() {
        let textFile = TextFile(
            fileName: "testAction_saveText_edit_success",
            content: "test content",
            size: 0,
            encode: String.Encoding.utf8.rawValue
        )
        let mockRouter = MockTextEditorViewRouter()
        let mockUploadFileUC = MockUploadFileUseCase(uploadFileResult: .success, filename: textFile.fileName)
        let mockDownloadNodeUC = MockDownloadNodeUseCase()
        let mockBackupsUC = MockBackupsUseCase()
        let nodeAccessLevel: NodeAccessTypeEntity = .owner
        let mockNodeDataUC = MockNodeDataUseCase(nodeAccessLevelVariable: nodeAccessLevel)
        
        let mockParentHandle: HandleEntity = 123
        let mockNode = NodeEntity(handle: 123, isFile: true)
        
        let viewModel = TextEditorViewModel(
            router: mockRouter,
            textFile: textFile,
            textEditorMode: .edit,
            uploadFileUseCase: mockUploadFileUC,
            downloadNodeUseCase: mockDownloadNodeUC,
            nodeUseCase: mockNodeDataUC,
            backupsUseCase: mockBackupsUC,
            networkMonitorUseCase: MockNetworkMonitorUseCase(),
            resumeTextPositionUseCase: MockResumeTextPositionUseCase(),
            parentHandle: mockParentHandle,
            nodeEntity: mockNode
        )
        
        let editContent = "edit content"
        
        let textEditorViewModel = TextEditorModel(
            textFile: textFile,
            textEditorMode: .view,
            accessLevel: nodeAccessLevel,
            resumeReadingOffset: nil
        )
        
        let navbarItemsModel = TextEditorNavbarItemsModel(
            leftItem: NavbarItemModel(title: Strings.Localizable.close, image: nil),
            rightItem: NavbarItemModel(title: nil, image: MEGAAssets.UIImage.moreNavigationBar),
            textEditorMode: .view
        )
        
        test(viewModel: viewModel,
             action: .saveText(content: editContent),
             expectedCommands: [
                .startLoading,
                .stopLoading,
                .configView(textEditorViewModel, shallUpdateContent: false, isInRubbishBin: false, isBackupNode: false),
                .setupNavbarItems(navbarItemsModel)
             ]
        )
    }
    
    @MainActor func testAction_saveText_edit_failed() {
        let textFile = TextFile(
            fileName: "testAction_saveText_edit_failed",
            content: "test content",
            size: 0,
            encode: String.Encoding.utf8.rawValue
        )
        let mockRouter = MockTextEditorViewRouter()
        let mockUploadFileUC = MockUploadFileUseCase(uploadFileResult: .failure(.upload), filename: textFile.fileName)
        let mockDownloadNodeUC = MockDownloadNodeUseCase()
        let mockNodeDataUC = MockNodeDataUseCase()
        let mockBackupsUC = MockBackupsUseCase()
        
        let mockParentHandle: HandleEntity = 123
        
        let viewModel = TextEditorViewModel(
            router: mockRouter,
            textFile: textFile,
            textEditorMode: .edit,
            uploadFileUseCase: mockUploadFileUC,
            downloadNodeUseCase: mockDownloadNodeUC,
            nodeUseCase: mockNodeDataUC,
            backupsUseCase: mockBackupsUC,
            networkMonitorUseCase: MockNetworkMonitorUseCase(),
            resumeTextPositionUseCase: MockResumeTextPositionUseCase(),
            parentHandle: mockParentHandle
        )
        
        let editContent = "edit content"
        
        test(viewModel: viewModel,
             action: .saveText(content: editContent),
             expectedCommands: [.startLoading,
                                .stopLoading,
                                .showError(message: Strings.Localizable.transferFailed + " " + Strings.Localizable.upload)
             ]
        )
    }

    @MainActor func testAction_cancelAfterFailedSave_showsDiscardChangeAlert() {
        let textFile = TextFile(
            fileName: "testAction_cancelAfterFailedSave_showsDiscardChangeAlert",
            content: "test content",
            size: 0,
            encode: String.Encoding.utf8.rawValue
        )
        let mockUploadFileUC = MockUploadFileUseCase(uploadFileResult: .failure(.upload), filename: textFile.fileName)
        let viewModel = TextEditorViewModel(
            router: MockTextEditorViewRouter(),
            textFile: textFile,
            textEditorMode: .edit,
            uploadFileUseCase: mockUploadFileUC,
            downloadNodeUseCase: MockDownloadNodeUseCase(),
            nodeUseCase: MockNodeDataUseCase(),
            backupsUseCase: MockBackupsUseCase(),
            networkMonitorUseCase: MockNetworkMonitorUseCase(),
            resumeTextPositionUseCase: MockResumeTextPositionUseCase(),
            parentHandle: 123
        )
        let editContent = "edit content"

        test(viewModel: viewModel,
             actions: [.saveText(content: editContent), .cancelText(content: editContent)],
             expectedCommands: [.startLoading,
                                .stopLoading,
                                .showError(message: Strings.Localizable.transferFailed + " " + Strings.Localizable.upload),
                                .showDiscardChangeAlert
             ]
        )
        XCTAssertEqual(textFile.content, "test content")
    }

    @MainActor func testAction_saveText_edit_offline_showsErrorAndKeepsEdits() {
        let textFile = TextFile(fileName: "edit.txt", content: "test content", size: 0, encode: String.Encoding.utf8.rawValue)
        let viewModel = sut(
            parentHandle: 123,
            textFile: textFile,
            textEditorMode: .edit,
            networkMonitorUseCase: MockNetworkMonitorUseCase(connected: false)
        )
        let editContent = "edit content"

        test(viewModel: viewModel,
             actions: [.saveText(content: editContent), .cancelText(content: editContent)],
             expectedCommands: [.showError(message: Strings.Localizable.noInternetConnection),
                                .showDiscardChangeAlert]
        )
        XCTAssertEqual(textFile.content, "test content")
    }

    @MainActor func testAction_saveText_create_offline_showsErrorAndKeepsEditorOpen() {
        let mockRouter = MockTextEditorViewRouter()
        let viewModel = sut(
            parentHandle: nil,
            textFile: TextFile(fileName: "new.txt"),
            textEditorMode: .create,
            router: mockRouter,
            networkMonitorUseCase: MockNetworkMonitorUseCase(connected: false)
        )

        test(viewModel: viewModel,
             action: .saveText(content: "new text"),
             expectedCommands: [.showError(message: Strings.Localizable.noInternetConnection)]
        )
        XCTAssertEqual(mockRouter.chooseDestination_calledTimes, 0)
        XCTAssertEqual(mockRouter.dismissBrowserVC_calledTimes, 0)
        XCTAssertEqual(mockRouter.dismissTextEditorVC_calledTimes, 0)
    }

    @MainActor func testAction_saveText_edit_tempFileWriteFails_stopsLoadingAndShowsError() {
        let textFile = TextFile(
            fileName: "testAction_saveText_edit_tempFileWriteFails",
            content: "test content",
            size: 0,
            encode: String.Encoding.utf8.rawValue
        )
        // The temp file goes into a folder that does not exist, so the write fails.
        let missingFolderFileName = UUID().uuidString + "/" + textFile.fileName
        let viewModel = TextEditorViewModel(
            router: MockTextEditorViewRouter(),
            textFile: textFile,
            textEditorMode: .edit,
            uploadFileUseCase: MockUploadFileUseCase(uploadFileResult: .success, filename: missingFolderFileName),
            downloadNodeUseCase: MockDownloadNodeUseCase(),
            nodeUseCase: MockNodeDataUseCase(),
            backupsUseCase: MockBackupsUseCase(),
            networkMonitorUseCase: MockNetworkMonitorUseCase(),
            resumeTextPositionUseCase: MockResumeTextPositionUseCase(),
            parentHandle: 123
        )

        test(viewModel: viewModel,
             action: .saveText(content: "edit content"),
             expectedCommands: [.startLoading,
                                .stopLoading,
                                .showError(message: Strings.Localizable.transferFailed + " " + Strings.Localizable.upload)
             ]
        )
    }

    @MainActor func testAction_saveText_create_hasParent_duplicateName() {
        let textFile = TextFile(fileName: "testAction_saveText_create_hasParent_duplicateName")
        let mockRouter = MockTextEditorViewRouter()
        let mockUploadFileUC = MockUploadFileUseCase()
        let mockDownloadNodeUC = MockDownloadNodeUseCase()
        let mockNodeDataUC = MockNodeDataUseCase()
        let mockBackupsUC = MockBackupsUseCase()
        let textEditorMode: TextEditorMode = .create
        let mockParentHandle: HandleEntity = 123
        
        let duplicateNameAlertModel = TextEditorDuplicateNameAlertModel(
            alertTitle: Strings.Localizable.renameFileAlertTitle(textFile.fileName),
            alertMessage: Strings.Localizable.thereIsAlreadyAFileWithTheSameName,
            cancelButtonTitle: Strings.Localizable.cancel,
            replaceButtonTitle: Strings.Localizable.replace,
            renameButtonTitle: Strings.Localizable.rename
        )
        
        let viewModel = TextEditorViewModel(
            router: mockRouter,
            textFile: textFile,
            textEditorMode: textEditorMode,
            uploadFileUseCase: mockUploadFileUC,
            downloadNodeUseCase: mockDownloadNodeUC,
            nodeUseCase: mockNodeDataUC,
            backupsUseCase: mockBackupsUC,
            networkMonitorUseCase: MockNetworkMonitorUseCase(),
            resumeTextPositionUseCase: MockResumeTextPositionUseCase(),
            parentHandle: mockParentHandle
        )
        
        let createContent = "create content"
        
        test(viewModel: viewModel,
             action: .saveText(content: createContent),
             expectedCommands: [.showDuplicateNameAlert(duplicateNameAlertModel)]
        )
        XCTAssertEqual(mockRouter.chooseDestination_calledTimes, 0)
    }
    
    @MainActor func testAction_saveText_create_hasParent_uniqueName_success() {
        let textFile = TextFile(fileName: "testAction_saveText_create_hasParent_uniqueName_success")
        let mockRouter = MockTextEditorViewRouter()
        let mockUploadFileUC = MockUploadFileUseCase(duplicate: false, uploadFileResult: .success, filename: textFile.fileName)
        let mockDownloadNodeUC = MockDownloadNodeUseCase()
        let mockNodeDataUC = MockNodeDataUseCase()
        let mockBackupsUC = MockBackupsUseCase()
        let textEditorMode: TextEditorMode = .create
        let mockParentHandle: HandleEntity = 123
        
        let viewModel = TextEditorViewModel(
            router: mockRouter,
            textFile: textFile,
            textEditorMode: textEditorMode,
            uploadFileUseCase: mockUploadFileUC,
            downloadNodeUseCase: mockDownloadNodeUC,
            nodeUseCase: mockNodeDataUC,
            backupsUseCase: mockBackupsUC,
            networkMonitorUseCase: MockNetworkMonitorUseCase(),
            resumeTextPositionUseCase: MockResumeTextPositionUseCase(),
            parentHandle: mockParentHandle
        )
        
        let createContent = "create content"
        
        test(viewModel: viewModel,
             action: .saveText(content: createContent),
             expectedCommands: [.startLoading, .stopLoading]
        )
        XCTAssertEqual(mockRouter.chooseDestination_calledTimes, 0)
        XCTAssertEqual(mockRouter.dismissTextEditorVC_calledTimes, 1)
        XCTAssertEqual(mockRouter.dismissBrowserVC_calledTimes, 1)
    }
    
    @MainActor func testAction_saveText_create_hasParent_uniqueName_failed() {
        let textFile = TextFile(fileName: "testAction_saveText_create_hasParent_uniqueName_failed")
        let mockRouter = MockTextEditorViewRouter()
        let mockUploadFileUC = MockUploadFileUseCase(duplicate: false, uploadFileResult: .failure(.upload), filename: textFile.fileName)
        let mockDownloadNodeUC = MockDownloadNodeUseCase()
        let mockNodeDataUC = MockNodeDataUseCase()
        let mockBackupsUC = MockBackupsUseCase()
        let textEditorMode: TextEditorMode = .create
        let mockParentHandle: HandleEntity = 123
        
        let viewModel = TextEditorViewModel(
            router: mockRouter,
            textFile: textFile,
            textEditorMode: textEditorMode,
            uploadFileUseCase: mockUploadFileUC,
            downloadNodeUseCase: mockDownloadNodeUC,
            nodeUseCase: mockNodeDataUC,
            backupsUseCase: mockBackupsUC,
            networkMonitorUseCase: MockNetworkMonitorUseCase(),
            resumeTextPositionUseCase: MockResumeTextPositionUseCase(),
            parentHandle: mockParentHandle
        )
        
        let createContent = "create content"
        
        test(viewModel: viewModel,
             action: .saveText(content: createContent),
             expectedCommands: [.startLoading,
                                .stopLoading,
                                .showError(message: Strings.Localizable.transferFailed + " " + Strings.Localizable.upload)]
        )
        XCTAssertEqual(mockRouter.chooseDestination_calledTimes, 0)
        XCTAssertEqual(mockRouter.dismissTextEditorVC_calledTimes, 0)
        XCTAssertEqual(mockRouter.dismissBrowserVC_calledTimes, 1)
    }
    
    @MainActor func testAction_saveText_create_noParent_duplicateName() {
        let textFile = TextFile(fileName: "testAction_saveText_create_noParent_duplicateName")
        let mockRouter = MockTextEditorViewRouter()
        let mockUploadFileUC = MockUploadFileUseCase()
        let mockDownloadNodeUC = MockDownloadNodeUseCase()
        let mockNodeDataUC = MockNodeDataUseCase()
        let mockBackupsUC = MockBackupsUseCase()
        let textEditorMode: TextEditorMode = .create
        
        let duplicateNameAlertModel = TextEditorDuplicateNameAlertModel(
            alertTitle: Strings.Localizable.renameFileAlertTitle(textFile.fileName),
            alertMessage: Strings.Localizable.thereIsAlreadyAFileWithTheSameName,
            cancelButtonTitle: Strings.Localizable.cancel,
            replaceButtonTitle: Strings.Localizable.replace,
            renameButtonTitle: Strings.Localizable.rename
        )
        
        let viewModel = TextEditorViewModel(
            router: mockRouter,
            textFile: textFile,
            textEditorMode: textEditorMode,
            uploadFileUseCase: mockUploadFileUC,
            downloadNodeUseCase: mockDownloadNodeUC,
            nodeUseCase: mockNodeDataUC,
            backupsUseCase: mockBackupsUC,
            networkMonitorUseCase: MockNetworkMonitorUseCase(),
            resumeTextPositionUseCase: MockResumeTextPositionUseCase()
        )
        
        let createContent = "create content"
        
        test(viewModel: viewModel,
             action: .saveText(content: createContent),
             expectedCommands: [.showDuplicateNameAlert(duplicateNameAlertModel)]
        )
        XCTAssertEqual(mockRouter.chooseDestination_calledTimes, 1)
    }
    
    @MainActor func testAction_saveText_create_noParent_uniqueName_success() {
        let textFile = TextFile(fileName: "testAction_saveText_create_noParent_uniqueName_success")
        let mockRouter = MockTextEditorViewRouter()
        let mockUploadFileUC = MockUploadFileUseCase(duplicate: false, uploadFileResult: .success, filename: textFile.fileName)
        let mockDownloadNodeUC = MockDownloadNodeUseCase()
        let mockNodeDataUC = MockNodeDataUseCase()
        let mockBackupsUC = MockBackupsUseCase()
        let textEditorMode: TextEditorMode = .create
        
        let viewModel = TextEditorViewModel(
            router: mockRouter,
            textFile: textFile,
            textEditorMode: textEditorMode,
            uploadFileUseCase: mockUploadFileUC,
            downloadNodeUseCase: mockDownloadNodeUC,
            nodeUseCase: mockNodeDataUC,
            backupsUseCase: mockBackupsUC,
            networkMonitorUseCase: MockNetworkMonitorUseCase(),
            resumeTextPositionUseCase: MockResumeTextPositionUseCase()
        )
        
        let createContent = "create content"
        
        test(viewModel: viewModel,
             action: .saveText(content: createContent),
             expectedCommands: [.startLoading, .stopLoading]
        )
        XCTAssertEqual(mockRouter.chooseDestination_calledTimes, 1)
        XCTAssertEqual(mockRouter.dismissTextEditorVC_calledTimes, 1)
        XCTAssertEqual(mockRouter.dismissBrowserVC_calledTimes, 1)
    }
    
    @MainActor func testAction_saveText_create_noParent_uniqueName_failed() {
        let textFile = TextFile(fileName: "testAction_saveText_create_noParent_uniqueName_failed")
        let mockRouter = MockTextEditorViewRouter()
        let mockUploadFileUC = MockUploadFileUseCase(duplicate: false, uploadFileResult: .failure(.upload), filename: textFile.fileName)
        let mockDownloadNodeUC = MockDownloadNodeUseCase()
        let mockNodeDataUC = MockNodeDataUseCase()
        let mockBackupsUC = MockBackupsUseCase()
        let textEditorMode: TextEditorMode = .create
        
        let viewModel = TextEditorViewModel(
            router: mockRouter,
            textFile: textFile,
            textEditorMode: textEditorMode,
            uploadFileUseCase: mockUploadFileUC,
            downloadNodeUseCase: mockDownloadNodeUC,
            nodeUseCase: mockNodeDataUC,
            backupsUseCase: mockBackupsUC,
            networkMonitorUseCase: MockNetworkMonitorUseCase(),
            resumeTextPositionUseCase: MockResumeTextPositionUseCase()
        )
        
        let createContent = "create content"
        
        test(viewModel: viewModel,
             action: .saveText(content: createContent),
             expectedCommands: [.startLoading,
                                .stopLoading,
                                .showError(message: Strings.Localizable.transferFailed + " " + Strings.Localizable.upload)]
        )
        XCTAssertEqual(mockRouter.chooseDestination_calledTimes, 1)
        XCTAssertEqual(mockRouter.dismissTextEditorVC_calledTimes, 0)
        XCTAssertEqual(mockRouter.dismissBrowserVC_calledTimes, 1)
    }
    
    @MainActor func testAction_cancelAfterFailedCreate_showsDiscardChangeAlert() {
        let textFile = TextFile(fileName: "testAction_cancelAfterFailedCreate_showsDiscardChangeAlert")
        let mockRouter = MockTextEditorViewRouter()
        let viewModel = TextEditorViewModel(
            router: mockRouter,
            textFile: textFile,
            textEditorMode: .create,
            uploadFileUseCase: MockUploadFileUseCase(duplicate: false, uploadFileResult: .failure(.upload), filename: textFile.fileName),
            downloadNodeUseCase: MockDownloadNodeUseCase(),
            nodeUseCase: MockNodeDataUseCase(),
            backupsUseCase: MockBackupsUseCase(),
            networkMonitorUseCase: MockNetworkMonitorUseCase(),
            resumeTextPositionUseCase: MockResumeTextPositionUseCase(),
            parentHandle: 123
        )
        let createContent = "create content"

        test(viewModel: viewModel,
             actions: [.saveText(content: createContent), .cancelText(content: createContent)],
             expectedCommands: [.startLoading,
                                .stopLoading,
                                .showError(message: Strings.Localizable.transferFailed + " " + Strings.Localizable.upload),
                                .showDiscardChangeAlert
             ]
        )
        XCTAssertEqual(mockRouter.dismissTextEditorVC_calledTimes, 0)
    }

    @MainActor func testAction_uploadFile_create_success_closesPickerThenEditorWithoutCloseEvent() {
        let textFile = TextFile(fileName: "testAction_uploadFile_create_success")
        let mockRouter = MockTextEditorViewRouter()
        let tracker = MockTracker()
        let viewModel = TextEditorViewModel(
            router: mockRouter,
            textFile: textFile,
            textEditorMode: .create,
            uploadFileUseCase: MockUploadFileUseCase(uploadFileResult: .success, filename: textFile.fileName),
            downloadNodeUseCase: MockDownloadNodeUseCase(),
            nodeUseCase: MockNodeDataUseCase(),
            backupsUseCase: MockBackupsUseCase(),
            networkMonitorUseCase: MockNetworkMonitorUseCase(),
            resumeTextPositionUseCase: MockResumeTextPositionUseCase(),
            parentHandle: 123,
            tracker: tracker
        )

        test(viewModel: viewModel,
             action: .uploadFile,
             expectedCommands: [.startLoading, .stopLoading]
        )
        XCTAssertEqual(mockRouter.dismissBrowserVC_calledTimes, 1)
        XCTAssertEqual(mockRouter.dismissTextEditorVC_calledTimes, 1)
        XCTAssertTrue(tracker.trackedEventIdentifiers.isEmpty)
    }

    @MainActor func testAction_uploadFile_create_failed_keepsEditorOpen() {
        let textFile = TextFile(fileName: "testAction_uploadFile_create_failed")
        let mockRouter = MockTextEditorViewRouter()
        let viewModel = TextEditorViewModel(
            router: mockRouter,
            textFile: textFile,
            textEditorMode: .create,
            uploadFileUseCase: MockUploadFileUseCase(uploadFileResult: .failure(.upload), filename: textFile.fileName),
            downloadNodeUseCase: MockDownloadNodeUseCase(),
            nodeUseCase: MockNodeDataUseCase(),
            backupsUseCase: MockBackupsUseCase(),
            networkMonitorUseCase: MockNetworkMonitorUseCase(),
            resumeTextPositionUseCase: MockResumeTextPositionUseCase(),
            parentHandle: 123
        )

        test(viewModel: viewModel,
             action: .uploadFile,
             expectedCommands: [.startLoading,
                                .stopLoading,
                                .showError(message: Strings.Localizable.transferFailed + " " + Strings.Localizable.upload)]
        )
        XCTAssertEqual(mockRouter.dismissBrowserVC_calledTimes, 1)
        XCTAssertEqual(mockRouter.dismissTextEditorVC_calledTimes, 0)
    }
    
    @MainActor func testAction_renameFile_create() {
        let textFile = TextFile(fileName: "testAction_renameFile_create")
        let mockRouter = MockTextEditorViewRouter()
        let mockUploadFileUC = MockUploadFileUseCase()
        let mockDownloadNodeUC = MockDownloadNodeUseCase()
        let mockNodeDataUC = MockNodeDataUseCase()
        let mockBackupsUC = MockBackupsUseCase()
        let textEditorMode: TextEditorMode = .create
        
        let renameAlertModel = TextEditorRenameAlertModel(
            alertTitle: Strings.Localizable.rename,
            alertMessage: Strings.Localizable.renameNodeMessage,
            cancelButtonTitle: Strings.Localizable.cancel,
            renameButtonTitle: Strings.Localizable.rename,
            textFileName: textFile.fileName
        )
        
        let viewModel = TextEditorViewModel(
            router: mockRouter,
            textFile: textFile,
            textEditorMode: textEditorMode,
            uploadFileUseCase: mockUploadFileUC,
            downloadNodeUseCase: mockDownloadNodeUC,
            nodeUseCase: mockNodeDataUC,
            backupsUseCase: mockBackupsUC,
            networkMonitorUseCase: MockNetworkMonitorUseCase(),
            resumeTextPositionUseCase: MockResumeTextPositionUseCase()
        )
        
        test(viewModel: viewModel,
             action: .renameFile,
             expectedCommands: [.showRenameAlert(renameAlertModel)]
        )
    }
    
    @MainActor func testAction_renameFileTo_create() {
        let textFile = TextFile(fileName: "testAction_renameFileTo_create")
        let mockRouter = MockTextEditorViewRouter()
        let mockUploadFileUC = MockUploadFileUseCase(duplicate: false, filename: textFile.fileName)
        let mockDownloadNodeUC = MockDownloadNodeUseCase()
        let mockNodeDataUC = MockNodeDataUseCase()
        let mockBackupsUC = MockBackupsUseCase()
        let textEditorMode: TextEditorMode = .create
        let mockParentHandle: HandleEntity = 123
        
        let newName = "new name"
        
        let viewModel = TextEditorViewModel(
            router: mockRouter,
            textFile: textFile,
            textEditorMode: textEditorMode,
            uploadFileUseCase: mockUploadFileUC,
            downloadNodeUseCase: mockDownloadNodeUC,
            nodeUseCase: mockNodeDataUC,
            backupsUseCase: mockBackupsUC,
            networkMonitorUseCase: MockNetworkMonitorUseCase(),
            resumeTextPositionUseCase: MockResumeTextPositionUseCase(),
            parentHandle: mockParentHandle
        )
        
        test(viewModel: viewModel,
             action: .renameFileTo(newInputName: newName),
             expectedCommands: [.startLoading]
        )
        
        XCTAssertEqual(mockUploadFileUC.newName, newName)
    }
    
    @MainActor func testAction_dismissTextEditorVC() {
        let textFile = TextFile(fileName: "testAction_dismissTextEditorVC")
        let mockRouter = MockTextEditorViewRouter()
        let mockUploadFileUC = MockUploadFileUseCase()
        let mockDownloadNodeUC = MockDownloadNodeUseCase()
        let mockNodeDataUC = MockNodeDataUseCase()
        let mockBackupsUC = MockBackupsUseCase()
        let tracker = MockTracker()
        var events = [TextEditorCloseMenuToolbarEvent]()
        
        for (index, textEditorMode) in TextEditorMode.allCases.enumerated() {
            let viewModel = TextEditorViewModel(
                router: mockRouter,
                textFile: textFile,
                textEditorMode: textEditorMode,
                uploadFileUseCase: mockUploadFileUC,
                downloadNodeUseCase: mockDownloadNodeUC,
                nodeUseCase: mockNodeDataUC,
                backupsUseCase: mockBackupsUC,
                networkMonitorUseCase: MockNetworkMonitorUseCase(),
                resumeTextPositionUseCase: MockResumeTextPositionUseCase(),
                tracker: tracker
            )
            
            test(viewModel: viewModel,
                 action: .dismissTextEditorVC,
                 expectedCommands: []
            )
            
            XCTAssertEqual(mockRouter.dismissTextEditorVC_calledTimes, index + 1)
            events.append(TextEditorCloseMenuToolbarEvent())
            assertTrackAnalyticsEventCalled(trackedEventIdentifiers: tracker.trackedEventIdentifiers,
                                            with: events)
        }
    }
    
    @MainActor func testAction_editFile_view_editableSize() {
        let textFile = TextFile(
            fileName: "testAction_editFile_view_editableSize",
            content: "test content",
            size: TextFile.maxEditableFileSize - 1,
            encode: String.Encoding.utf8.rawValue
        )
        
        let mockRouter = MockTextEditorViewRouter()
        let mockUploadFileUC = MockUploadFileUseCase()
        let mockDownloadNodeUC = MockDownloadNodeUseCase()
        let mockNodeDataUC = MockNodeDataUseCase()
        let mockBackupsUC = MockBackupsUseCase()
        
        let viewModel = TextEditorViewModel(
            router: mockRouter,
            textFile: textFile,
            textEditorMode: .view,
            uploadFileUseCase: mockUploadFileUC,
            downloadNodeUseCase: mockDownloadNodeUC,
            nodeUseCase: mockNodeDataUC,
            backupsUseCase: mockBackupsUC,
            networkMonitorUseCase: MockNetworkMonitorUseCase(),
            resumeTextPositionUseCase: MockResumeTextPositionUseCase()
        )
        
        let textEditorModel = TextEditorModel(
            textFile: textFile,
            textEditorMode: .edit,
            accessLevel: nil,
            resumeReadingOffset: nil
        )
        
        let navbarItemsModel = TextEditorNavbarItemsModel(
            leftItem: NavbarItemModel(title: Strings.Localizable.cancel, image: nil),
            rightItem: NavbarItemModel(title: Strings.Localizable.save, image: nil),
            textEditorMode: .edit
        )
        
        test(viewModel: viewModel,
             action: .editFile,
             expectedCommands: [
                .configView(textEditorModel, shallUpdateContent: false, isInRubbishBin: false, isBackupNode: false),
                .setupNavbarItems(navbarItemsModel)
             ]
        )
    }
    
    @MainActor func testAction_editFile_view_ineditableSize() {
        let textFile = TextFile(
            fileName: "testAction_editFile_view_editableSize",
            content: "test content",
            size: TextFile.maxEditableFileSize,
            encode: String.Encoding.utf8.rawValue
        )
        let mockRouter = MockTextEditorViewRouter()
        let mockUploadFileUC = MockUploadFileUseCase()
        let mockDownloadNodeUC = MockDownloadNodeUseCase()
        let mockNodeDataUC = MockNodeDataUseCase()
        let mockBackupsUC = MockBackupsUseCase()
        let tracker = MockTracker()
        
        let viewModel = TextEditorViewModel(
            router: mockRouter,
            textFile: textFile,
            textEditorMode: .view,
            uploadFileUseCase: mockUploadFileUC,
            downloadNodeUseCase: mockDownloadNodeUC,
            nodeUseCase: mockNodeDataUC,
            backupsUseCase: mockBackupsUC,
            networkMonitorUseCase: MockNetworkMonitorUseCase(),
            resumeTextPositionUseCase: MockResumeTextPositionUseCase(),
            tracker: tracker
        )
        
        test(viewModel: viewModel,
             action: .editFile,
             expectedCommands: [.showError(message: Strings.Localizable.General.TextEditor.Hud.uneditableLargeFile)]
        )
        
        assertTrackAnalyticsEventCalled(trackedEventIdentifiers: tracker.trackedEventIdentifiers, with: [TextEditorEditMenuToolbarEvent(), EditTextFileActionEvent()])
    }

    /// A file opened from the cloud gets its text file from `TextFile(fileName:size:)`, so the size must reach the edit check.
    @MainActor func testAction_editFile_view_ineditableSizeFromNodeSize() {
        let viewModel = TextEditorViewModel(
            router: MockTextEditorViewRouter(),
            textFile: TextFile(fileName: "large.txt", size: TextFile.maxEditableFileSize),
            textEditorMode: .view,
            uploadFileUseCase: MockUploadFileUseCase(),
            downloadNodeUseCase: MockDownloadNodeUseCase(),
            nodeUseCase: MockNodeDataUseCase(),
            backupsUseCase: MockBackupsUseCase(),
            networkMonitorUseCase: MockNetworkMonitorUseCase(),
            resumeTextPositionUseCase: MockResumeTextPositionUseCase()
        )

        test(viewModel: viewModel,
             action: .editFile,
             expectedCommands: [.showError(message: Strings.Localizable.General.TextEditor.Hud.uneditableLargeFile)]
        )
    }

    @MainActor func testAction_editAfterOpen_view_editableSize() {
        let textFile = TextFile(
            fileName: "testAction_editAfterOpen_view_editableSize",
            content: "test content",
            size: TextFile.maxEditableFileSize - 1,
            encode: String.Encoding.utf8.rawValue
        )
        
        let mockRouter = MockTextEditorViewRouter()
        let mockUploadFileUC = MockUploadFileUseCase()
        let mockDownloadNodeUC = MockDownloadNodeUseCase()
        let mockNodeDataUC = MockNodeDataUseCase()
        let mockBackupsUC = MockBackupsUseCase()
        
        let viewModel = TextEditorViewModel(
            router: mockRouter,
            textFile: textFile,
            textEditorMode: .view,
            uploadFileUseCase: mockUploadFileUC,
            downloadNodeUseCase: mockDownloadNodeUC,
            nodeUseCase: mockNodeDataUC,
            backupsUseCase: mockBackupsUC,
            networkMonitorUseCase: MockNetworkMonitorUseCase(),
            resumeTextPositionUseCase: MockResumeTextPositionUseCase()
        )
        
        let textEditorModel = TextEditorModel(
            textFile: textFile,
            textEditorMode: .edit,
            accessLevel: nil,
            resumeReadingOffset: nil
        )
        
        let navbarItemsModel = TextEditorNavbarItemsModel(
            leftItem: NavbarItemModel(title: Strings.Localizable.cancel, image: nil),
            rightItem: NavbarItemModel(title: Strings.Localizable.save, image: nil),
            textEditorMode: .edit
        )
        
        test(viewModel: viewModel,
             action: .editAfterOpen,
             expectedCommands: [
                .configView(textEditorModel, shallUpdateContent: true, isInRubbishBin: false, isBackupNode: false),
                .setupNavbarItems(navbarItemsModel)
             ]
        )
    }
    
    @MainActor func testAction_editAfterOpen_view_ineditableSize() {
        let textFile = TextFile(
            fileName: "testAction_editAfterOpen_view_ineditableSize",
            content: "test content",
            size: TextFile.maxEditableFileSize,
            encode: String.Encoding.utf8.rawValue
        )
        let mockRouter = MockTextEditorViewRouter()
        let mockUploadFileUC = MockUploadFileUseCase()
        let mockDownloadNodeUC = MockDownloadNodeUseCase()
        let mockNodeDataUC = MockNodeDataUseCase()
        let mockBackupsUC = MockBackupsUseCase()
        
        let viewModel = TextEditorViewModel(
            router: mockRouter,
            textFile: textFile,
            textEditorMode: .view,
            uploadFileUseCase: mockUploadFileUC,
            downloadNodeUseCase: mockDownloadNodeUC,
            nodeUseCase: mockNodeDataUC,
            backupsUseCase: mockBackupsUC,
            networkMonitorUseCase: MockNetworkMonitorUseCase(),
            resumeTextPositionUseCase: MockResumeTextPositionUseCase()
        )
        
        test(viewModel: viewModel,
             action: .editAfterOpen,
             expectedCommands: [.showError(message: Strings.Localizable.General.TextEditor.Hud.uneditableLargeFile)]
        )
    }
    
    @MainActor func testAction_editAfterOpen_load() {
        let textFile = TextFile(
            fileName: "testAction_editAfterOpen_load",
            content: "test content",
            size: TextFile.maxEditableFileSize,
            encode: String.Encoding.utf8.rawValue
        )
        let mockRouter = MockTextEditorViewRouter()
        let mockUploadFileUC = MockUploadFileUseCase()
        let mockDownloadNodeUC = MockDownloadNodeUseCase()
        let mockNodeDataUC = MockNodeDataUseCase()
        let mockBackupsUC = MockBackupsUseCase()
        
        let viewModel = TextEditorViewModel(
            router: mockRouter,
            textFile: textFile,
            textEditorMode: .load,
            uploadFileUseCase: mockUploadFileUC,
            downloadNodeUseCase: mockDownloadNodeUC,
            nodeUseCase: mockNodeDataUC,
            backupsUseCase: mockBackupsUC,
            networkMonitorUseCase: MockNetworkMonitorUseCase(),
            resumeTextPositionUseCase: MockResumeTextPositionUseCase()
        )
        
        test(viewModel: viewModel,
             action: .editAfterOpen,
             expectedCommands: []
        )
    }
    
    /// Edit from the actions of a file that is too large to edit shows the message, then opens the file to read.
    @MainActor func testAction_editAfterOpen_load_tooLargeToEdit_opensToRead() async throws {
        let textFile = TextFile(fileName: "large.txt", size: TextFile.maxEditableFileSize)
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let testPath = directory.appendingPathComponent(textFile.fileName).path
        try "large file text".write(toFile: testPath, atomically: true, encoding: .utf8)
        let transferEntity = mockTransferEntity(transferTypeEntity: .download, path: testPath)
        let viewModel = TextEditorViewModel(
            router: MockTextEditorViewRouter(),
            textFile: textFile,
            textEditorMode: .load,
            uploadFileUseCase: MockUploadFileUseCase(),
            downloadNodeUseCase: MockDownloadNodeUseCase(transferEntity: transferEntity, result: .success(transferEntity)),
            nodeUseCase: MockNodeDataUseCase(nodeAccessLevelVariable: .owner),
            backupsUseCase: MockBackupsUseCase(),
            networkMonitorUseCase: MockNetworkMonitorUseCase(),
            resumeTextPositionUseCase: MockResumeTextPositionUseCase(),
            nodeEntity: NodeEntity(handle: 123, isFile: true)
        )
        var commands = [TextEditorViewModel.Command]()
        viewModel.invokeCommand = { commands.append($0) }

        viewModel.dispatch(.editAfterOpen)
        viewModel.dispatch(.setUpView)
        await Task.megaYield()

        XCTAssertTrue(commands.contains(.showError(message: Strings.Localizable.General.TextEditor.Hud.uneditableLargeFile)))
        let viewModeConfigured = commands.contains {
            guard case .configView(let model, _, _, _) = $0 else { return false }
            return model.textEditorMode == .view && model.textFile.content == "large file text"
        }
        XCTAssertTrue(viewModeConfigured)
    }

    @MainActor func testAction_showActions_view() {
        let textFile = TextFile(fileName: "testAction_showActions_view")
        let mockRouter = MockTextEditorViewRouter()
        let mockUploadFileUC = MockUploadFileUseCase()
        let mockDownloadNodeUC = MockDownloadNodeUseCase()
        let mockNodeDataUC = MockNodeDataUseCase()
        let mockBackupsUC = MockBackupsUseCase()
        let mockNode = NodeEntity(handle: 123, isFile: true)
        
        let viewModel = TextEditorViewModel(
            router: mockRouter,
            textFile: textFile,
            textEditorMode: .view,
            uploadFileUseCase: mockUploadFileUC,
            downloadNodeUseCase: mockDownloadNodeUC,
            nodeUseCase: mockNodeDataUC,
            backupsUseCase: mockBackupsUC,
            networkMonitorUseCase: MockNetworkMonitorUseCase(),
            resumeTextPositionUseCase: MockResumeTextPositionUseCase(),
            nodeEntity: mockNode
        )
        
        test(viewModel: viewModel,
             action: .showActions(sender: UIButton()),
             expectedCommands: []
        )
        XCTAssertEqual(mockRouter.showActions_calledTimes, 1)
    }
    
    @MainActor func testAction_cancel_create_edit_contentChange() {
        let textFile = TextFile(fileName: "testAction_cancel_contentChange")
        let mockRouter = MockTextEditorViewRouter()
        let mockUploadFileUC = MockUploadFileUseCase()
        let mockDownloadNodeUC = MockDownloadNodeUseCase()
        let mockNodeDataUC = MockNodeDataUseCase()
        let mockBackupsUC = MockBackupsUseCase()
        
        let newContent = "new content"
        
        let testModes: [TextEditorMode] = [.create, .edit]
        for textEditorMode in testModes {
            let viewModel = TextEditorViewModel(
                router: mockRouter,
                textFile: textFile,
                textEditorMode: textEditorMode,
                uploadFileUseCase: mockUploadFileUC,
                downloadNodeUseCase: mockDownloadNodeUC,
                nodeUseCase: mockNodeDataUC,
                backupsUseCase: mockBackupsUC,
                networkMonitorUseCase: MockNetworkMonitorUseCase(),
                resumeTextPositionUseCase: MockResumeTextPositionUseCase()
            )
            
            test(viewModel: viewModel,
                 action: .cancelText(content: newContent),
                 expectedCommands: [.showDiscardChangeAlert]
            )
        }
    }
    
    @MainActor func testAction_cancel_create_noContentChange() {
        let textFile = TextFile(fileName: "testAction_cancel_create_noContentChange")
        let mockRouter = MockTextEditorViewRouter()
        let mockUploadFileUC = MockUploadFileUseCase()
        let mockDownloadNodeUC = MockDownloadNodeUseCase()
        let mockNodeDataUC = MockNodeDataUseCase()
        let mockBackupsUC = MockBackupsUseCase()
        
        let viewModel = TextEditorViewModel(
            router: mockRouter,
            textFile: textFile,
            textEditorMode: .create,
            uploadFileUseCase: mockUploadFileUC,
            downloadNodeUseCase: mockDownloadNodeUC,
            nodeUseCase: mockNodeDataUC,
            backupsUseCase: mockBackupsUC,
            networkMonitorUseCase: MockNetworkMonitorUseCase(),
            resumeTextPositionUseCase: MockResumeTextPositionUseCase()
        )
        
        test(viewModel: viewModel,
             action: .cancelText(content: textFile.content),
             expectedCommands: []
        )
        XCTAssertEqual(mockRouter.dismissTextEditorVC_calledTimes, 1)
    }
    
    @MainActor func testAction_cancel_edit_noContentChange() {
        let textFile = TextFile(fileName: "testAction_cancel_edit_noContentChange")
        let mockRouter = MockTextEditorViewRouter()
        let mockUploadFileUC = MockUploadFileUseCase()
        let mockDownloadNodeUC = MockDownloadNodeUseCase()
        let mockBackupsUC = MockBackupsUseCase()
        let nodeAccessLevel: NodeAccessTypeEntity = .owner
        let mockNodeDataUC = MockNodeDataUseCase(nodeAccessLevelVariable: nodeAccessLevel)
        
        let mockNode = NodeEntity(handle: 123, isFile: true)
        
        let viewModel = TextEditorViewModel(
            router: mockRouter,
            textFile: textFile,
            textEditorMode: .edit,
            uploadFileUseCase: mockUploadFileUC,
            downloadNodeUseCase: mockDownloadNodeUC,
            nodeUseCase: mockNodeDataUC,
            backupsUseCase: mockBackupsUC,
            networkMonitorUseCase: MockNetworkMonitorUseCase(),
            resumeTextPositionUseCase: MockResumeTextPositionUseCase(),
            nodeEntity: mockNode
        )
        
        let textEditorViewModel = TextEditorModel(
            textFile: textFile,
            textEditorMode: .view,
            accessLevel: nodeAccessLevel,
            resumeReadingOffset: nil
        )
        
        let navbarItemsModel = TextEditorNavbarItemsModel(
            leftItem: NavbarItemModel(title: Strings.Localizable.close, image: nil),
            rightItem: NavbarItemModel(title: nil, image: MEGAAssets.UIImage.moreNavigationBar),
            textEditorMode: .view
        )
        
        test(viewModel: viewModel,
             action: .cancelText(content: textFile.content),
             expectedCommands: [
                .configView(textEditorViewModel, shallUpdateContent: true, isInRubbishBin: false, isBackupNode: false),
                .setupNavbarItems(navbarItemsModel)
             ]
        )
    }
    
    @MainActor func testAction_downloadToOffline_view() {
        let textFile = TextFile(fileName: "testAction_downloadToOffline_view")
        let mockRouter = MockTextEditorViewRouter()
        let mockUploadFileUC = MockUploadFileUseCase()
        let mockDownloadNodeUC = MockDownloadNodeUseCase()
        let mockNodeDataUC = MockNodeDataUseCase()
        let mockBackupsUC = MockBackupsUseCase()
        let mockNode = NodeEntity(handle: 123, isFile: true)
        let tracker = MockTracker()
        
        let viewModel = TextEditorViewModel(
            router: mockRouter,
            textFile: textFile,
            textEditorMode: .view,
            uploadFileUseCase: mockUploadFileUC,
            downloadNodeUseCase: mockDownloadNodeUC,
            nodeUseCase: mockNodeDataUC,
            backupsUseCase: mockBackupsUC,
            networkMonitorUseCase: MockNetworkMonitorUseCase(),
            resumeTextPositionUseCase: MockResumeTextPositionUseCase(),
            nodeEntity: mockNode,
            tracker: tracker
        )
        
        test(viewModel: viewModel,
             action: .downloadToOffline,
             expectedCommands: []
        )
        
        XCTAssertEqual(mockRouter.showDownloadTransfer_calledTimes, 1)
        assertTrackAnalyticsEventCalled(trackedEventIdentifiers: tracker.trackedEventIdentifiers, with: [TextEditorMakeAvailableOfflineMenuToolbarEvent()])
    }
    
    @MainActor func testAction_importNode_view() {
        let textFile = TextFile(fileName: "testAction_importNode_view")
        let mockRouter = MockTextEditorViewRouter()
        let mockUploadFileUC = MockUploadFileUseCase()
        let mockDownloadNodeUC = MockDownloadNodeUseCase()
        let mockNodeDataUC = MockNodeDataUseCase()
        let mockBackupsUC = MockBackupsUseCase()
        
        let viewModel = TextEditorViewModel(
            router: mockRouter,
            textFile: textFile,
            textEditorMode: .view,
            uploadFileUseCase: mockUploadFileUC,
            downloadNodeUseCase: mockDownloadNodeUC,
            nodeUseCase: mockNodeDataUC,
            backupsUseCase: mockBackupsUC,
            networkMonitorUseCase: MockNetworkMonitorUseCase(),
            resumeTextPositionUseCase: MockResumeTextPositionUseCase()
        )
        
        test(viewModel: viewModel,
             action: .importNode,
             expectedCommands: []
        )
        XCTAssertEqual(mockRouter.importNode_calledTimes, 1)
    }
    
    @MainActor func testAction_exportFile() {
        let textFile = TextFile(fileName: "testAction_exportFile")
        let mockRouter = MockTextEditorViewRouter()
        let mockUploadFileUC = MockUploadFileUseCase()
        let mockDownloadNodeUC = MockDownloadNodeUseCase()
        let mockNodeDataUC = MockNodeDataUseCase()
        let mockBackupsUC = MockBackupsUseCase()
        let mockNode = NodeEntity(handle: 123, isFile: true)
        let tracker = MockTracker()
        
        let viewModel = TextEditorViewModel(
            router: mockRouter,
            textFile: textFile,
            textEditorMode: .view,
            uploadFileUseCase: mockUploadFileUC,
            downloadNodeUseCase: mockDownloadNodeUC,
            nodeUseCase: mockNodeDataUC,
            backupsUseCase: mockBackupsUC,
            networkMonitorUseCase: MockNetworkMonitorUseCase(),
            resumeTextPositionUseCase: MockResumeTextPositionUseCase(),
            nodeEntity: mockNode,
            tracker: tracker
        )
        
        test(viewModel: viewModel,
             action: .exportFile(sender: UIButton()),
             expectedCommands: [])
        XCTAssertEqual(mockRouter.exportFile_calledTimes, 1)
        
        assertTrackAnalyticsEventCalled(trackedEventIdentifiers: tracker.trackedEventIdentifiers, with: [TextEditorExportFileMenuToolbarEvent()])
    }
    
    @MainActor
    func testAction_HideNode() {
        let textFile = TextFile(fileName: "testAction_hideNode")
        let mockRouter = MockTextEditorViewRouter()
        let tracker = MockTracker()
        let viewModel = sut(
            textFile: textFile,
            router: mockRouter,
            tracker: tracker
        )
        
        viewModel.nodeAction(
            mockNodeActionViewController(),
            didSelect: .hide,
            for: MockNode(handle: 1),
            from: "any-sender")
        
        XCTAssertEqual(mockRouter.hideNode_calledTimes, 1)
        assertTrackAnalyticsEventCalled(trackedEventIdentifiers: tracker.trackedEventIdentifiers, with: [TextEditorHideNodeMenuItemEvent()])
    }
    
    @MainActor
    func testAction_download() {
        let textFile = TextFile(fileName: "testAction_download")
        let mockRouter = MockTextEditorViewRouter()
        let tracker = MockTracker()
        let viewModel = sut(
            textFile: textFile,
            router: mockRouter,
            tracker: tracker
        )
        
        viewModel.nodeAction(
            mockNodeActionViewController(),
            didSelect: .download,
            for: MockNode(handle: 1),
            from: "any-sender")
        
        assertTrackAnalyticsEventCalled(trackedEventIdentifiers: tracker.trackedEventIdentifiers, with: [TextEditorMakeAvailableOfflineMenuItemEvent()])
    }
    
    @MainActor
    func testAction_editTextFile() {
        let textFile = TextFile(fileName: "testAction_editTextFile")
        let mockRouter = MockTextEditorViewRouter()
        let tracker = MockTracker()
        let viewModel = sut(
            textFile: textFile,
            router: mockRouter,
            tracker: tracker
        )
        
        viewModel.nodeAction(
            mockNodeActionViewController(),
            didSelect: .editTextFile,
            for: MockNode(handle: 1),
            from: "any-sender")
        
        assertTrackAnalyticsEventCalled(trackedEventIdentifiers: tracker.trackedEventIdentifiers, with: [TextEditorEditMenuItemEvent(), EditTextFileActionEvent(), TextEditorScreenEvent()])
    }
    
    @MainActor
    func testAction_sendToChat() {
        let textFile = TextFile(fileName: "testAction_sendToChat")
        let mockRouter = MockTextEditorViewRouter()
        let tracker = MockTracker()
        let viewModel = sut(
            textFile: textFile,
            router: mockRouter,
            tracker: tracker
        )
        
        viewModel.nodeAction(
            mockNodeActionViewController(),
            didSelect: .sendToChat,
            for: MockNode(handle: 1),
            from: "any-sender")
        
        assertTrackAnalyticsEventCalled(trackedEventIdentifiers: tracker.trackedEventIdentifiers, with: [TextEditorSendToChatMenuItemEvent()])
    }
    
    @MainActor
    func testAction_shareLink() {
        let textFile = TextFile(fileName: "testAction_shareLink")
        let mockRouter = MockTextEditorViewRouter()
        let tracker = MockTracker()
        let viewModel = sut(
            textFile: textFile,
            router: mockRouter,
            tracker: tracker
        )
        
        viewModel.nodeAction(
            mockNodeActionViewController(),
            didSelect: .shareLink,
            for: MockNode(handle: 1),
            from: "any-sender")
        
        assertTrackAnalyticsEventCalled(trackedEventIdentifiers: tracker.trackedEventIdentifiers, with: [TextEditorShareLinkMenuItemEvent()])
    }
    
    @MainActor
    func testAction_UnhideNode() {
        let textFile = TextFile(fileName: "testAction_hideNode")
        let mockRouter = MockTextEditorViewRouter()
        let mockUploadFileUC = MockUploadFileUseCase()
        let mockDownloadNodeUC = MockDownloadNodeUseCase()
        let mockNodeDataUC = MockNodeDataUseCase()
        let mockBackupsUC = MockBackupsUseCase()
        let mockNode = NodeEntity(handle: 123, isFile: true)
        
        let viewModel = TextEditorViewModel(
            router: mockRouter,
            textFile: textFile,
            textEditorMode: .view,
            uploadFileUseCase: mockUploadFileUC,
            downloadNodeUseCase: mockDownloadNodeUC,
            nodeUseCase: mockNodeDataUC,
            backupsUseCase: mockBackupsUC,
            networkMonitorUseCase: MockNetworkMonitorUseCase(),
            resumeTextPositionUseCase: MockResumeTextPositionUseCase(),
            nodeEntity: mockNode
        )
        
        viewModel.nodeAction(
            mockNodeActionViewController(),
            didSelect: .unhide,
            for: MockNode(handle: 1),
            from: "any-sender")
        
        XCTAssertEqual(mockRouter.unhideNode_calledTimes, 1)
    }

    @MainActor
    func testAction_moveToRubbishBin() {
        let router = MockTextEditorViewRouter()
        let sut = sut(
            router: router
        )

        sut.nodeAction(
            mockNodeActionViewController(),
            didSelect: .moveToRubbishBin,
            for: MockNode(handle: 1),
            from: "any-sender"
        )

        XCTAssertEqual(router.moveToRubbishBin_calledTimes, 1)
    }

    @MainActor
    private func sut(
        nodeEntity: NodeEntity = NodeEntity(handle: 123, isFile: true),
        parentHandle: HandleEntity? = nil,
        textFile: TextFile = TextFile(fileName: "testAction_hideNode"),
        textEditorMode: TextEditorMode = .view,
        router: MockTextEditorViewRouter? = nil,
        uploadFileUseCase: MockUploadFileUseCase = MockUploadFileUseCase(),
        downloadNodeUseCase: MockDownloadNodeUseCase = MockDownloadNodeUseCase(),
        nodeUseCase: MockNodeDataUseCase = MockNodeDataUseCase(),
        backupsUseCase: MockBackupsUseCase = MockBackupsUseCase(),
        networkMonitorUseCase: MockNetworkMonitorUseCase = MockNetworkMonitorUseCase(),
        resumeTextPositionUseCase: MockResumeTextPositionUseCase = MockResumeTextPositionUseCase(),
        leftOffItemRecordUseCase: MockLeftOffItemRecordUseCase = MockLeftOffItemRecordUseCase(),
        tracker: MockTracker = MockTracker(),
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> TextEditorViewModel {
        let sut = TextEditorViewModel(
            router: router ?? MockTextEditorViewRouter(),
            textFile: textFile,
            textEditorMode: textEditorMode,
            uploadFileUseCase: uploadFileUseCase,
            downloadNodeUseCase: downloadNodeUseCase,
            nodeUseCase: nodeUseCase,
            backupsUseCase: backupsUseCase,
            networkMonitorUseCase: networkMonitorUseCase,
            resumeTextPositionUseCase: resumeTextPositionUseCase,
            parentHandle: parentHandle,
            nodeEntity: nodeEntity,
            leftOffItemRecordUseCase: leftOffItemRecordUseCase,
            tracker: tracker)
        trackForMemoryLeaks(on: sut, file: file, line: line)
        return sut
    }
    
    @MainActor
    private func mockNodeActionViewController() -> NodeActionViewController {
        NodeActionViewController(
            node: MockNode(handle: 1),
            delegate: MockNodeActionViewControllerGenericDelegate(
                viewController: UIViewController(),
                moveToRubbishBinViewModel: MockMoveToRubbishBinViewModel()
            ),
            displayMode: .albumLink,
            isInVersionsView: false,
            isBackupNode: false,
            sender: "any-sender"
        )
    }
    
    private func mockTransferEntity(transferTypeEntity: TransferTypeEntity, path: String? = nil) -> TransferEntity {
        return TransferEntity(
            type: transferTypeEntity,
            transferString: nil,
            startTime: nil,
            transferredBytes: 1,
            totalBytes: 3,
            path: path,
            parentPath: nil,
            nodeHandle: 123,
            parentHandle: 123,
            startPos: nil,
            endPos: nil,
            fileName: nil,
            numRetry: 1,
            maxRetries: 1,
            tag: 1,
            speed: 0,
            deltaSize: nil,
            updateTime: nil,
            publicNode: nil,
            isStreamingTransfer: false,
            isForeignOverquota: false,
            lastErrorExtended: nil,
            isFolderTransfer: false,
            folderTransferTag: .zero,
            appData: nil,
            state: .none,
            priority: 123,
            stage: .none
        )
    }
}

private final class MockNodeActionViewControllerGenericDelegate: NodeActionViewControllerGenericDelegate {
    
    private(set) var didSelectNodeActionCallCount = 0
    
    override func nodeAction(_ nodeAction: NodeActionViewController, didSelect action: MegaNodeActionType, for node: MEGANode, from sender: Any) {
        didSelectNodeActionCallCount += 1
    }
}

final class MockTextEditorViewRouter: TextEditorViewRouting {
    
    var dismissTextEditorVC_calledTimes = 0
    var dismissBrowserVC_calledTimes = 0
    var chooseDestination_calledTimes = 0
    var showActions_calledTimes = 0
    var showActions_sender: Any?
    var reloadData_calledTimes = 0
    var presentPreviewDocVC_calledTimes = 0
    var presentPreviewDocVC_path: String?
    var importNode_calledTimes = 0
    var exportFile_calledTimes = 0
    var exportFile_sender: Any?
    var showDownloadTransfer_calledTimes = 0
    var sendToChat_calledTimes = 0
    var restoreTextFile_calledTimes = 0
    var viewInfo_calledTimes = 0
    var viewVersions_calledTimes = 0
    var removeTextFile_calledTimes = 0
    var shareLink_calledTimes = 0
    var removeLink_calledTimes = 0
    var hideNode_calledTimes = 0
    var unhideNode_calledTimes = 0
    var moveToRubbishBin_calledTimes = 0

    func chooseParentNode(completion: @escaping (HandleEntity) -> Void) {
        chooseDestination_calledTimes += 1
        completion(123)
    }
    
    func dismissTextEditorVC() {
        dismissTextEditorVC_calledTimes += 1
    }
    
    func dismissBrowserVC() {
        dismissBrowserVC_calledTimes += 1
    }
    
    func showActions(nodeHandle: HandleEntity, delegate: some NodeActionViewControllerDelegate, sender button: Any) {
        showActions_calledTimes += 1
        showActions_sender = button
    }
    
    func showPreviewDocVC(fromFilePath path: String, showUneditableError: Bool) {
        presentPreviewDocVC_calledTimes += 1
        presentPreviewDocVC_path = path
    }
    
    func importNode(nodeHandle: HandleEntity?) {
        importNode_calledTimes += 1
    }
    
    func exportFile(from node: NodeEntity, sender button: Any) {
        exportFile_calledTimes += 1
        exportFile_sender = button
    }
    
    func showDownloadTransfer(node: NodeEntity) {
        showDownloadTransfer_calledTimes += 1
    }
    
    func sendToChat(node: MEGANode) {
        sendToChat_calledTimes += 1
    }
    
    func restoreTextFile(node: MEGANode) {
        restoreTextFile_calledTimes += 1
    }
    
    func viewInfo(node: MEGANode) {
        viewInfo_calledTimes += 1
    }
    
    func viewVersions(node: MEGANode) {
        viewVersions_calledTimes += 1
    }
    
    func removeTextFile(node: MEGANode) {
        removeTextFile_calledTimes += 1
    }
    
    func shareLink(from nodeHandle: HandleEntity) {
        shareLink_calledTimes += 1
    }
    
    func removeLink(from nodeHandle: HandleEntity) {
        removeLink_calledTimes += 1
    }
    
    func hide(node: NodeEntity) {
        hideNode_calledTimes += 1
    }
    
    func unhide(node: NodeEntity) {
        unhideNode_calledTimes += 1
    }

    func moveToRubbishBin(node: MEGANode) {
        moveToRubbishBin_calledTimes += 1
    }
}
