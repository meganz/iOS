import XCTest
@testable import MEGA

final class TextEditorViewModelTests: XCTestCase {

    func testAction_setUpView_View_Create_Edit() {
        let mockRouter = MockTextEditorViewRouter()
        let mockUploadFileUC = MockUploadFileUseCase()
        let mockDownloadFileUC = MockDownloadFileUseCase()
        let mockNodeActionUC = MockNodeActionUseCase()
        let nodeAccessLevel: NodeAccessTypeEntity = .owner
        mockNodeActionUC.nodeAccessLevel = nodeAccessLevel
        let textFile = TextFile(fileName: "test")
        
        let mockNodeHandle: MEGAHandle = 123
        
        var textEditorModel: TextEditorModel
        
        let testModes: [TextEditorMode] = [.view, .create, .edit]
        for textEditorMode in testModes {
            if textEditorMode == .view {
                textEditorModel = TextEditorModel(
                    leftButtonTitle: TextEditorL10n.close,
                    rightButtonTitle: nil,
                    textFile: textFile,
                    textEditorMode: textEditorMode,
                    accessLevel: nodeAccessLevel
                )
            } else {
                textEditorModel = TextEditorModel(
                    leftButtonTitle: TextEditorL10n.cancel,
                    rightButtonTitle: TextEditorL10n.save,
                    textFile: textFile,
                    textEditorMode: textEditorMode,
                    accessLevel: nil
                )
            }
            
            let viewModel = TextEditorViewModel(
                router: mockRouter,
                textFile: textFile,
                textEditorMode: textEditorMode,
                uploadFileUseCase: mockUploadFileUC,
                downloadFileUseCase: mockDownloadFileUC,
                nodeActionUseCase: mockNodeActionUC,
                nodeHandle: mockNodeHandle
            )
            test(viewModel: viewModel,
                 action: .setUpView,
                 expectedCommands: [.configView(textEditorModel)]
            )
        }
    }
    
    func testAction_setUpView_Load_tempDownload_success_read_success() {
        let textFile = TextFile(fileName: "testSuccess")
        let mockRouter = MockTextEditorViewRouter()
        let mockUploadFileUC = MockUploadFileUseCase()
        
        let mockDownloadFileUC = MockDownloadFileUseCase()
        let testPath = (NSTemporaryDirectory() as NSString).appendingPathComponent(textFile.fileName)
        let transferEntity = mockTransferEntity(transferTypeEntity: .download, path: testPath)
        mockDownloadFileUC.transferEntity = transferEntity
        mockDownloadFileUC.result = .success(transferEntity)
        
        let mockNodeActionUC = MockNodeActionUseCase()
        let nodeAccessLevel: NodeAccessTypeEntity = .owner
        mockNodeActionUC.nodeAccessLevel = nodeAccessLevel
        
        let textEditorMode: TextEditorMode = .load
        
        let textEditorLoadModel = TextEditorModel(
            leftButtonTitle: TextEditorL10n.close,
            rightButtonTitle: nil,
            textFile: textFile,
            textEditorMode: .load,
            accessLevel: nil
        )
        
        let textEditorViewModel = TextEditorModel(
            leftButtonTitle: TextEditorL10n.close,
            rightButtonTitle: nil,
            textFile: textFile,
            textEditorMode: .view,
            accessLevel: nodeAccessLevel
        )
        
        let mockNodeHandle: MEGAHandle = 123
        
        let viewModel = TextEditorViewModel(
            router: mockRouter,
            textFile: textFile,
            textEditorMode: textEditorMode,
            uploadFileUseCase: mockUploadFileUC,
            downloadFileUseCase: mockDownloadFileUC,
            nodeActionUseCase: mockNodeActionUC,
            nodeHandle: mockNodeHandle
        )

        guard let transferredBytes = transferEntity.transferredBytes,
              let totalBytes = transferEntity.totalBytes
        else { return }
        let percentage = transferredBytes / totalBytes

        let content = "test"
        do {
            try content.write(toFile: testPath, atomically: true, encoding: .utf8)
            
            test(viewModel: viewModel,
                 action: .setUpView,
                 expectedCommands: [
                    .setupLoadViews,
                    .configView(textEditorLoadModel),
                    .updateProgressView(progress: percentage),
                    .configView(textEditorViewModel)
                 ]
            )

            try FileManager.default.removeItem(atPath: testPath)
        } catch {
            return
        }
    }
    
    func testAction_setUpView_Load_tempDownload_success_read_failed() {
        let textFile = TextFile(fileName: "testFailed")
        let mockRouter = MockTextEditorViewRouter()
        let mockUploadFileUC = MockUploadFileUseCase()
        
        let mockDownloadFileUC = MockDownloadFileUseCase()
        let testPath = (NSTemporaryDirectory() as NSString).appendingPathComponent(textFile.fileName)
        let transferEntity = mockTransferEntity(transferTypeEntity: .download, path: testPath)
        mockDownloadFileUC.transferEntity = transferEntity
        mockDownloadFileUC.result = .success(transferEntity)
        
        let mockNodeActionUC = MockNodeActionUseCase()
        let nodeAccessLevel: NodeAccessTypeEntity = .owner
        mockNodeActionUC.nodeAccessLevel = nodeAccessLevel
        
        let textEditorMode: TextEditorMode = .load
        
        let textEditorLoadModel = TextEditorModel(
            leftButtonTitle: TextEditorL10n.close,
            rightButtonTitle: nil,
            textFile: textFile,
            textEditorMode: .load,
            accessLevel: nil
        )
        
        let mockNodeHandle: MEGAHandle = 123
        
        let viewModel = TextEditorViewModel(
            router: mockRouter,
            textFile: textFile,
            textEditorMode: textEditorMode,
            uploadFileUseCase: mockUploadFileUC,
            downloadFileUseCase: mockDownloadFileUC,
            nodeActionUseCase: mockNodeActionUC,
            nodeHandle: mockNodeHandle
        )

        guard let transferredBytes = transferEntity.transferredBytes,
              let totalBytes = transferEntity.totalBytes
        else { return }
        let percentage = transferredBytes / totalBytes

        test(viewModel: viewModel,
             action: .setUpView,
             expectedCommands: [
                .setupLoadViews,
                .configView(textEditorLoadModel),
                .updateProgressView(progress: percentage)
             ]
        )
        XCTAssertEqual(mockRouter.dismissTextEditorVC_calledTimes, 1)
        XCTAssertEqual(mockRouter.presentPreviewDocVC_calledTimes, 1)
    }
    
    func testAction_setUpView_Load_tempDownload_failed() {
        let textFile = TextFile(fileName: "test")
        let mockRouter = MockTextEditorViewRouter()
        let mockUploadFileUC = MockUploadFileUseCase()
        
        let mockDownloadFileUC = MockDownloadFileUseCase()
        let transferEntity = mockTransferEntity(transferTypeEntity: .download)
        mockDownloadFileUC.result = .failure(TransferErrorEntity.download)
        mockDownloadFileUC.transferEntity = transferEntity
        
        let mockNodeActionUC = MockNodeActionUseCase()
        let nodeAccessLevel: NodeAccessTypeEntity = .owner
        mockNodeActionUC.nodeAccessLevel = nodeAccessLevel
        
        let textEditorMode: TextEditorMode = .load
        
        let textEditorLoadModel = TextEditorModel(
            leftButtonTitle: TextEditorL10n.close,
            rightButtonTitle: nil,
            textFile: textFile,
            textEditorMode: .load,
            accessLevel: nil
        )
        
        let mockNodeHandle: MEGAHandle = 123
        
        let viewModel = TextEditorViewModel(
            router: mockRouter,
            textFile: textFile,
            textEditorMode: textEditorMode,
            uploadFileUseCase: mockUploadFileUC,
            downloadFileUseCase: mockDownloadFileUC,
            nodeActionUseCase: mockNodeActionUC,
            nodeHandle: mockNodeHandle
        )

        guard let transferredBytes = transferEntity.transferredBytes,
              let totalBytes = transferEntity.totalBytes
        else { return }
        let percentage = transferredBytes / totalBytes

        test(viewModel: viewModel,
             action: .setUpView,
             expectedCommands: [
                .setupLoadViews,
                .configView(textEditorLoadModel),
                .updateProgressView(progress: percentage),
                .showError(TextEditorL10n.transferError + " " + TextEditorL10n.download)
             ]
        )
    }

    func testAction_saveText_edit_success() {
        let mockRouter = MockTextEditorViewRouter()
        let mockUploadFileUC = MockUploadFileUseCase()
        mockUploadFileUC.result = .success((mockTransferEntity(transferTypeEntity: .upload)))
        let mockDownloadFileUC = MockDownloadFileUseCase()
        let mockNodeActionUC = MockNodeActionUseCase()
        let nodeAccessLevel: NodeAccessTypeEntity = .owner
        mockNodeActionUC.nodeAccessLevel = nodeAccessLevel
        
        let textFile = TextFile(fileName: "test", content: "test content")
        
        let mockParentHandle: MEGAHandle = 123
        let mockNodeHandle: MEGAHandle = 123

        let viewModel = TextEditorViewModel(
            router: mockRouter,
            textFile: textFile,
            textEditorMode: .edit,
            uploadFileUseCase: mockUploadFileUC,
            downloadFileUseCase: mockDownloadFileUC,
            nodeActionUseCase: mockNodeActionUC,
            parentHandle: mockParentHandle,
            nodeHandle: mockNodeHandle
        )

        let editContent = "edit content"

        let textEditorModel = TextEditorModel(
            leftButtonTitle: TextEditorL10n.close,
            rightButtonTitle: nil,
            textFile: textFile,
            textEditorMode: .view,
            accessLevel: nodeAccessLevel
        )
        test(viewModel: viewModel,
             action: .saveText(editContent),
             expectedCommands: [.startLoading,
                                .stopLoading,
                                .configView(textEditorModel)
             ]
        )
    }
    
    func testAction_saveText_edit_failed() {
        let mockRouter = MockTextEditorViewRouter()
        let mockUploadFileUC = MockUploadFileUseCase()
        mockUploadFileUC.result = .failure(TransferErrorEntity.upload)
        let mockDownloadFileUC = MockDownloadFileUseCase()
        let mockNodeActionUC = MockNodeActionUseCase()
        let textFile = TextFile(fileName: "test", content: "test content")
        
        let mockParentHandle: MEGAHandle = 123

        let viewModel = TextEditorViewModel(
            router: mockRouter,
            textFile: textFile,
            textEditorMode: .edit,
            uploadFileUseCase: mockUploadFileUC,
            downloadFileUseCase: mockDownloadFileUC,
            nodeActionUseCase: mockNodeActionUC,
            parentHandle: mockParentHandle
        )

        let editContent = "edit content"

        test(viewModel: viewModel,
             action: .saveText(editContent),
             expectedCommands: [.startLoading,
                                .stopLoading,
                                .showError(TextEditorL10n.transferError + " " + TextEditorL10n.upload)
             ]
        )
    }

    func testAction_saveText_create_duplicateName() {
        let mockRouter = MockTextEditorViewRouter()
        let mockUploadFileUC = MockUploadFileUseCase()
        mockUploadFileUC.duplicate = true
        let mockDownloadFileUC = MockDownloadFileUseCase()
        let mockNodeActionUC = MockNodeActionUseCase()
        let textFile = TextFile(fileName: "test")
        let textEditorMode: TextEditorMode = .create
        
        let duplicateNameAlertModel = TextEditorDuplicateNameAlertModel(
            alertTitle: String(format: TextEditorL10n.duplicateNameAlertTitle, textFile.fileName),
            alertMessage: TextEditorL10n.duplicateNameAlertMessage,
            cancelButtonTitle: TextEditorL10n.cancel,
            replaceButtonTitle: TextEditorL10n.replace,
            renameButtonTitle: TextEditorL10n.rename
        )

        let viewModel = TextEditorViewModel(
            router: mockRouter,
            textFile: textFile,
            textEditorMode: textEditorMode,
            uploadFileUseCase: mockUploadFileUC,
            downloadFileUseCase: mockDownloadFileUC,
            nodeActionUseCase: mockNodeActionUC
        )
        
        let createContent = "create content"

        test(viewModel: viewModel,
             action: .saveText(createContent),
             expectedCommands: [.showDuplicateNameAlert(duplicateNameAlertModel)]
        )
        XCTAssertEqual(mockRouter.chooseDestination_calledTimes, 1)
    }
    
    func testAction_saveText_create_uniqueName_success() {
        let mockRouter = MockTextEditorViewRouter()
        let mockUploadFileUC = MockUploadFileUseCase()
        mockUploadFileUC.duplicate = false
        mockUploadFileUC.result = .success((mockTransferEntity(transferTypeEntity: .upload)))
        let mockDownloadFileUC = MockDownloadFileUseCase()
        let mockNodeActionUC = MockNodeActionUseCase()
        let textFile = TextFile(fileName: "test")
        let textEditorMode: TextEditorMode = .create

        let viewModel = TextEditorViewModel(
            router: mockRouter,
            textFile: textFile,
            textEditorMode: textEditorMode,
            uploadFileUseCase: mockUploadFileUC,
            downloadFileUseCase: mockDownloadFileUC,
            nodeActionUseCase: mockNodeActionUC
        )
        
        let createContent = "create content"

        test(viewModel: viewModel,
             action: .saveText(createContent),
             expectedCommands: []
        )
        XCTAssertEqual(mockRouter.chooseDestination_calledTimes, 1)
        XCTAssertEqual(mockRouter.dismissTextEditorVC_calledTimes, 1)
        XCTAssertEqual(mockRouter.dismissBrowserVC_calledTimes, 1)
    }
    
    func testAction_saveText_create_uniqueName_failed() {
        let mockRouter = MockTextEditorViewRouter()
        let mockUploadFileUC = MockUploadFileUseCase()
        mockUploadFileUC.duplicate = false
        mockUploadFileUC.result = .failure(TransferErrorEntity.upload)
        let mockDownloadFileUC = MockDownloadFileUseCase()
        let mockNodeActionUC = MockNodeActionUseCase()
        let textFile = TextFile(fileName: "test")
        let textEditorMode: TextEditorMode = .create

        let viewModel = TextEditorViewModel(
            router: mockRouter,
            textFile: textFile,
            textEditorMode: textEditorMode,
            uploadFileUseCase: mockUploadFileUC,
            downloadFileUseCase: mockDownloadFileUC,
            nodeActionUseCase: mockNodeActionUC
        )
        
        let createContent = "create content"

        test(viewModel: viewModel,
             action: .saveText(createContent),
             expectedCommands: [.showError(TextEditorL10n.transferError + " " + TextEditorL10n.upload)]
        )
        XCTAssertEqual(mockRouter.chooseDestination_calledTimes, 1)
        XCTAssertEqual(mockRouter.dismissTextEditorVC_calledTimes, 1)
        XCTAssertEqual(mockRouter.dismissBrowserVC_calledTimes, 1)
    }
    
    func testAction_renameFile_create() {
        let mockRouter = MockTextEditorViewRouter()
        let mockUploadFileUC = MockUploadFileUseCase()
        mockUploadFileUC.duplicate = true
        let mockDownloadFileUC = MockDownloadFileUseCase()
        let mockNodeActionUC = MockNodeActionUseCase()
        let textFile = TextFile(fileName: "test")
        let textEditorMode: TextEditorMode = .create
        
        let renameAlertModel = TextEditorRenameAlertModel(
            alertTitle: TextEditorL10n.rename,
            alertMessage: TextEditorL10n.renameAlertMessage,
            cancelButtonTitle: TextEditorL10n.cancel,
            renameButtonTitle: TextEditorL10n.rename,
            textFileName: textFile.fileName
        )

        let viewModel = TextEditorViewModel(
            router: mockRouter,
            textFile: textFile,
            textEditorMode: textEditorMode,
            uploadFileUseCase: mockUploadFileUC,
            downloadFileUseCase: mockDownloadFileUC,
            nodeActionUseCase: mockNodeActionUC
        )

        test(viewModel: viewModel,
             action: .renameFile,
             expectedCommands: [.showRenameAlert(renameAlertModel)]
        )
    }
    
    func testAction_renameFileTo_create() {
        let mockRouter = MockTextEditorViewRouter()
        let mockUploadFileUC = MockUploadFileUseCase()
        mockUploadFileUC.duplicate = false
        let mockDownloadFileUC = MockDownloadFileUseCase()
        let mockNodeActionUC = MockNodeActionUseCase()
        let textFile = TextFile(fileName: "test")
        let textEditorMode: TextEditorMode = .create
        let mockParentHandle: MEGAHandle = 123
        
        let newName = "new name"

        let viewModel = TextEditorViewModel(
            router: mockRouter,
            textFile: textFile,
            textEditorMode: textEditorMode,
            uploadFileUseCase: mockUploadFileUC,
            downloadFileUseCase: mockDownloadFileUC,
            nodeActionUseCase: mockNodeActionUC,
            parentHandle: mockParentHandle
        )

        test(viewModel: viewModel,
             action: .renameFileTo(newName),
             expectedCommands: []
        )
        
        XCTAssertEqual(mockUploadFileUC.newName, newName)
    }

    func testAction_dismissTextEditorVC() {
        let mockRouter = MockTextEditorViewRouter()
        let mockUploadFileUC = MockUploadFileUseCase()
        let mockDownloadFileUC = MockDownloadFileUseCase()
        let mockNodeActionUC = MockNodeActionUseCase()
        let textFile = TextFile(fileName: "test")

        for (index, textEditorMode) in TextEditorMode.allCases.enumerated() {
            let viewModel = TextEditorViewModel(
                router: mockRouter,
                textFile: textFile,
                textEditorMode: textEditorMode,
                uploadFileUseCase: mockUploadFileUC,
                downloadFileUseCase: mockDownloadFileUC,
                nodeActionUseCase: mockNodeActionUC
            )

            test(viewModel: viewModel,
                 action: .dismissTextEditorVC,
                 expectedCommands: []
            )
            XCTAssertEqual(mockRouter.dismissTextEditorVC_calledTimes, index + 1)
        }
    }
    
    func testAction_showActions_view() {
        let mockRouter = MockTextEditorViewRouter()
        let mockUploadFileUC = MockUploadFileUseCase()
        let mockDownloadFileUC = MockDownloadFileUseCase()
        let mockNodeActionUC = MockNodeActionUseCase()
        let textFile = TextFile(fileName: "test")

        let viewModel = TextEditorViewModel(
            router: mockRouter,
            textFile: textFile,
            textEditorMode: .view,
            uploadFileUseCase: mockUploadFileUC,
            downloadFileUseCase: mockDownloadFileUC,
            nodeActionUseCase: mockNodeActionUC
        )

        test(viewModel: viewModel,
             action: .showActions(sender: UIButton()),
             expectedCommands: []
        )
        XCTAssertEqual(mockRouter.showActions_calledTimes, 1)
    }
    
    func testAction_cancel_create() {
        let mockRouter = MockTextEditorViewRouter()
        let mockUploadFileUC = MockUploadFileUseCase()
        let mockDownloadFileUC = MockDownloadFileUseCase()
        let mockNodeActionUC = MockNodeActionUseCase()
        let textFile = TextFile(fileName: "test")

        let viewModel = TextEditorViewModel(
            router: mockRouter,
            textFile: textFile,
            textEditorMode: .create,
            uploadFileUseCase: mockUploadFileUC,
            downloadFileUseCase: mockDownloadFileUC,
            nodeActionUseCase: mockNodeActionUC
        )

        test(viewModel: viewModel,
             action: .cancel,
             expectedCommands: []
        )
        XCTAssertEqual(mockRouter.dismissTextEditorVC_calledTimes, 1)
    }
    
    func testAction_cancel_edit() {
        let mockRouter = MockTextEditorViewRouter()
        let mockUploadFileUC = MockUploadFileUseCase()
        let mockDownloadFileUC = MockDownloadFileUseCase()
        let mockNodeActionUC = MockNodeActionUseCase()
        let nodeAccessLevel: NodeAccessTypeEntity = .owner
        mockNodeActionUC.nodeAccessLevel = nodeAccessLevel
        let textFile = TextFile(fileName: "test")
        
        let mockNodeHandle: MEGAHandle = 123

        let viewModel = TextEditorViewModel(
            router: mockRouter,
            textFile: textFile,
            textEditorMode: .edit,
            uploadFileUseCase: mockUploadFileUC,
            downloadFileUseCase: mockDownloadFileUC,
            nodeActionUseCase: mockNodeActionUC,
            nodeHandle: mockNodeHandle
        )

        let textEditorModel = TextEditorModel(
            leftButtonTitle: TextEditorL10n.close,
            rightButtonTitle: nil,
            textFile: textFile,
            textEditorMode: .view,
            accessLevel: nodeAccessLevel
        )
        test(viewModel: viewModel,
             action: .cancel,
             expectedCommands: [.configView(textEditorModel)]
        )
    }
    
    func testAction_downloadToOffline_view() {
        let mockRouter = MockTextEditorViewRouter()
        let mockUploadFileUC = MockUploadFileUseCase()
        let mockDownloadFileUC = MockDownloadFileUseCase()
        let mockNodeActionUC = MockNodeActionUseCase()
        let textFile = TextFile(fileName: "test")

        let viewModel = TextEditorViewModel(
            router: mockRouter,
            textFile: textFile,
            textEditorMode: .view,
            uploadFileUseCase: mockUploadFileUC,
            downloadFileUseCase: mockDownloadFileUC,
            nodeActionUseCase: mockNodeActionUC
        )

        test(viewModel: viewModel,
             action: .downloadToOffline,
             expectedCommands: [.startDownload(status: TextEditorL10n.downloadMessage)]
        )
    }
    
    func testAction_importNode_view() {
        let mockRouter = MockTextEditorViewRouter()
        let mockUploadFileUC = MockUploadFileUseCase()
        let mockDownloadFileUC = MockDownloadFileUseCase()
        let mockNodeActionUC = MockNodeActionUseCase()
        let textFile = TextFile(fileName: "test")

        let viewModel = TextEditorViewModel(
            router: mockRouter,
            textFile: textFile,
            textEditorMode: .view,
            uploadFileUseCase: mockUploadFileUC,
            downloadFileUseCase: mockDownloadFileUC,
            nodeActionUseCase: mockNodeActionUC
        )

        test(viewModel: viewModel,
             action: .importNode,
             expectedCommands: []
        )
        XCTAssertEqual(mockRouter.importNode_calledTimes, 1)
    }
    
    func testAction_share_view() {
        let mockRouter = MockTextEditorViewRouter()
        let mockUploadFileUC = MockUploadFileUseCase()
        let mockDownloadFileUC = MockDownloadFileUseCase()
        let mockNodeActionUC = MockNodeActionUseCase()
        let textFile = TextFile(fileName: "test")

        let viewModel = TextEditorViewModel(
            router: mockRouter,
            textFile: textFile,
            textEditorMode: .view,
            uploadFileUseCase: mockUploadFileUC,
            downloadFileUseCase: mockDownloadFileUC,
            nodeActionUseCase: mockNodeActionUC
        )

        test(viewModel: viewModel,
             action: .share(sender: UIButton()),
             expectedCommands: []
        )
        XCTAssertEqual(mockRouter.share_calledTimes, 1)
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
            speed: nil,
            deltaSize: nil,
            updateTime: nil,
            publicNode: nil,
            isStreamingTransfer: false,
            isFolderTransfer: false,
            folderTransferTag: .zero,
            appData: nil,
            state: .none,
            priority: 123
        )
    }
}

final class MockTextEditorViewRouter: TextEditorViewRouting {
    
    var dismissTextEditorVC_calledTimes = 0
    var dismissBrowserVC_calledTimes = 0
    var chooseDestination_calledTimes = 0
    var showActions_calledTimes = 0
    var reloadData_calledTimes = 0
    var presentPreviewDocVC_calledTimes = 0
    var importNode_calledTimes = 0
    var share_calledTimes = 0
    
    func chooseParentNode(completion: @escaping (MEGAHandle) -> Void) {
        chooseDestination_calledTimes += 1
        completion(123)
    }
    
    func dismissTextEditorVC() {
        dismissTextEditorVC_calledTimes += 1
    }
    
    func dismissBrowserVC() {
        dismissBrowserVC_calledTimes += 1
    }
    
    func showActions(sender button: Any, handle: MEGAHandle?) {
        showActions_calledTimes += 1
    }
    
    func showPreviewDocVC(fromFilePath path: String) {
        presentPreviewDocVC_calledTimes += 1
    }
    
    func importNode(nodeHandle: MEGAHandle?) {
        importNode_calledTimes += 1
    }
    
    func share(nodeHandle: MEGAHandle?, sender button: Any) {
        share_calledTimes += 1
    }
}
