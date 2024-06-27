import AsyncAlgorithms
import Combine
import MEGADomain
import MEGADomainMock
import MEGAL10n
import MEGASwift
import MEGASwiftUI
@testable import Video
import XCTest

final class VideoPlaylistContentViewModelTests: XCTestCase {
    
    // MARK: - onViewAppeared.monitorVideoPlaylistContent
    
    func testOnViewAppeared_onMonitorVideoPlaylistContentTriggeredWithUpdates_reloadVideoPlaylistContentSuccessfully() async {
        let allVideos = [
            NodeEntity(name: "video 1", handle: 1, hasThumbnail: true, duration: 60),
            NodeEntity(name: "video 2", handle: 2, hasThumbnail: true)
        ]
        let videoPlaylistEntity = VideoPlaylistEntity(
            id: 1,
            name: "name",
            count: allVideos.count,
            type: .user,
            creationTime: Date(),
            modificationTime: Date()
        )
        
        let mockVideoPlaylistContentsUseCase = MockVideoPlaylistContentUseCase(
            allVideos: allVideos,
            monitorVideoPlaylistAsyncSequenceResult: SingleItemAsyncSequence(item: videoPlaylistEntity).eraseToAnyAsyncThrowingSequence(),
            monitorUserVideoPlaylistContentAsyncSequenceResult: [allVideos].async.eraseToAnyAsyncSequence()
        )
        let thumbnailUseCase = MockThumbnailUseCase(
            cachedThumbnails: [],
            loadThumbnailResult: .failure(GenericErrorEntity()),
            loadPreviewResult: .failure(GenericErrorEntity()),
            loadThumbnailAndPreviewResult: .failure(GenericErrorEntity())
        )
        let (sut, _, videoPlaylistContentsUseCase, _, _, _, _, _) = makeSUT(
            videoPlaylistEntity: videoPlaylistEntity,
            videoPlaylistContentsUseCase: mockVideoPlaylistContentsUseCase,
            thumbnailUseCase: thumbnailUseCase
        )
        
        await sut.onViewAppeared()
        
        XCTAssertTrue(videoPlaylistContentsUseCase.messages.contains(.monitorVideoPlaylist(id: videoPlaylistEntity.id)))
        XCTAssertEqual(sut.videos.count, allVideos.count)
        XCTAssertEqual(sut.sharedUIState.videosCount, allVideos.count)
    }
    
    func testOnViewAppeared_onMonitorVideoPlaylistContentTriggeredWithErrorUpdates_reloadVideoPlaylistContentWithError() async {
        let allVideos = [
            NodeEntity(name: "video 1", handle: 1, hasThumbnail: true, duration: 60),
            NodeEntity(name: "video 2", handle: 2, hasThumbnail: true)
        ]
        let videoPlaylistEntity = VideoPlaylistEntity(
            id: 1,
            name: "name",
            count: allVideos.count,
            type: .user,
            creationTime: Date(),
            modificationTime: Date()
        )
        
        let videoPlaylistUpdatesStream = AsyncThrowingStream<VideoPlaylistEntity, any Error> { continuation in
            continuation.yield(with: .failure(GenericErrorEntity()))
        }.eraseToAnyAsyncThrowingSequence()
        
        let mockVideoPlaylistContentsUseCase = MockVideoPlaylistContentUseCase(
            allVideos: allVideos,
            monitorVideoPlaylistAsyncSequenceResult: videoPlaylistUpdatesStream,
            monitorUserVideoPlaylistContentAsyncSequenceResult: [allVideos].async.eraseToAnyAsyncSequence()
        )
        let thumbnailUseCase = MockThumbnailUseCase(
            cachedThumbnails: [],
            loadThumbnailResult: .failure(GenericErrorEntity()),
            loadPreviewResult: .failure(GenericErrorEntity()),
            loadThumbnailAndPreviewResult: .failure(GenericErrorEntity())
        )
        let (sut, _, _, _, _, _, _, _) = makeSUT(
            videoPlaylistEntity: videoPlaylistEntity,
            videoPlaylistContentsUseCase: mockVideoPlaylistContentsUseCase,
            thumbnailUseCase: thumbnailUseCase
        )
        
        await sut.onViewAppeared()
        
        XCTAssertTrue(sut.shouldShowError, "Expect to show error when has any other error during reload")
    }
    
    func testOnViewAppeared_onMonitorVideoPlaylistContentTriggeredWithVideoPlaylistNotFOundErrorUpdates_popsScreen() async {
        let allVideos = [
            NodeEntity(name: "video 1", handle: 1, hasThumbnail: true, duration: 60),
            NodeEntity(name: "video 2", handle: 2, hasThumbnail: true)
        ]
        let videoPlaylistEntity = VideoPlaylistEntity(
            id: 1,
            name: "name",
            count: allVideos.count,
            type: .user,
            creationTime: Date(),
            modificationTime: Date()
        )
        
        let videoPlaylistUpdatesStream = AsyncThrowingStream<VideoPlaylistEntity, any Error> { continuation in
            continuation.yield(with: .failure(VideoPlaylistErrorEntity.videoPlaylistNotFound(id: videoPlaylistEntity.id)))
        }.eraseToAnyAsyncThrowingSequence()
        let mockVideoPlaylistContentsUseCase = MockVideoPlaylistContentUseCase(
            allVideos: allVideos,
            monitorVideoPlaylistAsyncSequenceResult: videoPlaylistUpdatesStream,
            monitorUserVideoPlaylistContentAsyncSequenceResult: [allVideos].async.eraseToAnyAsyncSequence()
        )
        let thumbnailUseCase = MockThumbnailUseCase(
            cachedThumbnails: [],
            loadThumbnailResult: .failure(GenericErrorEntity()),
            loadPreviewResult: .failure(GenericErrorEntity()),
            loadThumbnailAndPreviewResult: .failure(GenericErrorEntity())
        )
        let (sut, _, _, _, _, _, _, _) = makeSUT(
            videoPlaylistEntity: videoPlaylistEntity,
            videoPlaylistContentsUseCase: mockVideoPlaylistContentsUseCase,
            thumbnailUseCase: thumbnailUseCase
        )
        
        await sut.onViewAppeared()
        
        XCTAssertTrue(sut.shouldPopScreen, "Expect to exit screen")
    }
    
    // MARK: - addVideosToVideoPlaylist
    
    func testAddVideosToVideoPlaylist_emptyVideos_shouldNotAddVideosToPlaylist() async {
        let allVideos = [
            NodeEntity(name: "video 1", handle: 1, hasThumbnail: true, duration: 60),
            NodeEntity(name: "video 2", handle: 2, hasThumbnail: true)
        ]
        let videoPlaylistEntity = VideoPlaylistEntity(
            id: 1,
            name: "name",
            count: allVideos.count,
            type: .user,
            creationTime: Date(),
            modificationTime: Date()
        )
        let (sut, _, _, _, _, _, _, videoPlaylistModificationUseCase) = makeSUT(videoPlaylistEntity: videoPlaylistEntity)
        
        await sut.addVideosToVideoPlaylist(videos: [])
        
        XCTAssertTrue(videoPlaylistModificationUseCase.messages.isEmpty)
    }
    
    func testAddVideosToVideoPlaylist_addVideosFailed_shouldNotShowSnackBar() async {
        let allVideos: [NodeEntity] = []
        let videoPlaylistEntity = VideoPlaylistEntity(
            id: 1,
            name: "name",
            count: allVideos.count,
            type: .user,
            creationTime: Date(),
            modificationTime: Date()
        )
        let (sut, _, _, _, _, _, _, _) = makeSUT(
            videoPlaylistEntity: videoPlaylistEntity,
            videoPlaylistModificationUseCase: MockVideoPlaylistModificationUseCase(addToVideoPlaylistResult: .failure(GenericErrorEntity()))
        )
        
        await sut.addVideosToVideoPlaylist(videos: [ NodeEntity(name: "video 2", handle: 2, hasThumbnail: true) ])
        
        XCTAssertTrue(sut.sharedUIState.snackBarText.isEmpty)
        XCTAssertFalse(sut.sharedUIState.shouldShowSnackBar)
    }
    
    func testAddVideosToVideoPlaylist_addVideosSuccess_shouldShowSnackBar() async {
        let videosToAdd = [ NodeEntity(name: "video 2", handle: 2, hasThumbnail: true) ]
        let allVideos: [NodeEntity] = []
        let videoPlaylistEntity = VideoPlaylistEntity(
            id: 1,
            name: "name",
            count: allVideos.count,
            type: .user,
            creationTime: Date(),
            modificationTime: Date()
        )
        let addToVideoPlaylistResult: Result<VideoPlaylistElementsResultEntity, Error> = .success(VideoPlaylistElementsResultEntity(success: UInt(videosToAdd.count), failure: 0))
        let (sut, _, _, _, _, _, _, _) = makeSUT(
            videoPlaylistEntity: videoPlaylistEntity,
            videoPlaylistModificationUseCase: .init(addToVideoPlaylistResult: addToVideoPlaylistResult)
        )
        
        await sut.addVideosToVideoPlaylist(videos: videosToAdd)
        
        XCTAssertEqual(sut.sharedUIState.snackBarText, addVideosToVideoPlaylistSucessfulMessage(videosCount: videosToAdd.count, videoPlaylistName: videoPlaylistEntity.name))
        XCTAssertTrue(sut.sharedUIState.shouldShowSnackBar)
    }
    
    // MARK: - subscribeToAllSelected
    
    func testSubscribeToAllSelected_whenIsAllSelectedChanged_triggerSelectionDelegate() async {
        let allVideos = [
            NodeEntity(name: "video 1", handle: 1, hasThumbnail: true, duration: 60),
            NodeEntity(name: "video 2", handle: 2, hasThumbnail: true)
        ]
        let videoPlaylistEntity = VideoPlaylistEntity(
            id: 1,
            name: "name",
            count: allVideos.count,
            type: .user,
            creationTime: Date(),
            modificationTime: Date()
        )
        
        let videoPlaylistUpdatesStream = AsyncThrowingStream<VideoPlaylistEntity, any Error> { continuation in
            continuation.yield(with: .failure(VideoPlaylistErrorEntity.videoPlaylistNotFound(id: videoPlaylistEntity.id)))
        }.eraseToAnyAsyncThrowingSequence()
        let mockVideoPlaylistContentsUseCase = MockVideoPlaylistContentUseCase(
            allVideos: allVideos,
            monitorVideoPlaylistAsyncSequenceResult: videoPlaylistUpdatesStream,
            monitorUserVideoPlaylistContentAsyncSequenceResult: [allVideos].async.eraseToAnyAsyncSequence()
        )
        let (sut, _, _, _, sharedUIState, _, _, _) = makeSUT(
            videoPlaylistEntity: videoPlaylistEntity,
            videoPlaylistContentsUseCase: mockVideoPlaylistContentsUseCase
        )
        
        let taskExpectation = expectation(description: "wait for task complete")
        let task = Task {
            await sut.subscribeToAllSelected()
            taskExpectation.fulfill()
        }
        
        let isCalledExpectation = expectation(description: "isAllSelected is called")
        let cancellable = sharedUIState.$isAllSelected
            .filter { $0 }
            .sink { _ in
                isCalledExpectation.fulfill()
            }
        
        XCTAssertFalse(sharedUIState.isAllSelected)
        
        // act
        sharedUIState.isAllSelected = true
        
        // assert
        await fulfillment(of: [isCalledExpectation], timeout: 1.0)
        
        task.cancel()
        cancellable.cancel()
        
        await fulfillment(of: [taskExpectation], timeout: 1.0)
    }
    
    // MARK: - subscribeToSelectedDisplayActionChanged
    
    @MainActor
    func testSubscribeToSelectedDisplayActionChanged_whenSelectedQuickActionEntityChangedToRename_shouldShowRenamePlaylistAlert() async {
        // Arrange
        let allVideos: [NodeEntity] = []
        let videoPlaylistEntity = VideoPlaylistEntity(
            id: 1,
            name: "name",
            count: allVideos.count,
            type: .user,
            creationTime: Date(),
            modificationTime: Date()
        )
        let (sut, _, _, _, sharedUIState, _, _, _) = makeSUT(videoPlaylistEntity: videoPlaylistEntity)
        var receivedShouldShowAlertValue: Bool?
        let shouldShowExp = expectation(description: "Wait for alert subscription")
        shouldShowExp.assertForOverFulfill = false
        let cancellable = sut.$shouldShowRenamePlaylistAlert
            .dropFirst()
            .sink { shouldShow in
                receivedShouldShowAlertValue = shouldShow
                shouldShowExp.fulfill()
            }
        let backgroundTaskExp = expectation(description: "Wait for background task finished")
        let task = Task {
            await sut.subscribeToSelectedDisplayActionChanged()
            backgroundTaskExp.fulfill()
        }
        
        // Act
        sharedUIState.selectedQuickActionEntity = .rename
        await fulfillment(of: [shouldShowExp], timeout: 0.5)
        
        // Assert
        XCTAssertEqual(receivedShouldShowAlertValue, true)
        
        task.cancel()
        cancellable.cancel()
        await fulfillment(of: [backgroundTaskExp], timeout: 1.0)
    }
    
    @MainActor
    func testSubscribeToSelectedDisplayActionChanged_whenSelectedQuickActionEntityChangedToOtherThanRename_shouldNotShowRenamePlaylistAlert() async throws {
        // Arrange
        let allVideos: [NodeEntity] = []
        let videoPlaylistEntity = VideoPlaylistEntity(
            id: 1,
            name: "name",
            count: allVideos.count,
            type: .user,
            creationTime: Date(),
            modificationTime: Date()
        )
        let (sut, _, _, _, sharedUIState, _, _, _) = makeSUT(videoPlaylistEntity: videoPlaylistEntity)
        var receivedShouldShowAlertValue: Bool?
        let shouldShowExp = expectation(description: "Wait for alert subscription")
        shouldShowExp.assertForOverFulfill = false
        let cancellable = sut.$shouldShowRenamePlaylistAlert
            .sink { shouldShow in
                receivedShouldShowAlertValue = shouldShow
                shouldShowExp.fulfill()
            }
        let backgroundTaskExp = expectation(description: "Wait for background task finished")
        let task = Task {
            await sut.subscribeToSelectedDisplayActionChanged()
            backgroundTaskExp.fulfill()
        }
        
        // Act
        sharedUIState.selectedQuickActionEntity = try anyInvalidActionForRename()
        await fulfillment(of: [shouldShowExp], timeout: 0.5)
        
        // Assert
        XCTAssertEqual(receivedShouldShowAlertValue, false)
        
        cancellable.cancel()
        task.cancel()
        await fulfillment(of: [backgroundTaskExp], timeout: 1.0)
    }
    
    // MARK: - monitorVideoPlaylists
    
    func testMonitorVideoPlaylists_whenCalled_loadsVideoPlaylists() async {
        let videoPlaylistEntity = videoPlaylist(id: 1, type: .user)
        let userVideoPlaylists = [
            videoPlaylistEntity,
            videoPlaylist(id: 2, type: .user)
        ]
        let (sut, _, _, _, _, _, _, _) = makeSUT(
            videoPlaylistEntity: videoPlaylistEntity,
            videoPlaylistsUseCase: MockVideoPlaylistUseCase(userVideoPlaylistsResult: userVideoPlaylists)
        )
        
        await sut.monitorVideoPlaylists()
        
        let expectedPlaylistNames = userVideoPlaylists.map(\.name) + [Strings.Localizable.Videos.Tab.Playlist.Content.PlaylistCell.Title.favorites]
        XCTAssertEqual(Set(sut.videoPlaylistNames), Set(expectedPlaylistNames))
    }
    
    // MARK: - renameVideoPlaylist
    
    func testRenameVideoPlaylist_emptyOrNil_doesNotRenameVideoPlaylist() async {
        let videoPlaylistEntity = videoPlaylist(id: 1, type: .user)
        let invalidNames: [String?] = [nil, ""]
        
        for (index, invalidName) in invalidNames.enumerated() {
            let (sut, _, _, _, _, _, _, videoPlaylistModificationUseCase) = makeSUT(videoPlaylistEntity: videoPlaylistEntity)
            
            sut.renameVideoPlaylist(with: invalidName)
            await sut.renameVideoPlaylistTask?.value
            
            XCTAssertTrue(videoPlaylistModificationUseCase.messages.isEmpty, "failed at index: \(index)")
            XCTAssertTrue(videoPlaylistModificationUseCase.messages.notContains(.updateVideoPlaylistName), "failed at index: \(index)")
        }
    }
    
    func testRenameVideoPlaylist_whenRenameInvalidPlaylist_doesNotRenameVideoPlaylist() async {
        let videoPlaylistName =  "a video playlist name"
        let invalidPlaylistType = VideoPlaylistEntityType.favourite
        let videoPlaylistEntity = VideoPlaylistEntity(id: 1, name: videoPlaylistName, count: 0, type: invalidPlaylistType, creationTime: Date(), modificationTime: Date())
        let (sut, _, _, _, _, _, _, videoPlaylistModificationUseCase) = makeSUT(
            videoPlaylistEntity: videoPlaylistEntity,
            videoPlaylistModificationUseCase: MockVideoPlaylistModificationUseCase(updateVideoPlaylistNameResult: .success(()))
        )
        
        sut.renameVideoPlaylist(with: videoPlaylistName)
        await sut.renameVideoPlaylistTask?.value
        
        XCTAssertTrue(videoPlaylistModificationUseCase.messages.notContains(.updateVideoPlaylistName))
    }
    
    func testRenameVideoPlaylist_whenCalled_renameVideoPlaylist() async {
        let videoPlaylistName =  "a video playlist name"
        let videoPlaylistEntity = VideoPlaylistEntity(id: 1, name: videoPlaylistName, count: 0, type: .user, creationTime: Date(), modificationTime: Date())
        let (sut, _, _, _, _, _, _, videoPlaylistModificationUseCase) = makeSUT(
            videoPlaylistEntity: videoPlaylistEntity,
            videoPlaylistModificationUseCase: MockVideoPlaylistModificationUseCase(updateVideoPlaylistNameResult: .success(()))
        )
        
        sut.renameVideoPlaylist(with: videoPlaylistName)
        await sut.renameVideoPlaylistTask?.value
        
        XCTAssertEqual(videoPlaylistModificationUseCase.messages, [ .updateVideoPlaylistName ])
    }
    
    func testRenameVideoPlaylist_whenRenameSuccessfully_renameActualPlaylist() async {
        let videoPlaylistName =  "a video playlist name"
        let videoPlaylistEntity = VideoPlaylistEntity(id: 1, name: videoPlaylistName, count: 0, type: .user, creationTime: Date(), modificationTime: Date())
        let (sut, _, _, _, _, _, _, _) = makeSUT(
            videoPlaylistEntity: videoPlaylistEntity,
            videoPlaylistModificationUseCase: MockVideoPlaylistModificationUseCase(updateVideoPlaylistNameResult: .success(()))
        )
        
        sut.renameVideoPlaylist(with: videoPlaylistName)
        await sut.renameVideoPlaylistTask?.value
        
        XCTAssertEqual(sut.videoPlaylistEntity.name, videoPlaylistName)
        XCTAssertEqual(sut.headerPreviewEntity.title, videoPlaylistName)
    }
    
    func testRenameVideoPlaylist_whenRenameFailed_showsRenameError() async {
        let newName =  "new name"
        let videoPlaylistEntity = VideoPlaylistEntity(id: 1, name: "old name", count: 0, type: .user, creationTime: Date(), modificationTime: Date())
        let (sut, _, _, _, sharedUIState, _, _, _) = makeSUT(
            videoPlaylistEntity: videoPlaylistEntity,
            videoPlaylistModificationUseCase: MockVideoPlaylistModificationUseCase(updateVideoPlaylistNameResult: .failure(GenericErrorEntity()))
        )
        
        sut.renameVideoPlaylist(with: newName)
        await sut.renameVideoPlaylistTask?.value
        
        XCTAssertNotEqual(sut.videoPlaylistEntity.name, newName)
        XCTAssertEqual(sut.videoPlaylistEntity.name, videoPlaylistEntity.name)
        XCTAssertEqual(sharedUIState.snackBarText, Strings.Localizable.Videos.Tab.Playlist.Content.Snackbar.renamingFailed)
        XCTAssertTrue(sharedUIState.shouldShowSnackBar)
    }
    
    // MARK: - Helpers
    
    private func makeSUT(
        videoPlaylistEntity: VideoPlaylistEntity,
        videoPlaylistContentsUseCase: MockVideoPlaylistContentUseCase = MockVideoPlaylistContentUseCase(),
        thumbnailUseCase: MockThumbnailUseCase = MockThumbnailUseCase(),
        sortOrderPreferenceUseCase: MockSortOrderPreferenceUseCase = MockSortOrderPreferenceUseCase(sortOrderEntity: .defaultAsc),
        videoPlaylistsUseCase: MockVideoPlaylistUseCase = MockVideoPlaylistUseCase(),
        videoPlaylistModificationUseCase: MockVideoPlaylistModificationUseCase = MockVideoPlaylistModificationUseCase(),
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> (
        sut: VideoPlaylistContentViewModel,
        videoPlaylistThumbnailLoader: MockVideoPlaylistThumbnailLoader,
        videoPlaylistContentsUseCase: MockVideoPlaylistContentUseCase,
        sortOrderPreferenceUseCase: MockSortOrderPreferenceUseCase,
        sharedUIState: VideoPlaylistContentSharedUIState,
        selectionAdapter: MockVideoPlaylistContentViewModelSelectionAdapter,
        videoPlaylistUseCase: MockVideoPlaylistUseCase,
        videoPlaylistModificationUseCase: MockVideoPlaylistModificationUseCase
    ) {
        let sharedUIState = VideoPlaylistContentSharedUIState()
        let videoPlaylistThumbnailLoader = MockVideoPlaylistThumbnailLoader()
        let selectionAdapter = MockVideoPlaylistContentViewModelSelectionAdapter()
        let sut = VideoPlaylistContentViewModel(
            videoPlaylistEntity: videoPlaylistEntity,
            videoPlaylistContentsUseCase: videoPlaylistContentsUseCase,
            thumbnailUseCase: thumbnailUseCase,
            videoPlaylistThumbnailLoader: videoPlaylistThumbnailLoader,
            sharedUIState: sharedUIState,
            sortOrderPreferenceUseCase: sortOrderPreferenceUseCase,
            selectionDelegate: selectionAdapter,
            renameVideoPlaylistAlertViewModel: TextFieldAlertViewModel(
                title: "Title",
                affirmativeButtonTitle: "Affirmative",
                destructiveButtonTitle: "Destructive"
            ),
            videoPlaylistsUseCase: videoPlaylistsUseCase,
            videoPlaylistModificationUseCase: videoPlaylistModificationUseCase
        )
        trackForMemoryLeaks(on: sut, file: file, line: line)
        return (
            sut,
            videoPlaylistThumbnailLoader,
            videoPlaylistContentsUseCase,
            sortOrderPreferenceUseCase,
            sharedUIState,
            selectionAdapter,
            videoPlaylistsUseCase,
            videoPlaylistModificationUseCase
        )
    }
    
    private func anyInvalidActionForRename() throws -> QuickActionEntity {
        try XCTUnwrap(
            QuickActionEntity.allCases
                .filter { $0 != .rename }
                .randomElement(),
            "Fail to unwrap QuickActionEntity"
        )
    }
    
    private func videoPlaylist(id: HandleEntity, type: VideoPlaylistEntityType) -> VideoPlaylistEntity {
        VideoPlaylistEntity(
            id: id,
            name: "name-\(id)",
            count: 0,
            type: type,
            creationTime: Date(),
            modificationTime: Date()
        )
    }
    
    private func addVideosToVideoPlaylistSucessfulMessage(videosCount: Int, videoPlaylistName: String) -> String {
        let message = Strings.Localizable.Videos.Tab.Playlist.Snackbar.videoCount(videosCount)
        return message.replacingOccurrences(of: "[A]", with: videoPlaylistName)
    }
}
