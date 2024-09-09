import MEGADomain
import MEGADomainMock
@testable import Video
import XCTest

final class VideoPlaylistsViewModelContentProviderTests: XCTestCase {
    
    func testLoadVideoPlaylists_returnsCorrectOrderPlaylists() async throws {
        let systemVideoPlaylists = [ VideoPlaylistEntity(setIdentifier: SetIdentifier(handle: 1), name: "Favorites", count: 0, type: .favourite, creationTime: Date(), modificationTime: Date()) ]
        let userVideoPlaylists = [
            VideoPlaylistEntity(setIdentifier: SetIdentifier(handle: 2), name: "User playlist 1", count: 0, type: .user, creationTime: Date().addingTimeInterval(60), modificationTime: Date().addingTimeInterval(60)),
            VideoPlaylistEntity(setIdentifier: SetIdentifier(handle: 3), name: "User playlist 2", count: 0, type: .user, creationTime: Date().addingTimeInterval(120), modificationTime: Date().addingTimeInterval(120))
        ]
        let videoPlaylistsUseCase = MockVideoPlaylistUseCase(
            systemVideoPlaylistsResult: systemVideoPlaylists,
            userVideoPlaylistsResult: userVideoPlaylists
        )
        let sut = sut(videoPlaylistsUseCase: videoPlaylistsUseCase)
        
        let result = try await sut.loadVideoPlaylists(searchText: "", sortOrder: .modificationDesc)
        
        XCTAssertEqual(result.map(\.id), systemVideoPlaylists.map(\.id) + userVideoPlaylists.reversed().map(\.id))
    }
    
    func testLoadVideoPlaylists_withSearchText_returnsCorrectOrderedAndFilteredPlaylists() async throws {
        let playlists = [
            VideoPlaylistEntity(setIdentifier: SetIdentifier(handle: 1), name: "Favorites", count: 0, type: .favourite, creationTime: Date(), modificationTime: Date()),
            VideoPlaylistEntity(setIdentifier: SetIdentifier(handle: 2), name: "Other Favorites", count: 0, type: .favourite, creationTime: Date().addingTimeInterval(60), modificationTime: Date().addingTimeInterval(60))
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
