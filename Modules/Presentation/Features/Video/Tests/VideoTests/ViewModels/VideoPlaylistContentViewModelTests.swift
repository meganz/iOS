import AsyncAlgorithms
import Combine
import MEGADomain
import MEGADomainMock
import MEGAL10n
import MEGASwift
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
        let (sut, _, videoPlaylistContentsUseCase, _, _, _, _) = makeSUT(
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
        let (sut, _, _, _, _, _, _) = makeSUT(
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
        let (sut, _, _, _, _, _, _) = makeSUT(
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
        let (sut, _, _, _, _, videoPlaylistModificationUseCase, _) = makeSUT(videoPlaylistEntity: videoPlaylistEntity)
        
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
        let (sut, _, _, _, _, _, _) = makeSUT(
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
        let (sut, _, _, _, _, _, _) = makeSUT(
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
        let (sut, _, _, _, sharedUIState, _, _) = makeSUT(
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

    
    // MARK: - Helpers
    
    private func makeSUT(
        videoPlaylistEntity: VideoPlaylistEntity,
        videoPlaylistContentsUseCase: MockVideoPlaylistContentUseCase = MockVideoPlaylistContentUseCase(),
        thumbnailUseCase: MockThumbnailUseCase = MockThumbnailUseCase(),
        sortOrderPreferenceUseCase: MockSortOrderPreferenceUseCase = MockSortOrderPreferenceUseCase(sortOrderEntity: .defaultAsc),
        videoPlaylistModificationUseCase: MockVideoPlaylistModificationUseCase = MockVideoPlaylistModificationUseCase(addToVideoPlaylistResult: .failure(GenericErrorEntity())),
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> (
        sut: VideoPlaylistContentViewModel,
        videoPlaylistThumbnailLoader: MockVideoPlaylistThumbnailLoader,
        videoPlaylistContentsUseCase: MockVideoPlaylistContentUseCase,
        sortOrderPreferenceUseCase: MockSortOrderPreferenceUseCase,
        sharedUIState: VideoPlaylistContentSharedUIState,
        videoPlaylistModificationUseCase: MockVideoPlaylistModificationUseCase,
        selectionAdapter: MockVideoPlaylistContentViewModelSelectionAdapter
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
            videoPlaylistModificationUseCase: videoPlaylistModificationUseCase,
            selectionDelegate: selectionAdapter
        )
        trackForMemoryLeaks(on: sut, file: file, line: line)
        return (
            sut,
            videoPlaylistThumbnailLoader,
            videoPlaylistContentsUseCase,
            sortOrderPreferenceUseCase,
            sharedUIState,
            videoPlaylistModificationUseCase,
            selectionAdapter
        )
    }
    
    private func addVideosToVideoPlaylistSucessfulMessage(videosCount: Int, videoPlaylistName: String) -> String {
        let message = Strings.Localizable.Videos.Tab.Playlist.Snackbar.videoCount(videosCount)
        return message.replacingOccurrences(of: "[A]", with: videoPlaylistName)
    }
}
