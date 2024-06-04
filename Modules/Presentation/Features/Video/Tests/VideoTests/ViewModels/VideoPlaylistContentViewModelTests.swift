import AsyncAlgorithms
import MEGADomain
import MEGADomainMock
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
        let (sut, _, videoPlaylistContentsUseCase) = makeSUT(
            videoPlaylistEntity: videoPlaylistEntity,
            videoPlaylistContentsUseCase: mockVideoPlaylistContentsUseCase,
            thumbnailUseCase: thumbnailUseCase
        )
        
        await sut.onViewAppeared()
        
        XCTAssertTrue(videoPlaylistContentsUseCase.messages.contains(.monitorVideoPlaylist(id: videoPlaylistEntity.id)))
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
        let (sut, _, _) = makeSUT(
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
        let (sut, _, _) = makeSUT(
            videoPlaylistEntity: videoPlaylistEntity,
            videoPlaylistContentsUseCase: mockVideoPlaylistContentsUseCase,
            thumbnailUseCase: thumbnailUseCase
        )
        
        await sut.onViewAppeared()
        
        XCTAssertTrue(sut.shouldPopScreen, "Expect to exit screen")
    }
    
    // MARK: - Helpers
    
    private func makeSUT(
        videoPlaylistEntity: VideoPlaylistEntity,
        videoPlaylistContentsUseCase: MockVideoPlaylistContentUseCase,
        thumbnailUseCase: MockThumbnailUseCase,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> (
        sut: VideoPlaylistContentViewModel,
        videoPlaylistThumbnailLoader: MockVideoPlaylistThumbnailLoader,
        videoPlaylistContentsUseCase: MockVideoPlaylistContentUseCase
    ) {
        let videoPlaylistThumbnailLoader = MockVideoPlaylistThumbnailLoader()
        let sut = VideoPlaylistContentViewModel(
            videoPlaylistEntity: videoPlaylistEntity,
            videoPlaylistContentsUseCase: videoPlaylistContentsUseCase,
            thumbnailUseCase: thumbnailUseCase,
            videoPlaylistThumbnailLoader: videoPlaylistThumbnailLoader
        )
        trackForMemoryLeaks(on: sut, file: file, line: line)
        return (sut, videoPlaylistThumbnailLoader, videoPlaylistContentsUseCase)
    }
}
