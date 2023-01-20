import XCTest
import Combine
import MEGADomainMock
import MEGADomain
@testable import MEGA

final class AlbumContentViewModelTests: XCTestCase {
    private let albumEntity =
    AlbumEntity(id: 1, name: "GIFs", coverNode: NodeEntity(handle: 1), count: 2, type: .gif)
    
    
    private lazy var router = AlbumContentRouter(album: albumEntity, messageForNewAlbum: nil)
    
    func testDispatchViewReady_onLoadedNodesSuccessfully_shouldReturnNodesForAlbum() throws {
        let expectedNodes = [NodeEntity(name: "sample1.gif", handle: 1),
                             NodeEntity(name: "sample2.gif", handle: 2)]
        
        let sut = AlbumContentViewModel(album: albumEntity,
                                        albumContentsUseCase: MockAlbumContentUseCase(nodes: expectedNodes),
                                        router: router)
        test(viewModel: sut, action: .onViewReady, expectedCommands: [.showAlbum(nodes: expectedNodes)])
    }
    
    func testDispatchViewReady_onLoadedNodesSuccessfully_shouldSortAndThenReturnNodesForFavouritesAlbum() throws {
        let expectedNodes = [NodeEntity(name: "sample2.gif", handle: 4, modificationTime: try "2022-12-15T20:01:04Z".date),
                             NodeEntity(name: "sample2.gif", handle: 3, modificationTime: try "2022-12-3T20:01:04Z".date),
                             NodeEntity(name: "sample1.gif", handle: 2, modificationTime: try "2022-08-19T20:01:04Z".date),
                             NodeEntity(name: "sample2.gif", handle: 1, modificationTime: try "2022-08-19T20:01:04Z".date)]
        
        let sut = AlbumContentViewModel(album: AlbumEntity(id: 1, name: "Favourites", coverNode: NodeEntity(handle: 1), count: 2, type: .favourite), albumContentsUseCase: MockAlbumContentUseCase(nodes: expectedNodes.reversed()), router: router)
        test(viewModel: sut, action: .onViewReady, expectedCommands: [.showAlbum(nodes: expectedNodes)])
    }
    
    func testDispatchViewReady_onLoadedNodesEmptyForFavouritesAlbum_shouldShowEmptyAlbum() throws {
        let sut = AlbumContentViewModel(album: AlbumEntity(id: 1, name: "Favourites", coverNode: nil, count: 0, type: .favourite), albumContentsUseCase: MockAlbumContentUseCase(nodes: []), router: router)
        test(viewModel: sut, action: .onViewReady, expectedCommands: [.showAlbum(nodes: [])])
    }
    
    func testDispatchViewReady_onLoadedNodesEmpty_albumNilShouldDismiss() throws {
        let sut = AlbumContentViewModel(album: albumEntity,
                                        albumContentsUseCase: MockAlbumContentUseCase(nodes: []),
                                        router: router)
        test(viewModel: sut, action: .onViewReady, expectedCommands: [.dismissAlbum])
    }
    
    func testDispatchViewReady_onNewlyCreatedAlbum_messageForNewAlbumWillBeNil() throws {
        let sut = AlbumContentViewModel(album: albumEntity,
                                        messageForNewAlbum: "Hey there",
                                        albumContentsUseCase: MockAlbumContentUseCase(nodes: []),
                                        router: router)
        
        XCTAssertNotNil(sut.messageForNewAlbum)
        sut.dispatch(.onViewReady)
        XCTAssertNil(sut.messageForNewAlbum)
    }
    
    func testSubscription_onAlbumContentUpdated_shouldShowAlbumWithNewNodes() throws {
        let updatePublisher = PassthroughSubject<Void, Never>()
        let expectedNodes = [NodeEntity(name: "sample1.gif", handle: 1)]
        let useCase = MockAlbumContentUseCase(nodes: expectedNodes, updatePublisher: updatePublisher.eraseToAnyPublisher())
        let sut = AlbumContentViewModel(album: albumEntity,
                                        albumContentsUseCase: useCase,
                                        router: router)
        let exp = expectation(description: "show album nodes after update publisher triggered")
        sut.invokeCommand = { command in
            switch command {
            case .showAlbum(let nodes):
                XCTAssertEqual(nodes, expectedNodes)
                exp.fulfill()
            case .dismissAlbum:
                XCTFail()
            case .showHud:
                XCTFail()
            }
        }
        updatePublisher.send()
        
        wait(for: [exp], timeout: 1.0)
    }
    
    func testIsFavouriteAlbum_isEqualToAlbumEntityType() {
        let sut = AlbumContentViewModel(album: AlbumEntity(id: 1, name: "Favourites", coverNode: NodeEntity(handle: 1), count: 2, type: .favourite), albumContentsUseCase: MockAlbumContentUseCase(nodes: []), router: router)
        XCTAssertTrue(sut.isFavouriteAlbum)
    }
}
