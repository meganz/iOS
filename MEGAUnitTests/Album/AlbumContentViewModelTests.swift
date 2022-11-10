import XCTest
import MEGADomainMock
import MEGADomain
@testable import MEGA

final class AlbumContentViewModelTests: XCTestCase {
    private var albumEntity: AlbumEntity {
        AlbumEntity(id: 1, name: "GIFs", coverNode: NodeEntity(handle: 1), count: 2, type: .gif)
    }
    
    private func albumContentViewModel() -> AlbumContentViewModel {
        let mockAlbumContentUseCase = MockAlbumContentUseCase(nodes: [NodeEntity(name: "sample1.gif", handle: 1),
                                                                      NodeEntity(name: "sample2.gif", handle: 2)])
        
        return AlbumContentViewModel(cameraUploadNode: nil,
                                     album: albumEntity,
                                     albumName: "",
                                     albumContentsUseCase: mockAlbumContentUseCase,
                                     router: AlbumContentRouter(cameraUploadNode: nil, album: albumEntity))
    }

    func testOtherAlbumNodes_whenUserTapOnGifAlbum_shouldReturnTwoGifNodes() throws {
        let sut = albumContentViewModel()
        let expectation = XCTestExpectation(description: "Download album contents")
        var gifNodes = [NodeEntity]()
        
        sut.invokeCommand = { command in
            switch command {
            case .showAlbum(let nodes):
                gifNodes = nodes
                expectation.fulfill()
            case .dismissAlbum:
                XCTFail()
            }
        }
        
        sut.dispatch(.onViewReady)
        
        wait(for: [expectation], timeout: 1.0)
        
        XCTAssert(gifNodes.count == 2)
    }
    
}
