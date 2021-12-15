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
        mockNodeActionUC.nodeAccessLevelVariable = nodeAccessLevel
        
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
                    leftItem: NavbarItemModel(title: Strings.Localizable.close, imageName: nil),
                    rightItem: NavbarItemModel(title: nil, imageName: "moreNavigationBar"),
                    textEditorMode: textEditorMode
                )
            } else {
                navbarItemsModel = TextEditorNavbarItemsModel (
                    leftItem: NavbarItemModel(title: Strings.Localizable.cancel, imageName: nil),
                    rightItem: NavbarItemModel(title: Strings.Localizable.save, imageName: nil),
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
                    .configView(textEditorModel, shallUpdateContent: true),
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
        mockNodeActionUC.nodeAccessLevelVariable = nodeAccessLevel
        
        let textEditorMode: TextEditorMode = .load
        
        let textEditorLoadModel = TextEditorModel(
            textFile: textFile,
            textEditorMode: textEditorMode,
            accessLevel: nil
        )
        
        let navbarItemsLoadModel = TextEditorNavbarItemsModel (
            leftItem: NavbarItemModel(title: Strings.Localizable.close, imageName: nil),
            rightItem: nil,
            textEditorMode: textEditorMode
        )
        
        let textEditorViewModel = TextEditorModel(
            textFile: textFile,
            textEditorMode: .view,
            accessLevel: nodeAccessLevel
        )
        
        let navbarItemsViewModel = TextEditorNavbarItemsModel (
            leftItem: NavbarItemModel(title: Strings.Localizable.close, imageName: nil),
            rightItem: NavbarItemModel(title: nil, imageName: "moreNavigationBar"),
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

        let percentage = Float(transferEntity.transferredBytes) / Float(transferEntity.totalBytes)

        let content = "test"
        do {
            try content.write(toFile: testPath, atomically: true, encoding: .utf8)
            
            test(viewModel: viewModel,
                 action: .setUpView,
                 expectedCommands: [
                    .setupLoadViews,
                    .configView(textEditorLoadModel, shallUpdateContent: false),
                    .setupNavbarItems(navbarItemsLoadModel),
                    .updateProgressView(progress: percentage),
                    .configView(textEditorViewModel, shallUpdateContent: true),
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
        mockNodeActionUC.nodeAccessLevelVariable = nodeAccessLevel
        
        let textEditorMode: TextEditorMode = .load
        
        let textEditorLoadModel = TextEditorModel(
            textFile: textFile,
            textEditorMode: textEditorMode,
            accessLevel: nil
        )
        
        let navbarItemsModel = TextEditorNavbarItemsModel (
            leftItem: NavbarItemModel(title: Strings.Localizable.close, imageName: nil),
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

        let percentage = Float(transferEntity.transferredBytes) / Float(transferEntity.totalBytes)

        test(viewModel: viewModel,
             action: .setUpView,
             expectedCommands: [
                .setupLoadViews,
                .configView(textEditorLoadModel, shallUpdateContent: false),
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
        mockNodeActionUC.nodeAccessLevelVariable = nodeAccessLevel
        
        let textEditorMode: TextEditorMode = .load
        
        let textEditorLoadModel = TextEditorModel(
            textFile: textFile,
            textEditorMode: textEditorMode,
            accessLevel: nil
        )
        
        let navbarItemsModel = TextEditorNavbarItemsModel (
            leftItem: NavbarItemModel(title: Strings.Localizable.close, imageName: nil),
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

        let percentage = Float(transferEntity.transferredBytes) / Float(transferEntity.totalBytes)

        test(viewModel: viewModel,
             action: .setUpView,
             expectedCommands: [
                .setupLoadViews,
                .configView(textEditorLoadModel, shallUpdateContent: false),
                .setupNavbarItems(navbarItemsModel),
                .updateProgressView(progress: percentage),
                .showError(message: Strings.Localizable.transferFailed + " " + Strings.Localizable.download)
             ]
        )
    }

    func testAction_saveText_edit_success() {
        let textFile = TextFile(
            fileName: "testAction_saveText_edit_success",
            content: "test content",
            size: 0,
            encode: String.Encoding.utf8.rawValue
        )
        let mockRouter = MockTextEditorViewRouter()
        let mockUploadFileUC = MockUploadFileUseCase()
        mockUploadFileUC.result = .success((mockTransferEntity(transferTypeEntity: .upload)))
        let mockDownloadFileUC = MockDownloadFileUseCase()
        let mockNodeActionUC = MockNodeActionUseCase()
        let nodeAccessLevel: NodeAccessTypeEntity = .owner
        mockNodeActionUC.nodeAccessLevelVariable = nodeAccessLevel
        
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
            leftItem: NavbarItemModel(title: Strings.Localizable.close, imageName: nil),
            rightItem: NavbarItemModel(title: nil, imageName: "moreNavigationBar"),
            textEditorMode: .view
        )
        
        test(viewModel: viewModel,
             action: .saveText(content: editContent),
             expectedCommands: [
                .startLoading,
                .stopLoading,
                .configView(textEditorViewModel, shallUpdateContent: false),
                .setupNavbarItems(navbarItemsModel)
             ]
        )
    }
    
    func testAction_saveText_edit_failed() {
        let textFile = TextFile(
            fileName: "testAction_saveText_edit_failed",
            content: "test content",
            size: 0,
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
             action: .saveText(content: editContent),
             expectedCommands: [.startLoading,
                                .stopLoading,
                                .showError(message: Strings.Localizable.transferFailed + " " + Strings.Localizable.upload)
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
            downloadFileUseCase: mockDownloadFileUC,
            nodeActionUseCase: mockNodeActionUC,
            parentHandle: mockParentHandle
        )
        
        let createContent = "create content"

        test(viewModel: viewModel,
             action: .saveText(content: createContent),
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
             action: .saveText(content: createContent),
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
             action: .saveText(content: createContent),
             expectedCommands: [.showError(message: Strings.Localizable.transferFailed + " " + Strings.Localizable.upload)]
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
            downloadFileUseCase: mockDownloadFileUC,
            nodeActionUseCase: mockNodeActionUC
        )
        
        let createContent = "create content"

        test(viewModel: viewModel,
             action: .saveText(content: createContent),
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
             action: .saveText(content: createContent),
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
             action: .saveText(content: createContent),
             expectedCommands: [.showError(message: Strings.Localizable.transferFailed + " " + Strings.Localizable.upload)]
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
             action: .renameFileTo(newInputName: newName),
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
    
    func testAction_editFile_view_editableSize() {
        let textFile = TextFile(
            fileName: "testAction_editFile_view_editableSize",
            content: "test content",
            size: TextFile.maxEditableFileSize - 1,
            encode: String.Encoding.utf8.rawValue
        )
        
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
        
        let textEditorModel = TextEditorModel(
            textFile: textFile,
            textEditorMode: .edit,
            accessLevel: nil
        )
        
        let navbarItemsModel = TextEditorNavbarItemsModel (
            leftItem: NavbarItemModel(title: Strings.Localizable.cancel, imageName: nil),
            rightItem: NavbarItemModel(title: Strings.Localizable.save, imageName: nil),
            textEditorMode: .edit
        )

        test(viewModel: viewModel,
             action: .editFile,
             expectedCommands: [
                .configView(textEditorModel, shallUpdateContent: false),
                .setupNavbarItems(navbarItemsModel)
             ]
        )
    }
    
    func testAction_editFile_view_ineditableSize() {
        let textFile = TextFile(
            fileName: "testAction_editFile_view_editableSize",
            content: "test content",
            size: TextFile.maxEditableFileSize,
            encode: String.Encoding.utf8.rawValue
        )
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
             action: .editFile,
             expectedCommands: [.showError(message: Strings.Localizable.General.TextEditor.Hud.uneditableLargeFile)]
        )
    }
    
    func testAction_editAfterOpen_view_editableSize() {
        let textFile = TextFile(
            fileName: "testAction_editAfterOpen_view_editableSize",
            content: "test content",
            size: TextFile.maxEditableFileSize - 1,
            encode: String.Encoding.utf8.rawValue
        )
        
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
        
        let textEditorModel = TextEditorModel(
            textFile: textFile,
            textEditorMode: .edit,
            accessLevel: nil
        )
        
        let navbarItemsModel = TextEditorNavbarItemsModel (
            leftItem: NavbarItemModel(title: Strings.Localizable.cancel, imageName: nil),
            rightItem: NavbarItemModel(title: Strings.Localizable.save, imageName: nil),
            textEditorMode: .edit
        )

        test(viewModel: viewModel,
             action: .editAfterOpen,
             expectedCommands: [
                .configView(textEditorModel, shallUpdateContent: true),
                .setupNavbarItems(navbarItemsModel)
             ]
        )
    }
    
    func testAction_editAfterOpen_view_ineditableSize() {
        let textFile = TextFile(
            fileName: "testAction_editAfterOpen_view_ineditableSize",
            content: "test content",
            size: TextFile.maxEditableFileSize,
            encode: String.Encoding.utf8.rawValue
        )
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
             action: .editAfterOpen,
             expectedCommands: [.showError(message: Strings.Localizable.General.TextEditor.Hud.uneditableLargeFile)]
        )
    }
    
    func testAction_editAfterOpen_load() {
        let textFile = TextFile(
            fileName: "testAction_editAfterOpen_load",
            content: "test content",
            size: TextFile.maxEditableFileSize,
            encode: String.Encoding.utf8.rawValue
        )
        let mockRouter = MockTextEditorViewRouter()
        let mockUploadFileUC = MockUploadFileUseCase()
        let mockDownloadFileUC = MockDownloadFileUseCase()
        let mockNodeActionUC = MockNodeActionUseCase()

        let viewModel = TextEditorViewModel(
            router: mockRouter,
            textFile: textFile,
            textEditorMode: .load,
            uploadFileUseCase: mockUploadFileUC,
            downloadFileUseCase: mockDownloadFileUC,
            nodeActionUseCase: mockNodeActionUC
        )

        test(viewModel: viewModel,
             action: .editAfterOpen,
             expectedCommands: []
        )
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
                 action: .cancelText(content: newContent),
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
             action: .cancelText(content: textFile.content),
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
        mockNodeActionUC.nodeAccessLevelVariable = nodeAccessLevel
        
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
            leftItem: NavbarItemModel(title: Strings.Localizable.close, imageName: nil),
            rightItem: NavbarItemModel(title: nil, imageName: "moreNavigationBar"),
            textEditorMode: .view
        )
        
        test(viewModel: viewModel,
             action: .cancelText(content: textFile.content),
             expectedCommands: [
                .configView(textEditorViewModel, shallUpdateContent: true),
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
             expectedCommands: [.startDownload(status: Strings.Localizable.downloadStarted)]
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
    
    func showPreviewDocVC(fromFilePath path: String, showUneditableError: Bool) {
        presentPreviewDocVC_calledTimes += 1
    }
    
    func importNode(nodeHandle: MEGAHandle?) {
        importNode_calledTimes += 1
    }
    
    func share(nodeHandle: MEGAHandle?, sender button: Any) {
        share_calledTimes += 1
    }
}
