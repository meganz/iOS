import MEGADomain
import MEGADomainMock
import MEGATest
import SwiftUI
@testable import Video
import XCTest

final class VideoPlaylistCellViewModelTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        cleanTestArtifacts()
        writeCacheImage()
    }
    
    override func tearDown() {
        super.tearDown()
        cleanTestArtifacts()
    }
    
    // MARK: - attemptLoadThumbnail
    
    func testAttemptLoadThumbnail_whenNoCachedThumbnailsThumbnailAndErrors_deliversPlaceholderImage() async {
        let videoPlaylist = videoPlaylistEntity(name: "name", handle: 1)
        let mockThumbnailUseCase = MockThumbnailUseCase(
            cachedThumbnails: [],
            loadThumbnailResult: .failure(GenericErrorEntity()),
            loadPreviewResult: .failure(GenericErrorEntity()),
            loadThumbnailAndPreviewResult: .failure(GenericErrorEntity())
        )
        let sut = await makeSUT(
            thumbnailUseCase: mockThumbnailUseCase,
            videoPlaylistEntity: videoPlaylist,
            videos: [ nodeEntity(name: "video 1", handle: 1, hasThumbnail: true) ]
        )
        
        await sut.attemptLoadThumbnail()
        
        let previewEntity = sut.previewEntity
        previewEntity.imageContainers.enumerated().forEach { (index, imageContainer) in
            XCTAssertEqual(imageContainer.image, Image(systemName: "square.fill"), "Failed at index: \(index), with data: \(imageContainer)")
        }
    }
    
    func testAttemptLoadThumbnail_whenHasCachedThumbnailThumbnailAndErrors_deliversImage() async {
        let videoPlaylist = videoPlaylistEntity(name: "name", handle: 1)
        let (_, _, imageURL) = imagePathData()
        let thumbnailEntity = ThumbnailEntity(url: imageURL!, type: .thumbnail)
        let mockThumbnailUseCase = MockThumbnailUseCase(
            cachedThumbnails: [thumbnailEntity],
            loadThumbnailResult: .failure(GenericErrorEntity()),
            loadPreviewResult: .failure(GenericErrorEntity()),
            loadThumbnailAndPreviewResult: .failure(GenericErrorEntity())
        )
        let sut = await makeSUT(
            thumbnailUseCase: mockThumbnailUseCase,
            videoPlaylistEntity: videoPlaylist,
            videos: [ nodeEntity(name: "video 1", handle: 1, hasThumbnail: true) ]
        )
        
        await sut.attemptLoadThumbnail()
        
        let previewEntity = sut.previewEntity
        previewEntity.imageContainers.enumerated().forEach { (index, imageContainer) in
            XCTAssertNotNil(imageContainer, "Failed at index: \(index), with data: \(imageContainer)")
        }
    }
    
    func testAttemptLoadThumbnail_whenSucessLoadThumbnail_useLoadedImage() async {
        let videoPlaylist = videoPlaylistEntity(name: "name", handle: 1)
        let (_, _, imageURL) = imagePathData()
        let thumbnailEntity = ThumbnailEntity(url: imageURL!, type: .thumbnail)
        let mockThumbnailUseCase = MockThumbnailUseCase(
            cachedThumbnails: [thumbnailEntity],
            loadThumbnailResult: .success(thumbnailEntity)
        )
        let sut = await makeSUT(
            thumbnailUseCase: mockThumbnailUseCase,
            videoPlaylistEntity: videoPlaylist,
            videos: [ nodeEntity(name: "video 1", handle: 1, hasThumbnail: true) ]
        )
        
        await sut.attemptLoadThumbnail()
        
        let previewEntity = sut.previewEntity
        previewEntity.imageContainers.enumerated().forEach { (index, imageContainer) in
            XCTAssertNotNil(imageContainer, "Failed at index: \(index), with data: \(imageContainer)")
        }
    }
    
    // MARK: - onTappedMoreOptions
    
    func testOnTappedMoreOptions_whenCalled_triggerTap() async {
        let videoPlaylist = videoPlaylistEntity(name: "name", handle: 1)
        let mockThumbnailUseCase = MockThumbnailUseCase(
            cachedThumbnails: [],
            loadThumbnailResult: .failure(GenericErrorEntity()),
            loadPreviewResult: .failure(GenericErrorEntity()),
            loadThumbnailAndPreviewResult: .failure(GenericErrorEntity())
        )
        var tappedVideoPlaylists = [VideoPlaylistEntity]()
        let sut = await makeSUT(
            thumbnailUseCase: mockThumbnailUseCase,
            videoPlaylistEntity: videoPlaylist,
            videos: [ nodeEntity(name: "video 1", handle: 1, hasThumbnail: true) ],
            onTapMoreOptions: { tappedVideoPlaylists.append($0) }
        )
        
        sut.onTappedMoreOptions()
        
        XCTAssertEqual(tappedVideoPlaylists, [ videoPlaylist ])
    }
    
    // MARK: - previewEntity
    
    func testPreviewEntity_whenViewModelInit_createsCorrectEntity() async {
        let videoPlaylist = videoPlaylistEntity(name: "name", handle: 1, sharedLinkStatus: .exported(true), count: 2)
        let (_, _, imageURL) = imagePathData()
        let thumbnailEntity = ThumbnailEntity(url: imageURL!, type: .thumbnail)
        let mockThumbnailUseCase = MockThumbnailUseCase(
            cachedThumbnails: [thumbnailEntity],
            loadThumbnailResult: .success(thumbnailEntity)
        )
        let sut = await makeSUT(
            thumbnailUseCase: mockThumbnailUseCase,
            videoPlaylistEntity: videoPlaylist,
            videos: [
                nodeEntity(name: "video 1", handle: 1, hasThumbnail: true, duration: 30),
                nodeEntity(name: "video 2", handle: 2, hasThumbnail: true, duration: 30)
            ]
        )
        
        assertThatPreviewEntityCreatesCorrectly(on: sut, videoPlaylist: videoPlaylist)
    }
    
    func testPreviewEntity_whenAttemptLoadThumbnail_createsCorrectEntity() async {
        let videoPlaylist = videoPlaylistEntity(name: "name", handle: 1, sharedLinkStatus: .exported(true), count: 2)
        let (_, _, imageURL) = imagePathData()
        let thumbnailEntity = ThumbnailEntity(url: imageURL!, type: .thumbnail)
        let mockThumbnailUseCase = MockThumbnailUseCase(
            cachedThumbnails: [thumbnailEntity],
            loadThumbnailResult: .success(thumbnailEntity)
        )
        let sut = await makeSUT(
            thumbnailUseCase: mockThumbnailUseCase,
            videoPlaylistEntity: videoPlaylist,
            videos: [
                nodeEntity(name: "video 1", handle: 1, hasThumbnail: true, duration: 30),
                nodeEntity(name: "video 2", handle: 2, hasThumbnail: true, duration: 30)
            ]
        )
        
        await sut.attemptLoadThumbnail()
        
        assertThatPreviewEntityCreatesCorrectly(on: sut, videoPlaylist: videoPlaylist)
    }
    
    // MARK: - Helpers
    
    private func makeSUT(
        thumbnailUseCase: ThumbnailUseCaseProtocol,
        videoPlaylistEntity: VideoPlaylistEntity,
        videos: [NodeEntity] = [],
        onTapMoreOptions: @escaping (_ node: VideoPlaylistEntity) -> Void = { _ in },
        file: StaticString = #filePath,
        line: UInt = #line
    ) async -> VideoPlaylistCellViewModel {
        let sut = VideoPlaylistCellViewModel(
            thumbnailUseCase: thumbnailUseCase,
            videoPlaylistEntity: videoPlaylistEntity,
            videos: videos,
            onTapMoreOptions: onTapMoreOptions
        )
        trackForMemoryLeaks(on: sut, file: file, line: line)
        return sut
    }
    
    private func videoPlaylistEntity(name: String, handle: HandleEntity, sharedLinkStatus: SharedLinkStatusEntity = .exported(false), type: VideoPlaylistEntityType = .user, count: Int = 0) -> VideoPlaylistEntity {
        VideoPlaylistEntity(
            id: handle,
            name: name,
            count: count,
            type: type,
            sharedLinkStatus: sharedLinkStatus
        )
    }
    
    private func nodeEntity(name: String, handle: HandleEntity, hasThumbnail: Bool, isPublic: Bool = false, isShare: Bool = false, isFavorite: Bool = false, label: NodeLabelTypeEntity = .blue, size: UInt64 = 1, duration: Int = 60) -> NodeEntity {
        NodeEntity(
            changeTypes: .name,
            nodeType: .folder,
            name: name,
            handle: handle,
            hasThumbnail: hasThumbnail,
            hasPreview: true,
            isPublic: isPublic,
            isShare: isShare,
            isFavourite: isFavorite,
            label: label,
            publicHandle: handle,
            size: size,
            duration: duration,
            mediaType: .video
        )
    }
    
    private func imagePathData() -> (imagePath: String, imageData: Data?, imageURL: URL?) {
        let testImagePath = NSTemporaryDirectory() + "test_image.jpg"
        
        let imageData = UIImage(systemName: "square")?.jpegData(compressionQuality: 1.0)
        
        let url = URL(string: testImagePath)
        
        return (testImagePath, imageData, url)
    }
    
    private func writeCacheImage() {
        let (testImagePath, imageData, _) = imagePathData()
        XCTAssertNotNil(imageData)
        XCTAssertTrue(FileManager.default.createFile(atPath: testImagePath, contents: imageData, attributes: nil))
    }
    
    private func cleanTestArtifacts() {
        let (testImagePath, _, _) = imagePathData()
        try? FileManager.default.removeItem(atPath: testImagePath)
    }
    
    private func assertThatPreviewEntityCreatesCorrectly(
        on sut: VideoPlaylistCellViewModel,
        videoPlaylist: VideoPlaylistEntity,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        XCTAssertEqual(sut.previewEntity.title, videoPlaylist.name, file: file, line: line)
        XCTAssertEqual(sut.previewEntity.count, "\(videoPlaylist.count) Videos", file: file, line: line)
        XCTAssertEqual(sut.previewEntity.isExported, videoPlaylist.isLinkShared, file: file, line: line)
        XCTAssertEqual(sut.previewEntity.duration, "00:01:00")
        XCTAssertEqual(sut.previewEntity.imageContainers.count, videoPlaylist.count, file: file, line: line)
    }
}
