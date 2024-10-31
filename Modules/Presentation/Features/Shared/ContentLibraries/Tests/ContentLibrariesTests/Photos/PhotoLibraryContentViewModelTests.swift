@testable import ContentLibraries
import MEGADomain
import XCTest

final class PhotoLibraryContentViewModelTests: XCTestCase {
    @MainActor
    func testShouldShowPhotoLibraryPicker_contentModeThatsNotAlbumOrAlbumLink_shouldReturnFalse() {
        let modes = [PhotoLibraryContentMode.album, .albumLink]
        modes.forEach {
            let sut = PhotoLibraryContentViewModel(library: PhotoLibrary(), contentMode: $0, configuration: nil)
            XCTAssertFalse(sut.shouldShowPhotoLibraryPicker)
        }
    }
    
    @MainActor
    func testShouldShowPhotoLibraryPicker_contentModeAlbumOrAlbumLink_shouldReturnTrue() {
        let modes = [PhotoLibraryContentMode.library, .mediaDiscovery, .mediaDiscoveryFolderLink]
        modes.forEach {
            let sut = PhotoLibraryContentViewModel(library: PhotoLibrary(), contentMode: $0, configuration: nil)
            XCTAssertTrue(sut.shouldShowPhotoLibraryPicker)
        }
    }
    
    @MainActor
    func testToggleSelectAllPhotos_onCalledAgain_shouldToggleBetweenSelectAllAndUnselectAll() throws {
        let photos = [NodeEntity(name: "a.png", handle: HandleEntity(1),
                                 modificationTime: try "2023-08-18T22:01:04Z".date),
                      NodeEntity(name: "b.png", handle: HandleEntity(2),
                                 modificationTime: try "2023-08-11T22:01:04Z".date)
        ]
        let library = photos.toPhotoLibrary(withSortType: .modificationDesc)
        let sut = PhotoLibraryContentViewModel(library: library,
                                               contentMode: .album, configuration: nil)
        
        sut.toggleSelectAllPhotos()
        
        XCTAssertTrue(sut.selection.allSelected)
        XCTAssertEqual(Set(library.allPhotos), Set(photos))
        
        sut.toggleSelectAllPhotos()
        
        XCTAssertFalse(sut.selection.allSelected)
        XCTAssertTrue(sut.selection.photos.isEmpty)
        XCTAssertTrue(library.allPhotos.isNotEmpty)
    }
}
