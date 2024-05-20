@testable import MEGADomain
import MEGADomainMock
import XCTest

final class VideoPlaylistUseCaseTests: XCTestCase {
    
    // MARK: - Init
    
    func testInit_whenCalled_doesNotTriggerFilesSearchUseCase() {
        let (_, filesSearchUseCase, _) = makeSUT()
        
        XCTAssertTrue(filesSearchUseCase.messages.isEmpty)
    }
    
    // MARK: - systemVideoPlaylists
    
    func testSystemVideoPlaylists_whenCalled_TriggerFilesSearchUseCase() async {
        let (sut, filesSearchUseCase, _) = makeSUT()
        
        _ = try? await sut.systemVideoPlaylists()
        
        XCTAssertEqual(filesSearchUseCase.messages, [ .searchLegacy ])
    }
    
    func testSystemVideoPlaylists_whenCalledTwice_TriggerFilesSearchUseCaseTwice() async {
        let (sut, filesSearchUseCase, _) = makeSUT()
        
        _ = try? await sut.systemVideoPlaylists()
        _ = try? await sut.systemVideoPlaylists()
        
        XCTAssertEqual(filesSearchUseCase.messages, [ .searchLegacy, .searchLegacy ])
    }
    
    func testSystemVideoPlaylists_whenError_returnsError() async {
        let (sut, _, _) = makeSUT()
        
        do {
            _ = try await sut.systemVideoPlaylists()
            XCTFail("Expect to fail")
        } catch {
            XCTAssertTrue(error is GenericErrorEntity, "Expect to get error")
        }
    }
    
    func testSystemVideoPlaylists_whenSuccessfullyLoadPlaylistWithEmptyVideos_returnsEmptySystemVideoPlaylists() async throws {
        let emptyVideos = [NodeEntity]()
        let (sut, _, _) = makeSUT(
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
        let (sut, _, _) = makeSUT(
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
        let (sut, _, _) = makeSUT(
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
        let (sut, _, _) = makeSUT(
            filesSearchUseCase: MockFilesSearchUseCase(searchResult: .success(favoriteVideos))
        )
        
        let resultVideoPlaylists = try await sut.systemVideoPlaylists()
        
        assertThatSystemPlaylistCreatedCorrectly(resultVideoPlaylists: resultVideoPlaylists, expectedVideosCount: favoriteVideos.count)
    }
    
    // MARK: - userVideoPlaylists
    
    func testUserVideoPlaylists_whenCalled_getUserVideoPlaylists() async {
        let (sut, _, userVideoPlaylistsRepository) = makeSUT(
            userVideoPlaylistRepositoryResult: []
        )
        
        _ = await sut.userVideoPlaylists()
        
        let messages = await userVideoPlaylistsRepository.messages
        XCTAssertEqual(messages, [ .userVideoPlaylists ])
    }
    
    func testUserVideoPlaylists_whenCalledTwice_getUserVideoPlaylistsTwice() async {
        let (sut, _, userVideoPlaylistsRepository) = makeSUT(
            userVideoPlaylistRepositoryResult: []
        )
        
        _ = await sut.userVideoPlaylists()
        _ = await sut.userVideoPlaylists()
        
        let messages = await userVideoPlaylistsRepository.messages
        XCTAssertEqual(messages, [ .userVideoPlaylists, .userVideoPlaylists ])
    }
    
    func testUserVideoPlaylists_whenCalled_returnsEmpty() async {
        let (sut, _, _) = makeSUT(
            userVideoPlaylistRepositoryResult: []
        )
        
        let userVideoPlaylists = await sut.userVideoPlaylists()
        
        XCTAssertTrue(userVideoPlaylists.isEmpty)
    }
    
    func testUserVideoPlaylists_whenCalled_returnsSinglePlaylist() async {
        let videoPlaylistSetEntities = [
            videoPlaylistSetEntity(handle: 1, setType: .playlist, name: "My Video Playlist")
        ]
        let (sut, _, _) = makeSUT(
            userVideoPlaylistRepositoryResult: videoPlaylistSetEntities
        )
        
        let userVideoPlaylists = await sut.userVideoPlaylists()
        
        XCTAssertEqual(
            userVideoPlaylists,
            videoPlaylistSetEntities.map { $0.toVideoPlaylistEntity(type: .user) }
        )
        
    }
    
    func testUserVideoPlaylists_whenCalled_returnsMoreThanOnePlaylists() async {
        let videoPlaylistSetEntities = [
            videoPlaylistSetEntity(handle: 1, setType: .playlist, name: "My Video Playlist"),
            videoPlaylistSetEntity(handle: 2, setType: .playlist, name: "My Video Playlist 2")
        ]
        let (sut, _, _) = makeSUT(
            userVideoPlaylistRepositoryResult: videoPlaylistSetEntities
        )
        
        let userVideoPlaylists = await sut.userVideoPlaylists()
        
        XCTAssertEqual(
            userVideoPlaylists,
            videoPlaylistSetEntities.map { $0.toVideoPlaylistEntity(type: .user) }
        )
    }
    
    func testUserVideoPlaylists_whenCalled_returnsOnlyUserVideoPlaylists() async {
        let videoPlaylistSetEntities = [
            videoPlaylistSetEntity(handle: 1, setType: .playlist, name: "My Video Playlist"),
            videoPlaylistSetEntity(handle: 2, setType: .album, name: "My Album")
        ]
        let userVideoPlaylistSetEntityCount = videoPlaylistSetEntities
            .filter { $0.setType == .playlist }
            .count
        let (sut, _, _) = makeSUT(
            userVideoPlaylistRepositoryResult: videoPlaylistSetEntities
        )
        
        let userVideoPlaylists = await sut.userVideoPlaylists()
        
        XCTAssertEqual(userVideoPlaylists.count, userVideoPlaylistSetEntityCount, "Should only returning Set entities with type SetType.playlist only")
        XCTAssert(userVideoPlaylists.allSatisfy { $0.type == .user })
    }
    
    // MARK: - Helpers
    
    private func makeSUT(
        filesSearchUseCase: MockFilesSearchUseCase = MockFilesSearchUseCase(searchResult: .failure(.generic), nodeListSearchResult: .failure(.generic)),
        userVideoPlaylistRepositoryResult: [SetEntity] = []
    ) -> (
        sut: VideoPlaylistUseCase,
        filesSearchUseCase: MockFilesSearchUseCase,
        userVideoPlaylistRepository: MockUserVideoPlaylistsRepository
    ) {
        let userVideoPlaylistRepository = MockUserVideoPlaylistsRepository(
            videoPlaylistsResult: userVideoPlaylistRepositoryResult,
            addVideosToVideoPlaylistResult: .failure(GenericErrorEntity()),
            deleteVideosResult: .failure(GenericErrorEntity())
        )
        let sut = VideoPlaylistUseCase(
            fileSearchUseCase: filesSearchUseCase,
            userVideoPlaylistsRepository: userVideoPlaylistRepository
        )
        return (sut, filesSearchUseCase, userVideoPlaylistRepository)
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
    
    private func videoPlaylistSetEntity(handle: HandleEntity, setType: SetTypeEntity, name: String) -> SetEntity {
        SetEntity(
            handle: 1,
            userId: 1,
            coverId: .invalid,
            creationTime: Date(),
            modificationTime: Date(),
            setType: .playlist,
            name: name,
            isExported: false,
            changeTypes: .new
        )
    }
}
