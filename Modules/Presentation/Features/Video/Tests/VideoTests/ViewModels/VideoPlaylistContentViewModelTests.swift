import AsyncAlgorithms
import Combine
import ContentLibraries
import MEGAAppPresentation
import MEGAAppPresentationMock
import MEGADomain
import MEGADomainMock
import MEGAL10n
import MEGASwift
import MEGASwiftUI
import Testing
@testable import Video
import XCTest

final class VideoPlaylistContentViewModelTests: XCTestCase {
    
    // MARK: - onViewAppeared.monitorVideoPlaylistContent
    
    @MainActor
    func testOnViewAppeared_onMonitorVideoPlaylistContentTriggeredWithFailedUpdates_showsCorrectViewStateTransition() async {
        let allVideos = [
            NodeEntity(name: "video 1", handle: 1, hasThumbnail: true, duration: 60),
            NodeEntity(name: "video 2", handle: 2, hasThumbnail: true)
        ]
        let videoPlaylistEntity = VideoPlaylistEntity(
            setIdentifier: SetIdentifier(handle: 1),
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
        let (sut, _, _, _, _, _, _, _, _) = makeSUT(
            videoPlaylistEntity: videoPlaylistEntity,
            videoPlaylistContentsUseCase: mockVideoPlaylistContentsUseCase,
            thumbnailLoader: MockThumbnailLoader()
        )
        let exp = expectation(description: "subscribe to ViewState")
        exp.expectedFulfillmentCount = 3
        var receivedViewStates: [VideoPlaylistContentViewModel.ViewState] = []
        let cancellable = sut.$viewState
            .sink { viewState in
                receivedViewStates.append(viewState)
                exp.fulfill()
            }
        
        // Act
        trackTaskCancellation { await sut.onViewAppeared() }
        await fulfillment(of: [exp], timeout: 0.2)
        
        // Assert
        XCTAssertEqual(receivedViewStates, [ .partial, .loading, .error ])
        cancellable.cancel()
    }
    
    @MainActor
    func testOnViewAppeared_onMonitorVideoPlaylistContentTriggeredWithSuccessfullNonEmptyUpdates_showsCorrectViewStateTransition() async {
        // Arrange
        let allVideos = [
            NodeEntity(name: "video 1", handle: 1, hasThumbnail: true, duration: 60),
            NodeEntity(name: "video 2", handle: 2, hasThumbnail: true)
        ]
        let videoPlaylistEntity = VideoPlaylistEntity(
            setIdentifier: SetIdentifier(handle: 1),
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
        let (sut, _, _, _, _, _, _, _, _) = makeSUT(
            videoPlaylistEntity: videoPlaylistEntity,
            videoPlaylistContentsUseCase: mockVideoPlaylistContentsUseCase,
            thumbnailLoader: MockThumbnailLoader()
        )
        let exp = expectation(description: "subscribe to ViewState")
        exp.expectedFulfillmentCount = 3
        var receivedViewStates: [VideoPlaylistContentViewModel.ViewState] = []
        let cancellable = sut.$viewState
            .sink { viewState in
                receivedViewStates.append(viewState)
                exp.fulfill()
            }
        
        // Act
        trackTaskCancellation { await sut.onViewAppeared() }
        await fulfillment(of: [exp], timeout: 0.2)
        
        // Assert
        XCTAssertEqual(receivedViewStates, [ .partial, .loading, .loaded ])
        cancellable.cancel()
    }
    
    @MainActor
    func testOnViewAppeared_onMonitorVideoPlaylistContentTriggeredWithSuccessfullEmptyUpdates_showsCorrectViewStateTransition() async {
        // Arrange
        let allVideos: [NodeEntity] = []
        let videoPlaylistEntity = VideoPlaylistEntity(
            setIdentifier: SetIdentifier(handle: 1),
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
        let (sut, _, _, _, _, _, _, _, _) = makeSUT(
            videoPlaylistEntity: videoPlaylistEntity,
            videoPlaylistContentsUseCase: mockVideoPlaylistContentsUseCase,
            thumbnailLoader: MockThumbnailLoader()
        )
        let exp = expectation(description: "subscribe to ViewState")
        exp.expectedFulfillmentCount = 3
        var receivedViewStates: [VideoPlaylistContentViewModel.ViewState] = []
        let cancellable = sut.$viewState
            .sink { viewState in
                receivedViewStates.append(viewState)
                exp.fulfill()
            }
        
        // Act
        trackTaskCancellation { await sut.onViewAppeared() }
        await fulfillment(of: [exp], timeout: 0.2)
        
        // Assert
        XCTAssertEqual(receivedViewStates, [ .partial, .loading, .empty ])
        cancellable.cancel()
    }
    
    @MainActor
    func testOnViewAppeared_onMonitorVideoPlaylistContentTriggeredWithUpdates_reloadVideoPlaylistContentSuccessfully() async {
        let allVideos = [
            NodeEntity(name: "video 1", handle: 1, hasThumbnail: true, duration: 60),
            NodeEntity(name: "video 2", handle: 2, hasThumbnail: true)
        ]
        let videoPlaylistEntity = VideoPlaylistEntity(
            setIdentifier: SetIdentifier(handle: 1),
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
        let thumbnailLoader = MockThumbnailLoader()
        let (sut, _, videoPlaylistContentsUseCase, _, _, _, _, _, _) = makeSUT(
            videoPlaylistEntity: videoPlaylistEntity,
            videoPlaylistContentsUseCase: mockVideoPlaylistContentsUseCase,
            thumbnailLoader: thumbnailLoader
        )
        
        await sut.onViewAppeared()
        
        XCTAssertTrue(videoPlaylistContentsUseCase.messages.contains(.monitorVideoPlaylist(id: videoPlaylistEntity.id)))
        XCTAssertEqual(sut.videos.count, allVideos.count)
        XCTAssertEqual(sut.sharedUIState.videosCount, allVideos.count)
    }
    
    @MainActor
    func testOnViewAppeared_onMonitorVideoPlaylistContentTriggeredWithErrorUpdates_reloadVideoPlaylistContentWithError() async {
        let allVideos = [
            NodeEntity(name: "video 1", handle: 1, hasThumbnail: true, duration: 60),
            NodeEntity(name: "video 2", handle: 2, hasThumbnail: true)
        ]
        let videoPlaylistEntity = VideoPlaylistEntity(
            setIdentifier: SetIdentifier(handle: 1),
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
        let thumbnailLoader = MockThumbnailLoader()

        let (sut, _, _, _, _, _, _, _, _) = makeSUT(
            videoPlaylistEntity: videoPlaylistEntity,
            videoPlaylistContentsUseCase: mockVideoPlaylistContentsUseCase,
            thumbnailLoader: thumbnailLoader
        )
        
        await sut.onViewAppeared()
        
        XCTAssertEqual(sut.viewState, .error, "Expect to show error when has any other error during reload")
    }
    
    @MainActor
    func testOnViewAppeared_onMonitorVideoPlaylistContentTriggeredWithVideoPlaylistNotFoundErrorUpdates_popsScreenWithSnackBarMessage() async {
        let allVideos = [
            NodeEntity(name: "video 1", handle: 1, hasThumbnail: true, duration: 60),
            NodeEntity(name: "video 2", handle: 2, hasThumbnail: true)
        ]
        let videoPlaylistEntity = VideoPlaylistEntity(
            setIdentifier: SetIdentifier(handle: 1),
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
        let thumbnailLoader = MockThumbnailLoader()
        let (sut, _, _, _, _, _, _, _, syncModel) = makeSUT(
            videoPlaylistEntity: videoPlaylistEntity,
            videoPlaylistContentsUseCase: mockVideoPlaylistContentsUseCase,
            thumbnailLoader: thumbnailLoader
        )
        
        await sut.onViewAppeared()
        
        XCTAssertTrue(sut.shouldPopScreen, "Expect to exit screen")
        let snackBarMessage = Strings.Localizable.Videos.Tab.Playlist.Content.Snackbar.playlistNameDeleted
            .replacingOccurrences(of: "[A]", with: videoPlaylistEntity.name)
        XCTAssertEqual(syncModel.snackBarMessage, snackBarMessage)
        XCTAssertEqual(syncModel.shouldShowSnackBar, true)
    }
    
    // MARK: - addVideosToVideoPlaylist
    @MainActor
    func testAddVideosToVideoPlaylist_emptyVideos_shouldNotAddVideosToPlaylist() async {
        let allVideos = [
            NodeEntity(name: "video 1", handle: 1, hasThumbnail: true, duration: 60),
            NodeEntity(name: "video 2", handle: 2, hasThumbnail: true)
        ]
        let videoPlaylistEntity = VideoPlaylistEntity(
            setIdentifier: SetIdentifier(handle: 1),
            name: "name",
            count: allVideos.count,
            type: .user,
            creationTime: Date(),
            modificationTime: Date()
        )
        let (sut, _, _, _, _, _, _, videoPlaylistModificationUseCase, _) = makeSUT(videoPlaylistEntity: videoPlaylistEntity)
        
        await sut.addVideosToVideoPlaylist(videos: [])
        
        XCTAssertTrue(videoPlaylistModificationUseCase.messages.isEmpty)
    }
    
    @MainActor
    func testAddVideosToVideoPlaylist_addVideosFailed_shouldNotShowSnackBar() async {
        let allVideos: [NodeEntity] = []
        let videoPlaylistEntity = VideoPlaylistEntity(
            setIdentifier: SetIdentifier(handle: 1),
            name: "name",
            count: allVideos.count,
            type: .user,
            creationTime: Date(),
            modificationTime: Date()
        )
        let (sut, _, _, _, _, _, _, _, _) = makeSUT(
            videoPlaylistEntity: videoPlaylistEntity,
            videoPlaylistModificationUseCase: MockVideoPlaylistModificationUseCase(addToVideoPlaylistResult: .failure(GenericErrorEntity()))
        )
        
        await sut.addVideosToVideoPlaylist(videos: [ NodeEntity(name: "video 2", handle: 2, hasThumbnail: true) ])
        
        XCTAssertTrue(sut.sharedUIState.snackBarText.isEmpty)
        XCTAssertFalse(sut.sharedUIState.shouldShowSnackBar)
    }
    
    @MainActor
    func testAddVideosToVideoPlaylist_addVideosSuccess_shouldShowSnackBar() async {
        let videosToAdd = [ NodeEntity(name: "video 2", handle: 2, hasThumbnail: true) ]
        let allVideos: [NodeEntity] = []
        let videoPlaylistEntity = VideoPlaylistEntity(
            setIdentifier: SetIdentifier(handle: 1),
            name: "name",
            count: allVideos.count,
            type: .user,
            creationTime: Date(),
            modificationTime: Date()
        )
        let addToVideoPlaylistResult: Result<VideoPlaylistElementsResultEntity, any Error> = .success(VideoPlaylistElementsResultEntity(success: UInt(videosToAdd.count), failure: 0))
        let (sut, _, _, _, _, _, _, _, _) = makeSUT(
            videoPlaylistEntity: videoPlaylistEntity,
            videoPlaylistModificationUseCase: .init(addToVideoPlaylistResult: addToVideoPlaylistResult)
        )
        
        await sut.addVideosToVideoPlaylist(videos: videosToAdd)
        
        XCTAssertEqual(sut.sharedUIState.snackBarText, addVideosToVideoPlaylistSucessfulMessage(videosCount: videosToAdd.count, videoPlaylistName: videoPlaylistEntity.name))
        XCTAssertTrue(sut.sharedUIState.shouldShowSnackBar)
    }
    
    // MARK: - subscribeToAllSelected
    @MainActor
    func testSubscribeToAllSelected_whenIsAllSelectedChanged_triggerSelectionDelegate() async {
        let allVideos = [
            NodeEntity(name: "video 1", handle: 1, hasThumbnail: true, duration: 60),
            NodeEntity(name: "video 2", handle: 2, hasThumbnail: true)
        ]
        let videoPlaylistEntity = VideoPlaylistEntity(
            setIdentifier: SetIdentifier(handle: 1),
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
        let (sut, _, _, _, sharedUIState, _, _, _, _) = makeSUT(
            videoPlaylistEntity: videoPlaylistEntity,
            videoPlaylistContentsUseCase: mockVideoPlaylistContentsUseCase
        )
                
        trackTaskCancellation { await sut.subscribeToAllSelected() }
        
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
        
        cancellable.cancel()
    }
    
    // MARK: - subscribeToSelectedDisplayActionChanged
    
    @MainActor
    func testSubscribeToSelectedDisplayActionChanged_whenSelectedQuickActionEntityChangedToRename_shouldShowRenamePlaylistAlert() async {
        // Arrange
        let allVideos: [NodeEntity] = []
        let videoPlaylistEntity = VideoPlaylistEntity(
            setIdentifier: SetIdentifier(handle: 1),
            name: "name",
            count: allVideos.count,
            type: .user,
            creationTime: Date(),
            modificationTime: Date()
        )
        let (sut, _, _, _, sharedUIState, _, _, _, _) = makeSUT(videoPlaylistEntity: videoPlaylistEntity)
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
            setIdentifier: SetIdentifier(handle: 1),
            name: "name",
            count: allVideos.count,
            type: .user,
            creationTime: Date(),
            modificationTime: Date()
        )
        let (sut, _, _, _, sharedUIState, _, _, _, _) = makeSUT(videoPlaylistEntity: videoPlaylistEntity)
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
    
    @MainActor
    func testSubscribeToSelectedDisplayActionChanged_whenSelectedQuickActionEntityIsShareLink_shouldShowShareLinkView() async throws {
        // Arrange
        let allVideos: [NodeEntity] = []
        let videoPlaylistEntity = VideoPlaylistEntity(
            setIdentifier: SetIdentifier(handle: 1),
            name: "name",
            count: allVideos.count,
            type: .user,
            creationTime: Date(),
            modificationTime: Date()
        )
        let (sut, _, _, _, sharedUIState, _, _, _, _) = makeSUT(videoPlaylistEntity: videoPlaylistEntity)
        var receivedShouldShowShareLinkView: Bool?
        let shouldShowExp = expectation(description: "Wait for alert subscription")
        shouldShowExp.assertForOverFulfill = false
        let cancellable = sut.$shouldShowShareLinkView
            .sink { shouldShow in
                receivedShouldShowShareLinkView = shouldShow
                shouldShowExp.fulfill()
            }
        let backgroundTaskExp = expectation(description: "Wait for background task finished")
        let task = Task {
            await sut.subscribeToSelectedDisplayActionChanged()
            backgroundTaskExp.fulfill()
        }
        
        // Act
        sharedUIState.selectedQuickActionEntity = .shareLink
        await fulfillment(of: [shouldShowExp], timeout: 0.5)
        
        // Assert
        XCTAssertEqual(receivedShouldShowShareLinkView, true)
        
        cancellable.cancel()
        task.cancel()
        await fulfillment(of: [backgroundTaskExp], timeout: 1.0)
    }
    
    @MainActor
    func testSubscribeToSelectedDisplayActionChanged_whenSelectedQuickActionEntityIsNotShareLink_shouldNotShowShareLinkView() async throws {
        // Arrange
        let allVideos: [NodeEntity] = []
        let videoPlaylistEntity = VideoPlaylistEntity(
            setIdentifier: SetIdentifier(handle: 1),
            name: "name",
            count: allVideos.count,
            type: .user,
            creationTime: Date(),
            modificationTime: Date()
        )
        let (sut, _, _, _, sharedUIState, _, _, _, _) = makeSUT(videoPlaylistEntity: videoPlaylistEntity)
        var receivedShouldShowShareLinkView: Bool?
        let shouldShowExp = expectation(description: "Wait for alert subscription")
        shouldShowExp.assertForOverFulfill = false
        let cancellable = sut.$shouldShowShareLinkView
            .sink { shouldShow in
                receivedShouldShowShareLinkView = shouldShow
                shouldShowExp.fulfill()
            }
        let backgroundTaskExp = expectation(description: "Wait for background task finished")
        let task = Task {
            await sut.subscribeToSelectedDisplayActionChanged()
            backgroundTaskExp.fulfill()
        }
        
        // Act
        sharedUIState.selectedQuickActionEntity = QuickActionEntity.allCases.filter { $0 != .shareLink }.first ?? .none
        await fulfillment(of: [shouldShowExp], timeout: 0.5)
        
        // Assert
        XCTAssertEqual(receivedShouldShowShareLinkView, false)
        
        cancellable.cancel()
        task.cancel()
        await fulfillment(of: [backgroundTaskExp], timeout: 1.0)
    }
    
    // MARK: - monitorVideoPlaylists
    
    @MainActor
    func testMonitorVideoPlaylists_whenCalled_loadsVideoPlaylists() async {
        let videoPlaylistEntity = videoPlaylist(id: 1, type: .user)
        let userVideoPlaylists = [
            videoPlaylistEntity,
            videoPlaylist(id: 2, type: .user)
        ]
        let (sut, _, _, _, _, _, _, _, _) = makeSUT(
            videoPlaylistEntity: videoPlaylistEntity,
            videoPlaylistsUseCase: MockVideoPlaylistUseCase(userVideoPlaylistsResult: userVideoPlaylists)
        )
        
        await sut.monitorVideoPlaylists()
        
        let expectedPlaylistNames = userVideoPlaylists.map(\.name) + [Strings.Localizable.Videos.Tab.Playlist.Content.PlaylistCell.Title.favorites]
        XCTAssertEqual(Set(sut.videoPlaylistNames), Set(expectedPlaylistNames))
    }
    
    // MARK: - renameVideoPlaylist
    
    @MainActor
    func testRenameVideoPlaylist_emptyOrNil_doesNotRenameVideoPlaylist() async {
        let videoPlaylistEntity = videoPlaylist(id: 1, type: .user)
        let invalidNames: [String?] = [nil, ""]
        
        for (index, invalidName) in invalidNames.enumerated() {
            let (sut, _, _, _, _, _, _, videoPlaylistModificationUseCase, _) = makeSUT(videoPlaylistEntity: videoPlaylistEntity)
            
            sut.renameVideoPlaylist(with: invalidName)
            await sut.renameVideoPlaylistTask?.value
            
            XCTAssertTrue(videoPlaylistModificationUseCase.messages.isEmpty, "failed at index: \(index)")
            XCTAssertTrue(videoPlaylistModificationUseCase.messages.notContains(.updateVideoPlaylistName), "failed at index: \(index)")
        }
    }
    
    @MainActor
    func testRenameVideoPlaylist_whenRenameInvalidPlaylist_doesNotRenameVideoPlaylist() async {
        let videoPlaylistName =  "a video playlist name"
        let invalidPlaylistType = VideoPlaylistEntityType.favourite
        let videoPlaylistEntity = VideoPlaylistEntity(setIdentifier: SetIdentifier(handle: 1), name: videoPlaylistName, count: 0, type: invalidPlaylistType, creationTime: Date(), modificationTime: Date())
        let (sut, _, _, _, _, _, _, videoPlaylistModificationUseCase, _) = makeSUT(
            videoPlaylistEntity: videoPlaylistEntity,
            videoPlaylistModificationUseCase: MockVideoPlaylistModificationUseCase(updateVideoPlaylistNameResult: .success(()))
        )
        
        sut.renameVideoPlaylist(with: videoPlaylistName)
        await sut.renameVideoPlaylistTask?.value
        
        XCTAssertTrue(videoPlaylistModificationUseCase.messages.notContains(.updateVideoPlaylistName))
    }
    
    @MainActor
    func testRenameVideoPlaylist_whenCalled_renameVideoPlaylist() async {
        let videoPlaylistName =  "a video playlist name"
        let videoPlaylistEntity = VideoPlaylistEntity(setIdentifier: SetIdentifier(handle: 1), name: videoPlaylistName, count: 0, type: .user, creationTime: Date(), modificationTime: Date())
        let (sut, _, _, _, _, _, _, videoPlaylistModificationUseCase, _) = makeSUT(
            videoPlaylistEntity: videoPlaylistEntity,
            videoPlaylistModificationUseCase: MockVideoPlaylistModificationUseCase(updateVideoPlaylistNameResult: .success(()))
        )
        
        sut.renameVideoPlaylist(with: videoPlaylistName)
        await sut.renameVideoPlaylistTask?.value
        
        XCTAssertEqual(videoPlaylistModificationUseCase.messages, [ .updateVideoPlaylistName ])
    }
    
    @MainActor
    func testRenameVideoPlaylist_whenRenameSuccessfully_renameActualPlaylist() async {
        let videoPlaylistName =  "a video playlist name"
        let videoPlaylistEntity = VideoPlaylistEntity(setIdentifier: SetIdentifier(handle: 1), name: videoPlaylistName, count: 0, type: .user, creationTime: Date(), modificationTime: Date())
        let (sut, _, _, _, _, _, _, _, _) = makeSUT(
            videoPlaylistEntity: videoPlaylistEntity,
            videoPlaylistModificationUseCase: MockVideoPlaylistModificationUseCase(updateVideoPlaylistNameResult: .success(()))
        )
        
        sut.renameVideoPlaylist(with: videoPlaylistName)
        await sut.renameVideoPlaylistTask?.value
        
        XCTAssertEqual(sut.videoPlaylistEntity.name, videoPlaylistName)
        XCTAssertEqual(sut.headerPreviewEntity.title, videoPlaylistName)
    }
    
    @MainActor
    func testRenameVideoPlaylist_whenRenameFailed_showsRenameError() async {
        let newName =  "new name"
        let videoPlaylistEntity = VideoPlaylistEntity(setIdentifier: SetIdentifier(handle: 1), name: "old name", count: 0, type: .user, creationTime: Date(), modificationTime: Date())
        let (sut, _, _, _, sharedUIState, _, _, _, _) = makeSUT(
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
    
    // MARK: - deleteVideoPlaylist
    
    @MainActor
    func testDeleteVideoPlaylist_whenVideoPlaylistIsSystem_doNotDeleteVideoPlaylist() async {
        let videoPlaylistEntity = VideoPlaylistEntity(setIdentifier: SetIdentifier(handle: 1), name: "a video playlist name", count: 0, type: .favourite, creationTime: Date(), modificationTime: Date())
        let (sut, _, _, _, _, _, _, videoPlaylistModificationUseCase, _) = makeSUT(
            videoPlaylistEntity: videoPlaylistEntity,
            videoPlaylistModificationUseCase: MockVideoPlaylistModificationUseCase()
        )
        
        sut.deleteVideoPlaylist()
        await sut.deleteVideoPlaylistTask?.value
        
        XCTAssertTrue(videoPlaylistModificationUseCase.messages.isEmpty)
    }
    
    @MainActor
    func testDeleteVideoPlaylist_whenVideoPlaylistIsUser_deletesVideoPlaylist() async {
        let videoPlaylistEntity = VideoPlaylistEntity(setIdentifier: SetIdentifier(handle: 1), name: "a video playlist name", count: 0, type: .user, creationTime: Date(), modificationTime: Date())
        let (sut, _, _, _, _, _, _, videoPlaylistModificationUseCase, _) = makeSUT(
            videoPlaylistEntity: videoPlaylistEntity,
            videoPlaylistModificationUseCase: MockVideoPlaylistModificationUseCase()
        )
        
        sut.deleteVideoPlaylist()
        await sut.deleteVideoPlaylistTask?.value
        
        XCTAssertEqual(videoPlaylistModificationUseCase.messages, [ .deleteVideoPlaylist ])
    }
    
    @MainActor
    func testDeleteVideoPlaylist_whenDeleteFailed_doesNotPopScreen() async {
        let videoPlaylistEntity = VideoPlaylistEntity(setIdentifier: SetIdentifier(handle: 1), name: "a video playlist name", count: 0, type: .user, creationTime: Date(), modificationTime: Date())
        let (sut, _, _, _, _, _, _, _, _) = makeSUT(
            videoPlaylistEntity: videoPlaylistEntity,
            videoPlaylistModificationUseCase: MockVideoPlaylistModificationUseCase(deleteVideoPlaylistResult: [])
        )
        
        sut.deleteVideoPlaylist()
        await sut.deleteVideoPlaylistTask?.value
        
        XCTAssertFalse(sut.shouldPopScreen, "Expect to exit screen")
    }
    
    // MARK: - subscribeToSelectedVideoPlaylistActionChanged
    
    @MainActor
    func testSubscribeToSelectedVideoPlaylistActionChanged_whenDeleteTapped_showsDeleteAlert() async {
        // Arrange
        let videoPlaylistEntity = VideoPlaylistEntity(setIdentifier: SetIdentifier(handle: 1), name: "a video playlist name", count: 0, type: .user, creationTime: Date(), modificationTime: Date())
        let (sut, _, _, _, sharedUIState, _, _, _, _) = makeSUT(
            videoPlaylistEntity: videoPlaylistEntity,
            videoPlaylistModificationUseCase: MockVideoPlaylistModificationUseCase(deleteVideoPlaylistResult: [])
        )
        
        let backgroundExp = expectation(description: "subscribe background task")
        let task = Task {
            await sut.subscribeToSelectedVideoPlaylistActionChanged()
            backgroundExp.fulfill()
        }
        
        let exp = expectation(description: "shouldShowDeletePlaylistAlert equals true")
        let cancellable = sut.$shouldShowDeletePlaylistAlert
            .filter { $0 }
            .sink { _ in
                exp.fulfill()
            }
        
        // Act
        sharedUIState.selectedVideoPlaylistActionEntity = .delete
        
        // Assert
        await fulfillment(of: [exp], timeout: 0.5)
        
        cancellable.cancel()
        task.cancel()
        await fulfillment(of: [backgroundExp], timeout: 0.5)
    }
    
    @MainActor
    func testSubscribeToSelectedVideoPlaylistActionChanged_whenAddVideosToPlaylistContentTapped_showsVideosPicker() async {
        // Arrange
        let videoPlaylistEntity = VideoPlaylistEntity(setIdentifier: SetIdentifier(handle: 1), name: "a video playlist name", count: 0, type: .user, creationTime: Date(), modificationTime: Date())
        let (sut, _, _, _, sharedUIState, _, _, _, _) = makeSUT(videoPlaylistEntity: videoPlaylistEntity)
        
        let backgroundExp = expectation(description: "subscribe background task")
        let task = Task {
            await sut.subscribeToSelectedVideoPlaylistActionChanged()
            backgroundExp.fulfill()
        }
        
        let exp = expectation(description: "shouldShowVideoPlaylistPicker equals true")
        let cancellable = sut.$shouldShowVideoPlaylistPicker
            .filter { $0 }
            .sink { _ in
                exp.fulfill()
            }
        
        // Act
        sharedUIState.selectedVideoPlaylistActionEntity = .addVideosToVideoPlaylistContent
        
        // Assert
        await fulfillment(of: [exp], timeout: 0.5)
        
        cancellable.cancel()
        task.cancel()
        await fulfillment(of: [backgroundExp], timeout: 0.5)
    }
    
    // MARK: - init.subscribeToRemoveVideosFromVideoPlaylistAction
    
    @MainActor
    func testInitSubscribeToRemoveVideosFromVideoPlaylistAction_whenHasEmptyVideosChanged_doesNotTriggerActionSheet() async {
        // Arrange
        let videoPlaylistEntity = VideoPlaylistEntity(setIdentifier: SetIdentifier(handle: 1), name: "a video playlist name", count: 0, type: .user, creationTime: Date(), modificationTime: Date())
        let (sut, _, _, _, sharedUIState, _, _, _, _) = makeSUT(
            videoPlaylistEntity: videoPlaylistEntity
        )
        
        let exp = expectation(description: "action sheet flag expectation")
        exp.isInverted = true
        let cancellable = sut.$shouldShowDeleteVideosFromVideoPlaylistActionSheet
            .filter { $0 }
            .sink { _ in
                exp.fulfill()
            }
        
        // Act
        sharedUIState.didSelectRemoveVideoFromPlaylistAction.send([])
        
        // Assert
        await fulfillment(of: [exp], timeout: 0.5)
        XCTAssertNil(sut.selectedVideos)
        
        cancellable.cancel()
    }
    
    @MainActor
    func testInitSubscribeToRemoveVideosFromVideoPlaylistAction_whenHasVideosSelected_triggersActionSheet() async {
        // Arrange
        let videoPlaylistEntity = VideoPlaylistEntity(setIdentifier: SetIdentifier(handle: 1), name: "a video playlist name", count: 0, type: .user, creationTime: Date(), modificationTime: Date())
        let (sut, _, _, _, sharedUIState, _, _, _, _) = makeSUT(
            videoPlaylistEntity: videoPlaylistEntity
        )
        
        let exp = expectation(description: "action sheet flag expectation")
        let cancellable = sut.$shouldShowDeleteVideosFromVideoPlaylistActionSheet
            .filter { $0 }
            .sink { _ in
                exp.fulfill()
            }
        
        // Act
        let selectedVideos = [
            NodeEntity(name: "video 1", handle: 1, hasThumbnail: true, duration: 60),
            NodeEntity(name: "video 2", handle: 2, hasThumbnail: true)
        ]
        sharedUIState.didSelectRemoveVideoFromPlaylistAction.send(selectedVideos)
        
        // Assert
        await fulfillment(of: [exp], timeout: 0.5)
        XCTAssertEqual(sut.selectedVideos, selectedVideos)
        
        cancellable.cancel()
    }
    
    // MARK: - didTapCancelOnDeleteVideosFromVideoPlaylistActionSheet
    
    @MainActor
    func testDidTapCancelOnDeleteVideosFromVideoPlaylistActionSheet_whenCalled_clearSelectedVideos() {
        let videoPlaylistEntity = VideoPlaylistEntity(setIdentifier: SetIdentifier(handle: 1), name: "a video playlist name", count: 0, type: .user, creationTime: Date(), modificationTime: Date())
        let (sut, _, _, _, _, _, _, _, _) = makeSUT(
            videoPlaylistEntity: videoPlaylistEntity
        )
        
        sut.didTapCancelOnDeleteVideosFromVideoPlaylistActionSheet()
        
        XCTAssertNil(sut.selectedVideos)
    }
    
    @MainActor
    func testDidTapCancelOnDeleteVideosFromVideoPlaylistActionSheet_whenHasSelectedVideos_clearSelectedVideos() {
        let videoPlaylistEntity = VideoPlaylistEntity(setIdentifier: SetIdentifier(handle: 1), name: "a video playlist name", count: 0, type: .user, creationTime: Date(), modificationTime: Date())
        let (sut, _, _, _, sharedUIState, _, _, _, _) = makeSUT(
            videoPlaylistEntity: videoPlaylistEntity
        )
        let selectedVideos = [
            NodeEntity(name: "video 1", handle: 1, hasThumbnail: true, duration: 60),
            NodeEntity(name: "video 2", handle: 2, hasThumbnail: true)
        ]
        sharedUIState.didSelectRemoveVideoFromPlaylistAction.send(selectedVideos)
        
        sut.didTapCancelOnDeleteVideosFromVideoPlaylistActionSheet()
        
        XCTAssertNil(sut.selectedVideos)
    }
    
    // MARK: - deleteVideosFromVideoPlaylist
    
    @MainActor
    func testDeleteVideosFromVideoPlaylist_whenHasNoSelectedVideos_doesNotPerformDeleteVideosFromPlaylist() async throws {
        let videoPlaylistEntity = VideoPlaylistEntity(setIdentifier: SetIdentifier(handle: 1), name: "a video playlist name", count: 0, type: .user, creationTime: Date(), modificationTime: Date())
        let (sut, _, _, _, _, _, _, videoPlaylistModificationUseCase, _) = makeSUT(
            videoPlaylistEntity: videoPlaylistEntity
        )
        
        try await sut.deleteVideosFromVideoPlaylist()
        
        XCTAssertTrue(videoPlaylistModificationUseCase.messages.notContains(.deleteVideoPlaylist))
    }
    
    @MainActor
    func testDeleteVideosFromVideoPlaylist_whenHasSelectedVideos_deletesVideosInVideoPlaylists() async {
        // Arrange
        let selectedVideos = [
            NodeEntity(name: "video 1", handle: 1, hasThumbnail: true, duration: 60),
            NodeEntity(name: "video 2", handle: 2, hasThumbnail: true)
        ]
        let videoPlaylistEntity = VideoPlaylistEntity(setIdentifier: SetIdentifier(handle: 1), name: "a video playlist name", count: 0, type: .user, creationTime: Date(), modificationTime: Date())
        let (sut, _, videoPlaylistContentsUseCase, _, sharedUIState, _, _, videoPlaylistModificationUseCase, _) = makeSUT(
            videoPlaylistEntity: videoPlaylistEntity,
            videoPlaylistModificationUseCase: MockVideoPlaylistModificationUseCase(deleteVideosInVideoPlaylistResult: .failure(GenericErrorEntity()))
        )
        let exp = expectation(description: "action sheet flag expectation")
        let cancellable = sut.$shouldShowDeleteVideosFromVideoPlaylistActionSheet
            .filter { $0 }
            .sink { _ in
                exp.fulfill()
            }
        sharedUIState.didSelectRemoveVideoFromPlaylistAction.send(selectedVideos)
        await fulfillment(of: [exp], timeout: 0.5)
        
        // Act
        try? await sut.deleteVideosFromVideoPlaylist()
        
        // Assert
        XCTAssertEqual(videoPlaylistContentsUseCase.messages, [ .userVideoPlaylistVideos ])
        XCTAssertEqual(videoPlaylistModificationUseCase.messages, [ .deleteVideosInVideoPlaylist ])
        assertThatDeleteVideosFromVideoPlaylistClearSelectedVideos(on: sut)
        
        cancellable.cancel()
    }
    
    @MainActor
    func testDeleteVideosFromVideoPlaylist_whenHasError_doesNotUpdatesUI() async {
        // Arrange
        let selectedVideos = [
            NodeEntity(name: "video 1", handle: 1, hasThumbnail: true, duration: 60),
            NodeEntity(name: "video 2", handle: 2, hasThumbnail: true)
        ]
        let videoPlaylistEntity = VideoPlaylistEntity(setIdentifier: SetIdentifier(handle: 1), name: "a video playlist name", count: 0, type: .user, creationTime: Date(), modificationTime: Date())
        let (sut, _, _, _, sharedUIState, _, _, _, _) = makeSUT(
            videoPlaylistEntity: videoPlaylistEntity,
            videoPlaylistModificationUseCase: MockVideoPlaylistModificationUseCase(deleteVideosInVideoPlaylistResult: .failure(GenericErrorEntity()))
        )
        let exp = expectation(description: "action sheet flag expectation")
        let cancellable = sut.$shouldShowDeleteVideosFromVideoPlaylistActionSheet
            .filter { $0 }
            .sink { _ in
                exp.fulfill()
            }
        sharedUIState.didSelectRemoveVideoFromPlaylistAction.send(selectedVideos)
        await fulfillment(of: [exp], timeout: 0.5)
        
        // Act
        try? await sut.deleteVideosFromVideoPlaylist()
        
        // Assert
        XCTAssertEqual(sharedUIState.snackBarText, "")
        XCTAssertFalse(sharedUIState.shouldShowSnackBar)
        assertThatDeleteVideosFromVideoPlaylistClearSelectedVideos(on: sut)
        
        cancellable.cancel()
    }
    
    @MainActor
    func testDeleteVideosFromVideoPlaylist_whenSuccess_showsSnackBar() async throws {
        // Arrange
        let selectedVideos = [
            NodeEntity(name: "video 1", handle: 1, hasThumbnail: true, duration: 60),
            NodeEntity(name: "video 2", handle: 2, hasThumbnail: true)
        ]
        let videoPlaylistEntity = VideoPlaylistEntity(setIdentifier: SetIdentifier(handle: 1), name: "a video playlist name", count: selectedVideos.count, type: .user, creationTime: Date(), modificationTime: Date())
        let (sut, _, _, _, sharedUIState, _, _, _, _) = makeSUT(
            videoPlaylistEntity: videoPlaylistEntity,
            videoPlaylistModificationUseCase: MockVideoPlaylistModificationUseCase(deleteVideosInVideoPlaylistResult: .success(.init(success: UInt(selectedVideos.count), failure: 0)))
        )
        let exp = expectation(description: "action sheet flag expectation")
        let cancellable = sut.$shouldShowDeleteVideosFromVideoPlaylistActionSheet
            .filter { $0 }
            .sink { _ in
                exp.fulfill()
            }
        sharedUIState.didSelectRemoveVideoFromPlaylistAction.send(selectedVideos)
        await fulfillment(of: [exp], timeout: 0.5)
        
        // Act
        try await sut.deleteVideosFromVideoPlaylist()
        
        // Assert
        let snackBarMessage = Strings.Localizable.Videos.Tab.Playlist.PlaylistContent.Snackbar.removedVideosCountFromPlaylistName(selectedVideos.count)
            .replacingOccurrences(of: "[A]", with: videoPlaylistEntity.name)
        XCTAssertEqual(sharedUIState.snackBarText, snackBarMessage)
        XCTAssertTrue(sharedUIState.shouldShowSnackBar)
        assertThatDeleteVideosFromVideoPlaylistClearSelectedVideos(on: sut)
        
        cancellable.cancel()
    }
    
    @MainActor
    func testDeleteVideosFromVideoPlaylist_whenSuccess_doesNotShowSnackBar() async throws {
        // Arrange
        let selectedVideos = [
            NodeEntity(name: "video 1", handle: 1, hasThumbnail: true, duration: 60),
            NodeEntity(name: "video 2", handle: 2, hasThumbnail: true)
        ]
        let videoPlaylistEntity = VideoPlaylistEntity(setIdentifier: SetIdentifier(handle: 1), name: "a video playlist name", count: selectedVideos.count, type: .user, creationTime: Date(), modificationTime: Date())
        let (sut, _, _, _, sharedUIState, _, _, _, _) = makeSUT(
            videoPlaylistEntity: videoPlaylistEntity,
            videoPlaylistModificationUseCase: MockVideoPlaylistModificationUseCase(deleteVideosInVideoPlaylistResult: .success(.init(success: UInt(selectedVideos.count), failure: 0)))
        )
        let exp = expectation(description: "action sheet flag expectation")
        let cancellable = sut.$shouldShowDeleteVideosFromVideoPlaylistActionSheet
            .filter { $0 }
            .sink { _ in
                exp.fulfill()
            }
        sharedUIState.didSelectRemoveVideoFromPlaylistAction.send(selectedVideos)
        await fulfillment(of: [exp], timeout: 0.5)
        
        // Act
        try await sut.deleteVideosFromVideoPlaylist(showSnackBar: false)
        
        // Assert
        XCTAssertEqual(sharedUIState.snackBarText, "")
        XCTAssertFalse(sharedUIState.shouldShowSnackBar)
        assertThatDeleteVideosFromVideoPlaylistClearSelectedVideos(on: sut)
        
        cancellable.cancel()
    }
    
    // MARK: - subscribeToDidSelectMoveVideoInVideoPlaylistContentToRubbishBinAction
    
    @MainActor
    func testSubscribeTodidSelectMoveVideoInVideoPlaylistContentToRubbishBinAction_whenHasEmptyVideosChanged_doesNotRequestDeletion() async {
        // Arrange
        let videoPlaylistEntity = VideoPlaylistEntity(setIdentifier: SetIdentifier(handle: 1), name: "a video playlist name", count: 0, type: .user, creationTime: Date(), modificationTime: Date())
        let (_, _, _, _, sharedUIState, _, _, videoPlaylistModificationUseCase, _) = makeSUT(
            videoPlaylistEntity: videoPlaylistEntity
        )
        
        let exp = expectation(description: "listen for event")
        var receivedMessages: [MockVideoPlaylistModificationUseCase.Invocation]?
        let cancellable = videoPlaylistModificationUseCase.$invocations
            .receive(on: DispatchQueue.main)
            .sink { messages in
                receivedMessages = messages
                exp.fulfill()
            }
        
        // Act
        sharedUIState.didSelectMoveVideoInVideoPlaylistContentToRubbishBinAction.send([])
        await fulfillment(of: [exp], timeout: 0.5)
        
        // Assert
        XCTAssertTrue(receivedMessages?.isEmpty == true)
        
        cancellable.cancel()
    }
    
    @MainActor
    func testSubscribeTodidSelectMoveVideoInVideoPlaylistContentToRubbishBinAction_whenHasNonEmptyVideosChanged_requestDeletion() async {
        // Arrange
        let videos = [
            NodeEntity(name: "video 1", handle: 1, hasThumbnail: true, duration: 60),
            NodeEntity(name: "video 2", handle: 2, hasThumbnail: true)
        ]
        let videoPlaylistEntity = VideoPlaylistEntity(setIdentifier: SetIdentifier(handle: 1), name: "a video playlist name", count: videos.count, type: .user, creationTime: Date(), modificationTime: Date())
        let (sut, _, _, _, sharedUIState, _, _, videoPlaylistModificationUseCase, _) = makeSUT(
            videoPlaylistEntity: videoPlaylistEntity,
            videoPlaylistModificationUseCase: MockVideoPlaylistModificationUseCase(
                deleteVideosInVideoPlaylistResult: .success(VideoPlaylistElementsResultEntity(
                    success: UInt(videos.count),
                    failure: 0))
            )
        )
        
        let exp = expectation(description: "listen for event")
        exp.assertForOverFulfill = false
        var receivedInvocations: [MockVideoPlaylistModificationUseCase.Invocation]?
        let cancellable = videoPlaylistModificationUseCase.$invocations
            .receive(on: DispatchQueue.main)
            .sink { messages in
                receivedInvocations = messages
                exp.fulfill()
            }
        
        var videosToBeMovedToRubbihBin: [NodeEntity]?
        let rubbishBinActionExp = expectation(description: "about to move to rubbish bin action")
        let rubbishBinActionCancellable = sharedUIState
            .didFinishDeleteVideoFromVideoPlaylistContentThenAboutToMoveToRubbishBinAction
            .receive(on: DispatchQueue.main)
            .sink { videos in
                videosToBeMovedToRubbihBin = videos
                rubbishBinActionExp.fulfill()
            }
        
        // Act
        sharedUIState.didSelectMoveVideoInVideoPlaylistContentToRubbishBinAction.send(videos)
        await sut.moveVideoInVideoPlaylistContentToRubbishBinTask?.value
        await fulfillment(of: [exp], timeout: 0.5)
        await fulfillment(of: [rubbishBinActionExp], timeout: 0.5)
        
        // Assert
        XCTAssertEqual(receivedInvocations, [ .deleteVideosInVideoPlaylist ])
        XCTAssertEqual(videosToBeMovedToRubbihBin, videos)
        XCTAssertEqual(sharedUIState.snackBarText, "")
        XCTAssertFalse(sharedUIState.shouldShowSnackBar)
        
        cancellable.cancel()
        rubbishBinActionCancellable.cancel()
    }
    
    // MARK: - Helpers
    
    @MainActor
    private func makeSUT(
        videoPlaylistEntity: VideoPlaylistEntity,
        videoPlaylistContentsUseCase: MockVideoPlaylistContentUseCase = MockVideoPlaylistContentUseCase(),
        thumbnailLoader: MockThumbnailLoader = MockThumbnailLoader(),
        sensitiveNodeUseCase: MockSensitiveNodeUseCase = MockSensitiveNodeUseCase(),
        sortOrderPreferenceUseCase: MockSortOrderPreferenceUseCase = MockSortOrderPreferenceUseCase(sortOrderEntity: .defaultAsc),
        videoPlaylistsUseCase: MockVideoPlaylistUseCase = MockVideoPlaylistUseCase(),
        videoPlaylistModificationUseCase: MockVideoPlaylistModificationUseCase = MockVideoPlaylistModificationUseCase(),
        syncModel: VideoRevampSyncModel = VideoRevampSyncModel(),
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
        videoPlaylistModificationUseCase: MockVideoPlaylistModificationUseCase,
        syncModel: VideoRevampSyncModel
    ) {
        let sharedUIState = VideoPlaylistContentSharedUIState()
        let videoPlaylistThumbnailLoader = MockVideoPlaylistThumbnailLoader()
        let selectionAdapter = MockVideoPlaylistContentViewModelSelectionAdapter()
        let sut = VideoPlaylistContentViewModel(
            videoPlaylistEntity: videoPlaylistEntity,
            videoPlaylistContentsUseCase: videoPlaylistContentsUseCase,
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
            videoPlaylistModificationUseCase: videoPlaylistModificationUseCase,
            thumbnailLoader: thumbnailLoader,
            sensitiveNodeUseCase: sensitiveNodeUseCase,
            nodeUseCase: MockNodeUseCase(),
            accountStorageUseCase: MockAccountStorageUseCase(),
            videoRevampRouter: MockVideoRevampRouter(),
            featureFlagProvider: MockFeatureFlagProvider(list: [:]),
            syncModel: syncModel
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
            videoPlaylistModificationUseCase,
            syncModel
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
    
    private func videoPlaylist(id: SetHandleEntity, type: VideoPlaylistEntityType) -> VideoPlaylistEntity {
        VideoPlaylistEntity(
            setIdentifier: SetIdentifier(handle: id),
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
    
    @MainActor
    private func assertThatDeleteVideosFromVideoPlaylistClearSelectedVideos(
        on sut: VideoPlaylistContentViewModel,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        XCTAssertNil(sut.selectedVideos, file: file, line: line)
    }
}

@Suite("VideoPlaylistContentViewModel Tests")
struct VideoPlaylistContentViewModelTestSuite {
    @Suite("Show Video Picker")
    @MainActor
    struct ShowVideoPicker {
        @Test("when account paywalled it should show over disk quota")
        func overDiskQuota() {
            let accountStorageUseCase = MockAccountStorageUseCase(isPaywalled: true)
            let videoRevampRouter = MockVideoRevampRouter()
            let sut = makeSUT(
                accountStorageUseCase: accountStorageUseCase,
                videoRevampRouter: videoRevampRouter)
            sut.shouldShowVideoPlaylistPicker = true
            
            sut.showVideoPicker()
            
            #expect(videoRevampRouter.showOverDiskQuotaCalled == 1)
            #expect(videoRevampRouter.openVideoPickerCalled == 0)
            #expect(sut.shouldShowVideoPlaylistPicker == false)
        }
        
        @Test("when account is not paywalled it should show video picker")
        func notPaywalled() async throws {
            let accountStorageUseCase = MockAccountStorageUseCase(isPaywalled: false)
            let videoRevampRouter = MockVideoRevampRouter()
            let sut = makeSUT(
                accountStorageUseCase: accountStorageUseCase,
                videoRevampRouter: videoRevampRouter)
            sut.shouldShowVideoPlaylistPicker = true
            
            sut.showVideoPicker()
            
            #expect(videoRevampRouter.openVideoPickerCalled == 1)
            #expect(videoRevampRouter.showOverDiskQuotaCalled == 0)
            #expect(sut.shouldShowVideoPlaylistPicker == false)
        }
    }
    
    @MainActor
    private static func makeSUT(
        videoPlaylistEntity: VideoPlaylistEntity =  .init(setIdentifier: .init(handle: 1)),
        videoPlaylistContentsUseCase: some VideoPlaylistContentsUseCaseProtocol = MockVideoPlaylistContentUseCase(),
        videoPlaylistThumbnailLoader: some VideoPlaylistThumbnailLoaderProtocol = MockVideoPlaylistThumbnailLoader(),
        sharedUIState: VideoPlaylistContentSharedUIState = .init(),
        presentationConfig: VideoPlaylistContentSnackBarPresentationConfig? = nil,
        sortOrderPreferenceUseCase: some SortOrderPreferenceUseCaseProtocol = MockSortOrderPreferenceUseCase(),
        selectionDelegate: some VideoPlaylistContentViewModelSelectionDelegate = MockVideoPlaylistContentViewModelSelectionAdapter(),
        renameVideoPlaylistAlertViewModel: TextFieldAlertViewModel = .init(title: "", affirmativeButtonTitle: "", destructiveButtonTitle: ""),
        videoPlaylistsUseCase: some VideoPlaylistUseCaseProtocol = MockVideoPlaylistUseCase(),
        videoPlaylistModificationUseCase: some VideoPlaylistModificationUseCaseProtocol = MockVideoPlaylistModificationUseCase(),
        thumbnailLoader: some ThumbnailLoaderProtocol = MockThumbnailLoader(),
        sensitiveNodeUseCase: some SensitiveNodeUseCaseProtocol = MockSensitiveNodeUseCase(),
        nodeUseCase: some NodeUseCaseProtocol = MockNodeUseCase(),
        accountStorageUseCase: some AccountStorageUseCaseProtocol = MockAccountStorageUseCase(),
        videoRevampRouter: some VideoRevampRouting = MockVideoRevampRouter(),
        featureFlagProvider: some FeatureFlagProviderProtocol = MockFeatureFlagProvider(list: [:]),
        syncModel: VideoRevampSyncModel = .init()
    ) -> VideoPlaylistContentViewModel {
        .init(
            videoPlaylistEntity: videoPlaylistEntity,
            videoPlaylistContentsUseCase: videoPlaylistContentsUseCase,
            videoPlaylistThumbnailLoader: videoPlaylistThumbnailLoader,
            sharedUIState: sharedUIState,
            sortOrderPreferenceUseCase: sortOrderPreferenceUseCase,
            selectionDelegate: selectionDelegate,
            renameVideoPlaylistAlertViewModel: renameVideoPlaylistAlertViewModel,
            videoPlaylistsUseCase: videoPlaylistsUseCase,
            videoPlaylistModificationUseCase: videoPlaylistModificationUseCase,
            thumbnailLoader: thumbnailLoader,
            sensitiveNodeUseCase: sensitiveNodeUseCase,
            nodeUseCase: nodeUseCase,
            accountStorageUseCase: accountStorageUseCase,
            videoRevampRouter: videoRevampRouter,
            featureFlagProvider: featureFlagProvider,
            syncModel: syncModel
        )
    }
}
