import XCTest
@testable import MEGA

class HeaderViewModelTests: XCTestCase {

    func test_titleComponentsCount() {
        let viewModel = HeaderViewModel(isFile: true, name: "name")
        XCTAssert(viewModel.titleComponents.count == 3)
    }
    
    func test_fileTitle() {
        let name = "Item name"
        let viewModel = HeaderViewModel(isFile: true, name: name)
        let title = viewModel.titleComponents.joined()
        XCTAssert(title == Strings.Localizable.NameCollision.Files.alreadyExists(name))
    }
    
    func test_folderTitle() {
        let name = "Item name"
        let viewModel = HeaderViewModel(isFile: false, name: name)
        let title = viewModel.titleComponents.joined()
        XCTAssert(title == Strings.Localizable.NameCollision.Folders.alreadyExists(name))
    }
}
