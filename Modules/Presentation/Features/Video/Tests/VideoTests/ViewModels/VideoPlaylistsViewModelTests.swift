import Combine
import MEGADomain
import MEGADomainMock
import MEGAL10n
import MEGAPresentationMock
import MEGASwiftUI
import MEGATest
@testable import Video
import XCTest

final class VideoPlaylistsViewModelTests: XCTestCase {
    
    private var subscriptions = Set<AnyCancellable>()
    
    func testInit_whenInit_doesNotLoadVideoPlaylists() {
        let (_, videoPlaylistUseCase, _, _) = makeSUT()
        
        XCTAssertTrue(videoPlaylistUseCase.messages.isEmpty)
    }
    
    // MARK: - OnViewAppear
    
    func testOnViewAppeared_whenCalled_loadVideoPlaylists() async {
        let (sut, videoPlaylistUseCase, _, _) = makeSUT()
        
        await sut.onViewAppeared()
        
        XCTAssertTrue(videoPlaylistUseCase.messages.contains(.systemVideoPlaylists))
        XCTAssertTrue(videoPlaylistUseCase.messages.contains(.userVideoPlaylists))
    }
    
    func testOnViewAppeared_whenCalled_setVideoPlaylists() async {
        let (sut, _, _, _) = makeSUT(
            videoPlaylistUseCase: MockVideoPlaylistUseCase(systemVideoPlaylistsResult: [
                VideoPlaylistEntity(id: 1, name: "Favorites", count: 0, type: .favourite, creationTime: Date(), modificationTime: Date())
            ])
        )
        
        await sut.onViewAppeared()
        
        XCTAssertFalse(sut.videoPlaylists.isEmpty)
        XCTAssertTrue((sut.videoPlaylists.first?.isSystemVideoPlaylist) != nil)
    }
    
    func testOnViewAppeared_whenLoadVideosSuccessfully_showsCorrectLoadingState() async {
        let (sut, _, _, _) = makeSUT(
            videoPlaylistUseCase: MockVideoPlaylistUseCase(systemVideoPlaylistsResult: [
                VideoPlaylistEntity(id: 1, name: "Favorites", count: 0, type: .favourite, creationTime: Date(), modificationTime: Date())
            ])
        )
        var loadingStates: [Bool] = []
        let exp = expectation(description: "loading state subscription")
        exp.assertForOverFulfill = false
        let cancellable = sut.$shouldShowPlaceHolderView
            .sink { isLoading in
                loadingStates.append(isLoading)
                exp.fulfill()
            }
        
        await sut.onViewAppeared()
        
        XCTAssertEqual(loadingStates, [ false, true, false ])
        
        cancellable.cancel()
        await fulfillment(of: [exp], timeout: 0.5)
    }
    
    func testInit_inInitialState() {
        let (sut, _, _, _) = makeSUT()
        
        XCTAssertFalse(sut.shouldShowAddNewPlaylistAlert)
        XCTAssertEqual(sut.playlistName, "")
    }
    
    func testInit_whenShouldShowAddNewPlaylistAlertChanged_shouldReflectChanges() {
        let (sut, _, syncModel, _) = makeSUT()
        
        XCTAssertFalse(sut.shouldShowAddNewPlaylistAlert)
        
        syncModel.shouldShowAddNewPlaylistAlert = true
        
        XCTAssertTrue(sut.shouldShowAddNewPlaylistAlert)
    }
    
    // MARK: - createUserVideoPlaylist
    
    func testCreateUserVideoPlaylist_whenCalled_createsVideoPlaylist() async {
        let videoPlaylistName =  "a video playlist name"
        let createdVideoPlaylist = VideoPlaylistEntity(id: 1, name: videoPlaylistName, count: 0, type: .user, creationTime: Date(), modificationTime: Date())
        let (sut, videoPlaylistUseCase, _, _) = makeSUT(
            videoPlaylistUseCase: MockVideoPlaylistUseCase(createVideoPlaylistResult: .success(createdVideoPlaylist))
        )
        
        sut.createUserVideoPlaylist(with: videoPlaylistName)
        await sut.createVideoPlaylistTask?.value
        
        XCTAssertEqual(videoPlaylistUseCase.messages, [ .createVideoPlaylist(name: videoPlaylistName) ])
    }
    
    func testCreateUserVideoPlaylist_whenCreatedSuccessfully_setsNewlyCreatedPlaylist() async {
        let videoPlaylistName =  "a video playlist name"
        let createdVideoPlaylist = VideoPlaylistEntity(id: 1, name: videoPlaylistName, count: 0, type: .user, creationTime: Date(), modificationTime: Date())
        let (sut, _, _, _) = makeSUT(
            videoPlaylistUseCase: MockVideoPlaylistUseCase(createVideoPlaylistResult: .success(createdVideoPlaylist))
        )
        
        sut.createUserVideoPlaylist(with: videoPlaylistName)
        await sut.createVideoPlaylistTask?.value
        
        XCTAssertEqual(sut.newlyCreatedVideoPlaylist, createdVideoPlaylist)
    }
    
    func testCreateUserVideoPlaylist_whenCreatedSuccessfully_showsVideoPickerView() async {
        let videoPlaylistName =  "a video playlist name"
        let createdVideoPlaylist = VideoPlaylistEntity(id: 1, name: videoPlaylistName, count: 0, type: .user, creationTime: Date(), modificationTime: Date())
        let (sut, _, _, _) = makeSUT(
            videoPlaylistUseCase: MockVideoPlaylistUseCase(createVideoPlaylistResult: .success(createdVideoPlaylist))
        )
        XCTAssertFalse(sut.shouldShowVideoPlaylistPicker)
        
        sut.createUserVideoPlaylist(with: videoPlaylistName)
        await sut.createVideoPlaylistTask?.value
        
        XCTAssertTrue(sut.shouldShowVideoPlaylistPicker)
    }
    
    func testCreateUserVideoPlaylist_whenFailedToCreate_doesNotshowsVideoPickerView() async {
        let videoPlaylistName =  "a video playlist name"
        let (sut, _, _, _) = makeSUT(
            videoPlaylistUseCase: MockVideoPlaylistUseCase(createVideoPlaylistResult: .failure(GenericErrorEntity()))
        )
        
        sut.createUserVideoPlaylist(with: videoPlaylistName)
        await sut.createVideoPlaylistTask?.value
        
        XCTAssertFalse(sut.shouldShowVideoPlaylistPicker)
    }

    // MARK: Init.monitorSortOrderChanged

    @MainActor
    func testInit_whenValueChanged_loadsVideoPlaylists() async {
        let (sut, videoPlaylistUseCase, syncModel, _) = makeSUT(
            videoPlaylistUseCase: MockVideoPlaylistUseCase(systemVideoPlaylistsResult: [
                VideoPlaylistEntity(id: 1, name: "Favorites", count: 0, type: .favourite, creationTime: Date(), modificationTime: Date())
            ])
        )
        syncModel.videoRevampVideoPlaylistsSortOrderType = .modificationAsc
        let exp = expectation(description: "load video playlists")
        exp.expectedFulfillmentCount = 3
        var receivedMessages = [MockVideoPlaylistUseCase.Message]()
        videoPlaylistUseCase.$publishedMessage
            .sink { messages in
                receivedMessages = messages
                exp.fulfill()
            }
            .store(in: &subscriptions)
        
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        syncModel.videoRevampVideoPlaylistsSortOrderType = .modificationDesc
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        syncModel.videoRevampVideoPlaylistsSortOrderType = .modificationAsc
        await sut.monitorSortOrderChangedTask?.value
        await fulfillment(of: [exp], timeout: 3.0)
        
        XCTAssertTrue(receivedMessages.contains(.systemVideoPlaylists))
        sut.monitorSortOrderChangedTask?.cancel()
    }
    
    @MainActor
    func testInit_whenValueChanged_sortVideoPlaylists() async {
        let unsortedVideoPlaylists = [
            yesterdayPlaylist,
            aMonthAgoPlaylist,
            aWeekAgoPlaylist
        ]
        let (sut, _, syncModel, _) = makeSUT(
            videoPlaylistUseCase: MockVideoPlaylistUseCase(userVideoPlaylistsResult: unsortedVideoPlaylists)
        )
        
        syncModel.videoRevampVideoPlaylistsSortOrderType = .modificationAsc
        let exp = expectation(description: "load video playlists")
        exp.expectedFulfillmentCount = 4
        
        var receivedVideoPlaylists = [VideoPlaylistEntity]()
        sut.$videoPlaylists
            .sink { videoPlaylists in
                receivedVideoPlaylists = videoPlaylists
                exp.fulfill()
            }
            .store(in: &subscriptions)
        
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        syncModel.videoRevampVideoPlaylistsSortOrderType = .modificationDesc
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        syncModel.videoRevampVideoPlaylistsSortOrderType = .modificationAsc
        await sut.monitorSortOrderChangedTask?.value
        await fulfillment(of: [exp], timeout: 3.0)
        
        XCTAssertEqual(receivedVideoPlaylists.map(\.id), [
            aMonthAgoPlaylist.id,
            aWeekAgoPlaylist.id,
            yesterdayPlaylist.id
        ])
        sut.monitorSortOrderChangedTask?.cancel()
    }
    
    @MainActor
    func testAddVideosToNewlyCreatedVideoPlaylist_emptyVideos_shouldNotAddVideosToPlaylist() async {
        let (sut, _, _, videoPlaylistModificationUseCase) = makeSUT()
        
        await sut.addVideosToNewlyCreatedVideoPlaylist(videos: [])
        
        XCTAssertTrue(videoPlaylistModificationUseCase.messages.isEmpty)
    }
    
    @MainActor
    func testAddVideosToNewlyCreatedVideoPlaylist_whenNewlyPlaylistNotCreated_shouldNotAddVideoToPlaylist() async throws {
        let videosToAdd: [NodeEntity] = [
            NodeEntity(
                nodeType: .file,
                name: "name-1",
                handle: 1,
                publicHandle: 1,
                mediaType: .video
            )
        ]
        let (sut, _, _, videoPlaylistModificationUseCase) = makeSUT(
            videoPlaylistModificationUseCase: MockVideoPlaylistModificationUseCase(addToVideoPlaylistResult: .failure(GenericErrorEntity()))
        )
        
        await sut.addVideosToNewlyCreatedVideoPlaylist(videos: videosToAdd)
        
        XCTAssertTrue(videoPlaylistModificationUseCase.messages.isEmpty)
    }
    
    @MainActor
    func testAddVideosToNewlyCreatedVideoPlaylist_whenNewlyPlaylistIsCreated_shouldAddVideoToPlaylist() async throws {
        let videosToAdd: [NodeEntity] = [
            NodeEntity(
                nodeType: .file,
                name: "name-1",
                handle: 1,
                publicHandle: 1,
                mediaType: .video
            )
        ]
        let videoPlaylistName =  "a video playlist name"
        let createdVideoPlaylist = VideoPlaylistEntity(
            id: 1,
            name: videoPlaylistName,
            count: 0,
            type: .user,
            creationTime: Date(),
            modificationTime: Date()
        )
        let (sut, _, _, videoPlaylistModificationUseCase) = makeSUT(
            videoPlaylistUseCase: MockVideoPlaylistUseCase(createVideoPlaylistResult: .success(createdVideoPlaylist)),
            videoPlaylistModificationUseCase: MockVideoPlaylistModificationUseCase(
                addToVideoPlaylistResult: .success(VideoPlaylistElementsResultEntity(
                    success: UInt(videosToAdd.count),
                    failure: 0
                ))
            )
        )
        sut.createUserVideoPlaylist(with: videoPlaylistName)
        await sut.createVideoPlaylistTask?.value
        
        await sut.addVideosToNewlyCreatedVideoPlaylist(videos: videosToAdd)
        
        XCTAssertEqual(videoPlaylistModificationUseCase.messages, [ .addVideoToPlaylist ])
        XCTAssertTrue(sut.shouldOpenVideoPlaylistContent)
        XCTAssertEqual(sut.newlyCreatedVideoPlaylist, createdVideoPlaylist)
        let message = Strings.Localizable.Videos.Tab.Playlist.Snackbar.videoCount(videosToAdd.count).replacingOccurrences(of: "[A]", with: videoPlaylistName)
        XCTAssertEqual(sut.newlyAddedVideosToPlaylistSnackBarMessage, message)
    }
    
    // MARK: - didSelectMoreOptionForItem
    
    func testDidSelectMoreOptionForItem_whenSelectInvalidVideoPlaylist_doNotShowSheet() async {
        let invalidVideoPlaylist = VideoPlaylistEntity(id: 1, name: "new name", count: 0, type: .favourite, creationTime: Date(), modificationTime: Date())
        let (sut, _, _, _) = makeSUT()
        
        sut.didSelectMoreOptionForItem(invalidVideoPlaylist)
        
        XCTAssertNil(sut.selectedVideoPlaylistEntity)
        XCTAssertFalse(sut.isSheetPresented)
    }
    
    func testDidSelectMoreOptionForItem_selectedVideoPlaylist_setsSelectedsVideoPlaylistEntity() {
        let selectedVideoPlaylist = VideoPlaylistEntity(id: 1, name: "video playlist name", count: 0, type: .user, creationTime: Date(), modificationTime: Date())
        let (sut, _, _, _) = makeSUT()
        XCTAssertNil(sut.selectedVideoPlaylistEntity)
        XCTAssertFalse(sut.isSheetPresented)
        
        sut.didSelectMoreOptionForItem(selectedVideoPlaylist)
        
        XCTAssertEqual(sut.selectedVideoPlaylistEntity, selectedVideoPlaylist)
        XCTAssertTrue(sut.isSheetPresented)
    }
    
    // MARK: - didSelectActionSheetMenuAction
    
    func testDidSelectActionSheetMenuAction_renameContextAction_showsRenameAlert() {
        let renamePlaylistContextAction = ContextAction(type: .rename, icon: "any", title: "any")
        let (sut, _, _, _) = makeSUT()
        
        sut.didSelectActionSheetMenuAction(renamePlaylistContextAction)
        
        XCTAssertTrue(sut.shouldShowRenamePlaylistAlert)
    }
    
    func testDidSelectActionSheetMenuAction_deletePlaylistContextAction_showsRenameAlert() {
        let deletePlaylistPlaylistContextAction = ContextAction(type: .deletePlaylist, icon: "any", title: "any")
        let (sut, _, _, _) = makeSUT()
        
        sut.didSelectActionSheetMenuAction(deletePlaylistPlaylistContextAction)
        
        XCTAssertTrue(sut.shouldShowDeletePlaylistAlert)
    }
    
    // MARK: - renameVideoPlaylist
    
    func testRenameVideoPlaylist_emptyOrNil_doesNotRenameVideoPlaylist() async {
        let invalidNames: [String?] = [nil, ""]
        
        for (index, invalidName) in invalidNames.enumerated() {
            let (sut, videoPlaylistUseCase, _, _) = makeSUT()
            
            sut.renameVideoPlaylist(with: invalidName)
            await sut.renameVideoPlaylistTask?.value
            
            XCTAssertTrue(videoPlaylistUseCase.messages.isEmpty, "failed at index: \(index)")
        }
    }
    
    func testRenameVideoPlaylist_whenNoSelectedVideoPlaylist_doesNotRenameVideoPlaylist() async {
        let videoPlaylistName =  "a video playlist name"
        let (sut, videoPlaylistUseCase, _, _) = makeSUT(
            videoPlaylistUseCase: MockVideoPlaylistUseCase(updateVideoPlaylistNameResult: .success(()))
        )
        
        sut.renameVideoPlaylist(with: videoPlaylistName)
        await sut.renameVideoPlaylistTask?.value
        
        XCTAssertTrue(videoPlaylistUseCase.messages.isEmpty)
    }
    
    func testRenameVideoPlaylist_nameIsNil_doesNotRenameVideoPlaylist() async {
        let (sut, videoPlaylistUseCase, _, _) = makeSUT(
            videoPlaylistUseCase: MockVideoPlaylistUseCase(updateVideoPlaylistNameResult: .success(()))
        )
        
        sut.renameVideoPlaylist(with: nil)
        await sut.renameVideoPlaylistTask?.value
        
        XCTAssertTrue(videoPlaylistUseCase.messages.isEmpty)
    }
    
    func testRenameVideoPlaylist_whenCalled_renameVideoPlaylist() async {
        let videoPlaylistName =  "a video playlist name"
        let selectedVideoPlaylist = VideoPlaylistEntity(id: 1, name: videoPlaylistName, count: 0, type: .user, creationTime: Date(), modificationTime: Date())
        let (sut, videoPlaylistUseCase, _, _) = makeSUT(
            videoPlaylistUseCase: MockVideoPlaylistUseCase(updateVideoPlaylistNameResult: .success(()))
        )
        sut.didSelectMoreOptionForItem(selectedVideoPlaylist)
        
        sut.renameVideoPlaylist(with: videoPlaylistName)
        await sut.renameVideoPlaylistTask?.value
        
        XCTAssertEqual(videoPlaylistUseCase.messages, [ .updateVideoPlaylistName ])
    }
    
    func testRenameVideoPlaylist_whenRenameSuccessfully_renameActualSelectedPlaylist() async {
        let creationTime = Date()
        let modificationTime = Date()
        let initialUserVideoPlaylists = [
            VideoPlaylistEntity(id: 2, name: "sample user playlist 1", count: 0, type: .user, creationTime: creationTime, modificationTime: modificationTime),
            VideoPlaylistEntity(id: 3, name: "sample user playlist 2", count: 0, type: .user, creationTime: Date(), modificationTime: Date())
        ]
        let selectedVideoPlaylist = initialUserVideoPlaylists[0]
        var updatedVideoPlaylist = selectedVideoPlaylist
        updatedVideoPlaylist.name = "renamed"
        let (sut, _, _, _) = makeSUT(
            videoPlaylistUseCase: MockVideoPlaylistUseCase(
                updateVideoPlaylistNameResult: .success(()),
                userVideoPlaylistsResult: initialUserVideoPlaylists
            )
        )
        await sut.onViewAppeared()
        sut.didSelectMoreOptionForItem(selectedVideoPlaylist)
        
        sut.renameVideoPlaylist(with: "renamed")
        await sut.renameVideoPlaylistTask?.value
        
        XCTAssertTrue(sut.videoPlaylists.contains(updatedVideoPlaylist))
        XCTAssertNil(sut.selectedVideoPlaylistEntity)
        assertThatCleanUpTemporaryVariablesAfterRenaming(on: sut)
    }
    
    func testRenameVideoPlaylist_whenRenameFailed_showsRenameError() async {
        let videoPlaylistName =  "a video playlist name"
        let selectedVideoPlaylist = VideoPlaylistEntity(id: 2, name: videoPlaylistName, count: 0, type: .user, creationTime: Date(), modificationTime: Date())
        let updatedVideoPlaylist = VideoPlaylistEntity(id: 2, name: "new name", count: 0, type: .user, creationTime: Date(), modificationTime: Date())
        let (sut, _, syncModel, _) = makeSUT(
            videoPlaylistUseCase: MockVideoPlaylistUseCase(
                updateVideoPlaylistNameResult: .failure(GenericErrorEntity()),
                userVideoPlaylistsResult: [
                    VideoPlaylistEntity(id: 2, name: "sample user playlist 1", count: 0, type: .user, creationTime: Date(), modificationTime: Date()),
                    VideoPlaylistEntity(id: 3, name: "sample user playlist 2", count: 0, type: .user, creationTime: Date(), modificationTime: Date())
                ]
            )
        )
        await sut.onViewAppeared()
        sut.didSelectMoreOptionForItem(selectedVideoPlaylist)
        
        sut.renameVideoPlaylist(with: videoPlaylistName)
        await sut.renameVideoPlaylistTask?.value
        
        XCTAssertTrue(sut.videoPlaylists.notContains(updatedVideoPlaylist))
        XCTAssertEqual(syncModel.snackBarMessage, Strings.Localizable.Videos.Tab.Playlist.Content.Snackbar.renamingFailed)
        XCTAssertTrue(syncModel.shouldShowSnackBar)
        assertThatCleanUpTemporaryVariablesAfterRenaming(on: sut)
    }
    
    // MARK: - deleteVideoPlaylist
    
    func testDeleteVideoPlaylist_whenCalled_deletesVideoPlaylist() async {
        let videoPlaylists =  [
            VideoPlaylistEntity(id: 2, name: "sample user playlist 1", count: 0, type: .user, creationTime: Date(), modificationTime: Date()),
            VideoPlaylistEntity(id: 3, name: "sample user playlist 2", count: 0, type: .user, creationTime: Date(), modificationTime: Date())
        ]
        let videoPlaylistToDelete = videoPlaylists[0]
        let (sut, _, _, videoPlaylistModificationUseCase) = makeSUT(
            videoPlaylistUseCase: MockVideoPlaylistUseCase(
                userVideoPlaylistsResult: videoPlaylists
            ),
            videoPlaylistModificationUseCase: MockVideoPlaylistModificationUseCase(
                deleteVideoPlaylistResult: videoPlaylists.filter { $0.id != videoPlaylistToDelete.id }
            )
        )
        
        await sut.deleteVideoPlaylist(videoPlaylistToDelete)
        
        XCTAssertEqual(videoPlaylistModificationUseCase.messages, [ .deleteVideoPlaylist ])
    }
    
    func testDeleteVideoPlaylist_whenSuccessfullyDelete_showsMessage() async {
        let videoPlaylists =  [
            VideoPlaylistEntity(id: 2, name: "sample user playlist 1", count: 0, type: .user, creationTime: Date(), modificationTime: Date()),
            VideoPlaylistEntity(id: 3, name: "sample user playlist 2", count: 0, type: .user, creationTime: Date(), modificationTime: Date())
        ]
        let videoPlaylistToDelete = videoPlaylists[0]
        let (sut, _, syncModel, _) = makeSUT(
            videoPlaylistUseCase: MockVideoPlaylistUseCase(
                userVideoPlaylistsResult: videoPlaylists
            ),
            videoPlaylistModificationUseCase: MockVideoPlaylistModificationUseCase(
                deleteVideoPlaylistResult: videoPlaylists.filter { $0.id != videoPlaylistToDelete.id }
            )
        )
        
        await sut.deleteVideoPlaylist(videoPlaylistToDelete)
        
        let message = Strings.Localizable.Videos.Tab.Playlist.Content.Snackbar.playlistNameDeleted
        let snackBarMessage = message.replacingOccurrences(of: "[A]", with: videoPlaylistToDelete.name)
        XCTAssertEqual(syncModel.snackBarMessage, snackBarMessage)
        XCTAssertEqual(syncModel.shouldShowSnackBar, true)
    }
    
    // MARK: - onViewDissapear
    
    func testOnViewDissapear_whenFinishedAddingVideosToVideoPlaylistShowsVideoPlaylistContent_setsNewlyCreatedVideoPlaylistToNil() async {
        let videosToAdd: [NodeEntity] = [
            NodeEntity(
                nodeType: .file,
                name: "name-1",
                handle: 1,
                publicHandle: 1,
                mediaType: .video
            )
        ]
        let videoPlaylistName =  "a video playlist name"
        let createdVideoPlaylist = VideoPlaylistEntity(
            id: 1,
            name: videoPlaylistName,
            count: 0,
            type: .user,
            creationTime: Date(),
            modificationTime: Date()
        )
        let (sut, _, _, _) = makeSUT(
            videoPlaylistUseCase: MockVideoPlaylistUseCase(createVideoPlaylistResult: .success(createdVideoPlaylist)),
            videoPlaylistModificationUseCase: MockVideoPlaylistModificationUseCase(
                addToVideoPlaylistResult: .success(VideoPlaylistElementsResultEntity(
                    success: UInt(videosToAdd.count),
                    failure: 0
                ))
            )
        )
        sut.createUserVideoPlaylist(with: videoPlaylistName)
        await sut.createVideoPlaylistTask?.value
        
        await sut.addVideosToNewlyCreatedVideoPlaylist(videos: videosToAdd)
        
        XCTAssertTrue(sut.shouldOpenVideoPlaylistContent)
        XCTAssertEqual(sut.newlyCreatedVideoPlaylist, createdVideoPlaylist)
        
        sut.onViewDisappear()
        
        XCTAssertNil(sut.newlyCreatedVideoPlaylist)
        XCTAssertNil(sut.createVideoPlaylistTask)
    }
    
    // MARK: - subscribeToItemsStateForEmptyState
    
    func testSubscribeToItemsStateForEmptyState_whenConditionNotMet_shouldNotShowEmptyView() async {
        // Arrange
        let (sut, _, _, _) = makeSUT(videoPlaylistUseCase: MockVideoPlaylistUseCase(systemVideoPlaylistsResult: []))
        
        var receivedValues: [Bool]?
        let exp = expectation(description: "should not show empty view")
        exp.assertForOverFulfill = false
        let cancellable = sut.$shouldShowVideosEmptyView
            .dropFirst()
            .filter { !$0 }
            .receive(on: DispatchQueue.main)
            .sink {
                receivedValues?.append($0)
                exp.fulfill()
            }
        
        await sut.onViewAppeared()
        await fulfillment(of: [exp], timeout: 0.5)
        
        // Assert
        XCTAssertFalse(receivedValues?.contains(false) == true)
        
        cancellable.cancel()
    }
    
    func testSubscribeToItemsStateForEmptyState_whenConditionMet_shouldShowEmptyView() async {
        // Arrange
        let (sut, _, _, _) = makeSUT(
            videoPlaylistUseCase: MockVideoPlaylistUseCase(systemVideoPlaylistsResult: [
                VideoPlaylistEntity(id: 1, name: "Favorites", count: 0, type: .favourite, creationTime: Date(), modificationTime: Date())
            ])
        )
        
        var receivedValue = false
        let exp = expectation(description: "should show empty view")
        exp.assertForOverFulfill = false
        let cancellable = sut.$shouldShowVideosEmptyView
            .dropFirst()
            .sink { shouldShow in
                receivedValue = shouldShow
                exp.fulfill()
            }
        
        await sut.onViewAppeared()
        await fulfillment(of: [exp], timeout: 0.5)
        
        // Assert
        XCTAssertFalse(receivedValue)
        
        cancellable.cancel()
    }
    
    // MARK: - Helpers
    
    private func makeSUT(
        videoPlaylistUseCase: MockVideoPlaylistUseCase = MockVideoPlaylistUseCase(),
        syncModel: VideoRevampSyncModel = VideoRevampSyncModel(),
        videoPlaylistModificationUseCase: MockVideoPlaylistModificationUseCase = MockVideoPlaylistModificationUseCase(addToVideoPlaylistResult: .failure(GenericErrorEntity())),
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> (
        sut: VideoPlaylistsViewModel,
        videoPlaylistUseCase: MockVideoPlaylistUseCase,
        syncModel: VideoRevampSyncModel,
        videoPlaylistModificationUseCase: MockVideoPlaylistModificationUseCase
    ) {
        let alertViewModel = TextFieldAlertViewModel(title: "title", affirmativeButtonTitle: "Affirmative", destructiveButtonTitle: "Destructive")
        let sut = VideoPlaylistsViewModel(
            videoPlaylistsUseCase: videoPlaylistUseCase,
            videoPlaylistContentUseCase: MockVideoPlaylistContentUseCase(),
            videoPlaylistModificationUseCase: videoPlaylistModificationUseCase,
            syncModel: syncModel,
            alertViewModel: alertViewModel,
            renameVideoPlaylistAlertViewModel: alertViewModel, 
            thumbnailLoader: MockThumbnailLoader(),
            monitorSortOrderChangedDispatchQueue: DispatchQueue.main
        )
        trackForMemoryLeaks(on: sut, file: file, line: line)
        trackForMemoryLeaks(on: videoPlaylistUseCase, file: file, line: line)
        return (sut, videoPlaylistUseCase, syncModel, videoPlaylistModificationUseCase)
    }
    
    private func assertThatCleanUpTemporaryVariablesAfterRenaming(on sut: VideoPlaylistsViewModel, file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertNil(sut.selectedVideoPlaylistEntity, file: file, line: line)
    }
    
    private func videoPlaylist(id: HandleEntity, creationTime: Date, modificationTime: Date) -> VideoPlaylistEntity {
        VideoPlaylistEntity(
            id: id,
            name: "name-\(id)",
            coverNode: nil,
            count: 0,
            type: .favourite,
            creationTime: creationTime,
            modificationTime: modificationTime
        )
    }
    
}
