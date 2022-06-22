import XCTest
@testable import MEGA

class ActionViewModelTests: XCTestCase {
    
    func test_fileActionsShouldShowItemView() {
        let nameCollisionAction = NameCollisionAction(actionType: .merge, name: "File name", isFile: true, itemPlaceholder: "")
        let viewModel = ActionViewModel(collisionType: .upload, actionItem: nameCollisionAction)
        
        XCTAssert(viewModel.showItemView == true)
    }
    
    func test_folderActionShouldNotShowItemView() {
        let nameCollisionAction = NameCollisionAction(actionType: .merge, name: "Folder name", isFile: false, itemPlaceholder: "")
        let viewModel = ActionViewModel(collisionType: .upload, actionItem: nameCollisionAction)
        
        XCTAssert(viewModel.showItemView == false)
    }
    
    func test_actionWithName() {
        let nameCollisionAction = NameCollisionAction(actionType: .merge, name: "name", isFile: true, itemPlaceholder: "")
        let viewModel = ActionViewModel(collisionType: .upload, actionItem: nameCollisionAction)
        XCTAssert(viewModel.itemName == nameCollisionAction.name)
    }
    
    func test_actionWithoutName() {
        let nameCollisionAction = NameCollisionAction(actionType: .merge, isFile: true, itemPlaceholder: "")
        let viewModel = ActionViewModel(collisionType: .upload, actionItem: nameCollisionAction)
        XCTAssert(viewModel.itemName == "")
    }
    
    func test_titleForUploadCollisionMergeAction() {
        let nameCollisionAction = NameCollisionAction(actionType: .merge, name: "name", isFile: false, itemPlaceholder: "")
        let viewModel = ActionViewModel(collisionType: .upload, actionItem: nameCollisionAction)
        XCTAssert(viewModel.actionTitle == Strings.Localizable.NameCollision.Folders.Upload.mergeTitle)
    }
    
    func test_titleForUploadCollisionUpdateAction() {
        let nameCollisionAction = NameCollisionAction(actionType: .update, name: "name", isFile: true, itemPlaceholder: "")
        let viewModel = ActionViewModel(collisionType: .upload, actionItem: nameCollisionAction)
        XCTAssert(viewModel.actionTitle == Strings.Localizable.NameCollision.Files.Upload.updateTitle)
    }
    
    func test_titleForUploadCollisionReplaceAction() {
        let nameCollisionAction = NameCollisionAction(actionType: .replace, name: "name", isFile: true, itemPlaceholder: "")
        let viewModel = ActionViewModel(collisionType: .upload, actionItem: nameCollisionAction)
        XCTAssert(viewModel.actionTitle == Strings.Localizable.NameCollision.Files.Upload.replaceTitle)
    }
    
    func test_titleForUploadCollisionRenameAction() {
        let nameCollisionAction = NameCollisionAction(actionType: .rename, name: "name", isFile: true, itemPlaceholder: "")
        let viewModel = ActionViewModel(collisionType: .upload, actionItem: nameCollisionAction)
        XCTAssert(viewModel.actionTitle == Strings.Localizable.NameCollision.Files.Upload.renameTitle)
    }
    
    func test_titleForUploadCollisionCancelAction() {
        let nameCollisionAction = NameCollisionAction(actionType: .cancel, name: "name", isFile: true, itemPlaceholder: "")
        let viewModel = ActionViewModel(collisionType: .upload, actionItem: nameCollisionAction)
        XCTAssert(viewModel.actionTitle == Strings.Localizable.NameCollision.General.cancelTitle)
    }
    
    func test_titleForMoveCollisionMergeAction() {
        let nameCollisionAction = NameCollisionAction(actionType: .merge, name: "name", isFile: false, itemPlaceholder: "")
        let viewModel = ActionViewModel(collisionType: .move, actionItem: nameCollisionAction)
        XCTAssert(viewModel.actionTitle == Strings.Localizable.NameCollision.Folders.Move.mergeTitle)
    }
    
    func test_titleForMoveCollisionUpdateAction() {
        let nameCollisionAction = NameCollisionAction(actionType: .update, name: "name", isFile: true, itemPlaceholder: "")
        let viewModel = ActionViewModel(collisionType: .move, actionItem: nameCollisionAction)
        XCTAssert(viewModel.actionTitle == Strings.Localizable.NameCollision.Files.Move.replaceTitle)
    }
    
    func test_titleForMoveCollisionReplaceAction() {
        let nameCollisionAction = NameCollisionAction(actionType: .replace, name: "name", isFile: true, itemPlaceholder: "")
        let viewModel = ActionViewModel(collisionType: .move, actionItem: nameCollisionAction)
        XCTAssert(viewModel.actionTitle == Strings.Localizable.NameCollision.Files.Move.replaceTitle)
    }
    
    func test_titleForMoveCollisionRenameAction() {
        let nameCollisionAction = NameCollisionAction(actionType: .rename, name: "name", isFile: true, itemPlaceholder: "")
        let viewModel = ActionViewModel(collisionType: .move, actionItem: nameCollisionAction)
        XCTAssert(viewModel.actionTitle == Strings.Localizable.NameCollision.Files.Move.renameTitle)
    }
    
    func test_titleForMoveCollisionCancelAction() {
        let nameCollisionAction = NameCollisionAction(actionType: .cancel, name: "name", isFile: true, itemPlaceholder: "")
        let viewModel = ActionViewModel(collisionType: .move, actionItem: nameCollisionAction)
        XCTAssert(viewModel.actionTitle == Strings.Localizable.NameCollision.General.dontMove)
    }
    
    func test_titleForCopyCollisionMergeAction() {
        let nameCollisionAction = NameCollisionAction(actionType: .merge, name: "name", isFile: false, itemPlaceholder: "")
        let viewModel = ActionViewModel(collisionType: .copy, actionItem: nameCollisionAction)
        XCTAssert(viewModel.actionTitle == Strings.Localizable.NameCollision.Folders.Copy.mergeTitle)
    }
    
    func test_titleForCopyCollisionUpdateAction() {
        let nameCollisionAction = NameCollisionAction(actionType: .update, name: "name", isFile: true, itemPlaceholder: "")
        let viewModel = ActionViewModel(collisionType: .copy, actionItem: nameCollisionAction)
        XCTAssert(viewModel.actionTitle == Strings.Localizable.NameCollision.Files.Copy.replaceTitle)
    }
    
    func test_titleForCopyCollisionReplaceAction() {
        let nameCollisionAction = NameCollisionAction(actionType: .replace, name: "name", isFile: true, itemPlaceholder: "")
        let viewModel = ActionViewModel(collisionType: .copy, actionItem: nameCollisionAction)
        XCTAssert(viewModel.actionTitle == Strings.Localizable.NameCollision.Files.Copy.replaceTitle)
    }
    
    func test_titleForCopyCollisionRenameAction() {
        let nameCollisionAction = NameCollisionAction(actionType: .rename, name: "name", isFile: true, itemPlaceholder: "")
        let viewModel = ActionViewModel(collisionType: .copy, actionItem: nameCollisionAction)
        XCTAssert(viewModel.actionTitle == Strings.Localizable.NameCollision.Files.Copy.renameTitle)
    }
    
    func test_titleForCopyCollisionCancelAction() {
        let nameCollisionAction = NameCollisionAction(actionType: .cancel, name: "name", isFile: true, itemPlaceholder: "")
        let viewModel = ActionViewModel(collisionType: .copy, actionItem: nameCollisionAction)
        XCTAssert(viewModel.actionTitle == Strings.Localizable.NameCollision.General.dontCopy)
    }
    
    func test_descriptionForUploadCollisionMergeAction() {
        let nameCollisionAction = NameCollisionAction(actionType: .merge, name: "name", isFile: false, itemPlaceholder: "")
        let viewModel = ActionViewModel(collisionType: .upload, actionItem: nameCollisionAction)
        XCTAssert(viewModel.actionDescription == Strings.Localizable.NameCollision.Folders.Upload.mergeDescription)
    }
    
    func test_descriptionForUploadCollisionUpdateAction() {
        let nameCollisionAction = NameCollisionAction(actionType: .update, name: "name", isFile: true, itemPlaceholder: "")
        let viewModel = ActionViewModel(collisionType: .upload, actionItem: nameCollisionAction)
        XCTAssert(viewModel.actionDescription == Strings.Localizable.NameCollision.Files.Upload.updateDescription)
    }
    
    func test_descriptionForUploadCollisionReplaceAction() {
        let nameCollisionAction = NameCollisionAction(actionType: .replace, name: "name", isFile: true, itemPlaceholder: "")
        let viewModel = ActionViewModel(collisionType: .upload, actionItem: nameCollisionAction)
        XCTAssert(viewModel.actionDescription == Strings.Localizable.NameCollision.Files.Upload.replaceDescription)
    }
    
    func test_descriptionForUploadCollisionRenameAction() {
        let nameCollisionAction = NameCollisionAction(actionType: .rename, name: "name", isFile: true, itemPlaceholder: "")
        let viewModel = ActionViewModel(collisionType: .upload, actionItem: nameCollisionAction)
        XCTAssert(viewModel.actionDescription == Strings.Localizable.NameCollision.Files.Upload.renameDescription)
    }
    
    func test_descriptionForFileUploadCollisionCancelAction() {
        let nameCollisionAction = NameCollisionAction(actionType: .cancel, name: "name", isFile: true, itemPlaceholder: "")
        let viewModel = ActionViewModel(collisionType: .upload, actionItem: nameCollisionAction)
        XCTAssert(viewModel.actionDescription == Strings.Localizable.NameCollision.Files.cancelDescription)
    }
    
    func test_descriptionForFolderUploadCollisionCancelAction() {
        let nameCollisionAction = NameCollisionAction(actionType: .cancel, name: "name", isFile: false, itemPlaceholder: "")
        let viewModel = ActionViewModel(collisionType: .upload, actionItem: nameCollisionAction)
        XCTAssert(viewModel.actionDescription == Strings.Localizable.NameCollision.Folders.cancelDescription)
    }
    
    func test_descriptionForMoveCollisionMergeAction() {
        let nameCollisionAction = NameCollisionAction(actionType: .merge, name: "name", isFile: false, itemPlaceholder: "")
        let viewModel = ActionViewModel(collisionType: .move, actionItem: nameCollisionAction)
        XCTAssert(viewModel.actionDescription == Strings.Localizable.NameCollision.Folders.Move.mergeDescription)
    }
    
    func test_descriptionForMoveCollisionUpdateAction() {
        let nameCollisionAction = NameCollisionAction(actionType: .update, name: "name", isFile: true, itemPlaceholder: "")
        let viewModel = ActionViewModel(collisionType: .move, actionItem: nameCollisionAction)
        XCTAssert(viewModel.actionDescription == Strings.Localizable.NameCollision.Files.Move.replaceDescription)
    }
    
    func test_descriptionForMoveCollisionReplaceAction() {
        let nameCollisionAction = NameCollisionAction(actionType: .replace, name: "name", isFile: true, itemPlaceholder: "")
        let viewModel = ActionViewModel(collisionType: .move, actionItem: nameCollisionAction)
        XCTAssert(viewModel.actionDescription == Strings.Localizable.NameCollision.Files.Move.replaceDescription)
    }
    
    func test_descriptionForMoveCollisionRenameAction() {
        let nameCollisionAction = NameCollisionAction(actionType: .rename, name: "name", isFile: true, itemPlaceholder: "")
        let viewModel = ActionViewModel(collisionType: .move, actionItem: nameCollisionAction)
        XCTAssert(viewModel.actionDescription == Strings.Localizable.NameCollision.Files.Move.renameDescription)
    }
    
    func test_descriptionForFileMoveCollisionCancelAction() {
        let nameCollisionAction = NameCollisionAction(actionType: .cancel, name: "name", isFile: true, itemPlaceholder: "")
        let viewModel = ActionViewModel(collisionType: .move, actionItem: nameCollisionAction)
        XCTAssert(viewModel.actionDescription == Strings.Localizable.NameCollision.Files.cancelDescription)
    }
    
    func test_descriptionForFolderMoveCollisionCancelAction() {
        let nameCollisionAction = NameCollisionAction(actionType: .cancel, name: "name", isFile: false, itemPlaceholder: "")
        let viewModel = ActionViewModel(collisionType: .move, actionItem: nameCollisionAction)
        XCTAssert(viewModel.actionDescription == Strings.Localizable.NameCollision.Folders.cancelDescription)
    }
    
    func test_descriptionForCopyCollisionMergeAction() {
        let nameCollisionAction = NameCollisionAction(actionType: .merge, name: "name", isFile: false, itemPlaceholder: "")
        let viewModel = ActionViewModel(collisionType: .copy, actionItem: nameCollisionAction)
        XCTAssert(viewModel.actionDescription == Strings.Localizable.NameCollision.Folders.Copy.mergeDescription)
    }
    
    func test_descriptionForCopyCollisionUpdateAction() {
        let nameCollisionAction = NameCollisionAction(actionType: .update, name: "name", isFile: true, itemPlaceholder: "")
        let viewModel = ActionViewModel(collisionType: .copy, actionItem: nameCollisionAction)
        XCTAssert(viewModel.actionDescription == Strings.Localizable.NameCollision.Files.Copy.replaceDescription)
    }
    
    func test_descriptionForCopyCollisionReplaceAction() {
        let nameCollisionAction = NameCollisionAction(actionType: .replace, name: "name", isFile: true, itemPlaceholder: "")
        let viewModel = ActionViewModel(collisionType: .copy, actionItem: nameCollisionAction)
        XCTAssert(viewModel.actionDescription == Strings.Localizable.NameCollision.Files.Copy.replaceDescription)
    }
    
    func test_descriptionForCopyCollisionRenameAction() {
        let nameCollisionAction = NameCollisionAction(actionType: .rename, name: "name", isFile: true, itemPlaceholder: "")
        let viewModel = ActionViewModel(collisionType: .copy, actionItem: nameCollisionAction)
        XCTAssert(viewModel.actionDescription == Strings.Localizable.NameCollision.Files.Copy.renameDescription)
    }
    
    func test_descriptionForFileCopyCollisionCancelAction() {
        let nameCollisionAction = NameCollisionAction(actionType: .cancel, name: "name", isFile: true, itemPlaceholder: "")
        let viewModel = ActionViewModel(collisionType: .copy, actionItem: nameCollisionAction)
        XCTAssert(viewModel.actionDescription == Strings.Localizable.NameCollision.Files.cancelDescription)
    }
    
    func test_descriptionForFolderCopyCollisionCancelAction() {
        let nameCollisionAction = NameCollisionAction(actionType: .cancel, name: "name", isFile: false, itemPlaceholder: "")
        let viewModel = ActionViewModel(collisionType: .copy, actionItem: nameCollisionAction)
        XCTAssert(viewModel.actionDescription == Strings.Localizable.NameCollision.Folders.cancelDescription)
    }
}
