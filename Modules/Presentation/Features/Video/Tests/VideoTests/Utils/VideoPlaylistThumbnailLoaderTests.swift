import MEGADomain
import MEGADomainMock
import MEGAPresentation
import MEGAPresentationMock
import MEGATest
import SwiftUI
@testable import Video
import XCTest

final class VideoPlaylistThumbnailLoaderTests: XCTestCase {
    
    // MARK: - loadThumbnails
    
    func testLoadThumbnails_whenEmptyVideos_deliversEmptyThumbnail() async {
        let allVideos: [NodeEntity] = []
        let thumbnailLoader = MockThumbnailLoader()
        
        let sut = makeSUT(
            thumbnailLoader: thumbnailLoader,
            fallbackImageContainer: fallbackImageContainer()
        )
        
        let thumbnail = await sut.loadThumbnails(for: allVideos)
        
        XCTAssertEqual(thumbnail.type, .empty)
        XCTAssertTrue(thumbnail.imageContainers.isEmpty)
    }
    
    func testLoadThumbnails_whenAllVideosHasNoThumbnail_deliverFallbackThumbnail() async {
        let allVideos: [NodeEntity] = [
            NodeEntity(name: "video 1.mp4", handle: 1, hasThumbnail: false),
            NodeEntity(name: "video 2.mp4", handle: 2, hasThumbnail: false),
            NodeEntity(name: "video 3.mp4", handle: 3, hasThumbnail: false)
        ]
        let thumbnailLoader = MockThumbnailLoader()
        
        let sut = makeSUT(
            thumbnailLoader: thumbnailLoader,
            fallbackImageContainer: fallbackImageContainer()
        )
        
        let thumbnail = await sut.loadThumbnails(for: allVideos)
        
        XCTAssertEqual(thumbnail.type, .allVideosHasNoThumbnails)
        XCTAssertEqual(thumbnail.imageContainers.count, 1)
        XCTAssertEqual(thumbnail.imageContainers.first?.type, fallbackImageContainer().type)
        XCTAssertEqual(thumbnail.imageContainers.first?.image, fallbackImageContainer().image)
    }
    
    func testLoadThumbnails_whenHasImage_deliversImage() async {
        let allVideos: [NodeEntity] = [
            NodeEntity(name: "video 1.mp4", handle: 1, hasThumbnail: true)
        ]
        let loadImageResultContainers: [any ImageContaining] = [
            ImageContainer(image: Image(systemName: "square"), type: .thumbnail)
        ]
        let thumbnailLoader = MockThumbnailLoader(
            loadImage: loadImageResultContainers.async.eraseToAnyAsyncSequence()
        )
        
        let sut = makeSUT(
            thumbnailLoader: thumbnailLoader,
            fallbackImageContainer: fallbackImageContainer()
        )
        
        let thumbnail = await sut.loadThumbnails(for: allVideos)
        
        XCTAssertEqual(thumbnail.imageContainers.count, 1)
        thumbnail.imageContainers.enumerated().forEach { (index, imageContainer) in
            XCTAssertNotNil(imageContainer, "Failed at index: \(index), with data: \(imageContainer)")
        }
    }
    
    func testLoadThumbnails_whenHasTwoVideosOneHasThumbnailOneHasNoThumbnail_deliversThumbnailOnlyForVideosThatHasThumbnail() async {
        let allVideos: [NodeEntity] = [
            NodeEntity(name: "video 1.mp4", handle: 1, hasThumbnail: true),
            NodeEntity(name: "video 2.mp4", handle: 2, hasThumbnail: false)
        ]
        let loadImageResultContainers: [any ImageContaining] = [
            ImageContainer(image: Image(systemName: "square"), type: .thumbnail)
        ]
        let thumbnailLoader = MockThumbnailLoader(
            loadImage: loadImageResultContainers.async.eraseToAnyAsyncSequence()
        )
        
        let sut = makeSUT(
            thumbnailLoader: thumbnailLoader,
            fallbackImageContainer: fallbackImageContainer()
        )
        
        let thumbnail = await sut.loadThumbnails(for: allVideos)
        
        XCTAssertEqual(thumbnail.imageContainers.count, 1)
        XCTAssertEqual(thumbnail.type, .normal)
    }
    
    func testLoadThumbnails_whenHasThreeVideosTwoHasThumbnailOneHasNoThumbnail_deliversThumbnailOnlyForVideosThatHasThumbnail() async {
        let allVideos: [NodeEntity] = [
            NodeEntity(name: "video 1.mp4", handle: 1, hasThumbnail: true),
            NodeEntity(name: "video 2.mp4", handle: 2, hasThumbnail: true),
            NodeEntity(name: "video 3.mp4", handle: 3, hasThumbnail: false)
        ]
        let loadImageResultContainers: [any ImageContaining] = [
            ImageContainer(image: Image(systemName: "square"), type: .thumbnail)
        ]
        let thumbnailLoader = MockThumbnailLoader(
            loadImage: loadImageResultContainers.async.eraseToAnyAsyncSequence()
        )
        
        let sut = makeSUT(
            thumbnailLoader: thumbnailLoader,
            fallbackImageContainer: fallbackImageContainer()
        )
        
        let thumbnail = await sut.loadThumbnails(for: allVideos)
        
        XCTAssertEqual(thumbnail.imageContainers.count, 2)
        XCTAssertEqual(thumbnail.type, .normal)
    }
    
    // MARK: - Helpers
    
    private func makeSUT(thumbnailLoader: MockThumbnailLoader, fallbackImageContainer: (any ImageContaining)) -> VideoPlaylistThumbnailLoader {
        VideoPlaylistThumbnailLoader(
            thumbnailLoader: thumbnailLoader,
            fallbackImageContainer: fallbackImageContainer
        )
    }
    
    private func fallbackImageContainer() -> (any ImageContaining) {
        ImageContainer(image: fallbackImage, type: .thumbnail)
    }
    
    private var fallbackImage: Image {
        Image(uiImage: VideoConfig.preview.playlistContentAssets.videoPlaylistThumbnailFallbackImage)
    }
    
    private func anyImageURL() -> URL {
        try! makeImageURL(systemImageName: "square")
    }
}
