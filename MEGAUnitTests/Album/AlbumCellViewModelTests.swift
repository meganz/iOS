import XCTest
import MEGADomainMock
import MEGADomain
@testable import MEGA

final class AlbumCellViewModelTests: XCTestCase {

    private func albumCellViewModel() -> AlbumCellViewModel {
        AlbumCellViewModel(
            cameraUploadNode: nil,
            thumbnailUseCase: MockThumbnailUseCase(),
            albumContentsUseCase: MockAlbumContentUseCase(nodes: [NodeEntity(name: "sample1.gif", handle: 1),
                                                                  NodeEntity(name: "sample2.gif", handle: 2)]),
            album: AlbumEntity(id: 1,
                               name: "GIFs",
                               coverNode: NodeEntity(name: "sample1.gif", handle: 1),
                               count: 2,
                               type: .gif)
        )
    }
    
    func testAlbumType_whenRawOrGifAlbumIsGiven_favouriteShouldBeFalse() throws {
        let sut = albumCellViewModel()
        XCTAssertFalse(sut.isFavouriteAlbum)
    }

}
