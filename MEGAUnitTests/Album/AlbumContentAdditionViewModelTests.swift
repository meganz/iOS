import XCTest
import MEGA

final class AlbumContentAdditionViewModelTests: XCTestCase {
    func testOnDone_dismissSetToTrue() {
        let viewModel = albumContentAdditionViewModel()
        XCTAssertFalse(viewModel.dismiss)
        viewModel.onDone()
        XCTAssertTrue(viewModel.dismiss)
    }
    
    func testOnCancel_dismissSetToTrue() {
        let viewModel = albumContentAdditionViewModel()
        XCTAssertFalse(viewModel.dismiss)
        viewModel.onCancel()
        XCTAssertTrue(viewModel.dismiss)
    }
    
    private func albumContentAdditionViewModel() -> AlbumContentAdditionViewModel {
        AlbumContentAdditionViewModel(albumName: "item.name", locationName: Strings.Localizable.CameraUploads.Timeline.Filter.Location.allLocations)
    }
}
