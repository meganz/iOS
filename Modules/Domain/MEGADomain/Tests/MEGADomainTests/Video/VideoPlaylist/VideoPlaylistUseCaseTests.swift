@testable import MEGADomain
import MEGADomainMock
import XCTest

final class VideoPlaylistUseCaseTests: XCTestCase {
    
    // MARK: - Init
    
    func testInit_whenCalled_doesNotTriggerFilesSearchUseCase() {
        let (_, filesSearchUseCase) = makeSUT()
        
        XCTAssertTrue(filesSearchUseCase.messages.isEmpty)
    }
    
    // MARK: - systemVideoPlaylists
    
    func testSystemVideoPlaylists_whenCalled_TriggerFilesSearchUseCase() async {
        let (sut, filesSearchUseCase) = makeSUT()
        
        _ = try? await sut.systemVideoPlaylists()
        
        XCTAssertEqual(filesSearchUseCase.messages, [ .search ])
    }
    
    func testSystemVideoPlaylists_whenCalledTwice_TriggerFilesSearchUseCaseTwice() async {
        let (sut, filesSearchUseCase) = makeSUT()
        
        _ = try? await sut.systemVideoPlaylists()
        _ = try? await sut.systemVideoPlaylists()
        
        XCTAssertEqual(filesSearchUseCase.messages, [ .search, .search ])
    }
    
    func testSystemVideoPlaylists_whenError_returnsError() async {
        let (sut, _) = makeSUT(filesSearchUseCase: MockFilesSearchUseCase(searchResult: .failure(.generic)))
        
        do {
            _ = try await sut.systemVideoPlaylists()
            XCTFail("Expect to fail")
        } catch {
            XCTAssertTrue(error is GenericErrorEntity,  "Expect to get error")
        }
    }
    
    func testSystemVideoPlaylists_whenSuccessfullyLoadPlaylistWithEmptyVideos_returnsEmptySystemVideoPlaylists() async throws {
        let emptyVideos = [NodeEntity]()
        let (sut, _) = makeSUT(
            filesSearchUseCase: MockFilesSearchUseCase(searchResult: .success(emptyVideos))
        )
        
        let resultVideoPlaylists = try await sut.systemVideoPlaylists()
        
        assertThatSystemPlaylistCreatedCorrectly(resultVideoPlaylists: resultVideoPlaylists, expectedVideosCount: emptyVideos.count)
    }
    
    func testSystemVideoPlaylists_whenSuccessfullyLoadPlaylistWithNonFavoriteVideos_returnsEmptySystemVideoPlaylists() async throws {
        let nonFavoriteVideos = [
            anyNode(id: 1, isFavorite: false),
            anyNode(id: 2, isFavorite: false)
        ]
        let (sut, _) = makeSUT(
            filesSearchUseCase: MockFilesSearchUseCase(searchResult: .success(nonFavoriteVideos))
        )
        
        let resultVideoPlaylists = try await sut.systemVideoPlaylists()
        
        assertThatSystemPlaylistCreatedCorrectly(resultVideoPlaylists: resultVideoPlaylists, expectedVideosCount: 0)
    }
    
    func testSystemVideoPlaylists_whenSuccessfullyLoadPlaylistWithSomeFavoriteVideos_returnsSystemVideoPlaylistsWithFavoritesVideosCountOnly() async throws {
        let videos = [
            anyNode(id: 1, isFavorite: false),
            anyNode(id: 2, isFavorite: true)
        ]
        let (sut, _) = makeSUT(
            filesSearchUseCase: MockFilesSearchUseCase(searchResult: .success(videos))
        )
        
        let resultVideoPlaylists = try await sut.systemVideoPlaylists()
        
        assertThatSystemPlaylistCreatedCorrectly(resultVideoPlaylists: resultVideoPlaylists, expectedVideosCount: 1)
    }
    
    func testSystemVideoPlaylists_whenSuccessfullyLoadPlaylistWitAllFavoriteVideos_returnsSystemVideoPlaylistsWithFavoritesVideosCountOnly() async throws {
        let favoriteVideos = [
            anyNode(id: 1, isFavorite: true),
            anyNode(id: 2, isFavorite: true)
        ]
        let (sut, _) = makeSUT(
            filesSearchUseCase: MockFilesSearchUseCase(searchResult: .success(favoriteVideos))
        )
        
        let resultVideoPlaylists = try await sut.systemVideoPlaylists()
        
        assertThatSystemPlaylistCreatedCorrectly(resultVideoPlaylists: resultVideoPlaylists, expectedVideosCount: favoriteVideos.count)
    }
    
    // MARK: - Helpers
    
    private func makeSUT(
        filesSearchUseCase: MockFilesSearchUseCase = MockFilesSearchUseCase(searchResult: .failure(.generic))
    ) -> (
        sut: VideoPlaylistUseCase,
        filesSearchUseCase: MockFilesSearchUseCase
    ) {
        let sut = VideoPlaylistUseCase(fileSearchUseCase: filesSearchUseCase)
        return (sut, filesSearchUseCase)
    }
    
    private func anyNode(id: HandleEntity, isFavorite: Bool = false) -> NodeEntity {
        NodeEntity(
            changeTypes: .favourite,
            nodeType: .file,
            name: "name: \(id.description)",
            handle: id,
            isFile: true,
            hasThumbnail: true,
            hasPreview: true,
            isFavourite: isFavorite,
            label: .unknown,
            publicHandle: id,
            size: 2,
            duration: 2,
            mediaType: .video
        )
    }
    
    private func assertThatSystemPlaylistCreatedCorrectly(
        resultVideoPlaylists: [VideoPlaylistEntity],
        expectedVideosCount: Int,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let favoriteVideoPlaylist = resultVideoPlaylists.first
        XCTAssertEqual(resultVideoPlaylists.count, 1, file: file, line: line)
        XCTAssertEqual(favoriteVideoPlaylist?.id, 1, file: file, line: line)
        XCTAssertEqual(favoriteVideoPlaylist?.name, "", file: file, line: line)
        XCTAssertEqual(favoriteVideoPlaylist?.coverNode, nil, file: file, line: line)
        XCTAssertEqual(favoriteVideoPlaylist?.count, expectedVideosCount, file: file, line: line)
        XCTAssertEqual(favoriteVideoPlaylist?.type, .favourite, file: file, line: line)
        XCTAssertEqual(favoriteVideoPlaylist?.sharedLinkStatus, .exported(false), file: file, line: line)
    }
}
