import DeviceCenter
@testable import MEGA
import MEGAFoundation
import MEGAL10n
import MEGATest
import SwiftUI
import XCTest

final class ResourceInfoViewModelTests: XCTestCase {
    
    func testIconProperty_returnsInfoModelIcon() {
        let icon = Image(.brown)
        let viewModel = makeSUT(icon: icon)
        XCTAssertEqual(viewModel.icon, icon)
    }

    func testTitleProperty_returnsInfoModelName() {
        let itemName = "Item Name"
        let viewModel = makeSUT(name: itemName)
        XCTAssertEqual(viewModel.title, itemName)
    }
    
    func testTotalSize_with1024Bytes_returns1KBFormatted() {
        let itemSize = UInt64(1024)
        let viewModel = makeSUT(totalSize: itemSize)
        XCTAssertEqual(viewModel.totalSize, "1 KB")
    }

    func testAddedProperty_withAValidDate_returnsTheSameDate() {
        let date = Date()
        let viewModel = makeSUT(added: date)
        XCTAssertEqual(date, viewModel.infoModel.added)
    }

    func testAddedPropertyAndDateFormattingWithNil_returnsNil() {
        let viewModel = makeSUT()
        XCTAssertTrue(viewModel.formattedDate.isEmpty)
    }

    func testContentDescriptionPropertyWith0Files0Folders_returnsEmptyFolder() {
        let viewModel = makeSUT(files: 0, folders: 0)
        XCTAssertEqual(viewModel.contentDescription, Strings.Localizable.emptyFolder)
    }

    func testContentDescriptionPropertyWithFilesGreaterThan0_returnsFileCount() {
        let files = 5
        let viewModel = makeSUT(files: files)
        XCTAssertEqual(viewModel.contentDescription, Strings.Localizable.General.Format.Count.file(5))
    }

    func testContentDescriptionPropertyWithFoldersGreaterThan0_returnsFolderCount() {
        let folders = 3
        let viewModel = makeSUT(folders: folders)
        XCTAssertEqual(viewModel.contentDescription, Strings.Localizable.General.Format.Count.folder(3))
    }

    func testContentDescriptionPropertyWithFilesAndFoldersGreaterThan0_returnsCombinedCount() {
        let files = 4
        let folders = 2
        let viewModel = makeSUT(files: files, folders: folders)
        let expected = "\(Strings.Localizable.General.Format.Count.FolderAndFile.folder(folders)) \(Strings.Localizable.General.Format.Count.FolderAndFile.file(files))"
        XCTAssertEqual(viewModel.contentDescription, expected)
    }
    
    private func makeSUT(
        icon: Image = Image(.blue),
        name: String = "",
        totalSize: UInt64 = 0,
        added: Date? = nil,
        dateFormatting: (any DateFormatting)? = nil,
        files: Int = 0,
        folders: Int = 0,
        file: StaticString = #file,
        line: UInt = #line
    ) -> ResourceInfoViewModel {
        let infoModel = ResourceInfoModel(
            icon: icon,
            name: name,
            counter: ResourceCounter(
                files: files,
                folders: folders
            ),
            totalSize: totalSize,
            added: added) { date in
                dateFormatting?.localisedString(from: date) ?? ""
            }
        let router = ResourceInfoViewRouter(
            presenter: UIViewController(),
            infoModel: infoModel
        )
        
        let sut = ResourceInfoViewModel(
            infoModel: infoModel,
            router: router
        )
        
        trackForMemoryLeaks(on: sut, file: file, line: line)
        return sut
    }
}
