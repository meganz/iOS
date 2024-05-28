import MEGADomain
import MEGADomainMock
@testable import Video
import XCTest

final class VideoPlaylistContentViewModelTests: XCTestCase {
    
    // MARK: - onViewAppeared
    
    func testOnViewAppeared_onSuccesfullyLoadVideos_loadVideos() async {
        let allVideos = [
            NodeEntity(name: "video 1", handle: 1, hasThumbnail: true, duration: 60),
            NodeEntity(name: "video 2", handle: 2, hasThumbnail: true)
        ]
        let videoPlaylistContentsUseCase = MockVideoPlaylistContentUseCase(allVideos: allVideos)
        let thumbnailUseCase = MockThumbnailUseCase()
        let videoPlaylistEntity = VideoPlaylistEntity(
            id: 1,
            name: "name",
            count: allVideos.count,
            type: .favourite,
            creationTime: Date(),
            modificationTime: Date()
        )
        let (sut, _) = makeSUT(
            videoPlaylistEntity: videoPlaylistEntity,
            videoPlaylistContentsUseCase: videoPlaylistContentsUseCase,
            thumbnailUseCase: thumbnailUseCase
        )
        
        await sut.onViewAppeared()
        
        XCTAssertEqual(sut.videos, allVideos)
    }
    
    func testOnViewAppeared_whenLoad_loadThumbnailsFromThumbnailLoader() async {
        let allVideos: [NodeEntity] = []
        let videoPlaylistContentsUseCase = MockVideoPlaylistContentUseCase(allVideos: allVideos)
        let thumbnailUseCase = MockThumbnailUseCase(
            cachedThumbnails: [],
            loadThumbnailResult: .failure(GenericErrorEntity()),
            loadPreviewResult: .failure(GenericErrorEntity()),
            loadThumbnailAndPreviewResult: .failure(GenericErrorEntity())
        )
        let videoPlaylistEntity = VideoPlaylistEntity(
            id: 1,
            name: "name",
            count: allVideos.count,
            type: .favourite,
            creationTime: Date(),
            modificationTime: Date()
        )
        let (sut, videoPlaylistThumbnailLoader) = makeSUT(
            videoPlaylistEntity: videoPlaylistEntity,
            videoPlaylistContentsUseCase: videoPlaylistContentsUseCase,
            thumbnailUseCase: thumbnailUseCase
        )
        
        await sut.onViewAppeared()
        
        XCTAssertEqual(videoPlaylistThumbnailLoader.loadThumbnailsCallCount, 1)
    }
    
    func testOnViewAppeared_whenNoCachedThumbnailsThumbnailAndErrors_deliversHeaderViewPlaceholderImage() async {
        let allVideos: [NodeEntity] = []
        let videoPlaylistContentsUseCase = MockVideoPlaylistContentUseCase(allVideos: allVideos)
        let thumbnailUseCase = MockThumbnailUseCase(
            cachedThumbnails: [],
            loadThumbnailResult: .failure(GenericErrorEntity()),
            loadPreviewResult: .failure(GenericErrorEntity()),
            loadThumbnailAndPreviewResult: .failure(GenericErrorEntity())
        )
        let videoPlaylistEntity = VideoPlaylistEntity(
            id: 1,
            name: "name",
            count: allVideos.count,
            type: .favourite,
            creationTime: Date(),
            modificationTime: Date()
        )
        let (sut, _) = makeSUT(
            videoPlaylistEntity: videoPlaylistEntity,
            videoPlaylistContentsUseCase: videoPlaylistContentsUseCase,
            thumbnailUseCase: thumbnailUseCase
        )
        
        await sut.onViewAppeared()
        
        XCTAssertEqual(sut.secondaryInformationViewType, .emptyPlaylist)
        XCTAssertTrue(sut.headerPreviewEntity.imageContainers.isEmpty)
        XCTAssertEqual(sut.headerPreviewEntity.count, "Empty playlist")
        XCTAssertEqual(sut.headerPreviewEntity.duration, "00:00:00")
        XCTAssertEqual(sut.headerPreviewEntity.title, videoPlaylistEntity.name)
        XCTAssertEqual(sut.headerPreviewEntity.isExported, false)
        XCTAssertEqual(sut.headerPreviewEntity.type, videoPlaylistEntity.type)
    }
    
    func testOnViewAppeared_whenHasCachedThumbnailThumbnailAndErrors_deliversHeaderViewWithImage() async {
        let allVideos: [NodeEntity] = [
            NodeEntity(name: "video 1", handle: 1, hasThumbnail: true, duration: 60)
        ]
        let videoPlaylistContentsUseCase = MockVideoPlaylistContentUseCase(allVideos: allVideos)
        let thumbnailEntity = ThumbnailEntity(url: anyImageURL, type: .thumbnail)
        let thumbnailUseCase = MockThumbnailUseCase(
            cachedThumbnails: [thumbnailEntity],
            loadThumbnailResult: .failure(GenericErrorEntity()),
            loadPreviewResult: .failure(GenericErrorEntity()),
            loadThumbnailAndPreviewResult: .failure(GenericErrorEntity())
        )
        let videoPlaylistEntity = VideoPlaylistEntity(
            id: 1,
            name: "name",
            count: allVideos.count,
            type: .favourite,
            creationTime: Date(),
            modificationTime: Date()
        )
        let (sut, _) = makeSUT(
            videoPlaylistEntity: videoPlaylistEntity,
            videoPlaylistContentsUseCase: videoPlaylistContentsUseCase,
            thumbnailUseCase: thumbnailUseCase
        )
        
        await sut.onViewAppeared()
        
        XCTAssertEqual(sut.secondaryInformationViewType, .information)
        XCTAssertFalse(sut.headerPreviewEntity.imageContainers.isEmpty)
        XCTAssertEqual(sut.headerPreviewEntity.count, "1 Video")
        XCTAssertEqual(sut.headerPreviewEntity.duration, "00:01:00")
        XCTAssertEqual(sut.headerPreviewEntity.title, videoPlaylistEntity.name)
        XCTAssertEqual(sut.headerPreviewEntity.isExported, false)
        XCTAssertEqual(sut.headerPreviewEntity.type, videoPlaylistEntity.type)
    }
    
    func testOnViewAppeared_whenSucessLoadThumbnail_deliversHeaderViewUsingLoadedImage() async {
        let allVideos: [NodeEntity] = [
            NodeEntity(name: "video 1", handle: 1, hasThumbnail: true, duration: 60)
        ]
        let videoPlaylistContentsUseCase = MockVideoPlaylistContentUseCase(allVideos: allVideos)
        let thumbnailEntity = ThumbnailEntity(url: anyImageURL, type: .thumbnail)
        let thumbnailUseCase = MockThumbnailUseCase(
            cachedThumbnails: [thumbnailEntity],
            loadThumbnailResult: .success(thumbnailEntity)
        )
        let videoPlaylistEntity = VideoPlaylistEntity(
            id: 1,
            name: "name",
            count: allVideos.count,
            type: .favourite,
            creationTime: Date(),
            modificationTime: Date()
        )
        let (sut, _) = makeSUT(
            videoPlaylistEntity: videoPlaylistEntity,
            videoPlaylistContentsUseCase: videoPlaylistContentsUseCase,
            thumbnailUseCase: thumbnailUseCase
        )
        
        await sut.onViewAppeared()
        
        XCTAssertEqual(sut.secondaryInformationViewType, .information)
        XCTAssertFalse(sut.headerPreviewEntity.imageContainers.isEmpty)
        XCTAssertEqual(sut.headerPreviewEntity.count, "1 Video")
        XCTAssertEqual(sut.headerPreviewEntity.duration, "00:01:00")
        XCTAssertEqual(sut.headerPreviewEntity.title, videoPlaylistEntity.name)
        XCTAssertEqual(sut.headerPreviewEntity.isExported, false)
        XCTAssertEqual(sut.headerPreviewEntity.type, videoPlaylistEntity.type)
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
        videoPlaylistThumbnailLoader: MockVideoPlaylistThumbnailLoader
    ) {
        let videoPlaylistThumbnailLoader = MockVideoPlaylistThumbnailLoader()
        let sut = VideoPlaylistContentViewModel(
            videoPlaylistEntity: videoPlaylistEntity,
            videoPlaylistContentsUseCase: videoPlaylistContentsUseCase,
            thumbnailUseCase: thumbnailUseCase,
            videoPlaylistThumbnailLoader: videoPlaylistThumbnailLoader
        )
        trackForMemoryLeaks(on: sut, file: file, line: line)
        return (sut, videoPlaylistThumbnailLoader)
    }
    
    private var anyImageURL: URL {
        URL(string: "any-image-url")!
    }
}
