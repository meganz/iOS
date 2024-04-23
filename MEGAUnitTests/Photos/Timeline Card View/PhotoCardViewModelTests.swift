import Combine
@testable import MEGA
import MEGADomain
import MEGADomainMock
import MEGAFoundation
import MEGASwift
import MEGASwiftUI
import MEGATest
import SwiftUI
import XCTest

final class PhotoCardViewModelTests: XCTestCase {
    private var subscriptions = Set<AnyCancellable>()
    
    func testInit_defaultValue() throws {
        let sut = makeSUT()
        
        XCTAssertTrue(sut.thumbnailContainer.isEqual(ImageContainer(image: Image(.photoCardPlaceholder), type: .placeholder)))
    }
    
    func testLoadThumbnail_initialThumbnail_shouldNotLoadRemoteThumbnail() async throws {
        let previewContainer = ImageContainer(image: Image("folder"), type: .preview)
        
        let sut = makeSUT(
            coverPhoto: NodeEntity(handle: 1),
            thumbnailLoader: MockThumbnailLoader(initialImage: previewContainer)
        )
       
        let exp = expectation(description: "thumbnail should not change")
        exp.isInverted = true
        
        sut.$thumbnailContainer
            .dropFirst()
            .sink { _ in
                exp.fulfill()
            }
            .store(in: &subscriptions)
        
        await sut.loadThumbnail()
        
        await fulfillment(of: [exp], timeout: 1.0)
        
        XCTAssertTrue(sut.thumbnailContainer.isEqual(previewContainer))
    }
    
    func testLoadThumbnail_placeholder_loadBothThumbnailAndPreview() async throws {
        let initialContainer = ImageContainer(image: Image(.photoCardPlaceholder), type: .placeholder)
        let remoteThumbnail = ImageContainer(image: Image("folder.fill"), type: .thumbnail)
        let previewContainer = ImageContainer(image: Image("folder"), type: .preview)
        
        let (stream, continuation) = AsyncThrowingStream.makeStream(of: (any ImageContaining).self)
        
        let sut = makeSUT(
            coverPhoto: NodeEntity(handle: 1),
            thumbnailLoader: MockThumbnailLoader(
                initialImage: initialContainer,
                loadImage: stream.eraseToAnyAsyncSequence())
        )
        
        XCTAssertTrue(sut.thumbnailContainer.isEqual(initialContainer))
        
        let exp = expectation(description: "thumbnailContainer is updated")
        exp.expectedFulfillmentCount = 2
        
        var expectedContainers = [remoteThumbnail,
                                  previewContainer]
        sut.$thumbnailContainer
            .dropFirst()
            .sink { container in
                XCTAssertTrue(container.isEqual(expectedContainers.removeFirst()))
                exp.fulfill()
            }
            .store(in: &subscriptions)
        
        let task = Task { await sut.loadThumbnail() }
        
        [remoteThumbnail,
         previewContainer].forEach {
            continuation.yield($0)
        }
        continuation.finish()
        
        await fulfillment(of: [exp], timeout: 1)

        XCTAssertTrue(sut.thumbnailContainer.isEqual(previewContainer))
        XCTAssertTrue(expectedContainers.isEmpty)
        task.cancel()
    }
    
    private func makeSUT(
        coverPhoto: NodeEntity? = nil,
        thumbnailLoader: some ThumbnailLoaderProtocol = MockThumbnailLoader(),
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> PhotoCardViewModel {
        let sut = PhotoCardViewModel(
            coverPhoto: coverPhoto, thumbnailLoader: thumbnailLoader)
        trackForMemoryLeaks(on: sut, file: file, line: line)
        return sut
    }
}
