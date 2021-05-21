import XCTest
@testable import MEGA

final class TextEditorViewModelTests: XCTestCase {

    func testAction_setUpView_View_Create_Edit() {
        let textFile = TextFile(fileName: "testAction_setUpView_View_Create_Edit")
        let mockRouter = MockTextEditorViewRouter()
        let mockUploadFileUC = MockUploadFileUseCase()
        let mockDownloadFileUC = MockDownloadFileUseCase()
        let mockNodeActionUC = MockNodeActionUseCase()
        let nodeAccessLevel: NodeAccessTypeEntity = .owner
        mockNodeActionUC.nodeAccessLevel = nodeAccessLevel
        
        let mockNodeHandle: MEGAHandle = 123
        
        var textEditorModel: TextEditorModel
        var navbarItemsModel: TextEditorNavbarItemsModel
        
        let testModes: [TextEditorMode] = [.view, .create, .edit]
        for textEditorMode in testModes {
            if textEditorMode == .view {
                textEditorModel = TextEditorModel(
                    textFile: textFile,
                    textEditorMode: textEditorMode,
                    accessLevel: nodeAccessLevel
                )
            } else {
                textEditorModel = TextEditorModel(
                    textFile: textFile,
                    textEditorMode: textEditorMode,
                    accessLevel: nil
                )
            }
            
            if textEditorMode == .view {
                navbarItemsModel = TextEditorNavbarItemsModel (
                    leftItem: NavbarItemModel(title: TextEditorL10n.close, imageName: nil),
                    rightItem: NavbarItemModel(title: nil, imageName: "moreSelected"),
                    textEditorMode: textEditorMode
                )
            } else {
                navbarItemsModel = TextEditorNavbarItemsModel (
                    leftItem: NavbarItemModel(title: TextEditorL10n.cancel, imageName: nil),
                    rightItem: NavbarItemModel(title: TextEditorL10n.save, imageName: nil),
                    textEditorMode: textEditorMode
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
                 expectedCommands: [
                    .configView(textEditorModel),
                    .setupNavbarItems(navbarItemsModel)
                 ]
            )
        }
    }
    
    func testAction_setUpView_Load_tempDownload_success_read_success() {
        let textFile = TextFile(fileName: "testAction_setUpView_Load_tempDownload_success_read_success")
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
            textFile: textFile,
            textEditorMode: textEditorMode,
            accessLevel: nil
        )
        
        let navbarItemsLoadModel = TextEditorNavbarItemsModel (
            leftItem: NavbarItemModel(title: TextEditorL10n.close, imageName: nil),
            rightItem: nil,
            textEditorMode: textEditorMode
        )
        
        let textEditorViewModel = TextEditorModel(
            textFile: textFile,
            textEditorMode: .view,
            accessLevel: nodeAccessLevel
        )
        
        let navbarItemsViewModel = TextEditorNavbarItemsModel (
            leftItem: NavbarItemModel(title: TextEditorL10n.close, imageName: nil),
            rightItem: NavbarItemModel(title: nil, imageName: "moreSelected"),
            textEditorMode: .view
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
                    .setupNavbarItems(navbarItemsLoadModel),
                    .updateProgressView(progress: percentage),
                    .configView(textEditorViewModel),
                    .setupNavbarItems(navbarItemsViewModel)
                 ]
            )

            try FileManager.default.removeItem(atPath: testPath)
        } catch {
            return
        }
    }
    
    func testAction_setUpView_Load_tempDownload_success_read_failed() {
        let textFile = TextFile(fileName: "testAction_setUpView_Load_tempDownload_success_read_failed")
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
            textFile: textFile,
            textEditorMode: textEditorMode,
            accessLevel: nil
        )
        
        let navbarItemsModel = TextEditorNavbarItemsModel (
            leftItem: NavbarItemModel(title: TextEditorL10n.close, imageName: nil),
            rightItem: nil,
            textEditorMode: textEditorMode
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
                .setupNavbarItems(navbarItemsModel),
                .updateProgressView(progress: percentage)
             ]
        )
        XCTAssertEqual(mockRouter.presentPreviewDocVC_calledTimes, 1)
    }
    
    func testAction_setUpView_Load_tempDownload_failed() {
        let textFile = TextFile(fileName: "testAction_setUpView_Load_tempDownload_failed")
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
            textFile: textFile,
            textEditorMode: textEditorMode,
            accessLevel: nil
        )
        
        let navbarItemsModel = TextEditorNavbarItemsModel (
            leftItem: NavbarItemModel(title: TextEditorL10n.close, imageName: nil),
            rightItem: nil,
            textEditorMode: textEditorMode
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
                .setupNavbarItems(navbarItemsModel),
                .updateProgressView(progress: percentage),
                .showError(TextEditorL10n.transferError + " " + TextEditorL10n.download)
             ]
        )
    }

    func testAction_saveText_edit_success() {
        let textFile = TextFile(
            fileName: "testAction_saveText_edit_success",
            content: "test content",
            encode: String.Encoding.utf8.rawValue
        )
        let mockRouter = MockTextEditorViewRouter()
        let mockUploadFileUC = MockUploadFileUseCase()
        mockUploadFileUC.result = .success((mockTransferEntity(transferTypeEntity: .upload)))
        let mockDownloadFileUC = MockDownloadFileUseCase()
        let mockNodeActionUC = MockNodeActionUseCase()
        let nodeAccessLevel: NodeAccessTypeEntity = .owner
        mockNodeActionUC.nodeAccessLevel = nodeAccessLevel
        
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

        let textEditorViewModel = TextEditorModel(
            textFile: textFile,
            textEditorMode: .view,
            accessLevel: nodeAccessLevel
        )
        
        let navbarItemsModel = TextEditorNavbarItemsModel (
            leftItem: NavbarItemModel(title: TextEditorL10n.close, imageName: nil),
            rightItem: NavbarItemModel(title: nil, imageName: "moreSelected"),
            textEditorMode: .view
        )
        
        test(viewModel: viewModel,
             action: .saveText(editContent),
             expectedCommands: [
                .startLoading,
                .stopLoading,
                .configView(textEditorViewModel),
                .setupNavbarItems(navbarItemsModel)
             ]
        )
    }
    
    func testAction_saveText_edit_failed() {
        let textFile = TextFile(
            fileName: "testAction_saveText_edit_failed",
            content: "test content",
            encode: String.Encoding.utf8.rawValue
        )
        let mockRouter = MockTextEditorViewRouter()
        let mockUploadFileUC = MockUploadFileUseCase()
        mockUploadFileUC.result = .failure(TransferErrorEntity.upload)
        let mockDownloadFileUC = MockDownloadFileUseCase()
        let mockNodeActionUC = MockNodeActionUseCase()
        
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
    
    func testAction_saveText_create_hasParent_duplicateName() {
        let textFile = TextFile(fileName: "testAction_saveText_create_hasParent_duplicateName")
        let mockRouter = MockTextEditorViewRouter()
        let mockUploadFileUC = MockUploadFileUseCase()
        mockUploadFileUC.duplicate = true
        let mockDownloadFileUC = MockDownloadFileUseCase()
        let mockNodeActionUC = MockNodeActionUseCase()
        let textEditorMode: TextEditorMode = .create
        let mockParentHandle: MEGAHandle = 123
        
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
            nodeActionUseCase: mockNodeActionUC,
            parentHandle: mockParentHandle
        )
        
        let createContent = "create content"

        test(viewModel: viewModel,
             action: .saveText(createContent),
             expectedCommands: [.showDuplicateNameAlert(duplicateNameAlertModel)]
        )
        XCTAssertEqual(mockRouter.chooseDestination_calledTimes, 0)
    }
    
    func testAction_saveText_create_hasParent_uniqueName_success() {
        let textFile = TextFile(fileName: "testAction_saveText_create_hasParent_uniqueName_success")
        let mockRouter = MockTextEditorViewRouter()
        let mockUploadFileUC = MockUploadFileUseCase()
        mockUploadFileUC.duplicate = false
        mockUploadFileUC.result = .success((mockTransferEntity(transferTypeEntity: .upload)))
        let mockDownloadFileUC = MockDownloadFileUseCase()
        let mockNodeActionUC = MockNodeActionUseCase()
        let textEditorMode: TextEditorMode = .create
        let mockParentHandle: MEGAHandle = 123

        let viewModel = TextEditorViewModel(
            router: mockRouter,
            textFile: textFile,
            textEditorMode: textEditorMode,
            uploadFileUseCase: mockUploadFileUC,
            downloadFileUseCase: mockDownloadFileUC,
            nodeActionUseCase: mockNodeActionUC,
            parentHandle: mockParentHandle
        )
        
        let createContent = "create content"

        test(viewModel: viewModel,
             action: .saveText(createContent),
             expectedCommands: []
        )
        XCTAssertEqual(mockRouter.chooseDestination_calledTimes, 0)
        XCTAssertEqual(mockRouter.dismissTextEditorVC_calledTimes, 1)
        XCTAssertEqual(mockRouter.dismissBrowserVC_calledTimes, 1)
    }
    
    func testAction_saveText_create_hasParent_uniqueName_failed() {
        let textFile = TextFile(fileName: "testAction_saveText_create_hasParent_uniqueName_failed")
        let mockRouter = MockTextEditorViewRouter()
        let mockUploadFileUC = MockUploadFileUseCase()
        mockUploadFileUC.duplicate = false
        mockUploadFileUC.result = .failure(TransferErrorEntity.upload)
        let mockDownloadFileUC = MockDownloadFileUseCase()
        let mockNodeActionUC = MockNodeActionUseCase()
        let textEditorMode: TextEditorMode = .create
        let mockParentHandle: MEGAHandle = 123

        let viewModel = TextEditorViewModel(
            router: mockRouter,
            textFile: textFile,
            textEditorMode: textEditorMode,
            uploadFileUseCase: mockUploadFileUC,
            downloadFileUseCase: mockDownloadFileUC,
            nodeActionUseCase: mockNodeActionUC,
            parentHandle: mockParentHandle
        )
        
        let createContent = "create content"

        test(viewModel: viewModel,
             action: .saveText(createContent),
             expectedCommands: [.showError(TextEditorL10n.transferError + " " + TextEditorL10n.upload)]
        )
        XCTAssertEqual(mockRouter.chooseDestination_calledTimes, 0)
        XCTAssertEqual(mockRouter.dismissTextEditorVC_calledTimes, 1)
        XCTAssertEqual(mockRouter.dismissBrowserVC_calledTimes, 1)
    }

    func testAction_saveText_create_noParent_duplicateName() {
        let textFile = TextFile(fileName: "testAction_saveText_create_noParent_duplicateName")
        let mockRouter = MockTextEditorViewRouter()
        let mockUploadFileUC = MockUploadFileUseCase()
        mockUploadFileUC.duplicate = true
        let mockDownloadFileUC = MockDownloadFileUseCase()
        let mockNodeActionUC = MockNodeActionUseCase()
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
    
    func testAction_saveText_create_noParent_uniqueName_success() {
        let textFile = TextFile(fileName: "testAction_saveText_create_noParent_uniqueName_success")
        let mockRouter = MockTextEditorViewRouter()
        let mockUploadFileUC = MockUploadFileUseCase()
        mockUploadFileUC.duplicate = false
        mockUploadFileUC.result = .success((mockTransferEntity(transferTypeEntity: .upload)))
        let mockDownloadFileUC = MockDownloadFileUseCase()
        let mockNodeActionUC = MockNodeActionUseCase()
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
    
    func testAction_saveText_create_noParent_uniqueName_failed() {
        let textFile = TextFile(fileName: "testAction_saveText_create_noParent_uniqueName_failed")
        let mockRouter = MockTextEditorViewRouter()
        let mockUploadFileUC = MockUploadFileUseCase()
        mockUploadFileUC.duplicate = false
        mockUploadFileUC.result = .failure(TransferErrorEntity.upload)
        let mockDownloadFileUC = MockDownloadFileUseCase()
        let mockNodeActionUC = MockNodeActionUseCase()
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
        let textFile = TextFile(fileName: "testAction_renameFile_create")
        let mockRouter = MockTextEditorViewRouter()
        let mockUploadFileUC = MockUploadFileUseCase()
        mockUploadFileUC.duplicate = true
        let mockDownloadFileUC = MockDownloadFileUseCase()
        let mockNodeActionUC = MockNodeActionUseCase()
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
        let textFile = TextFile(fileName: "testAction_renameFileTo_create")
        let mockRouter = MockTextEditorViewRouter()
        let mockUploadFileUC = MockUploadFileUseCase()
        mockUploadFileUC.duplicate = false
        let mockDownloadFileUC = MockDownloadFileUseCase()
        let mockNodeActionUC = MockNodeActionUseCase()
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
        let textFile = TextFile(fileName: "testAction_dismissTextEditorVC")
        let mockRouter = MockTextEditorViewRouter()
        let mockUploadFileUC = MockUploadFileUseCase()
        let mockDownloadFileUC = MockDownloadFileUseCase()
        let mockNodeActionUC = MockNodeActionUseCase()

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
        let textFile = TextFile(fileName: "testAction_showActions_view")
        let mockRouter = MockTextEditorViewRouter()
        let mockUploadFileUC = MockUploadFileUseCase()
        let mockDownloadFileUC = MockDownloadFileUseCase()
        let mockNodeActionUC = MockNodeActionUseCase()

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
    
    func testAction_cancel_create_edit_contentChange() {
        let textFile = TextFile(fileName: "testAction_cancel_contentChange")
        let mockRouter = MockTextEditorViewRouter()
        let mockUploadFileUC = MockUploadFileUseCase()
        let mockDownloadFileUC = MockDownloadFileUseCase()
        let mockNodeActionUC = MockNodeActionUseCase()
    
        let newContent = "new content"
        
        let testModes: [TextEditorMode] = [.create, .edit]
        for textEditorMode in testModes {
            let viewModel = TextEditorViewModel(
                router: mockRouter,
                textFile: textFile,
                textEditorMode: textEditorMode,
                uploadFileUseCase: mockUploadFileUC,
                downloadFileUseCase: mockDownloadFileUC,
                nodeActionUseCase: mockNodeActionUC
            )

            test(viewModel: viewModel,
                 action: .cancelText(newContent),
                 expectedCommands: [.showDiscardChangeAlert]
            )
        }
    }
    
    func testAction_cancel_create_noContentChange() {
        let textFile = TextFile(fileName: "testAction_cancel_create_noContentChange")
        let mockRouter = MockTextEditorViewRouter()
        let mockUploadFileUC = MockUploadFileUseCase()
        let mockDownloadFileUC = MockDownloadFileUseCase()
        let mockNodeActionUC = MockNodeActionUseCase()

        let viewModel = TextEditorViewModel(
            router: mockRouter,
            textFile: textFile,
            textEditorMode: .create,
            uploadFileUseCase: mockUploadFileUC,
            downloadFileUseCase: mockDownloadFileUC,
            nodeActionUseCase: mockNodeActionUC
        )

        test(viewModel: viewModel,
             action: .cancelText(textFile.content),
             expectedCommands: []
        )
        XCTAssertEqual(mockRouter.dismissTextEditorVC_calledTimes, 1)
    }
    
    func testAction_cancel_edit_noContentChange() {
        let textFile = TextFile(fileName: "testAction_cancel_edit_noContentChange")
        let mockRouter = MockTextEditorViewRouter()
        let mockUploadFileUC = MockUploadFileUseCase()
        let mockDownloadFileUC = MockDownloadFileUseCase()
        let mockNodeActionUC = MockNodeActionUseCase()
        let nodeAccessLevel: NodeAccessTypeEntity = .owner
        mockNodeActionUC.nodeAccessLevel = nodeAccessLevel
        
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

        let textEditorViewModel = TextEditorModel(
            textFile: textFile,
            textEditorMode: .view,
            accessLevel: nodeAccessLevel
        )
        
        let navbarItemsModel = TextEditorNavbarItemsModel (
            leftItem: NavbarItemModel(title: TextEditorL10n.close, imageName: nil),
            rightItem: NavbarItemModel(title: nil, imageName: "moreSelected"),
            textEditorMode: .view
        )
        
        test(viewModel: viewModel,
             action: .cancelText(textFile.content),
             expectedCommands: [
                .configView(textEditorViewModel),
                .setupNavbarItems(navbarItemsModel)
             ]
        )
    }
    
    func testAction_downloadToOffline_view() {
        let textFile = TextFile(fileName: "testAction_downloadToOffline_view")
        let mockRouter = MockTextEditorViewRouter()
        let mockUploadFileUC = MockUploadFileUseCase()
        let mockDownloadFileUC = MockDownloadFileUseCase()
        let mockNodeActionUC = MockNodeActionUseCase()

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
        let textFile = TextFile(fileName: "testAction_importNode_view")
        let mockRouter = MockTextEditorViewRouter()
        let mockUploadFileUC = MockUploadFileUseCase()
        let mockDownloadFileUC = MockDownloadFileUseCase()
        let mockNodeActionUC = MockNodeActionUseCase()

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
        let textFile = TextFile(fileName: "testAction_share_view")
        let mockRouter = MockTextEditorViewRouter()
        let mockUploadFileUC = MockUploadFileUseCase()
        let mockDownloadFileUC = MockDownloadFileUseCase()
        let mockNodeActionUC = MockNodeActionUseCase()

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
    
    func showActions(sender button: Any) {
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
