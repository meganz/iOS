import XCTest
import Combine
import MEGADomainMock
import MEGADomain
@testable import MEGA

final class AlbumListViewModelTests: XCTestCase {
    private var subscriptions = Set<AnyCancellable>()
    
    func testLoadAlbums_onAlbumsLoaded_albumsAreLoadedAndTitlesAreUpdated() async throws {
        let favouriteAlbum = AlbumEntity(id: 1, name: "", coverNode: NodeEntity(handle: 1), count: 1, type: .favourite)
        let gifAlbum = AlbumEntity(id: 2, name: "", coverNode: NodeEntity(handle: 1), count: 1, type: .gif)
        let rawAlbum = AlbumEntity(id: 3, name: "", coverNode: NodeEntity(handle: 2), count: 1, type: .raw)
        let userAlbum = AlbumEntity(id: 3, name: "Custom Name", coverNode: NodeEntity(handle: 3), count: 1, type: .user)
        let useCase = MockAlbumListUseCase(albums: [favouriteAlbum, gifAlbum, rawAlbum, userAlbum])
        let sut = AlbumListViewModel(usecase: useCase)
        
        let exp = expectation(description: "albums titles are updated when retrieved")
        sut.$albums
            .dropFirst()
            .sink {
                XCTAssertEqual($0, [
                    favouriteAlbum.update(name: Strings.Localizable.CameraUploads.Albums.Favourites.title),
                    gifAlbum.update(name: Strings.Localizable.CameraUploads.Albums.Gif.title),
                    rawAlbum.update(name: Strings.Localizable.CameraUploads.Albums.Raw.title),
                    userAlbum
                ])
                exp.fulfill()
            }.store(in: &subscriptions)
        await sut.loadAlbums()
        await sut.albumLoadingTask?.value
        wait(for: [exp], timeout: 2.0)
    }
    
    func testLoadAlbums_onAlbumsLoadedFinsihed_shouldLoadSetToFalse() async throws {
        let sut = AlbumListViewModel(usecase: MockAlbumListUseCase())
        let exp = expectation(description: "should load set after album load")
        
        sut.$shouldLoad
            .dropFirst()
            .sink {
                XCTAssertFalse($0)
                exp.fulfill()
            }.store(in: &subscriptions)
        
        await sut.loadAlbums()
        await sut.albumLoadingTask?.value
        wait(for: [exp], timeout: 2.0)
    }
    
    func testCancelLoading_stopMonitoringForNodeUpdates() async throws {
        let useCase = MockAlbumListUseCase()
        let sut = AlbumListViewModel(usecase: useCase)
        XCTAssertTrue(useCase.startMonitoringNodesUpdateCalled == 0)
        XCTAssertTrue(useCase.stopMonitoringNodesUpdateCalled == 0)
        await sut.loadAlbums()
        XCTAssertTrue(useCase.startMonitoringNodesUpdateCalled == 1)
        sut.cancelLoading()
        XCTAssertTrue(useCase.stopMonitoringNodesUpdateCalled == 1)
    }
    
    @MainActor
    func testCreateUserAlbum_shouldCreateUserAlbum() {
        let exp = expectation(description: "should load album at first after creating")
        let useCase = MockAlbumListUseCase()
        let sut = AlbumListViewModel(usecase: useCase)
        sut.createUserAlbum(with: "userAlbum")
        sut.$shouldLoad
            .dropFirst()
            .sink {
                XCTAssertFalse($0)
                exp.fulfill()
            }.store(in: &subscriptions)
        
        wait(for: [exp], timeout: 2.0)
        XCTAssertEqual(sut.albums.last?.name, "userAlbum")
        XCTAssertEqual(sut.albums.last?.type, .user)
        XCTAssertEqual(sut.albums.last?.count, 0)
    }
}

