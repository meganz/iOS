import XCTest
import MEGADomain
import MEGADomainMock
@testable import MEGA

final class AlbumContentPickerViewModelTests: XCTestCase {
    @MainActor
    func testOnDone_whenNoImagesSelected_shouldDismissTheScreen() async throws {
        let sut = try albumContentAdditionViewModel()
        await sut.photosLoadingTask?.value
        sut.onDone()
        XCTAssertTrue(sut.isDismiss)
    }
    
    @MainActor
    func testOnDone_whenSomeImagesSelected_shouldDismissTheScreenAndReturnTheAlbumAndPluralSuccessMsg() async throws {
        let exp = XCTestExpectation(description: "Adding content to album should be successful")
        
        let resultEntity = AlbumElementsResultEntity(success: 2, failure: 0)
        let sut = try albumContentAdditionViewModel(resultEntity: resultEntity, completionHandler: { msg, album in
            XCTAssertEqual(msg, "Added 2 items to \"\(album.name)\"")
            XCTAssertNotNil(album)
            exp.fulfill()
        })
        await sut.photosLoadingTask?.value
        
        let node1 = NodeEntity(name: "a.png", handle: HandleEntity(1))
        let node2 = NodeEntity(name: "b.png", handle: HandleEntity(2))
        sut.photoLibraryContentViewModel.selection.setSelectedPhotos([node1, node2])
        sut.onDone()
        await sut.photosLoadingTask?.value
        XCTAssertTrue(sut.isDismiss)
        wait(for: [exp], timeout: 2.0)
    }
    
    @MainActor
    func testOnDone_whenOneImageSelected_shouldDismissTheScreenAndReturnTheAlbumAndSingularSuccessMsg() async throws {
        let exp = XCTestExpectation(description: "Adding content to album should be successful")
        
        let resultEntity = AlbumElementsResultEntity(success: 1, failure: 0)
        let sut = try albumContentAdditionViewModel(resultEntity: resultEntity, completionHandler: { msg, album in
            XCTAssertEqual(msg, "Added 1 item to \"\(album.name)\"")
            XCTAssertNotNil(album)
            exp.fulfill()
        })
        await sut.photosLoadingTask?.value
        
        let node1 = NodeEntity(name: "a.png", handle: HandleEntity(1))
        sut.photoLibraryContentViewModel.selection.setSelectedPhotos([node1])
        sut.onDone()
        await sut.photosLoadingTask?.value
        XCTAssertTrue(sut.isDismiss)
        wait(for: [exp], timeout: 2.0)
    }
    
    @MainActor
    func testOnCancel_dismissSetToTrue() throws {
        let viewModel = try albumContentAdditionViewModel()
        XCTAssertFalse(viewModel.isDismiss)
        viewModel.onCancel()
        XCTAssertTrue(viewModel.isDismiss)
    }
    
    @MainActor
    func testLoadPhotos_whenAddContentToAlbumScreenHasShown_shouldReturnPhotos() async throws {
        let sut = try albumContentAdditionViewModel()
        await sut.photosLoadingTask?.value
        XCTAssertEqual(sut.photoLibraryContentViewModel.library.allPhotos.count, 5)
    }
    
    @MainActor
    func testNavigationTitle_whenAddedContent_shouldReturnThreeDifferentResults() throws {
        let sut = try albumContentAdditionViewModel()
        let node1 = NodeEntity(name: "a.png", handle: HandleEntity(1))
        let node2 = NodeEntity(name: "b.png", handle: HandleEntity(2))
        
        let normalNavTitle = "Add items to \"Custom Name\""
        XCTAssertEqual(sut.navigationTitle, normalNavTitle)
                               
        sut.photoLibraryContentViewModel.selection.setSelectedPhotos([node1])
        XCTAssertEqual(sut.navigationTitle, "1 item selected")
        
        sut.photoLibraryContentViewModel.selection.setSelectedPhotos([node1, node2])
        XCTAssertEqual(sut.navigationTitle, "2 items selected")
    }
    
    
    @MainActor
    private func albumContentAdditionViewModel(resultEntity: AlbumElementsResultEntity? = nil, completionHandler: @escaping ((String, AlbumEntity) -> Void) = {_, _ in }) throws -> AlbumContentPickerViewModel {
        let album = AlbumEntity(id: 4, name: "Custom Name", coverNode: NodeEntity(handle: 4), count: 0, type: .user)
        let nodes = [MEGANode]()
        return AlbumContentPickerViewModel(album: album,
                                             locationName: Strings.Localizable.CameraUploads.Timeline.Filter.Location.allLocations,
                                             photoLibraryUseCase:
                                                MockPhotoLibraryUseCase(
                                                    allPhotos: try samplePhotoNodes(),
                                                    allPhotosFromCloudDriveOnly: nodes,
                                                    allPhotosFromCameraUpload: nodes),
                                                mediaUseCase: MockMediaUseCase(isStringImage: true),
                                                albumContentModificationUseCase: MockAlbumContentModificationUseCase(resultEntity: resultEntity),
                                                completionHandler: completionHandler )
    }
    
    private func samplePhotoNodes() throws ->[MEGANode] {
        let node1 = MockNode(handle: 1, name: "TestImage1.png", nodeType: .file, parentHandle: 0, modificationTime: try "2022-08-18T22:01:04Z".date, hasThumbnail: true)
        let node2 = MockNode(handle: 2, name: "TestImage2.png", nodeType: .file, parentHandle: 1, modificationTime: try "2022-08-18T22:01:04Z".date, hasThumbnail: true)
        let node3 = MockNode(handle: 3, name: "TestImage1.png", nodeType: .file, parentHandle: 4, modificationTime: try "2022-08-18T22:01:04Z".date, hasThumbnail: true)
        let node4 = MockNode(handle: 4, name: "TestImage2.png", nodeType: .file, parentHandle: 5, modificationTime: try "2022-08-18T22:01:04Z".date, hasThumbnail: true)
        let node5 = MockNode(handle: 5, name: "TestVideo.mp4", nodeType: .file, parentHandle: 6, modificationTime: try "2022-08-18T22:01:04Z".date, hasThumbnail: true)
        
        return [node1, node2, node3, node4, node5]
    }
}
