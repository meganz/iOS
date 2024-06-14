import Combine
import MEGADomain
import MEGADomainMock
import MEGAL10n
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
    
    // MARK: - init.listenSearchTextChange
    
    @MainActor
    func testInitListenSearchTextChange_whenSearchTextIsEmpty_loadVideoPlaylists() async {
        let (sut, videoPlaylistUseCase, syncModel, _) = makeSUT(
            videoPlaylistUseCase: MockVideoPlaylistUseCase(systemVideoPlaylistsResult: [
                VideoPlaylistEntity(id: 1, name: "Favorites", count: 0, type: .favourite, creationTime: Date(), modificationTime: Date())
            ])
        )
        let exp = expectation(description: "load video playlists")
        exp.expectedFulfillmentCount = 2
        var receivedMessages = [MockVideoPlaylistUseCase.Message]()
        videoPlaylistUseCase.$publishedMessage
            .sink { messages in
                if messages.contains(.systemVideoPlaylists) {
                    receivedMessages = messages
                }
                exp.fulfill()
            }
            .store(in: &subscriptions)
        
        syncModel.searchText = "hi"
        syncModel.searchText = ""
        await sut.loadVideoPlaylistsOnSearchTextChangedTask?.value
        await fulfillment(of: [exp], timeout: 0.5)
        
        XCTAssertTrue(receivedMessages.contains(.systemVideoPlaylists))
        sut.loadVideoPlaylistsOnSearchTextChangedTask?.cancel()
    }
    
    @MainActor
    func testInitListenSearchTextChange_whenSearchTextIsNotEmpty_filterPlaylists() async {
        let (sut, _, syncModel, _) = makeSUT(
            videoPlaylistUseCase: MockVideoPlaylistUseCase(systemVideoPlaylistsResult: [
                VideoPlaylistEntity(id: 1, name: "Favorites", count: 0, type: .favourite, creationTime: Date(), modificationTime: Date())
            ])
        )
        let exp = expectation(description: "load video playlists")
        exp.expectedFulfillmentCount = 2
        var receivedPlaylists = [VideoPlaylistEntity]()
        sut.$videoPlaylists
            .sink { videoPlaylists in
                receivedPlaylists = videoPlaylists
                exp.fulfill()
            }
            .store(in: &subscriptions)
        
        syncModel.searchText = ""
        syncModel.searchText = "any-search-text"
        await fulfillment(of: [exp], timeout: 0.5)
        
        XCTAssertTrue(receivedPlaylists.isEmpty)
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
    
    func testDidSelectMoreOptionForItem_selectedVideoPlaylist_setsSelectedsVideoPlaylistEntity() {
        let selectedVideoPlaylist = VideoPlaylistEntity(id: 1, name: "video playlist name", count: 0, type: .user, creationTime: Date(), modificationTime: Date())
        let (sut, _, _, _) = makeSUT()
        XCTAssertNil(sut.selectedVideoPlaylistEntity)
        XCTAssertFalse(sut.isSheetPresented)
        
        sut.didSelectMoreOptionForItem(selectedVideoPlaylist)
        
        XCTAssertEqual(sut.selectedVideoPlaylistEntity, selectedVideoPlaylist)
        XCTAssertTrue(sut.isSheetPresented)
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
            thumbnailUseCase: MockThumbnailUseCase(), 
            videoPlaylistContentUseCase: MockVideoPlaylistContentUseCase(),
            videoPlaylistModificationUseCase: videoPlaylistModificationUseCase,
            syncModel: syncModel,
            alertViewModel: alertViewModel,
            monitorSortOrderChangedDispatchQueue: DispatchQueue.main
        )
        trackForMemoryLeaks(on: sut, file: file, line: line)
        trackForMemoryLeaks(on: videoPlaylistUseCase, file: file, line: line)
        return (sut, videoPlaylistUseCase, syncModel, videoPlaylistModificationUseCase)
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
