import XCTest
@testable import MEGA

final class SlideShowOptionViewModelTests: XCTestCase {

    func testDidSelectCell_forDetailCell_selected() {
        let viewModel = SlideShowOptionViewModel(cellViewModels: cellViewModels())
        let cell = viewModel.cellViewModels.first
        viewModel.didSelectCell(cell!)
        XCTAssertTrue(viewModel.selectedCell === cell)
    }
    
    func testDidSelectCell_forNonDetailCell_notSelected() {
        let viewModel = SlideShowOptionViewModel(cellViewModels: [SlideShowOptionCellViewModel(title: "", type: .none, children: [])])
        let cell = viewModel.cellViewModels.first
        viewModel.didSelectCell(cell!)
        XCTAssertNil(viewModel.selectedCell)
    }
    
    func testNoCellTapped() {
        let viewModel = SlideShowOptionViewModel(cellViewModels: cellViewModels())
        XCTAssertNil(viewModel.selectedCell)
    }
    
    private func cellViewModels() -> [SlideShowOptionCellViewModel] {
        [SlideShowOptionCellViewModel(title: Strings.Localizable.Slideshow.PreferenceSetting.speed, type: .detail, children: [SlideShowOptionDetailCellViewModel(title: Strings.Localizable.Slideshow.PreferenceSetting.Speed.slow, isSelcted: false)])]
    }
}
