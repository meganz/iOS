@testable import MEGA
import MEGADomain
import MEGADomainMock
import MEGAPresentation
import MEGAPresentationMock
import MEGATest
import XCTest

final class HomeSearchResultFileViewModelTests: XCTestCase {
    
    func testInit_called_shouldSetPropertiesCorrectly() {
        let handle = HandleEntity(1)
        let name = "file.pdf"
        let ownerFolder = "file.pdf"
        let nodeType = NodeTypeEntity.file
        let hasThumbnail = true
        let node = NodeEntity(nodeType: nodeType, name: name, handle: handle, hasThumbnail: hasThumbnail)
        
        let sut = makeSUT(node: node, ownerFolder: ownerFolder)
        
        XCTAssertEqual(sut.handle, handle)
        XCTAssertEqual(sut.name, name)
        XCTAssertEqual(sut.ownerFolder, ownerFolder)
        XCTAssertEqual(sut.hasThumbnail, hasThumbnail)
    }
    
    @MainActor
    func testConfigureCell_nodeNoThumbnail_shouldLoadIcon() async throws {
        let imageData = try XCTUnwrap(UIImage(systemName: "heart.fill")?.pngData())
        let nodeIconUseCase = MockNodeIconUsecase(stubbedIconData: imageData)
        let node = NodeEntity(hasThumbnail: false)
        
        let sut = makeSUT(node: node,
                          nodeIconUseCase: nodeIconUseCase)
        
        await sut.configureCell()
        
        let thumbnailData = sut.thumbnail?.pngData()
        
        XCTAssertEqual(thumbnailData?.hashValue, imageData.hashValue)
    }
    
    @MainActor
    func testConfigureCell_hasCachedThumbnail_shouldUpadateThumbnailWithCachedThumbnail() async throws {
        let imageUrl = try makeImageURL()
        let node = NodeEntity(handle: 1, hasThumbnail: true)
        let thumbnailUseCase = MockThumbnailUseCase(
            cachedThumbnails: [.init(url: imageUrl, type: .thumbnail)])
        
        let sut = makeSUT(node: node,
                          thumbnailUseCase: thumbnailUseCase)
        
        await sut.configureCell()
        
        let thumbnailData = sut.thumbnail?.pngData()
        let expected = UIImage(contentsOfFile: imageUrl.path())?.pngData()
        
        XCTAssertEqual(thumbnailData, expected)
    }
    
    @MainActor
    func testConfigureCell_hasNoCachedThumbnail_shouldLoadThumbnail() async throws {
        let imageUrl = try makeImageURL()
        let node = NodeEntity(handle: 1, hasThumbnail: true)
        let thumbnailUseCase = MockThumbnailUseCase(
            loadThumbnailResult: .success(.init(url: imageUrl, type: .thumbnail)))
        
        let sut = makeSUT(node: node,
                          thumbnailUseCase: thumbnailUseCase)
        
        await sut.configureCell()
        
        let thumbnailData = sut.thumbnail?.pngData()
        let expected = UIImage(contentsOfFile: imageUrl.path())?.pngData()
        
        XCTAssertEqual(thumbnailData, expected)
    }
    
    @MainActor
    func testConfigureCell_loadThumbnailFails_shouldUseThumbnailIcon() async throws {
        let imageData = try XCTUnwrap(UIImage(systemName: "heart.fill")?.pngData())
        let nodeIconUseCase = MockNodeIconUsecase(stubbedIconData: imageData)
        let node = NodeEntity(handle: 1, hasThumbnail: true)
        let thumbnailUseCase = MockThumbnailUseCase(
            loadThumbnailResult: .failure(GenericErrorEntity()))
        
        let sut = makeSUT(node: node,
                          thumbnailUseCase: thumbnailUseCase,
                          nodeIconUseCase: nodeIconUseCase)
        
        await sut.configureCell()
        
        let thumbnailData = sut.thumbnail?.pngData()
        
        XCTAssertEqual(thumbnailData?.hashValue, imageData.hashValue)
    }
    
    @MainActor
    func testSensitive_initWithSensitiveNode_shouldSetInitialSensitiveValue() {
        let node = NodeEntity(handle: 1, isMarkedSensitive: true)
        
        let sut = makeSUT(node: node,
                          featureFlagProvider: MockFeatureFlagProvider(list: [.hiddenNodes: true]))
        
        XCTAssertEqual(sut.isSensitive, node.isMarkedSensitive)
    }
    
    @MainActor
    func testSensitive_nodeAlreadyMarkedSensitive_shouldNotNeedToSetAgainWhenCheckingInheritted() async {
        let node = NodeEntity(handle: 1, isMarkedSensitive: true)
        
        let sut = makeSUT(node: node,
                          featureFlagProvider: MockFeatureFlagProvider(list: [.hiddenNodes: true]))
        
        let exp = expectation(description: "Should not update again")
        exp.isInverted = true
        
        let subscription = sut.$isSensitive
            .dropFirst()
            .sink { _ in
                exp.fulfill()
            }
        
        await sut.configureCell()
        
        await fulfillment(of: [exp], timeout: 0.5)
        subscription.cancel()
    }
    
    @MainActor
    func testConfigureCell_nonSensitiveNode_shouldLoadAndSetSensitivity() async {
        let node = NodeEntity(handle: 1, isMarkedSensitive: false)
        let inheritSensitivity = true
        let nodeUseCase = MockNodeDataUseCase(isInheritingSensitivityResult: .success(inheritSensitivity))
        let sut = makeSUT(node: node,
                          nodeUseCase: nodeUseCase,
                          featureFlagProvider: MockFeatureFlagProvider(list: [.hiddenNodes: true]))
        
        await sut.configureCell()
        
        XCTAssertEqual(sut.isSensitive, inheritSensitivity)
    }
    
    func testConfigureCell_inheritSensitivityFailed_shouldNotUpdateSensitivity() async {
        let node = NodeEntity(handle: 1, isMarkedSensitive: false)
       
        let sut = makeSUT(node: node,
                          featureFlagProvider: MockFeatureFlagProvider(list: [.hiddenNodes: true]))
        let exp = expectation(description: "Should not update")
        exp.isInverted = true
        
        let subscription = sut.$isSensitive
            .dropFirst()
            .sink { _ in
                exp.fulfill()
            }
        
        await sut.configureCell()
        
        await fulfillment(of: [exp], timeout: 0.5)
        subscription.cancel()
    }
    
    @MainActor
    func testConfigureCell_loadInheritSensitivity_ensureThatSensitivityIsUpdatedBeforeThumbnail() async {
        enum Order {
            case sensitive
            case thumbnail
        }
        let node = NodeEntity(handle: 1, isMarkedSensitive: false)
        let nodeUseCase = MockNodeDataUseCase(isInheritingSensitivityResult: .success(true))
        let sut = makeSUT(node: node,
                          nodeUseCase: nodeUseCase,
                          featureFlagProvider: MockFeatureFlagProvider(list: [.hiddenNodes: true]))
        
        let exp = expectation(description: "Ensure that sensitive and thumbnail receives result")
        exp.expectedFulfillmentCount = 2
        
        var orderUpdated = [Order]()
        
        var subscriptions = [
            sut.$isSensitive
                .dropFirst()
                .sink { _ in
                    orderUpdated.append(.sensitive)
                    exp.fulfill()
                },
            sut.$thumbnail
                .dropFirst()
                .sink { _ in
                    orderUpdated.append(.thumbnail)
                    exp.fulfill()
                }
        ]
        await sut.configureCell()
        await fulfillment(of: [exp], timeout: 1.0)
        
        XCTAssertEqual(orderUpdated, [.sensitive, .thumbnail])
        subscriptions.removeAll()
    }
    
    private func makeSUT(
        node: NodeEntity = NodeEntity(handle: 1),
        ownerFolder: String = "",
        thumbnailUseCase: any ThumbnailUseCaseProtocol = MockThumbnailUseCase(),
        nodeIconUseCase: any NodeIconUsecaseProtocol = MockNodeIconUsecase(stubbedIconData: Data()),
        nodeUseCase: any NodeUseCaseProtocol = MockNodeDataUseCase(),
        featureFlagProvider: any FeatureFlagProviderProtocol = MockFeatureFlagProvider(list: [:]),
        moreAction: @escaping (HandleEntity, UIButton) -> Void = {_, _ in },
        file: StaticString = #file,
        line: UInt = #line
    ) -> HomeSearchResultFileViewModel {
        let sut = HomeSearchResultFileViewModel(
            node: node,
            ownerFolder: ownerFolder,
            thumbnailUseCase: thumbnailUseCase,
            nodeIconUseCase: nodeIconUseCase,
            nodeUseCase: nodeUseCase,
            featureFlagProvider: featureFlagProvider,
            moreAction: moreAction)
        trackForMemoryLeaks(on: sut, file: file, line: line)
        return sut
    }
}
