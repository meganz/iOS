import MEGADomain
import MEGADomainMock
import MEGATest
import SwiftUI
@testable import Video
import XCTest

final class VideoPlaylistThumbnailLoaderTests: XCTestCase {
    
    // MARK: - loadThumbnails
    
    func testLoadThumbnails_whenNoCachedThumbnailsThumbnailAndErrors_deliversPlaceholderImage() async {
        let allVideos: [NodeEntity] = []
        let thumbnailUseCase = MockThumbnailUseCase(
            cachedThumbnails: [],
            loadThumbnailResult: .failure(GenericErrorEntity()),
            loadPreviewResult: .failure(GenericErrorEntity()),
            loadThumbnailAndPreviewResult: .failure(GenericErrorEntity())
        )
        let sut = makeSUT(thumbnailUseCase: thumbnailUseCase)
        
        let imageContainers = await sut.loadThumbnails(for: allVideos).compactMap { $0 }
        
        imageContainers.enumerated().forEach { (index, imageContainer) in
            XCTAssertEqual(imageContainer.image, Image(systemName: "square.fill"), "Failed at index: \(index), with data: \(imageContainer)")
        }
    }
    
    func testLoadThumbnails_whenHasCachedThumbnailThumbnailAndErrors_deliversImage() async {
        let allVideos: [NodeEntity] = [
            NodeEntity(name: "video 1", handle: 1, hasThumbnail: true)
        ]
        let thumbnailEntity = ThumbnailEntity(url: anyImageURL(), type: .thumbnail)
        let thumbnailUseCase = MockThumbnailUseCase(
            cachedThumbnails: [thumbnailEntity],
            loadThumbnailResult: .failure(GenericErrorEntity()),
            loadPreviewResult: .failure(GenericErrorEntity()),
            loadThumbnailAndPreviewResult: .failure(GenericErrorEntity())
        )
        let sut = makeSUT(thumbnailUseCase: thumbnailUseCase)
        
        let imageContainers = await sut.loadThumbnails(for: allVideos).compactMap { $0 }
        
        imageContainers.enumerated().forEach { (index, imageContainer) in
            XCTAssertNotNil(imageContainer, "Failed at index: \(index), with data: \(imageContainer)")
        }
    }
    
    func testLoadThumbnails_whenSuccessLoadThumbnail_deliversLoadedImage() async {
        let allVideos: [NodeEntity] = [
            NodeEntity(name: "video 1", handle: 1, hasThumbnail: true)
        ]
        let thumbnailEntity = ThumbnailEntity(url: anyImageURL(), type: .thumbnail)
        let thumbnailUseCase = MockThumbnailUseCase(
            cachedThumbnails: [thumbnailEntity],
            loadThumbnailResult: .success(thumbnailEntity)
        )
        let sut = makeSUT(thumbnailUseCase: thumbnailUseCase)
        
        let imageContainers = await sut.loadThumbnails(for: allVideos).compactMap { $0 }
        
        imageContainers.enumerated().forEach { (index, imageContainer) in
            XCTAssertNotNil(imageContainer, "Failed at index: \(index), with data: \(imageContainer)")
        }
    }
    
    // MARK: - Helpers
    
    private func makeSUT(thumbnailUseCase: MockThumbnailUseCase) -> VideoPlaylistThumbnailLoader {
        VideoPlaylistThumbnailLoader(thumbnailUseCase: thumbnailUseCase)
    }
    
    private func anyImageURL() -> URL {
        try! makeImageURL(systemImageName: "square")
    }
}
