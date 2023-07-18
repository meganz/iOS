@testable import MEGA
import XCTest

final class PhotoLibraryContentViewModelTests: XCTestCase {
    func testShouldShowPhotoLibraryPicker_contentModeThatsNotAlbumOrAlbumLink_shouldReturnFalse() {
        let modes = [PhotoLibraryContentMode.album, .albumLink]
        modes.forEach {
            let sut = PhotoLibraryContentViewModel(library: PhotoLibrary(), contentMode: $0, configuration: nil)
            XCTAssertFalse(sut.shouldShowPhotoLibraryPicker)
        }
    }
    
    func testShouldShowPhotoLibraryPicker_contentModeAlbumOrAlbumLink_shouldReturnTrue() {
        let modes = [PhotoLibraryContentMode.library, .mediaDiscovery, .mediaDiscoveryFolderLink]
        modes.forEach {
            let sut = PhotoLibraryContentViewModel(library: PhotoLibrary(), contentMode: $0, configuration: nil)
            XCTAssertTrue(sut.shouldShowPhotoLibraryPicker)
        }
    }
}
