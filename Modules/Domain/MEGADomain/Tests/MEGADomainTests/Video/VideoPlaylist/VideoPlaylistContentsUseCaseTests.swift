import MEGADomain
import MEGADomainMock
import XCTest

final class VideoPlaylistContentsUseCaseTests: XCTestCase {
    
    // MARK: - init
    
    func testInit_whenInit_doesNotPerformRequestToCollaborators() async {
        let (_, userVideoPlaylistRepository, photoLibraryUseCase, fileSearchRepository) = makeSUT()
        
        let userVideoPlaylistRepositoryMessages = await userVideoPlaylistRepository.messages
        let photoLibraryUseCaseMessages = await photoLibraryUseCase.messages
        XCTAssertTrue(userVideoPlaylistRepositoryMessages.isEmpty)
        XCTAssertTrue(photoLibraryUseCaseMessages.isEmpty)
        XCTAssertTrue(fileSearchRepository.messages.isEmpty)
    }
    
    // MARK: - videos
    
    func testVideos_favoritePlaylistType_getVideos() async {
        let (sut, _, photoLibraryUseCase, _) = makeSUT()
        let videoPlaylist = VideoPlaylistEntity(id: 1, name: "Favorite", count: 0, type: .favourite)
        
        _ = try? await sut.videos(in: videoPlaylist)
        
        let photoLibraryUseCaseMessages = await photoLibraryUseCase.messages
        XCTAssertEqual(photoLibraryUseCaseMessages, [ .media ])
    }
    
    func testVideos_favoritePlaylistType_deliversFavoriteVideos() async throws {
        let videoPlaylistContentResult = [ setElementEntity(id: 1) ]
        let (sut, _, _, _) = makeSUT(
            videoPlaylistContentResult: videoPlaylistContentResult,
            photoLibraryUseCase: MockPhotoLibraryUseCase(allVideos: [
                NodeEntity(handle: 1, isFavourite: true, mediaType: .video),
                NodeEntity(handle: 2, isFavourite: false, mediaType: .video)
            ])
        )
        let videoPlaylist = VideoPlaylistEntity(id: 1, name: "Favorite", count: 0, type: .favourite)
        
        let videos = try await sut.videos(in: videoPlaylist)
        
        XCTAssertTrue(videos.allSatisfy { $0.isFavourite })
    }
    
    func testVideos_userPlaylistType_getVideos() async {
        let videoPlaylist = VideoPlaylistEntity(id: 1, name: "my custom video playlists", count: 0, type: .user)
        let (sut, userVideoPlaylistRepository, _, fileSearchRepository) = makeSUT(
            videoPlaylistContentResult: [ setElementEntity(id: 1) ]
        )
        
        _ = try? await sut.videos(in: videoPlaylist)
        
        let userVideoPlaylistRepositoryMessages = await userVideoPlaylistRepository.messages
        XCTAssertEqual(userVideoPlaylistRepositoryMessages, [
            .videoPlaylistContent(id: videoPlaylist.id, includeElementsInRubbishBin: false)
        ])
        
        let fileSearchRepositoryMessages = fileSearchRepository.messages
        XCTAssertEqual(fileSearchRepositoryMessages, [ .node(id: 1) ])
    }
    
    // MARK: - userVideoPlaylistVideos
    
    func userVideoPlaylistVideos_whenHasVideos_deliversVideos() async {
        let videoPlaylist = VideoPlaylistEntity(id: 1, name: "my custom video playlists", count: 0, type: .user)
        let (sut, _, _, _) = makeSUT(
            videoPlaylistContentResult: [ setElementEntity(id: 1) ],
            fileSearchRepositoryResult: [ NodeEntity(handle: 1, isFavourite: true, mediaType: .video) ]
        )
        
        let videos = await sut.userVideoPlaylistVideos(by: videoPlaylist.id)
        
        XCTAssertTrue(videos.isNotEmpty)
    }
    
    // MARK: - Helpers
    
    private func makeSUT(
        videoPlaylistContentResult: [SetElementEntity] = [],
        photoLibraryUseCase: MockPhotoLibraryUseCase = MockPhotoLibraryUseCase(),
        fileSearchRepositoryResult: [NodeEntity] = []
    ) -> (
        sut: VideoPlaylistContentsUseCase,
        userVideoPlaylistRepository: MockUserVideoPlaylistsRepository,
        photoLibraryUseCase: MockPhotoLibraryUseCase,
        fileSearchRepository: MockFilesSearchRepository
    ) {
        let userVideoPlaylistRepository = MockUserVideoPlaylistsRepository(
            videoPlaylistContentResult: videoPlaylistContentResult
        )
        let fileSearchRepository = MockFilesSearchRepository(videoNodes: fileSearchRepositoryResult)
        let sut = VideoPlaylistContentsUseCase(
            userVideoPlaylistRepository: userVideoPlaylistRepository,
            photoLibraryUseCase: photoLibraryUseCase,
            fileSearchRepository: fileSearchRepository
        )
        return (sut, userVideoPlaylistRepository, photoLibraryUseCase, fileSearchRepository)
    }
    
    private func setElementEntity(id: HandleEntity) -> SetElementEntity {
        SetElementEntity(
            handle: 1,
            ownerId: 2,
            order: 2,
            nodeId: 1,
            modificationTime: Date(),
            name: "Video \(1)",
            changeTypes: .name
        )
    }
}
