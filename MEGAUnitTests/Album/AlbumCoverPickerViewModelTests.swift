import XCTest
import SwiftUI
import MEGADomainMock
import MEGADomain
@testable import MEGA

final class AlbumCoverPickerViewModelTests: XCTestCase {

    func testOnSave_whenUserSelectACoverPic_shouldSetTheNewPicAsCoverPic() {
        let exp = expectation(description: "Should call completion handler and set isDismiss to true")
        
        let photo = NodeEntity(handle: 1)
        let sut = albumCoverPickerViewModel { album, node in
            XCTAssertEqual(node, photo)
            exp.fulfill()
        }
        
        XCTAssertFalse(sut.isDismiss)
        sut.onSave()
        XCTAssertFalse(sut.isDismiss)
        
        sut.photoSelection.selectedPhoto = NodeEntity(handle: 1)
        sut.onSave()
        wait(for: [exp], timeout: 1.0)
        XCTAssertTrue(sut.isDismiss)
    }
    
    func testOnCancel_whenUserTapCancel_shouldDismissTheScreen() {
        let sut = albumCoverPickerViewModel()
        
        XCTAssertFalse(sut.isDismiss)
        sut.onCancel()
        XCTAssertTrue(sut.isDismiss)
    }
    
    func testLoadAlbumContents_whenUserOpenSelectCoverPicScreen_shouldLoadAlbumContents() async {
        let sut = albumCoverPickerViewModel()
        
        sut.loadAlbumContents()
        await sut.loadingTask?.value
        
        XCTAssertEqual(sut.photos.count, 2)
    }
    
    func testSelectedCoverPicFromLoadedAlbum_whenUserOpenTheSelectCoverPicScreen_shouldSelectNodeFromAlbumCoverNode() {
        let coverNode = NodeEntity(handle: 10)
        let sut = albumCoverPickerViewModel(coverNode: coverNode)
        
        XCTAssertEqual(sut.photoSelection.selectedPhoto, coverNode)
    }
    
    func testSelectedCoverPicFromLoadedAlbumContents_whenUserOpenTheSelectCoverPicScreen_shouldSelectNodeFromAlbumContents() async {
        let node4 = AlbumPhotoEntity(photo: NodeEntity(handle: 4, modificationTime: Date.distantFuture))
        let node5 = AlbumPhotoEntity(photo: NodeEntity(handle: 5, modificationTime: Date.distantPast))
        
        let sut = albumCoverPickerViewModel(photos: [node4, node5])
        sut.loadAlbumContents()
        await sut.loadingTask?.value
        
        XCTAssertEqual(sut.photoSelection.selectedPhoto, node4.photo)
    }
    
    func testIsSaveButtonDisabled_whenSelectedNodeChange_shouldSelectTheRightValues(){
        let sut = albumCoverPickerViewModel()
        
        XCTAssertTrue(sut.isSaveButtonDisabled)
        sut.photoSelection.selectedPhoto = NodeEntity(handle: 2)
        XCTAssertFalse(sut.isSaveButtonDisabled)
    }
    
    private func albumCoverPickerViewModel(
        coverNode: NodeEntity? = nil,
        photos: [AlbumPhotoEntity] = [AlbumPhotoEntity(photo: NodeEntity(handle: 2)), AlbumPhotoEntity(photo: NodeEntity(handle: 3))],
        completion: ((AlbumEntity, NodeEntity) -> Void)? = nil ) -> AlbumCoverPickerViewModel {
        let album = AlbumEntity(id: 1, name: "User album", coverNode: coverNode, count: 2, type: .user, modificationTime: nil)
        let router = AlbumContentRouter(navigationController: nil, album: album, newAlbumPhotos: [], existingAlbumNames: {[]})
        
        return AlbumCoverPickerViewModel(album: album, albumContentsUseCase: MockAlbumContentUseCase(photos: photos), router: router, completion: completion ?? { _, _ in })
    }
}
