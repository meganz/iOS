@testable import MEGA
import MEGADomain
import MEGADomainMock
import MEGASwift
import MEGASwiftUI
import SwiftUI
import XCTest

final class ThumbnailLoaderTests: XCTestCase {
    
    func testInitialImageForType_noCachedImage_shouldReturnPlaceholder() {
        let fileName = "test.jpg"
        let photo = NodeEntity(name: fileName, handle: 43)
        
        let sut = makeSUT()
        
        XCTAssertTrue(sut.initialImage(for: photo, type: .thumbnail)
            .isEqual(ImageContainer(image: Image(FileTypes().fileTypeResource(forFileName: "0.jpg")), type: .placeholder)))
    }
    
    func testInitialImageForType_imageCached_shouldReturnCachedImage() throws {
        let localURL = try makeImageURL()
        let photo = NodeEntity(name: "0.jpg", handle: 1)
        
        [(ThumbnailTypeEntity.thumbnail, ImageType.thumbnail),
         (.preview, .preview),
         (.original, .original)].forEach { thumbnailType, expectedType in
            let sut = makeSUT(thumbnailUseCase: MockThumbnailUseCase(cachedThumbnails: [ThumbnailEntity(url: localURL, type: thumbnailType)]))
            
            let image = sut.initialImage(for: photo, type: thumbnailType)
            XCTAssertTrue(image.isEqual(URLImageContainer(imageURL: localURL, type: expectedType)))
        }
        
        try cleanUpFile(atPath: localURL.path)
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
        
        try cleanUpFile(atPath: localURL.path)
    }
    
    func testLoadImageForThumbnail_notCached_shouldLoadAndReturnImage() async throws {
        let imageURL = try makeImageURL()
        let photo = NodeEntity(name: "0.jpg", handle: 1)
        
        let sut = makeSUT(thumbnailUseCase: MockThumbnailUseCase(cachedThumbnails: [],
                                                                 loadThumbnailResult: .success(ThumbnailEntity(url: imageURL, type: .thumbnail))))
        
        var iterator = try await sut.loadImage(for: photo, type: .thumbnail).makeAsyncIterator()
        let loadedContainer = await iterator.next()
        
        XCTAssertTrue(try XCTUnwrap(loadedContainer).isEqual(URLImageContainer(imageURL: imageURL, type: .thumbnail)))
        
        try cleanUpFile(atPath: imageURL.path)
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
        
        try cleanUpFile(atPath: thumbnailURL.path)
        try cleanUpFile(atPath: previewURL.path)
    }
    
    private func makeSUT(
        thumbnailUseCase: some ThumbnailUseCaseProtocol = MockThumbnailUseCase()
    ) -> ThumbnailLoader {
        ThumbnailLoader(thumbnailUseCase: thumbnailUseCase)
    }
    
    private func makeImageURL(systemImageName: String = "folder") throws -> URL {
        let localImage = try XCTUnwrap(UIImage(systemName: systemImageName))
        let localURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: false)
        let isLocalFileCreated = FileManager.default.createFile(atPath: localURL.path, contents: localImage.pngData())
        XCTAssertTrue(isLocalFileCreated)
        return localURL
    }
    
    private func cleanUpFile(atPath path: String) throws {
        try FileManager.default.removeItem(atPath: path)
    }
}
