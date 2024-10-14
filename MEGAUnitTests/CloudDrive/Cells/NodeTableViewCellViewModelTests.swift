import Combine
@testable import MEGA
import MEGADomain
import MEGADomainMock
import MEGAPresentation
import MEGAPresentationMock
import XCTest

final class NodeTableViewCellViewModelTests: XCTestCase {
    
    @MainActor
    func testHasThumbnail_whenNodeCountIsOne_shouldReturnNodeHasThumbnailValue() {
        for hasThumbnail in [true, false] {
            let nodes = [
                NodeEntity(handle: 1, hasThumbnail: hasThumbnail)
            ]
            
            let viewModel = sut(nodes: nodes)
            
            XCTAssertEqual(viewModel.hasThumbnail, hasThumbnail)
        }
    }
    
    @MainActor
    func testHasThumbnail_whenNodeCountIsGreaterThanOne_shouldReturnFalse() {
        let nodes = [
            NodeEntity(handle: 1, hasThumbnail: true),
            NodeEntity(handle: 2, hasThumbnail: true)
        ]
        let viewModel = sut(nodes: nodes)
        
        XCTAssertFalse(viewModel.hasThumbnail)
    }
    
    @MainActor
    func testConfigureCell_whenFeatureFlagOnAndNodeIsSensitive_shouldSetIsSensitiveTrue() async {
        let nodes = [
            NodeEntity(handle: 1, isMarkedSensitive: true)
        ]
        let viewModel = sut(
            nodes: nodes,
            shouldApplySensitiveBehaviour: true,
            sensitiveNodeUseCase: MockSensitiveNodeUseCase(isInheritingSensitivityResult: .success(false)),
            accountUseCase: MockAccountUseCase(hasValidProOrUnexpiredBusinessAccount: true),
            featureFlags: [.hiddenNodes: true]
            )
        
        await viewModel.configureCell().value

        let expectation = expectation(description: "viewModel.isSensitive should return value")
        let subscription = viewModel.$isSensitive
            .first { $0 }
            .sink { isSensitive in
                XCTAssertTrue(isSensitive)
                expectation.fulfill()
            }
        
        await fulfillment(of: [expectation], timeout: 1)
        
        subscription.cancel()
    }
    
    @MainActor
    func testConfigureCell_invalidAccount_shouldSetIsSensitiveFalse() async {
        let nodes = [
            NodeEntity(handle: 1, isMarkedSensitive: true)
        ]
        let viewModel = sut(
            nodes: nodes,
            shouldApplySensitiveBehaviour: true,
            accountUseCase: MockAccountUseCase(hasValidProOrUnexpiredBusinessAccount: false),
            featureFlags: [.hiddenNodes: true]
            )
        
        await viewModel.configureCell().value

        let expectation = expectation(description: "viewModel.isSensitive should return value")
        let subscription = viewModel.$isSensitive
            .first { !$0 }
            .sink { isSensitive in
                XCTAssertFalse(isSensitive)
                expectation.fulfill()
            }
        
        await fulfillment(of: [expectation], timeout: 1)
        
        subscription.cancel()
    }
        
    @MainActor
    func testConfigureCell_whenFeatureFlagOffAndNodeIsSensitive_shouldSetIsSensitiveFalse() async {
        let nodes = [
            NodeEntity(handle: 1, isMarkedSensitive: true)
        ]
        let viewModel = sut(
            nodes: nodes,
            shouldApplySensitiveBehaviour: true,
            sensitiveNodeUseCase: MockSensitiveNodeUseCase(isInheritingSensitivityResult: .success(false)),
            accountUseCase: MockAccountUseCase(hasValidProOrUnexpiredBusinessAccount: true),
            featureFlags: [.hiddenNodes: false]
        )
        
        await viewModel.configureCell().value

        let expectation = expectation(description: "viewModel.isSensitive should return value")
        let subscription = viewModel.$isSensitive
            .debounce(for: 0.5, scheduler: DispatchQueue.main)
            .first { !$0 }
            .sink { isSensitive in
                XCTAssertFalse(isSensitive)
                expectation.fulfill()
            }
        
        await fulfillment(of: [expectation], timeout: 1)
        
        subscription.cancel()
    }
    
    @MainActor
    func testConfigureCell_whenFeatureFlagOnAndNodeInheritedSensitivity_shouldSetIsSensitiveTrue() async {
        let nodes = [
            NodeEntity(handle: 1, isMarkedSensitive: false)
        ]
        let viewModel = sut(
            nodes: nodes,
            shouldApplySensitiveBehaviour: true,
            sensitiveNodeUseCase: MockSensitiveNodeUseCase(isInheritingSensitivityResult: .success(true)),
            accountUseCase: MockAccountUseCase(hasValidProOrUnexpiredBusinessAccount: true),
            featureFlags: [.hiddenNodes: true]
            )
        
        await viewModel.configureCell().value

        let expectation = expectation(description: "viewModel.isSensitive should return value")
        let subscription = viewModel.$isSensitive
            .first { $0 }
            .sink { isSensitive in
                XCTAssertTrue(isSensitive)
                expectation.fulfill()
            }
        
        await fulfillment(of: [expectation], timeout: 1)
        
        subscription.cancel()
    }
        
    @MainActor
    func testConfigureCell_whenFeatureFlagOffAndNodeInheritedSensitivity_shouldSetIsSensitiveFalse() async {
        let nodes = [
            NodeEntity(handle: 1, isMarkedSensitive: false)
        ]
        let viewModel = sut(
            nodes: nodes,
            shouldApplySensitiveBehaviour: true,
            sensitiveNodeUseCase: MockSensitiveNodeUseCase(isInheritingSensitivityResult: .success(true)),
            accountUseCase: MockAccountUseCase(hasValidProOrUnexpiredBusinessAccount: true),
            featureFlags: [.hiddenNodes: false]
        )

        await viewModel.configureCell().value
        
        let expectation = expectation(description: "viewModel.isSensitive should return value")
        let subscription = viewModel.$isSensitive
            .debounce(for: 0.5, scheduler: DispatchQueue.main)
            .first { !$0 }
            .sink { isSensitive in
                XCTAssertFalse(isSensitive)
                expectation.fulfill()
            }
        
        await fulfillment(of: [expectation], timeout: 1)
        
        subscription.cancel()
    }
    
    @MainActor
    func testConfigureCell_whenFeatureFlagOnAndNodesCountGreaterOne_shouldSetIsSensitiveFalse() async {
        let nodes = [
            NodeEntity(handle: 1, isMarkedSensitive: true),
            NodeEntity(handle: 2, isMarkedSensitive: true)
        ]
        let viewModel = sut(
            nodes: nodes,
            shouldApplySensitiveBehaviour: true,
            sensitiveNodeUseCase: MockSensitiveNodeUseCase(isInheritingSensitivityResult: .success(true)),
            accountUseCase: MockAccountUseCase(hasValidProOrUnexpiredBusinessAccount: true),
            featureFlags: [.hiddenNodes: true]
            )
        
        await viewModel.configureCell().value

        let expectation = expectation(description: "viewModel.isSensitive should return value")
        let subscription = viewModel.$isSensitive
            .debounce(for: 0.5, scheduler: DispatchQueue.main)
            .first { !$0 }
            .sink { isSensitive in
                XCTAssertFalse(isSensitive)
                expectation.fulfill()
            }
        
        await fulfillment(of: [expectation], timeout: 1)
        
        subscription.cancel()
    }
        
    @MainActor
    func testConfigureCell_withAllVariationsOfShouldApplySensitiveBehaviour_shouldSetExpectedResult() async {
        for await shouldApplySensitiveBehaviour in [true, false].async {
            
            let viewModel = sut(
                nodes: [.init(handle: 1, isMarkedSensitive: true)],
                shouldApplySensitiveBehaviour: shouldApplySensitiveBehaviour,
                sensitiveNodeUseCase: MockSensitiveNodeUseCase(isInheritingSensitivityResult: .success(true)),
                accountUseCase: MockAccountUseCase(hasValidProOrUnexpiredBusinessAccount: true),
                featureFlags: [.hiddenNodes: true]
            )
            
            await viewModel.configureCell().value

            let expectation = expectation(description: "viewModel.isSensitive should return value")
            let subscription = viewModel.$isSensitive
                .debounce(for: 0.5, scheduler: DispatchQueue.main)
                .sink { isSensitive in
                    XCTAssertEqual(isSensitive, shouldApplySensitiveBehaviour, "\(shouldApplySensitiveBehaviour ? "should" : "shouldn't") support isSensitive")
                    expectation.fulfill()
                }
            
            await fulfillment(of: [expectation], timeout: 1)
            
            subscription.cancel()
        }
    }
    
    @MainActor
    func testThumbnailLoading_whenNodeHasValidThumbnail_shouldReturnCachedImage() async throws {
        let imageUrl = try makeImageURL()
        let node = NodeEntity(handle: 1, hasThumbnail: true, isMarkedSensitive: true)

        let viewModel = sut(
            nodes: [node],
            sensitiveNodeUseCase: MockSensitiveNodeUseCase(isInheritingSensitivityResult: .success(true)),
            thumbnailUseCase: MockThumbnailUseCase(
                loadThumbnailResult: .success(.init(url: imageUrl, type: .thumbnail))),
            accountUseCase: MockAccountUseCase(hasValidProOrUnexpiredBusinessAccount: true))
        
        await viewModel.configureCell().value
        
        let result = viewModel.thumbnail?.pngData()
        let expected = UIImage(contentsOfFile: imageUrl.path())?.pngData()
        
        XCTAssertEqual(result, expected)
    }
    
    @MainActor
    func testThumbnailLoading_whenNodeHasThumbnailAndFailsToLoad_shouldReturnFileTypeImage() async throws {
        let imageData = try XCTUnwrap(UIImage(systemName: "heart.fill")?.pngData())
        let node = NodeEntity(nodeType: .file, name: "test.txt", handle: 1, hasThumbnail: true, isMarkedSensitive: true)
        
        let nodeIconUseCase = MockNodeIconUsecase(stubbedIconData: imageData)
        let viewModel = sut(
            nodes: [node],
            sensitiveNodeUseCase: MockSensitiveNodeUseCase(isInheritingSensitivityResult: .success(true)),
            nodeIconUseCase: nodeIconUseCase,
            accountUseCase: MockAccountUseCase(hasValidProOrUnexpiredBusinessAccount: true))
        
        await viewModel.configureCell().value
        
        let result = viewModel.thumbnail?.pngData()
        
        XCTAssertEqual(result?.hashValue, imageData.hashValue)
    }
    
    @MainActor
    func testThumbnailLoading_whenNodeHasThumbnailAndIsRecentsFlavour_shouldReturnFileTypeImageOnly() async throws {
        let imageData = try XCTUnwrap(UIImage(systemName: "heart.fill")?.pngData())
        let node = NodeEntity(nodeType: .file, name: "test.txt", handle: 1, hasThumbnail: true)
        
        let nodeIconUseCase = MockNodeIconUsecase(stubbedIconData: imageData)
        let viewModel = sut(
            nodes: [node],
            shouldApplySensitiveBehaviour: true,
            sensitiveNodeUseCase: MockSensitiveNodeUseCase(isInheritingSensitivityResult: .success(true)),
            nodeIconUseCase: nodeIconUseCase,
            accountUseCase: MockAccountUseCase(hasValidProOrUnexpiredBusinessAccount: true))
        
        await viewModel.configureCell().value
        
        let result = viewModel.thumbnail?.pngData()
        
        XCTAssertEqual(result?.hashValue, imageData.hashValue)
    }
}

extension NodeTableViewCellViewModelTests {
    @MainActor
    func sut(nodes: [NodeEntity] = [],
             shouldApplySensitiveBehaviour: Bool = true,
             sensitiveNodeUseCase: some SensitiveNodeUseCaseProtocol = MockSensitiveNodeUseCase(),
             nodeIconUseCase: some NodeIconUsecaseProtocol = MockNodeIconUsecase(stubbedIconData: Data()),
             thumbnailUseCase: some ThumbnailUseCaseProtocol = MockThumbnailUseCase(),
             accountUseCase: some AccountUseCaseProtocol = MockAccountUseCase(),
             featureFlags: [FeatureFlagKey: Bool] = [.hiddenNodes: false]) -> NodeTableViewCellViewModel {
        NodeTableViewCellViewModel(
            nodes: nodes,
            shouldApplySensitiveBehaviour: shouldApplySensitiveBehaviour,
            sensitiveNodeUseCase: sensitiveNodeUseCase,
            thumbnailUseCase: thumbnailUseCase,
            nodeIconUseCase: nodeIconUseCase,
            accountUseCase: accountUseCase,
            featureFlagProvider: MockFeatureFlagProvider(list: featureFlags))
    }
}
