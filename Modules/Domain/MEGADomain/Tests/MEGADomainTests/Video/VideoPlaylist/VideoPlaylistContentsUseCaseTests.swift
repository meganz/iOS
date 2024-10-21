import MEGADomain
import MEGADomainMock
import MEGASwift
import Testing
import XCTest

final class VideoPlaylistContentsUseCaseTests: XCTestCase {
    
    // MARK: - init
    
    func testInit_whenInit_doesNotPerformRequestToCollaborators() async {
        let (_, userVideoPlaylistRepository, photoLibraryUseCase, fileSearchRepository) = makeSUT()
        
        let userVideoPlaylistRepositoryMessages = userVideoPlaylistRepository.messages
        let photoLibraryUseCaseMessages = await photoLibraryUseCase.messages
        XCTAssertTrue(userVideoPlaylistRepositoryMessages.isEmpty)
        XCTAssertTrue(photoLibraryUseCaseMessages.isEmpty)
        XCTAssertTrue(fileSearchRepository.messages.isEmpty)
    }
    
    // MARK: - videos
    
    func testVideos_favoritePlaylistType_getVideos() async {
        let (sut, _, photoLibraryUseCase, _) = makeSUT()
        let videoPlaylist = VideoPlaylistEntity(setIdentifier: SetIdentifier(handle: 1), name: "Favorite", count: 0, type: .favourite, creationTime: Date(), modificationTime: Date())
        
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
        let videoPlaylist = VideoPlaylistEntity(setIdentifier: SetIdentifier(handle: 1), name: "Favorite", count: 0, type: .favourite, creationTime: Date(), modificationTime: Date())
        
        let videos = try await sut.videos(in: videoPlaylist)
        
        XCTAssertTrue(videos.allSatisfy { $0.isFavourite })
    }
    
    func testVideos_userPlaylistType_getVideos() async {
        let videoPlaylist = VideoPlaylistEntity(setIdentifier: SetIdentifier(handle: 1), name: "my custom video playlists", count: 0, type: .user, creationTime: Date(), modificationTime: Date())
        let (sut, userVideoPlaylistRepository, _, fileSearchRepository) = makeSUT(
            videoPlaylistContentResult: [ setElementEntity(id: 1) ]
        )
        
        _ = try? await sut.videos(in: videoPlaylist)
        
        let userVideoPlaylistRepositoryMessages = userVideoPlaylistRepository.messages
        XCTAssertEqual(userVideoPlaylistRepositoryMessages, [
            .videoPlaylistContent(id: videoPlaylist.id, includeElementsInRubbishBin: false)
        ])
        
        let fileSearchRepositoryMessages = fileSearchRepository.messages
        XCTAssertEqual(fileSearchRepositoryMessages, [ .node(id: 1) ])
    }
    
    // MARK: - userVideoPlaylistVideos
    
    func userVideoPlaylistVideos_whenHasVideos_deliversVideos() async {
        let videoPlaylist = VideoPlaylistEntity(setIdentifier: SetIdentifier(handle: 1), name: "my custom video playlists", count: 0, type: .user, creationTime: Date(), modificationTime: Date())
        let (sut, _, _, _) = makeSUT(
            videoPlaylistContentResult: [ setElementEntity(id: 1) ],
            fileSearchRepositoryResult: [ NodeEntity(handle: 1, isFavourite: true, mediaType: .video) ]
        )
        
        let videos = await sut.userVideoPlaylistVideos(by: videoPlaylist.id)
        
        XCTAssertTrue(videos.isNotEmpty)
    }

    // MARK: - monitorVideoPlaylist - (favorite video playlist)
    
    func testMonitorVideoPlaylist_whenNoUpdatesOnFavoriteNodes_emitesValue() async {
        let videoPlaylist = VideoPlaylistEntity(setIdentifier: SetIdentifier(handle: 1), name: "Favorites", count: 0, type: .favourite, creationTime: Date(), modificationTime: Date())
        let (sut, _, _, _) = makeSUT(
            nodeRepository: MockNodeRepository(nodeUpdates: EmptyAsyncSequence().eraseToAnyAsyncSequence())
        )
        
        @Atomic var receivedVideoPlaylist: VideoPlaylistEntity?
        let started = expectation(description: "started")
        let iterated = expectation(description: "iterated")
        let finished = expectation(description: "finished")
        let task = Task { @Sendable in
            started.fulfill()
            for try await videoPlaylist in sut.monitorVideoPlaylist(for: videoPlaylist) {
                $receivedVideoPlaylist.mutate { $0 = videoPlaylist }
                iterated.fulfill()
            }
            finished.fulfill()
        }
        
        await fulfillment(of: [started, iterated, finished], timeout: 0.5)
        task.cancel()
        
        XCTAssertEqual(receivedVideoPlaylist, videoPlaylist)
    }
    
    // MARK: - monitorVideoPlaylistContent - (favorite video playlist)
    
    func testMonitorVideoPlaylist_whenNoUpdatesOnFavoriteNodes_doesNotEmitsValue() async {
        let videoPlaylist = VideoPlaylistEntity(setIdentifier: SetIdentifier(handle: 1), name: "Favorites", count: 0, type: .favourite, creationTime: Date(), modificationTime: Date())
        let (sut, _, _, _) = makeSUT(
            nodeRepository: MockNodeRepository(nodeUpdates: EmptyAsyncSequence().eraseToAnyAsyncSequence())
        )
        
        @Atomic var receivedVideos: [NodeEntity]?
        let started = expectation(description: "started")
        let iterated = expectation(description: "iterated")
        let finished = expectation(description: "finished")
        let task = Task { @Sendable in
            started.fulfill()
            for try await videos in sut.monitorUserVideoPlaylistContent(for: videoPlaylist) {
                $receivedVideos.mutate { $0 = videos }
                iterated.fulfill()
            }
            finished.fulfill()
        }
        
        await fulfillment(of: [started, iterated, finished], timeout: 0.5)
        task.cancel()
        
        XCTAssertTrue(receivedVideos?.isEmpty == true)
    }
    
    func testMonitorUserVideoPlaylistContent_whenHasFavoriteImagePlaylistUpdates_doesNotEmitsUpdate() async {
        let videoPlaylist = VideoPlaylistEntity(
            setIdentifier: SetIdentifier(handle: 1),
            name: "Favorites",
            count: 0,
            type: .favourite,
            creationTime: Date(),
            modificationTime: Date()
        )
        let expectedResults = [
            NodeEntity(name: "node-1.png", handle: 1, mediaType: .image),
            NodeEntity(name: "node-2.png", handle: 2, mediaType: .image)
        ]
        let nodeUpdatesStream = AsyncStream { continuation in
            for expectedResult in expectedResults {
                continuation.yield([expectedResult])
            }
            continuation.finish()
        }.eraseToAnyAsyncSequence()
        let (sut, _, _, _) = makeSUT(
            nodeRepository: MockNodeRepository(nodeUpdates: nodeUpdatesStream)
        )
        
        @Atomic var receivedVideos = [NodeEntity]()
        let started = expectation(description: "started")
        let iterated = expectation(description: "iterated")
        let finished = expectation(description: "finished")
        let task = Task { @Sendable in
            started.fulfill()
            for await videos in sut.monitorUserVideoPlaylistContent(for: videoPlaylist) {
                $receivedVideos.mutate { $0 = videos }
                iterated.fulfill()
            }
            finished.fulfill()
        }
        
        await fulfillment(of: [started, iterated, finished], timeout: 0.5)
        task.cancel()
        
        XCTAssertTrue(receivedVideos.isEmpty)
    }
    
    func testMonitorUserVideoPlaylistContent_whenHasFavoriteImagePlaylistUpdates_emitsUpdateOnlyForVideoNodeUpdates() async {
        let videoPlaylist = VideoPlaylistEntity(
            setIdentifier: SetIdentifier(handle: 1),
            name: "Favorites",
            count: 0,
            type: .favourite,
            creationTime: Date(),
            modificationTime: Date()
        )
        let expectedResults = [
            NodeEntity(name: "node-1.mp4", handle: 1, mediaType: .video),
            NodeEntity(name: "node-2.png", handle: 2, mediaType: .image)
        ]
        let nodeUpdatesStream = AsyncStream { continuation in
            for expectedResult in expectedResults {
                continuation.yield([expectedResult])
            }
            continuation.finish()
        }.eraseToAnyAsyncSequence()
        let (sut, _, _, _) = makeSUT(
            nodeRepository: MockNodeRepository(nodeUpdates: nodeUpdatesStream)
        )
        
        @Atomic var receivedVideos = [NodeEntity]()
        let started = expectation(description: "started")
        let iterated = expectation(description: "iterated")
        iterated.expectedFulfillmentCount = 2
        let finished = expectation(description: "finished")
        let task = Task { @Sendable in
            started.fulfill()
            for await videos in sut.monitorUserVideoPlaylistContent(for: videoPlaylist) {
                $receivedVideos.mutate { $0 = videos }
                iterated.fulfill()
            }
            finished.fulfill()
        }
        
        await fulfillment(of: [started, iterated, finished], timeout: 0.5)
        task.cancel()
        
        XCTAssertTrue(receivedVideos.allSatisfy { $0.mediaType == .video })
    }
    
    func testMonitorUserVideoPlaylistContent_whenHasFavoriteImagePlaylistUpdates_emitsUpdate() async {
        let videoPlaylist = VideoPlaylistEntity(
            setIdentifier: SetIdentifier(handle: 1),
            name: "Favorites",
            count: 0,
            type: .favourite,
            creationTime: Date(),
            modificationTime: Date()
        )
        let expectedResults = [
            NodeEntity(name: "node-1.mp4", handle: 1, mediaType: .video),
            NodeEntity(name: "node-2.mp4", handle: 2, mediaType: .video)
        ]
        let nodeUpdatesStream = AsyncStream { continuation in
            for expectedResult in expectedResults {
                continuation.yield([expectedResult])
            }
            continuation.finish()
        }.eraseToAnyAsyncSequence()
        let (sut, _, _, _) = makeSUT(
            nodeRepository: MockNodeRepository(nodeUpdates: nodeUpdatesStream)
        )
        
        @Atomic var receivedVideos = [NodeEntity]()
        let started = expectation(description: "started")
        let iterated = expectation(description: "iterated")
        iterated.expectedFulfillmentCount = 3
        let finished = expectation(description: "finished")
        let task = Task { @Sendable in
            started.fulfill()
            for await videos in sut.monitorUserVideoPlaylistContent(for: videoPlaylist) {
                $receivedVideos.mutate { $0 = videos }
                iterated.fulfill()
            }
            finished.fulfill()
        }
        
        await fulfillment(of: [started, iterated, finished], timeout: 0.5)
        task.cancel()
        
        XCTAssertTrue(receivedVideos.allSatisfy { $0.mediaType == .video })
    }
    
    // MARK: - monitorVideoPlaylist - User Video Playlist
    
    func testMonitorUserVideoPlaylist_whenHasUserVideoPlaylistUpdates_emitsUpdate() async {
        let videoPlaylist = VideoPlaylistEntity(
            setIdentifier: SetIdentifier(handle: 1),
            name: "user",
            count: 0,
            type: .user,
            creationTime: Date(),
            modificationTime: Date()
        )
        let expectedResults = [
            SetEntity(
                handle: videoPlaylist.id,
                userId: 2,
                coverId: 2,
                creationTime: Date(),
                modificationTime: Date(),
                setType: .playlist,
                name: "Playlist A",
                isExported: false,
                changeTypes: [ .name ]
            ),
            SetEntity(
                handle: videoPlaylist.id + 1,
                userId: 2,
                coverId: 3,
                creationTime: Date(),
                modificationTime: Date(),
                setType: .playlist,
                name: "Playlist B",
                isExported: false,
                changeTypes: [ .name ]
            )
        ]
        let setsUpdatesStream = AsyncStream { continuation in
            for expectedResult in expectedResults {
                continuation.yield([expectedResult])
            }
            continuation.finish()
        }.eraseToAnyAsyncSequence()
        let (sut, _, _, _) = makeSUT(
            videoPlaylistsResult: expectedResults,
            setsUpdatedAsyncSequence: setsUpdatesStream
        )
        
        @Atomic var receivedVideoPlaylist: VideoPlaylistEntity?
        let started = expectation(description: "started")
        let iterated = expectation(description: "iterated")
        iterated.expectedFulfillmentCount = 2
        let finished = expectation(description: "finished")
        let task = Task { @Sendable in
            started.fulfill()
            for try await videoPlaylist in sut.monitorVideoPlaylist(for: videoPlaylist) {
                $receivedVideoPlaylist.mutate { $0 = videoPlaylist }
                iterated.fulfill()
            }
            finished.fulfill()
        }
        
        await fulfillment(of: [started, iterated, finished], timeout: 0.5)
        task.cancel()
        
        XCTAssertEqual(receivedVideoPlaylist?.id, videoPlaylist.id)
    }
    
    // MARK: - monitorVideoPlaylist - User Video Playlist Content
    
    func testMonitorUserVideoPlaylist_whenHasNoUserVideoPlaylistContentUpdates_doesNotEmitsUpdate() async {
        let videoPlaylist = VideoPlaylistEntity(setIdentifier: SetIdentifier(handle: 1), name: "user", count: 0, type: .user, creationTime: Date(), modificationTime: Date())
        let (sut, _, _, _) = makeSUT(
            setElementsUpdatedAsyncSequence: EmptyAsyncSequence().eraseToAnyAsyncSequence()
        )
        
        let started = expectation(description: "started")
        let iterated = expectation(description: "iterated")
        iterated.isInverted = true
        let finished = expectation(description: "finished")
        let task = Task {
            started.fulfill()
            do {
                for try await _ in sut.monitorVideoPlaylist(for: videoPlaylist) {
                    iterated.fulfill()
                }
            } catch {
                finished.fulfill()
                XCTAssertEqual(error as? VideoPlaylistErrorEntity, .videoPlaylistNotFound(id: videoPlaylist.id))
            }
        }
        
        await fulfillment(of: [started, iterated, finished], timeout: 0.5)
        task.cancel()
    }
    
    // MARK: - monitorUserVideoPlaylistContent
    
    func testMonitorUserVideoPlaylistContent_whenHasUserVideoPlaylistContentUpdates_emitsUpdate() async {
        let videoPlaylist = VideoPlaylistEntity(setIdentifier: SetIdentifier(handle: 1), name: "user", count: 0, type: .user, creationTime: Date(), modificationTime: Date())
        let expectedResults = anyVideoPlaylistContents()
        let setElementUpdatesStream = AsyncStream { continuation in
            for expectedResult in expectedResults {
                continuation.yield([expectedResult])
            }
            continuation.finish()
        }.eraseToAnyAsyncSequence()
        let (sut, _, _, _) = makeSUT(
            setElementsUpdatedAsyncSequence: setElementUpdatesStream
        )
        
        @Atomic var receivedVideos: [NodeEntity]?
        let started = expectation(description: "started")
        let iterated = expectation(description: "iterated")
        iterated.expectedFulfillmentCount = 2
        let finished = expectation(description: "finished")
        let task = Task { @Sendable in
            started.fulfill()
            for await videos in sut.monitorUserVideoPlaylistContent(for: videoPlaylist) {
                $receivedVideos.mutate { $0 = videos }
                iterated.fulfill()
            }
            finished.fulfill()
        }
        
        await fulfillment(of: [started, iterated, finished], timeout: 1)
        task.cancel()
        
        XCTAssertNotNil(receivedVideos)
    }
    
    // MARK: - monitorUserVideoPlaylistContent - folderSensitivityChanged
    
    func testMonitorUserVideoPlaylistContent_whenFolderSensitivtyHasChanged_emitsUpdate() async {
        let videoPlaylist = VideoPlaylistEntity(setIdentifier: SetIdentifier(handle: 1), name: "user", count: 0, type: .user, creationTime: Date(), modificationTime: Date())
        let (sut, _, _, _) = makeSUT(
            sensitiveNodeUseCase: MockSensitiveNodeUseCase(
                folderSensitivityChanged: SingleItemAsyncSequence(item: ()).eraseToAnyAsyncSequence())
        )
        
        @Atomic var receivedVideos: [NodeEntity]?
        let started = expectation(description: "started")
        let iterated = expectation(description: "iterated")
        iterated.expectedFulfillmentCount = 2
        let finished = expectation(description: "finished")
        let task = Task { @Sendable in
            started.fulfill()
            for await videos in sut.monitorUserVideoPlaylistContent(for: videoPlaylist) {
                $receivedVideos.mutate { $0 = videos }
                iterated.fulfill()
            }
            finished.fulfill()
        }
        
        await fulfillment(of: [started, iterated, finished], timeout: 1)
        task.cancel()
        
        XCTAssertNotNil(receivedVideos)
    }
    
    // MARK: - Helpers
    
    private func makeSUT(
        videoPlaylistContentResult: [SetElementEntity] = [],
        photoLibraryUseCase: MockPhotoLibraryUseCase = MockPhotoLibraryUseCase(),
        fileSearchRepositoryResult: [NodeEntity] = [],
        videoPlaylistsResult: [SetEntity] = [],
        nodeRepository: MockNodeRepository = MockNodeRepository(),
        setsUpdatedAsyncSequence: AnyAsyncSequence<[SetEntity]> = EmptyAsyncSequence().eraseToAnyAsyncSequence(),
        setElementsUpdatedAsyncSequence: AnyAsyncSequence<[SetElementEntity]> = EmptyAsyncSequence().eraseToAnyAsyncSequence(),
        excludeSensitives: Bool = false,
        sensitiveNodeUseCase: MockSensitiveNodeUseCase = .init()
    ) -> (
        sut: VideoPlaylistContentsUseCase,
        userVideoPlaylistRepository: MockUserVideoPlaylistsRepository,
        photoLibraryUseCase: MockPhotoLibraryUseCase,
        fileSearchRepository: MockFilesSearchRepository
    ) {
        let userVideoPlaylistRepository = MockUserVideoPlaylistsRepository(
            videoPlaylistsResult: videoPlaylistsResult,
            videoPlaylistContentResult: videoPlaylistContentResult,
            setsUpdatedAsyncSequence: setsUpdatedAsyncSequence,
            setElementsUpdatedAsyncSequence: setElementsUpdatedAsyncSequence
        )
        let fileSearchRepository = MockFilesSearchRepository(videoNodes: fileSearchRepositoryResult)
        let sut = VideoPlaylistContentsUseCase(
            userVideoPlaylistRepository: userVideoPlaylistRepository,
            photoLibraryUseCase: photoLibraryUseCase,
            fileSearchRepository: fileSearchRepository,
            nodeRepository: nodeRepository,
            sensitiveDisplayPreferenceUseCase: MockSensitiveDisplayPreferenceUseCase(excludeSensitives: excludeSensitives),
            sensitiveNodeUseCase: sensitiveNodeUseCase
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
    
    private func setEntity(handle: HandleEntity, name: String, isExported: Bool) -> SetEntity {
        SetEntity(
            handle: handle,
            userId: 1,
            coverId: 1,
            creationTime: Date(),
            modificationTime: Date(),
            setType: .playlist,
            name: name,
            isExported: isExported,
            changeTypes: .new
        )
    }
    
    private func anyPlaylists() -> [SetEntity] {
        [
            videoPlaylistSetEntity(handle: 1, setType: .playlist, name: "My Video Playlist"),
            videoPlaylistSetEntity(handle: 2, setType: .playlist, name: "My Video Playlist 2")
        ]
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
    
    private func anyVideoPlaylistContents() -> [SetElementEntity] {
        [
            SetElementEntity(handle: 1, ownerId: 1, order: 1, nodeId: 1, modificationTime: Date(), name: "name", changeTypes: .name)
        ]
    }
}

@Suite("Video Playlist Contents Use Case Tests")
struct VideoPlaylistContentsUseCaseTestSuite {
    
    @Suite("userVideoPlaylistVideos for set handle")
    struct UserVideoPlaylistVideos {
        
        @Suite("Exclude sensitives")
        struct ExcludeSensitives {
            @Test("User playlist videos should filter out sensitive videos",
                  arguments: [
                    ([SetElementEntity.mp4Element, .sensitiveMp4Element],
                     [NodeEntity.mp4, .sensitiveMp4],
                     [NodeEntity.mp4.handle: Result<Bool, Error>.success(false)],
                     [VideoPlaylistVideoEntity(video: .mp4, videoPlaylistVideoId: SetElementEntity.mp4Element.handle)]
                    ),
                    ([SetElementEntity.mp4Element, .sensitiveMp4Element],
                     [NodeEntity.mp4, .sensitiveMp4],
                     [NodeEntity.mp4.handle: Result<Bool, Error>.success(true)],
                     []
                    )
                  ])
            func userPlaylistVideosExcludingSensitives(
                videoPlaylistContents: [SetElementEntity],
                videos: [NodeEntity],
                isInheritingSensitivityResults: [HandleEntity: Result<Bool, Error>],
                expectedPlaylistVideos: [VideoPlaylistVideoEntity]
            ) async {
                let sut = UserVideoPlaylistVideos.makeSUT(
                    excludeSensitives: true,
                    videoPlaylistContents: videoPlaylistContents,
                    videos: videos,
                    isInheritingSensitivityResults: isInheritingSensitivityResults)
                
                #expect(Set(await sut.userVideoPlaylistVideos(by: SetEntity.videoPlaylist.handle)) == Set(expectedPlaylistVideos))
            }
        }
        
        @Suite("Include sensitives")
        struct IncludeSensitives {
            @Test("User playlist videos should include sensitive videos")
            func userPlaylistVideosIncludingSensitives() async {
                let sut = UserVideoPlaylistVideos.makeSUT(
                    excludeSensitives: false,
                    videoPlaylistContents: [SetElementEntity.mp4Element, .sensitiveMp4Element],
                    videos: [NodeEntity.mp4, .sensitiveMp4])
                
                let expectedResult = Set([VideoPlaylistVideoEntity(video: .mp4, videoPlaylistVideoId: SetElementEntity.mp4Element.handle),
                                          VideoPlaylistVideoEntity(video: .sensitiveMp4, videoPlaylistVideoId: SetElementEntity.sensitiveMp4Element.handle)])
                #expect(Set(await sut.userVideoPlaylistVideos(by: SetEntity.videoPlaylist.handle)) == expectedResult)
            }
        }
        
        private static func makeSUT(
            excludeSensitives: Bool = false,
            videoPlaylistContents: [SetElementEntity] = [],
            videos: [NodeEntity] = [],
            isInheritingSensitivityResults: [HandleEntity: Result<Bool, Error>] = [:]
        ) -> VideoPlaylistContentsUseCase {
            let userVideoPlaylistRepository = MockUserVideoPlaylistsRepository(
                videoPlaylistContentResult: videoPlaylistContents
            )
            let fileSearchRepository = MockFilesSearchRepository(nodesForHandle: [1: videos])
            let sensitiveDisplayPreferenceUseCase = MockSensitiveDisplayPreferenceUseCase(excludeSensitives: excludeSensitives)
            let sensitiveNodeUseCase = MockSensitiveNodeUseCase(isInheritingSensitivityResults: isInheritingSensitivityResults)
            return VideoPlaylistContentsUseCaseTestSuite
                .makeSUT(
                    userVideoPlaylistRepository: userVideoPlaylistRepository,
                    fileSearchRepository: fileSearchRepository,
                    sensitiveDisplayPreferenceUseCase: sensitiveDisplayPreferenceUseCase,
                    sensitiveNodeUseCase: sensitiveNodeUseCase)
        }
    }
    
    private static func makeSUT(
        userVideoPlaylistRepository: some UserVideoPlaylistsRepositoryProtocol = MockUserVideoPlaylistsRepository(),
        photoLibraryUseCase: some PhotoLibraryUseCaseProtocol = MockPhotoLibraryUseCase(),
        fileSearchRepository: some FilesSearchRepositoryProtocol = MockFilesSearchRepository(),
        nodeRepository: some NodeRepositoryProtocol = MockNodeRepository(),
        sensitiveDisplayPreferenceUseCase: some SensitiveDisplayPreferenceUseCaseProtocol = MockSensitiveDisplayPreferenceUseCase(),
        sensitiveNodeUseCase: some SensitiveNodeUseCaseProtocol = MockSensitiveNodeUseCase()
    ) -> VideoPlaylistContentsUseCase {
        .init(
            userVideoPlaylistRepository: userVideoPlaylistRepository,
            photoLibraryUseCase: photoLibraryUseCase,
            fileSearchRepository: fileSearchRepository,
            nodeRepository: nodeRepository,
            sensitiveDisplayPreferenceUseCase: sensitiveDisplayPreferenceUseCase,
            sensitiveNodeUseCase: sensitiveNodeUseCase)
    }
}

private extension SetEntity {
    static let videoPlaylist = SetEntity(handle: 56)
}

private extension SetElementEntity {
    static let mp4Element = SetElementEntity(handle: 1, ownerId: SetEntity.videoPlaylist.handle, nodeId: NodeEntity.mp4.handle)
    static let sensitiveMp4Element = SetElementEntity(handle: 2, ownerId: SetEntity.videoPlaylist.handle, nodeId: NodeEntity.sensitiveMp4.handle)
}

private extension NodeEntity {
    static let mp4 = NodeEntity(name: "file.mp4", handle: 25, isMarkedSensitive: false)
    static let sensitiveMp4 = NodeEntity(name: "file.mp4", handle: 27, isMarkedSensitive: true)
}
