import XCTest
import MEGADomainMock
import MEGADomain
@testable import MEGA

final class AlbumListViewModelTests: XCTestCase {
    
    @MainActor
    func testLoadAlbums_onAlbumScreen_shouldReturnOneRootNodeForFavouriteAlbum() async throws {
        let sut = AlbumListViewModel(usecase: AlbumListUseCase(
                                                    albumRepository: MockAlbumRepository.newRepo,
                                                    fileSearchRepository: MockFileSearchRepository.newRepo,
                                                    mediaUseCase: MockMediaUseCase()))
        
        sut.loadAlbums()
        await sut.loadingTask?.value
        XCTAssertNotNil(sut.cameraUploadNode)
    }
    
    func testCancelLoading_onAlbumScreen_shouldFavouriteAlbumLoadingTaskBeNil() async throws {
        let sut = AlbumListViewModel(usecase: AlbumListUseCase(
                                                    albumRepository: MockAlbumRepository.newRepo,
                                                    fileSearchRepository: MockFileSearchRepository.newRepo,
                                                    mediaUseCase: MockMediaUseCase()))
        
        sut.cancelLoading()
        XCTAssertNil(sut.cameraUploadNode)
    }
}

