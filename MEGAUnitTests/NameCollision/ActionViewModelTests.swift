@testable import MEGA
import XCTest

class ActionViewModelTests: XCTestCase {
    
    func test_fileActionsShouldShowItemView() {
        let nameCollisionAction = NameCollisionAction(actionType: .merge, name: "File name", isFile: true, itemPlaceholder: "")
        let viewModel = ActionViewModel(actionItem: nameCollisionAction)
        
        XCTAssert(viewModel.showItemView == true)
    }
    
    func test_folderActionShouldNotShowItemView() {
        let nameCollisionAction = NameCollisionAction(actionType: .merge, name: "Folder name", isFile: false, itemPlaceholder: "")
        let viewModel = ActionViewModel(actionItem: nameCollisionAction)
        
        XCTAssert(viewModel.showItemView == false)
    }
    
    func test_actionWithName() {
        let nameCollisionAction = NameCollisionAction(actionType: .merge, name: "name", isFile: true, itemPlaceholder: "")
        let viewModel = ActionViewModel(actionItem: nameCollisionAction)
        XCTAssert(viewModel.itemName == nameCollisionAction.name)
    }
    
    func test_actionWithoutName() {
        let nameCollisionAction = NameCollisionAction(actionType: .merge, isFile: true, itemPlaceholder: "")
        let viewModel = ActionViewModel(actionItem: nameCollisionAction)
        XCTAssert(viewModel.itemName == "")
    }
    
    func test_titleForMergeAction() {
        let nameCollisionAction = NameCollisionAction(actionType: .merge, name: "name", isFile: false, itemPlaceholder: "")
        let viewModel = ActionViewModel(actionItem: nameCollisionAction)
        XCTAssert(viewModel.actionTitle == Strings.Localizable.NameCollision.Folders.Action.Merge.title)
    }
    
    func test_titleForUpdateAction() {
        let nameCollisionAction = NameCollisionAction(actionType: .update, name: "name", isFile: true, itemPlaceholder: "")
        let viewModel = ActionViewModel(actionItem: nameCollisionAction)
        XCTAssert(viewModel.actionTitle == Strings.Localizable.NameCollision.Files.Action.Update.title)
    }
    
    func test_titleForReplaceAction() {
        let nameCollisionAction = NameCollisionAction(actionType: .replace, name: "name", isFile: true, itemPlaceholder: "")
        let viewModel = ActionViewModel(actionItem: nameCollisionAction)
        XCTAssert(viewModel.actionTitle == Strings.Localizable.NameCollision.Files.Action.Replace.title)
    }
    
    func test_titleForRenameAction() {
        let nameCollisionAction = NameCollisionAction(actionType: .rename, name: "name", isFile: true, itemPlaceholder: "")
        let viewModel = ActionViewModel(actionItem: nameCollisionAction)
        XCTAssert(viewModel.actionTitle == Strings.Localizable.NameCollision.Files.Action.Rename.title)
    }
    
    func test_titleForSkipFolderAction() {
        let nameCollisionAction = NameCollisionAction(actionType: .cancel, name: "name", isFile: false, itemPlaceholder: "")
        let viewModel = ActionViewModel(actionItem: nameCollisionAction)
        XCTAssert(viewModel.actionTitle == Strings.Localizable.NameCollision.Folders.Action.Skip.title)
    }
    
    func test_titleForSkipFileAction() {
        let nameCollisionAction = NameCollisionAction(actionType: .cancel, name: "name", isFile: true, itemPlaceholder: "")
        let viewModel = ActionViewModel(actionItem: nameCollisionAction)
        XCTAssert(viewModel.actionTitle == Strings.Localizable.NameCollision.Files.Action.Skip.title)
    }
    
    func test_descriptionForMergeAction() {
        let nameCollisionAction = NameCollisionAction(actionType: .merge, name: "name", isFile: false, itemPlaceholder: "")
        let viewModel = ActionViewModel(actionItem: nameCollisionAction)
        XCTAssert(viewModel.actionDescription == Strings.Localizable.NameCollision.Folders.Action.Merge.description)
    }
    
    func test_descriptionForUpdateAction() {
        let nameCollisionAction = NameCollisionAction(actionType: .update, name: "name", isFile: true, itemPlaceholder: "")
        let viewModel = ActionViewModel(actionItem: nameCollisionAction)
        XCTAssert(viewModel.actionDescription == Strings.Localizable.NameCollision.Files.Action.Update.description)
    }
    
    func test_descriptionForReplaceAction() {
        let nameCollisionAction = NameCollisionAction(actionType: .replace, name: "name", isFile: true, itemPlaceholder: "")
        let viewModel = ActionViewModel(actionItem: nameCollisionAction)
        XCTAssert(viewModel.actionDescription == Strings.Localizable.NameCollision.Files.Action.Replace.description)
    }
    
    func test_descriptionForRenameAction() {
        let nameCollisionAction = NameCollisionAction(actionType: .rename, name: "name", isFile: true, itemPlaceholder: "")
        let viewModel = ActionViewModel(actionItem: nameCollisionAction)
        XCTAssert(viewModel.actionDescription == Strings.Localizable.NameCollision.Files.Action.Rename.description)
    }
    
    func test_descriptionForFileSkipAction() {
        let nameCollisionAction = NameCollisionAction(actionType: .cancel, name: "name", isFile: true, itemPlaceholder: "")
        let viewModel = ActionViewModel(actionItem: nameCollisionAction)
        XCTAssert(viewModel.actionDescription == nil)
    }
    
    func test_descriptionForFolderSkipAction() {
        let nameCollisionAction = NameCollisionAction(actionType: .cancel, name: "name", isFile: false, itemPlaceholder: "")
        let viewModel = ActionViewModel(actionItem: nameCollisionAction)
        XCTAssert(viewModel.actionDescription == nil)
    }
}
