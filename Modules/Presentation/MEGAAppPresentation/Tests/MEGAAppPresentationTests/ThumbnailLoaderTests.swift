@testable import MEGAAppPresentation
import MEGADomain
import MEGADomainMock
import MEGASwift
import MEGATest
import SwiftUI
import XCTest

final class ThumbnailLoaderTests: XCTestCase {
    
    func testInitialImageForType_noCachedImage_shouldReturnPlaceholderForFileType() {
        let fileName = "test.jpg"
        let photo = NodeEntity(name: fileName, handle: 43)
        let placeholder: Image = Image("heart")
        let sut = makeSUT()
        
        XCTAssertTrue(sut.initialImage(for: photo, type: .thumbnail, placeholder: { placeholder })
            .isEqual(ImageContainer(image: placeholder, type: .placeholder)))
    }
    
    func testInitialImageForType_noCachedImage_shouldReturnPlaceholderProvided() {
        let fileName = "test.jpg"
        let photo = NodeEntity(name: fileName, handle: 43)
        
        let sut = makeSUT()
        let expectedImage: Image = Image("heart")
        XCTAssertTrue(sut.initialImage(for: photo, type: .thumbnail, placeholder: { expectedImage })
            .isEqual(ImageContainer(image: expectedImage, type: .placeholder)))
    }
    
    func testInitialImageForType_imageCached_shouldReturnCachedImage() throws {
        let localURL = try makeImageURL()
        let photo = NodeEntity(name: "0.jpg", handle: 1)
        let placeholder: Image = Image("heart")

        [(ThumbnailTypeEntity.thumbnail, ImageType.thumbnail),
         (.preview, .preview),
         (.original, .original)].forEach { thumbnailType, expectedType in
            let sut = makeSUT(thumbnailUseCase: MockThumbnailUseCase(cachedThumbnails: [ThumbnailEntity(url: localURL, type: thumbnailType)]))
            
            let image = sut.initialImage(for: photo, type: thumbnailType, placeholder: { placeholder })
            XCTAssertTrue(image.isEqual(URLImageContainer(imageURL: localURL, type: expectedType)))
        }
    }
    
    func testLoadImageForType_imageCached_shouldReturnCachedImage() async throws {
        let localURL = try makeImageURL()
        let photo = NodeEntity(name: "0.jpg", handle: 1)
        
        let testCases = [(loadType: ThumbnailTypeEntity.thumbnail, expectedType: ImageType.thumbnail),
                         (loadType: .preview, expectedType: .preview),
                         (loadType: .original, expectedType: .original)]
        
        let result = try await withThrowingTaskGroup(of: Bool.self) { group in
            testCases.forEach { testCase in
                let sut = makeSUT(thumbnailUseCase: MockThumbnailUseCase(cachedThumbnails: [ThumbnailEntity(url: localURL, type: testCase.loadType)]))
                
                group.addTask {
                    var iterator = try await sut.loadImage(for: photo, type: testCase.loadType).makeAsyncIterator()
                    let cachedContainer = await iterator.next()
                    return try XCTUnwrap(cachedContainer).isEqual(URLImageContainer(imageURL: localURL, type: testCase.expectedType))
                }
            }
            
            return try await group.allSatisfy { $0 }
        }
        
        XCTAssertTrue(result)
    }
    
    func testLoadImageForThumbnail_notCached_shouldLoadAndReturnImage() async throws {
        let imageURL = try makeImageURL()
        let photo = NodeEntity(name: "0.jpg", handle: 1)
        
        let sut = makeSUT(thumbnailUseCase: MockThumbnailUseCase(cachedThumbnails: [],
                                                                 loadThumbnailResult: .success(ThumbnailEntity(url: imageURL, type: .thumbnail))))
        
        var iterator = try await sut.loadImage(for: photo, type: .thumbnail).makeAsyncIterator()
        let loadedContainer = await iterator.next()
        
        XCTAssertTrue(try XCTUnwrap(loadedContainer).isEqual(URLImageContainer(imageURL: imageURL, type: .thumbnail)))
    }
    
    func testLoadImageForPreviewOrOrignal_notCached_shouldYieldThumbnailThenPreviewResults() async throws {
        let thumbnailURL = try makeImageURL(systemImageName: "folder")
        let previewURL = try makeImageURL(systemImageName: "folder.fill")
        let photo = NodeEntity(name: "0.jpg", handle: 1)
        
        let result = try await withThrowingTaskGroup(of: Bool.self) { group in
            [ThumbnailTypeEntity.preview, .original].forEach { thumbnailType in
                let sut = makeSUT(thumbnailUseCase: MockThumbnailUseCase(cachedThumbnails: [],
                                                                         loadThumbnailResult: .success(ThumbnailEntity(url: thumbnailURL, type: .thumbnail)),
                                                                         loadPreviewResult: .success(ThumbnailEntity(url: previewURL, type: .preview))))
            
                group.addTask {
                    var iterator = try await sut.loadImage(for: photo, type: thumbnailType).makeAsyncIterator()
                    
                    let thumbnailContainer = await iterator.next()
                    let previewContainer = await iterator.next()
                    
                    return [try XCTUnwrap(thumbnailContainer).isEqual(URLImageContainer(imageURL: thumbnailURL, type: .thumbnail)),
                            try XCTUnwrap(previewContainer).isEqual(URLImageContainer(imageURL: previewURL, type: .preview))].allSatisfy { $0 }
                }
            }
            
            return try await group.allSatisfy { $0 }
        }
        
        XCTAssertTrue(result)
    }
    
    private func makeSUT(
        thumbnailUseCase: some ThumbnailUseCaseProtocol = MockThumbnailUseCase()
    ) -> ThumbnailLoader {
        ThumbnailLoader(thumbnailUseCase: thumbnailUseCase)
    }
}
