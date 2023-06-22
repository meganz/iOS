@testable import MEGA
import XCTest

class SettingsViewModelTests: XCTestCase {
    
    var sut: SettingsViewModel!
    var router = SettingViewRouter(presenter: UINavigationController())
    
    override func setUpWithError() throws {
        sut = SettingsViewModel(router: router, sections: [])
    }
    
    func testNumberOfSections() {
        XCTAssertEqual(sut.numberOfSections(), 0)
    }
    
    func testNumberOfRows() {
        var rows = sut.numberOfRows(in: Int.random(in: Int.min...Int.max))
        XCTAssertEqual(rows, 0)
        updateSutWithDummySection()
        rows = sut.numberOfRows(in: 0)
        XCTAssertEqual(1, rows)
    }
    
    func testCellViewModelAtSectionAndRow() {
        XCTAssertNil(sut.cellViewModel(at: Int.random(in: Int.min...Int.max), in: Int.random(in: Int.min...Int.max)))
        updateSutWithDummySection()
        XCTAssertNotNil(sut.cellViewModel(at: 0, in: 0))
    }
    
    func testReloadData() {
        var value: Bool?
        XCTAssertNil(value)
        sut.reloadData()
        XCTAssertNil(value)
        sut.invokeCommand = { cmd in
            if cmd == .reloadData {
                value = true
            }
        }
        sut.reloadData()
        XCTAssertNotNil(value)
    }
    
    func updateSutWithDummySection() {
        sut = SettingsViewModel(router: router, sections: [getDummySection()])
    }
    
    func getDummySection() -> SettingSectionViewModel {
        SettingSectionViewModel {
            SettingCellViewModel(image: nil, title: "")
        }
    }
}
