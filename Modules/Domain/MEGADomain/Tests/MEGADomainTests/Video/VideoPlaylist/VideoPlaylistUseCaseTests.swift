@testable import MEGADomain
import MEGADomainMock
import MEGASwift
import XCTest

final class VideoPlaylistUseCaseTests: XCTestCase {
    
    // MARK: - Init
    
    func testInit_whenCalled_doesNotTriggerFilesSearchUseCase() async {
        let (_, _, _, photoLibraryUseCase) = makeSUT()
        
        let messages = await photoLibraryUseCase.messages
        XCTAssertTrue(messages.isEmpty)
    }
    
    // MARK: - systemVideoPlaylists
    
    func testSystemVideoPlaylists_whenCalled_TriggerFilesSearchUseCase() async {
        let (sut, _, _, photoLibraryUseCase) = makeSUT()
        
        _ = try? await sut.systemVideoPlaylists()
        
        let messages = await photoLibraryUseCase.messages
        XCTAssertEqual(messages, [ .media ])
    }
    
    func testSystemVideoPlaylists_whenCalledTwice_TriggerFilesSearchUseCaseTwice() async {
        let (sut, _, _, photoLibraryUseCase) = makeSUT()
        
        _ = try? await sut.systemVideoPlaylists()
        _ = try? await sut.systemVideoPlaylists()
        
        let messages = await photoLibraryUseCase.messages
        XCTAssertEqual(messages, [ .media, .media ])
    }
    
    func testSystemVideoPlaylists_whenError_returnsError() async {
        let (sut, _, _, _) = makeSUT(photoLibrarayUseCase: MockPhotoLibraryUseCase(succesfullyLoadMedia: false))
        
        do {
            _ = try await sut.systemVideoPlaylists()
            XCTFail("Expect to fail")
        } catch {
            XCTAssertTrue(error is GenericErrorEntity, "Expect to get error")
        }
    }
    
    func testSystemVideoPlaylists_whenSuccessfullyLoadPlaylistWithEmptyVideos_returnsEmptySystemVideoPlaylists() async throws {
        let emptyVideos = [NodeEntity]()
        let (sut, _, _, _) = makeSUT(
            photoLibrarayUseCase: MockPhotoLibraryUseCase(allVideos: emptyVideos)
        )
        
        let resultVideoPlaylists = try await sut.systemVideoPlaylists()
        
        assertThatSystemPlaylistCreatedCorrectly(resultVideoPlaylists: resultVideoPlaylists, expectedVideosCount: emptyVideos.count)
    }
    
    func testSystemVideoPlaylists_whenSuccessfullyLoadPlaylistWithNonFavoriteVideos_returnsEmptySystemVideoPlaylists() async throws {
        let nonFavoriteVideos = [
            anyNode(id: 1, isFavorite: false),
            anyNode(id: 2, isFavorite: false)
        ]
        let (sut, _, _, _) = makeSUT(
            photoLibrarayUseCase: MockPhotoLibraryUseCase(allVideos: nonFavoriteVideos)
        )
        
        let resultVideoPlaylists = try await sut.systemVideoPlaylists()
        
        assertThatSystemPlaylistCreatedCorrectly(resultVideoPlaylists: resultVideoPlaylists, expectedVideosCount: 0)
    }
    
    func testSystemVideoPlaylists_whenSuccessfullyLoadPlaylistWithSomeFavoriteVideos_returnsSystemVideoPlaylistsWithFavoritesVideosCountOnly() async throws {
        let videos = [
            anyNode(id: 1, isFavorite: false),
            anyNode(id: 2, isFavorite: true)
        ]
        let (sut, _, _, _) = makeSUT(
            photoLibrarayUseCase: MockPhotoLibraryUseCase(allVideos: videos)
        )
        
        let resultVideoPlaylists = try await sut.systemVideoPlaylists()
        
        assertThatSystemPlaylistCreatedCorrectly(resultVideoPlaylists: resultVideoPlaylists, expectedVideosCount: 1)
    }
    
    func testSystemVideoPlaylists_whenSuccessfullyLoadPlaylistWitAllFavoriteVideos_returnsSystemVideoPlaylistsWithFavoritesVideosCountOnly() async throws {
        let favoriteVideos = [
            anyNode(id: 1, isFavorite: true),
            anyNode(id: 2, isFavorite: true)
        ]
        let (sut, _, _, _) = makeSUT(
            photoLibrarayUseCase: MockPhotoLibraryUseCase(allVideos: favoriteVideos)
        )
        
        let resultVideoPlaylists = try await sut.systemVideoPlaylists()
        
        assertThatSystemPlaylistCreatedCorrectly(resultVideoPlaylists: resultVideoPlaylists, expectedVideosCount: favoriteVideos.count)
    }
    
    // MARK: - userVideoPlaylists
    
    func testUserVideoPlaylists_whenCalled_getUserVideoPlaylists() async {
        let (sut, _, userVideoPlaylistsRepository, _) = makeSUT(
            userVideoPlaylistRepositoryResult: []
        )
        
        _ = await sut.userVideoPlaylists()
        
        let messages = userVideoPlaylistsRepository.messages
        XCTAssertEqual(messages, [ .userVideoPlaylists ])
    }
    
    func testUserVideoPlaylists_whenCalledTwice_getUserVideoPlaylistsTwice() async {
        let (sut, _, userVideoPlaylistsRepository, _) = makeSUT(
            userVideoPlaylistRepositoryResult: []
        )
        
        _ = await sut.userVideoPlaylists()
        _ = await sut.userVideoPlaylists()
        
        let messages = userVideoPlaylistsRepository.messages
        XCTAssertEqual(messages, [ .userVideoPlaylists, .userVideoPlaylists ])
    }
    
    func testUserVideoPlaylists_whenCalled_returnsEmpty() async {
        let (sut, _, _, _) = makeSUT(
            userVideoPlaylistRepositoryResult: []
        )
        
        let userVideoPlaylists = await sut.userVideoPlaylists()
        
        XCTAssertTrue(userVideoPlaylists.isEmpty)
    }
    
    func testUserVideoPlaylists_whenCalled_returnsSinglePlaylist() async {
        let videoPlaylistSetEntities = [
            videoPlaylistSetEntity(handle: 1, setType: .playlist, name: "My Video Playlist")
        ]
        let (sut, _, _, _) = makeSUT(
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
        let (sut, _, _, _) = makeSUT(
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
        let (sut, _, _, _) = makeSUT(
            userVideoPlaylistRepositoryResult: videoPlaylistSetEntities
        )
        
        let userVideoPlaylists = await sut.userVideoPlaylists()
        
        XCTAssertEqual(userVideoPlaylists.count, userVideoPlaylistSetEntityCount, "Should only returning Set entities with type SetType.playlist only")
        XCTAssert(userVideoPlaylists.allSatisfy { $0.type == .user })
    }
    
    // MARK: - createVideoPlaylist
    
    func testCreateVideoPlaylist_whenCalled_createsVideoPlaylist() async {
        let videoPlaylistNameToCreate = "any-name"
        let (sut, _, userVideoPlaylistRepository, _) = makeSUT()
        
        _ = try? await sut.createVideoPlaylist(videoPlaylistNameToCreate)
        
        let messages = userVideoPlaylistRepository.messages
        XCTAssertEqual(messages, [ .createVideoPlaylist(name: videoPlaylistNameToCreate) ])
    }
    
    func testCreateVideoPlaylist_whenHasError_throwsError() async {
        let videoPlaylistNameToCreate = "any-name"
        let expectedError = VideoPlaylistErrorEntity.failedToCreatePlaylist(name: videoPlaylistNameToCreate)
        let (sut, _, _, _) = makeSUT(createVideoPlaylistResult: .failure(expectedError))
        
        do {
            _ = try await sut.createVideoPlaylist(videoPlaylistNameToCreate)
            XCTFail("expect to throw error")
        } catch {
            XCTAssertEqual(error as? VideoPlaylistErrorEntity, expectedError, "Expect to get error")
        }
    }
    
    func testCreateVideoPlaylist_whenSuccess_createsVideoPlaylistSuccessfully() async {
        let videoPlaylistNameToCreate = "any-name"
        let (sut, _, _, _) = makeSUT(
            createVideoPlaylistResult: .success(anySetEntity(id: 1, name: videoPlaylistNameToCreate))
        )
        
        do {
            let videoPlaylistEntity = try await sut.createVideoPlaylist(videoPlaylistNameToCreate)
            XCTAssertEqual(videoPlaylistEntity.id, 1)
            XCTAssertEqual(videoPlaylistEntity.name, videoPlaylistNameToCreate)
            XCTAssertEqual(videoPlaylistEntity.count, 0)
            XCTAssertEqual(videoPlaylistEntity.type, .user)
            XCTAssertEqual(videoPlaylistEntity.isLinkShared, false)
            XCTAssertEqual(videoPlaylistEntity.sharedLinkStatus, .exported(false))
            XCTAssertEqual(videoPlaylistEntity.coverNode, nil)
            XCTAssertNotNil(videoPlaylistEntity.creationTime)
            XCTAssertNotNil(videoPlaylistEntity.modificationTime)
        } catch {
            XCTFail("expect to not throw error, got error instead: \(error)")
        }
    }
    
    // MARK: - videoPlaylistsUpdatedAsyncSequence
    
    func testVideoPlaylistsUpdatedAsyncSequence_whenHasNoFavoriteVideoPlaylistUpdates_doesNotEmitsUpdate() async {
        let initialPlaylists = anyPlaylists()
        let (sut, _, _, _) = makeSUT(
            filesSearchUseCase: MockFilesSearchUseCase(nodeUpdates: EmptyAsyncSequence().eraseToAnyAsyncSequence()),
            userVideoPlaylistRepositoryResult: initialPlaylists
        )
        
        let started = expectation(description: "started")
        let iterated = expectation(description: "iterated")
        iterated.isInverted = true
        let finished = expectation(description: "finished")
        let task = Task {
            started.fulfill()
            for await _ in sut.videoPlaylistsUpdatedAsyncSequence {
                iterated.fulfill()
            }
            finished.fulfill()
        }
        
        await fulfillment(of: [started, iterated, finished], timeout: 0.5)
        task.cancel()
    }
    
    func testVideoPlaylistsUpdatedAsyncSequence_whenHasFavoriteImagePlaylistUpdates_doesNotEmitsUpdate() async {
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
            filesSearchUseCase: MockFilesSearchUseCase(nodeUpdates: nodeUpdatesStream)
        )
        
        let started = expectation(description: "started")
        let iterated = expectation(description: "iterated")
        iterated.isInverted = true
        let finished = expectation(description: "finished")
        let task = Task {
            started.fulfill()
            for await _ in sut.videoPlaylistsUpdatedAsyncSequence {
                iterated.fulfill()
            }
            finished.fulfill()
        }
        
        await fulfillment(of: [started, iterated, finished], timeout: 0.5)
        task.cancel()
    }
    
    func testVideoPlaylistsUpdatedAsyncSequence_whenHasFavoriteImagePlaylistUpdates_emitsUpdateOnlyForVideoNodeUpdates() async {
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
            filesSearchUseCase: MockFilesSearchUseCase(nodeUpdates: nodeUpdatesStream)
        )
        
        let started = expectation(description: "started")
        let iterated = expectation(description: "iterated")
        iterated.expectedFulfillmentCount = expectedResults.filter { $0.mediaType == .video }.count
        let finished = expectation(description: "finished")
        let task = Task {
            started.fulfill()
            for await _ in sut.videoPlaylistsUpdatedAsyncSequence {
                iterated.fulfill()
            }
            finished.fulfill()
        }
        
        await fulfillment(of: [started, iterated, finished], timeout: 0.5)
        task.cancel()
    }
    
    func testVideoPlaylistsUpdatedAsyncSequence_whenHasFavoriteImagePlaylistUpdates_emitsUpdate() async {
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
            filesSearchUseCase: MockFilesSearchUseCase(nodeUpdates: nodeUpdatesStream)
        )
        
        let started = expectation(description: "started")
        let iterated = expectation(description: "iterated")
        iterated.expectedFulfillmentCount = expectedResults.count
        let finished = expectation(description: "finished")
        let task = Task {
            started.fulfill()
            for await _ in sut.videoPlaylistsUpdatedAsyncSequence {
                iterated.fulfill()
            }
            finished.fulfill()
        }
        
        await fulfillment(of: [started, iterated, finished], timeout: 0.5)
        task.cancel()
    }
    
    func testVideoPlaylistsUpdatedAsyncSequence_whenHasNoUserVideoPlaylistUpdates_doesNotEmitsUpdate() async {
        let initialPlaylists = anyPlaylists()
        let (sut, _, _, _) = makeSUT(
            userVideoPlaylistRepositoryResult: initialPlaylists,
            setsUpdatedAsyncSequence: EmptyAsyncSequence().eraseToAnyAsyncSequence()
        )
        
        let started = expectation(description: "started")
        let iterated = expectation(description: "iterated")
        iterated.isInverted = true
        let finished = expectation(description: "finished")
        let task = Task {
            started.fulfill()
            for await _ in sut.videoPlaylistsUpdatedAsyncSequence {
                iterated.fulfill()
            }
            finished.fulfill()
        }
        
        await fulfillment(of: [started, iterated, finished], timeout: 0.5)
        task.cancel()
    }
    
    func testVideoPlaylistsUpdatedAsyncSequence_whenHasUserVideoPlaylistUpdates_emitsUpdate() async {
        let expectedResults = anyPlaylists()
        let setsUpdatesStream = AsyncStream { continuation in
            for expectedResult in expectedResults {
                continuation.yield([expectedResult])
            }
            continuation.finish()
        }.eraseToAnyAsyncSequence()
        let initialPlaylists = anyPlaylists()
        let (sut, _, _, _) = makeSUT(
            userVideoPlaylistRepositoryResult: initialPlaylists,
            setsUpdatedAsyncSequence: setsUpdatesStream
        )
        
        let started = expectation(description: "started")
        let iterated = expectation(description: "iterated")
        iterated.expectedFulfillmentCount = 2
        let finished = expectation(description: "finished")
        let task = Task {
            started.fulfill()
            for await _ in sut.videoPlaylistsUpdatedAsyncSequence {
                iterated.fulfill()
            }
            finished.fulfill()
        }
        
        await fulfillment(of: [started, iterated, finished], timeout: 0.5)
        task.cancel()
    }
    
    func testVideoPlaylistsUpdatedAsyncSequence_whenHasNoUserVideoPlaylistContentUpdates_doesNotEmitsUpdate() async {
        let initialPlaylists = anyPlaylists()
        let (sut, _, _, _) = makeSUT(
            userVideoPlaylistRepositoryResult: initialPlaylists,
            setElementsUpdatedAsyncSequence: EmptyAsyncSequence().eraseToAnyAsyncSequence()
        )
        
        let started = expectation(description: "started")
        let iterated = expectation(description: "iterated")
        iterated.isInverted = true
        let finished = expectation(description: "finished")
        let task = Task {
            started.fulfill()
            for await _ in sut.videoPlaylistsUpdatedAsyncSequence {
                iterated.fulfill()
            }
            finished.fulfill()
        }
        
        await fulfillment(of: [started, iterated, finished], timeout: 0.5)
        task.cancel()
    }
    
    func testVideoPlaylistsUpdatedAsyncSequence_whenHasUserVideoPlaylistContentUpdates_emitsUpdate() async {
        let expectedResults = anyVideoPlaylistContents()
        let setElementUpdatesStream = AsyncStream { continuation in
            for expectedResult in expectedResults {
                continuation.yield([expectedResult])
            }
            continuation.finish()
        }.eraseToAnyAsyncSequence()
        let initialPlaylists = anyPlaylists()
        let (sut, _, _, _) = makeSUT(
            userVideoPlaylistRepositoryResult: initialPlaylists,
            setElementsUpdatedAsyncSequence: setElementUpdatesStream
        )
        
        let started = expectation(description: "started")
        let iterated = expectation(description: "iterated")
        iterated.expectedFulfillmentCount = 1
        let finished = expectation(description: "finished")
        let task = Task {
            started.fulfill()
            for await _ in sut.videoPlaylistsUpdatedAsyncSequence {
                iterated.fulfill()
            }
            finished.fulfill()
        }
        
        await fulfillment(of: [started, iterated, finished], timeout: 0.5)
        task.cancel()
    }
    
    func testVideoPlaylistsUpdatedAsyncSequence_whenhasAnyTypesOfPlaylistUpdates_emitsUpdate() async {
        let expectedFavoriteVideosUpdateResults = [
            NodeEntity(name: "node-1", handle: 1),
            NodeEntity(name: "node-2", handle: 2)
        ]
        let nodeUpdatesStream = AsyncStream { continuation in
            for expectedResult in expectedFavoriteVideosUpdateResults {
                continuation.yield([expectedResult])
            }
            continuation.finish()
        }.eraseToAnyAsyncSequence()
        
        let initialPlaylists = anyPlaylists()
        let expectedUserVideoPlaylistResults = anyPlaylists()
        let setsUpdatesStream = AsyncStream { continuation in
            for expectedResult in expectedUserVideoPlaylistResults {
                continuation.yield([expectedResult])
            }
            continuation.finish()
        }.eraseToAnyAsyncSequence()
        
        let expectedVideoPlaylistContentResults = anyVideoPlaylistContents()
        let setElementUpdatesStream = AsyncStream { continuation in
            for expectedResult in expectedVideoPlaylistContentResults {
                continuation.yield([expectedResult])
            }
            continuation.finish()
        }.eraseToAnyAsyncSequence()
        
        let (sut, _, _, _) = makeSUT(
            filesSearchUseCase: MockFilesSearchUseCase(nodeUpdates: nodeUpdatesStream),
            userVideoPlaylistRepositoryResult: initialPlaylists,
            setsUpdatedAsyncSequence: setsUpdatesStream,
            setElementsUpdatedAsyncSequence: setElementUpdatesStream
        )
        
        let started = expectation(description: "started")
        let iterated = expectation(description: "iterated")
        iterated.expectedFulfillmentCount = 3
        let finished = expectation(description: "finished")
        let task = Task {
            started.fulfill()
            for await _ in sut.videoPlaylistsUpdatedAsyncSequence {
                iterated.fulfill()
            }
            finished.fulfill()
        }
        
        await fulfillment(of: [started, iterated, finished], timeout: 0.5)
        task.cancel()
    }
    
    // MARK: - updateVideoPlaylistName
    
    func testUpdateVideoPlaylistName_whenCalled_updatesVideoPlaylist() async {
        let videoPlaylistNameToUpdate = "new-name"
        let videoPlaylistToUpdate = VideoPlaylistEntity(setIdentifier: SetIdentifier(handle: 1), name: "old-name", count: 0, type: .user, creationTime: Date(), modificationTime: Date())
        let (sut, _, userVideoPlaylistRepository, _) = makeSUT()
        
        _ = try? await sut.updateVideoPlaylistName(videoPlaylistNameToUpdate, for: videoPlaylistToUpdate)
        
        let messages = userVideoPlaylistRepository.messages
        XCTAssertEqual(messages, [ .updateVideoPlaylistName(newName: videoPlaylistNameToUpdate, videoPlaylistEntity: videoPlaylistToUpdate) ])
    }
    
    func testUpdateVideoPlaylistName_whenRenameSystemVideoPlaylist_throwsError() async {
        let videoPlaylistNameToUpdate = "Old-name"
        let videoPlaylistToUpdate = VideoPlaylistEntity(setIdentifier: SetIdentifier(handle: 1), name: "Old-name", count: 0, type: .favourite, creationTime: Date(), modificationTime: Date())
        let expectedError = VideoPlaylistErrorEntity.invalidOperation
        let (sut, _, _, _) = makeSUT(updateVideoPlaylistNameResult: .failure(expectedError))
        
        await simulateUpdateVideoPlaylistNameThenCompleteWithError(expectedError, on: sut, videoPlaylistNameToUpdate: videoPlaylistNameToUpdate, videoPlaylistToUpdate: videoPlaylistToUpdate)
    }
    
    func testUpdateVideoPlaylistName_whenCalledWithSameName_throwsError() async {
        let videoPlaylistNameToUpdate = "Old-name"
        let videoPlaylistToUpdate = VideoPlaylistEntity(setIdentifier: SetIdentifier(handle: 1), name: "Old-name", count: 0, type: .user, creationTime: Date(), modificationTime: Date())
        let expectedError = VideoPlaylistErrorEntity.invalidOperation
        let (sut, _, _, _) = makeSUT(updateVideoPlaylistNameResult: .failure(expectedError))
        
        await simulateUpdateVideoPlaylistNameThenCompleteWithError(expectedError, on: sut, videoPlaylistNameToUpdate: videoPlaylistNameToUpdate, videoPlaylistToUpdate: videoPlaylistToUpdate)
    }
    
    func testUpdateVideoPlaylistName_whenCalledWithSimilarNameButNotSame_updateVideoPlaylist() async {
        let videoPlaylistNameToUpdate = "old-name"
        let videoPlaylistToUpdate = VideoPlaylistEntity(setIdentifier: SetIdentifier(handle: 1), name: "Old-name", count: 0, type: .user, creationTime: Date(), modificationTime: Date())
        let (sut, _, userVideoPlaylistRepository, _) = makeSUT()
        
        _ = try? await sut.updateVideoPlaylistName(videoPlaylistNameToUpdate, for: videoPlaylistToUpdate)
        
        let messages = userVideoPlaylistRepository.messages
        XCTAssertEqual(messages, [ .updateVideoPlaylistName(newName: videoPlaylistNameToUpdate, videoPlaylistEntity: videoPlaylistToUpdate) ])
    }
    
    func testUpdateVideoPlaylistName_whenHasError_throwsError() async {
        let videoPlaylistNameToUpdate = "new-name"
        let videoPlaylistToUpdate = VideoPlaylistEntity(setIdentifier: SetIdentifier(handle: 1), name: "old-name", count: 0, type: .user, creationTime: Date(), modificationTime: Date())
        let expectedError = VideoPlaylistErrorEntity.failedToUpdateVideoPlaylistName(name: videoPlaylistNameToUpdate)
        let (sut, _, _, _) = makeSUT(updateVideoPlaylistNameResult: .failure(expectedError))
        
        await simulateUpdateVideoPlaylistNameThenCompleteWithError(expectedError, on: sut, videoPlaylistNameToUpdate: videoPlaylistNameToUpdate, videoPlaylistToUpdate: videoPlaylistToUpdate)
    }
    
    func testUpdateVideoPlaylistName_whenSuccess_updatesVideoPlaylistNameSuccessfully() async {
        let videoPlaylistNameToUpdate = "new-name"
        let anyDate = Date()
        let videoPlaylistToUpdate = VideoPlaylistEntity(setIdentifier: SetIdentifier(handle: 1), name: "old-name", count: 0, type: .user, creationTime: anyDate, modificationTime: anyDate, sharedLinkStatus: .exported(false))
        let (sut, _, _, _) = makeSUT(updateVideoPlaylistNameResult: .success(()))
        
        await simulateUpdateVideoPlaylistNameCompletedSuccessfullyThenAssert(on: sut, videoPlaylistNameToUpdate: videoPlaylistNameToUpdate, videoPlaylistToUpdate: videoPlaylistToUpdate)
    }
    
    // MARK: - Helpers
    
    private func makeSUT(
        filesSearchUseCase: MockFilesSearchUseCase = MockFilesSearchUseCase(searchResult: .failure(.generic)),
        userVideoPlaylistRepositoryResult: [SetEntity] = [],
        photoLibrarayUseCase: MockPhotoLibraryUseCase = MockPhotoLibraryUseCase(),
        createVideoPlaylistResult: Result<SetEntity, any Error> = .failure(GenericErrorEntity()),
        setsUpdatedAsyncSequence: AnyAsyncSequence<[SetEntity]> = EmptyAsyncSequence().eraseToAnyAsyncSequence(),
        setElementsUpdatedAsyncSequence: AnyAsyncSequence<[SetElementEntity]> = EmptyAsyncSequence().eraseToAnyAsyncSequence(),
        updateVideoPlaylistNameResult: Result<Void, any Error> = .failure(GenericErrorEntity())
    ) -> (
        sut: VideoPlaylistUseCase,
        filesSearchUseCase: MockFilesSearchUseCase,
        userVideoPlaylistRepository: MockUserVideoPlaylistsRepository,
        PhotoLibraryUseCase: MockPhotoLibraryUseCase
    ) {
        let userVideoPlaylistRepository = MockUserVideoPlaylistsRepository(
            videoPlaylistsResult: userVideoPlaylistRepositoryResult,
            addVideosToVideoPlaylistResult: .failure(GenericErrorEntity()),
            deleteVideosResult: .failure(GenericErrorEntity()),
            createVideoPlaylistResult: createVideoPlaylistResult,
            setsUpdatedAsyncSequence: setsUpdatedAsyncSequence,
            setElementsUpdatedAsyncSequence: setElementsUpdatedAsyncSequence,
            updateVideoPlaylistNameResult: updateVideoPlaylistNameResult
        )
        let sut = VideoPlaylistUseCase(
            fileSearchUseCase: filesSearchUseCase,
            userVideoPlaylistsRepository: userVideoPlaylistRepository, 
            photoLibraryUseCase: photoLibrarayUseCase
        )
        return (sut, filesSearchUseCase, userVideoPlaylistRepository, photoLibrarayUseCase)
    }
    
    private func simulateUpdateVideoPlaylistNameThenCompleteWithError(
        _ expectedError: VideoPlaylistErrorEntity,
        on sut: VideoPlaylistUseCase,
        videoPlaylistNameToUpdate: String,
        videoPlaylistToUpdate: VideoPlaylistEntity,
        file: StaticString = #filePath,
        line: UInt = #line
    ) async {
        do {
            _ =  try await sut.updateVideoPlaylistName(videoPlaylistNameToUpdate, for: videoPlaylistToUpdate)
            XCTFail("expect to throw error", file: file, line: line)
        } catch {
            XCTAssertEqual(error as? VideoPlaylistErrorEntity, expectedError, "Expect to get error", file: file, line: line)
        }
    }
    
    private func simulateUpdateVideoPlaylistNameCompletedSuccessfullyThenAssert(
        on sut: VideoPlaylistUseCase,
        videoPlaylistNameToUpdate: String,
        videoPlaylistToUpdate: VideoPlaylistEntity,
        file: StaticString = #filePath,
        line: UInt = #line
    ) async {
        do {
            try await sut.updateVideoPlaylistName(videoPlaylistNameToUpdate, for: videoPlaylistToUpdate)
        } catch {
            XCTFail("expect to not throw error, got error instead: \(error)", file: file, line: line)
        }
    }
    
    private func anySetEntity(id: HandleEntity, name: String, creationTime: Date = Date(), modificationTime: Date = Date(), isExported: Bool = false) -> SetEntity {
        SetEntity(
            handle: id,
            userId: id,
            coverId: id,
            creationTime: creationTime,
            modificationTime: modificationTime,
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
    
    private func anyVideoPlaylistContents() -> [SetElementEntity] {
        [
            SetElementEntity(handle: 1, ownerId: 1, order: 1, nodeId: 1, modificationTime: Date(), name: "name", changeTypes: .name)
        ]
    }
    
    private func anyNode(id: HandleEntity, isFavorite: Bool = false) -> NodeEntity {
        NodeEntity(
            changeTypes: .favourite,
            nodeType: .file,
            name: "name: \(id.description).mp4",
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
