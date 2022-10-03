import XCTest
@testable import MEGA

final class SlideShowOptionViewModelTests: XCTestCase {
    private func cellViewModels() -> [SlideShowOptionCellViewModel] {
        [SlideShowOptionCellViewModel(name: .speed, title: Strings.Localizable.Slideshow.PreferenceSetting.speed, type: .detail, children: [SlideShowOptionDetailCellViewModel(name: .speedNormal, title: Strings.Localizable.Slideshow.PreferenceSetting.Speed.slow, isSelcted: false)])]
    }
    
    private func getConfiguration() -> SlideShowViewConfiguration {
        SlideShowViewConfiguration(playingOrder: .shuffled, timeIntervalForSlideInSeconds: .normal, isRepeat: false, includeSubfolders: false)
    }
    
    func testDidSelectCell_forDetailCell_selected() {
        let viewModel = SlideShowOptionViewModel(cellViewModels: cellViewModels(), currentConfiguration: getConfiguration())
        let cell = viewModel.cellViewModels.first
        viewModel.didSelectCell(cell!)
        XCTAssertTrue(viewModel.selectedCell === cell)
    }
    
    func testDidSelectCell_forNonDetailCell_notSelected() {
        let viewModel = SlideShowOptionViewModel(cellViewModels: [SlideShowOptionCellViewModel(name: .speed, title: "", type: .none, children: [])], currentConfiguration: getConfiguration())
        let cell = viewModel.cellViewModels.first
        viewModel.didSelectCell(cell!)
        XCTAssertNil(viewModel.selectedCell)
    }
    
    func testNoCellTapped() {
        let viewModel = SlideShowOptionViewModel(cellViewModels: cellViewModels(), currentConfiguration: getConfiguration())
        XCTAssertNil(viewModel.selectedCell)
    }
    
    func testGetNewConfiguration_whenRepeat_shouldReturnTrueForRepeat() throws {
        let cellViewModels = [
            SlideShowOptionCellViewModel(name: .repeat, title: "Repeat", type: .toggle, children: [], isOn: true)
        ]
        
        let viewModel = SlideShowOptionViewModel(cellViewModels: cellViewModels, currentConfiguration: getConfiguration())
        let sut = viewModel.configuration()
        
        XCTAssertTrue(sut.isRepeat)
    }
    
    func testGetNewConfiguration_whenSpeedChangeToFast_shouldReturnFast() throws {
        let cellViewModels = [
            SlideShowOptionCellViewModel(name: .speed, title: "Speed", type: .detail, children: [
                SlideShowOptionDetailCellViewModel(name: .speedSlow, title: "Slow", isSelcted: false),
                SlideShowOptionDetailCellViewModel(name: .speedNormal, title: "Normal", isSelcted: false),
                SlideShowOptionDetailCellViewModel(name: .speedFast, title: "Fast", isSelcted: true)
            ])
        ]
        
        let viewModel = SlideShowOptionViewModel(cellViewModels: cellViewModels, currentConfiguration: getConfiguration())
        let sut = viewModel.configuration()
        
        XCTAssert(sut.timeIntervalForSlideInSeconds == SlideShowTimeIntervalOption.fast)
    }
}
