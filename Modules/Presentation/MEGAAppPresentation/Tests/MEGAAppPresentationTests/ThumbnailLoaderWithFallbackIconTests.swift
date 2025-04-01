@testable import MEGAAppPresentation
import MEGAAppPresentationMock
import MEGADomain
import MEGADomainMock
import MEGATest
import SwiftUI
import XCTest

final class ThumbnailLoaderWithFallbackIconTests: XCTestCase {
    
    // MARK: - init
    
    func testInit_whenCalled_doesNotRequestUseCase() {
        let (_, thumbnailLoader, nodeIconUseCase) = makeSUT()
        
        XCTAssertTrue(thumbnailLoader.invocations.isEmpty)
        XCTAssertTrue(nodeIconUseCase.invocations.isEmpty)
    }
    
    // MARK: - initialImage
    
    func testInitialImageWithPlaceholder_whenHasThumbnail_forwardsCall() {
        let (sut, thumbnailLoader, nodeIconUseCase) = makeSUT()
        
        _ = sut.initialImage(for: anyNode(hasThumbnail: true, name: "video.mp4"), type: anyThumbnailType, placeholder: { [anyPlaceholder] in anyPlaceholder })
        
        XCTAssertEqual(thumbnailLoader.invocations, [ .initialImageWithPlaceholder ])
        XCTAssertTrue(nodeIconUseCase.invocations.isEmpty)
    }
    
    func testInitialImageWithPlaceholder_whenHasNoThumbnail_forwardsToNodeIconUseCase() {
        let (sut, thumbnailLoader, nodeIconUseCase) = makeSUT()
        
        _ = sut.initialImage(for: anyNode(hasThumbnail: false, name: "video.mp4"), type: anyThumbnailType, placeholder: { [anyPlaceholder] in anyPlaceholder })
        
        XCTAssertEqual(nodeIconUseCase.invocations, [ .iconData ])
        XCTAssertTrue(thumbnailLoader.invocations.isEmpty)
    }
    
    // MARK: - loadImage
    
    func testLoadImage_whenNodeHasThumbnail_forwardsCall() async {
        let (sut, thumbnailLoader, nodeIconUseCase) = makeSUT()
        
        _ = try? await sut.loadImage(for: anyNode(hasThumbnail: true, name: "video.mp4"), type: anyThumbnailType)
        
        XCTAssertEqual(thumbnailLoader.invocations, [ .loadImage ])
        XCTAssertTrue(nodeIconUseCase.invocations.isEmpty)
    }
    
    func testLoadImage_whenNodeHasNoThumbnail_loadsDefaultIconThumbnail() async {
        let (sut, thumbnailLoader, nodeIconUseCase) = makeSUT()
        
        _ = try? await sut.loadImage(for: anyNode(hasThumbnail: false, name: "video.mp4"), type: anyThumbnailType)
        
        XCTAssertTrue(thumbnailLoader.invocations.isEmpty)
        XCTAssertEqual(nodeIconUseCase.invocations, [ .iconData ])
    }
    
    // MAKR: - Helpers
    
    private func anyNode(hasThumbnail: Bool, name: String) -> NodeEntity {
        NodeEntity(name: name, handle: 1, hasThumbnail: hasThumbnail)
    }
    private let anyThumbnailType = ThumbnailTypeEntity.thumbnail
    private let anyPlaceholder = Image(systemName: "square.fill")
    
    private func makeSUT() -> (
        sut: ThumbnailLoaderWithFallbackIcon,
        thumbnailLoader: MockThumbnailLoader,
        nodeIconUseCase: MockNodeIconUsecase
    ) {
        let thumbnailLoader = MockThumbnailLoader()
        let nodeIconUseCase = MockNodeIconUsecase(stubbedIconData: anyData())
        let sut = ThumbnailLoaderWithFallbackIcon(
            decoratee: thumbnailLoader,
            nodeIconUseCase: nodeIconUseCase
        )
        return (sut, thumbnailLoader, nodeIconUseCase)
    }
    
    private func anyData() -> Data {
        "any-data".data(using: .utf8)!
    }
    
}
