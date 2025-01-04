@testable import MEGA
import Testing

@MainActor
class SettingsViewModelTests {
    
    var sut: SettingsViewModel
    var router = SettingViewRouter(presenter: UINavigationController())
    
    init() {
        sut = SettingsViewModel(router: router, sections: [])
    }
    
    func testNumberOfSections() {
        #expect(sut.numberOfSections() == 0)
    }
    
    func testNumberOfRows() {
        var rows = sut.numberOfRows(in: Int.random(in: Int.min...Int.max))
        #expect(rows == 0)
        updateSutWithDummySection()
        rows = sut.numberOfRows(in: 0)
        #expect(1 == rows)
    }
    
    func testCellViewModelAtSectionAndRow() {
        #expect(sut.cellViewModel(at: Int.random(in: Int.min...Int.max), in: Int.random(in: Int.min...Int.max)) == nil)
        updateSutWithDummySection()
        #expect(sut.cellViewModel(at: 0, in: 0) != nil)
    }
    
    func testReloadData() {
        var value: Bool?
        sut.invokeCommand = { cmd in
            if cmd == .reloadData {
                value = true
            }
        }
        sut.reloadData()
        #expect(value != nil)
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
