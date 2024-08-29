import MEGADomain
import MEGADomainMock
@testable import Video
import XCTest

final class VideoPlaylistsViewModelContentProviderTests: XCTestCase {
    
    func testLoadVideoPlaylists_returnsCorrectOrderPlaylists() async throws {
        let playlists = [
            VideoPlaylistEntity(id: 1, name: "Favorites", count: 0, type: .favourite, creationTime: Date(), modificationTime: Date()),
            VideoPlaylistEntity(id: 2, name: "Other Favorites", count: 0, type: .favourite, creationTime: Date().addingTimeInterval(60), modificationTime: Date().addingTimeInterval(60))
        ]
        let videoPlaylistsUseCase = MockVideoPlaylistUseCase(userVideoPlaylistsResult: playlists)
        let sut = sut(videoPlaylistsUseCase: videoPlaylistsUseCase)
    
        let result = try await sut.loadVideoPlaylists(searchText: "", sortOrder: .modificationDesc)
        
        XCTAssertEqual(playlists.reversed(), result)
    }
    
    func testLoadVideoPlaylists_withSearchText_returnsCorrectOrderedAndFilteredPlaylists() async throws {
        let playlists = [
            VideoPlaylistEntity(id: 1, name: "Favorites", count: 0, type: .favourite, creationTime: Date(), modificationTime: Date()),
            VideoPlaylistEntity(id: 2, name: "Other Favorites", count: 0, type: .favourite, creationTime: Date().addingTimeInterval(60), modificationTime: Date().addingTimeInterval(60))
        ]
        let videoPlaylistsUseCase = MockVideoPlaylistUseCase(userVideoPlaylistsResult: playlists)
        let sut = sut(videoPlaylistsUseCase: videoPlaylistsUseCase)
    
        let result = try await sut.loadVideoPlaylists(searchText: "other", sortOrder: .modificationDesc)
        
        XCTAssertEqual(playlists.filter { $0.name.localizedCaseInsensitiveContains("other") }, result)
    }
}

extension VideoPlaylistsViewModelContentProviderTests {
    func sut(videoPlaylistsUseCase: some VideoPlaylistUseCaseProtocol = MockVideoPlaylistUseCase()) -> VideoPlaylistsViewModelContentProvider {
        VideoPlaylistsViewModelContentProvider(videoPlaylistsUseCase: videoPlaylistsUseCase)
    }
}
