import MEGADomain
import MEGADomainMock
import MEGATest
import SwiftUI
@testable import Video
import XCTest

@MainActor
final class VideoCellViewModelTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        cleanTestArtifacts()
        writeCacheImage()
    }
    
    override func tearDown() {
        super.tearDown()
        cleanTestArtifacts()
    }
    
    func testAttemptLoadThumbnail_whenNoCachedThumbnailsThumbnailAndErrors_deliversPlaceholderImage() async {
        let node = nodeEntity(name: "name", handle: 1, hasThumbnail: true, isFavorite: true, label: .blue, size: 12, duration: 12)
        let mockThumbnailUseCase = MockThumbnailUseCase(
            cachedThumbnails: [],
            loadThumbnailResult: .failure(GenericErrorEntity()),
            loadPreviewResult: .failure(GenericErrorEntity()),
            loadThumbnailAndPreviewResult: .failure(GenericErrorEntity())
        )
        let sut = await makeSUT(thumbnailUseCase: mockThumbnailUseCase, nodeEntity: node)
        
        await sut.attemptLoadThumbnail()
        
        let previewEntity = sut.previewEntity
        XCTAssertEqual(previewEntity.imageContainer.image, Image(systemName: "square.fill"))
    }
    
    func testAttemptLoadThumbnail_whenHasCachedThumbnailThumbnailAndErrors_deliversImage() async {
        let node = nodeEntity(name: "name", handle: 1, hasThumbnail: true, isFavorite: true, label: .blue, size: 12, duration: 12)
        let (_, _, imageURL) = imagePathData()
        let thumbnailEntity = ThumbnailEntity(url: imageURL!, type: .thumbnail)
        let mockThumbnailUseCase = MockThumbnailUseCase(
            cachedThumbnails: [thumbnailEntity],
            loadThumbnailResult: .failure(GenericErrorEntity()),
            loadPreviewResult: .failure(GenericErrorEntity()),
            loadThumbnailAndPreviewResult: .failure(GenericErrorEntity())
        )
        let sut = await makeSUT(thumbnailUseCase: mockThumbnailUseCase, nodeEntity: node)
        
        await sut.attemptLoadThumbnail()
        
        let previewEntity = sut.previewEntity
        XCTAssertNotNil(previewEntity.imageContainer)
    }
    
    func testAttemptLoadThumbnail_whenSucessLoadThumbnail_useLoadedImage() async {
        let node = nodeEntity(name: "name", handle: 1, hasThumbnail: true, isFavorite: true, label: .blue, size: 12, duration: 12)
        let (_, _, imageURL) = imagePathData()
        let thumbnailEntity = ThumbnailEntity(url: imageURL!, type: .thumbnail)
        let mockThumbnailUseCase = MockThumbnailUseCase(
            cachedThumbnails: [thumbnailEntity],
            loadThumbnailResult: .success(thumbnailEntity)
        )
        let sut = await makeSUT(thumbnailUseCase: mockThumbnailUseCase, nodeEntity: node)
        
        await sut.attemptLoadThumbnail()
        
        let previewEntity = sut.previewEntity
        XCTAssertNotNil(previewEntity.imageContainer)
    }
    
    func testOnTappedMoreOptions_whenCalled_triggerTap() async {
        let node = nodeEntity(name: "name", handle: 1, hasThumbnail: true, isFavorite: true, label: .blue, size: 12, duration: 12)
        let mockThumbnailUseCase = MockThumbnailUseCase(
            cachedThumbnails: [],
            loadThumbnailResult: .failure(GenericErrorEntity()),
            loadPreviewResult: .failure(GenericErrorEntity()),
            loadThumbnailAndPreviewResult: .failure(GenericErrorEntity())
        )
        var tappedNodes = [NodeEntity]()
        let sut = await makeSUT(
            thumbnailUseCase: mockThumbnailUseCase,
            nodeEntity: node,
            onTapMoreOptions: { tappedNodes.append($0) }
        )
        
        sut.onTappedMoreOptions()
        
        XCTAssertEqual(tappedNodes, [ node ])
    }
    
    // MARK: - Helpers
    
    private func makeSUT(
        thumbnailUseCase: ThumbnailUseCaseProtocol,
        nodeEntity: NodeEntity,
        onTapMoreOptions: @escaping (_ node: NodeEntity) -> Void = { _ in },
        file: StaticString = #filePath,
        line: UInt = #line
    ) async -> VideoCellViewModel {
        let sut = VideoCellViewModel(thumbnailUseCase: thumbnailUseCase, nodeEntity: nodeEntity, onTapMoreOptions: onTapMoreOptions)
        trackForMemoryLeaks(on: sut, file: file, line: line)
        return sut
    }
    
    private func nodeEntity(name: String, handle: HandleEntity, hasThumbnail: Bool, isPublic: Bool = false, isShare: Bool = false, isFavorite: Bool, label: NodeLabelTypeEntity, size: UInt64, duration: Int) -> NodeEntity {
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
}
