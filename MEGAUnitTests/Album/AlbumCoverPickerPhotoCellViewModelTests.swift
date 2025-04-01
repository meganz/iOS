import ContentLibraries
@testable import MEGA
import MEGAAppPresentationMock
import MEGADomain
import MEGADomainMock
import XCTest

final class AlbumCoverPickerPhotoCellViewModelTests: XCTestCase {

    @MainActor
    func testOnPhotoSelect_whenDifferentPhotoSelected_shouldSetIsSelectedToTrue() throws {
        let library = try testNodes.toPhotoLibrary(withSortType: .modificationDesc, in: .GMT)
        let libraryViewModel = PhotoLibraryContentViewModel(library: library)
        libraryViewModel.selectedMode = .all
        let viewModel = PhotoLibraryModeAllGridViewModel(libraryViewModel: libraryViewModel)
        
        let sut = AlbumCoverPickerPhotoCellViewModel(
            albumPhoto: AlbumPhotoEntity(photo: NodeEntity(handle: 1)),
            photoSelection: AlbumCoverPickerPhotoSelection(),
            viewModel: viewModel,
            thumbnailLoader: MockThumbnailLoader(),
            nodeUseCase: MockNodeDataUseCase(),
            sensitiveNodeUseCase: MockSensitiveNodeUseCase()
        )
        
        XCTAssertFalse(sut.isSelected)
        sut.onPhotoSelect()
        XCTAssertTrue(sut.isSelected)
    }
    
    private var testNodes: [NodeEntity] {
        get throws {
            [
                NodeEntity(name: "00.jpg", handle: 100, modificationTime: try "2022-09-03T22:01:04Z".date),
                NodeEntity(name: "0.jpg", handle: 0, modificationTime: try "2022-09-01T22:01:04Z".date),
                NodeEntity(name: "a.jpg", handle: 1, modificationTime: try "2022-08-18T22:01:04Z".date),
                NodeEntity(name: "a.jpg", handle: 2, modificationTime: try "2022-08-10T22:01:04Z".date),
                NodeEntity(name: "b.jpg", handle: 3, modificationTime: try "2020-04-18T20:01:04Z".date),
                NodeEntity(name: "c.mov", handle: 4, modificationTime: try "2020-04-18T12:01:04Z".date),
                NodeEntity(name: "d.mp4", handle: 5, modificationTime: try "2020-04-18T01:01:04Z".date),
                NodeEntity(name: "e.mp4", handle: 6, modificationTime: try "2019-10-18T01:01:04Z".date),
                NodeEntity(name: "f.mp4", handle: 7, modificationTime: try "2018-01-23T01:01:04Z".date),
                NodeEntity(name: "g.mp4", handle: 8, modificationTime: try "2017-12-31T01:01:04Z".date)
            ]
        }
    }

}
