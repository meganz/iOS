import Combine
@testable import MEGA
import MEGADomain
import MEGADomainMock
import MEGAPresentation
import MEGAPresentationMock
import MEGASDKRepo
import MEGASDKRepoMock
import XCTest

final class ItemCollectionViewCellViewModelTests: XCTestCase {
    
    @MainActor
    func testConfigureCell_whenAccountInvalid_shouldSetIsSensitiveTrue() async {
        let node = NodeEntity(handle: 1, isMarkedSensitive: true)
        let viewModel = sut(
            node: node,
            sensitiveNodeUseCase: MockSensitiveNodeUseCase(
                isAccessible: false),
            featureFlagHiddenNodes: true)
        
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
    func testConfigureCell_whenFeatureFlagOnAndNodeIsSensitive_shouldSetIsSensitiveTrue() async {
        let node = NodeEntity(handle: 1, isMarkedSensitive: true)
        let viewModel = sut(
            node: node,
            sensitiveNodeUseCase: MockSensitiveNodeUseCase(
                isAccessible: true,
                isInheritingSensitivityResult: .success(false)),
            featureFlagHiddenNodes: true)
        
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
    func testConfigureCell_whenFeatureFlagOffAndNodeIsSensitive_shouldSetIsSensitiveFalse() async {
        let node = NodeEntity(handle: 1, isMarkedSensitive: true)

        let viewModel = sut(
            node: node,
            sensitiveNodeUseCase: MockSensitiveNodeUseCase(
                isAccessible: true,
                isInheritingSensitivityResult: .success(false)),
            featureFlagHiddenNodes: false)
        
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
        let node = NodeEntity(handle: 1, isMarkedSensitive: false)

        let viewModel = sut(
            node: node,
            sensitiveNodeUseCase: MockSensitiveNodeUseCase(
                isAccessible: true,
                isInheritingSensitivityResult: .success(true)),
            featureFlagHiddenNodes: true)
        
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
        let node = NodeEntity(handle: 1, isMarkedSensitive: true)

        let viewModel = sut(
            node: node,
            sensitiveNodeUseCase: MockSensitiveNodeUseCase(
                isAccessible: true,
                isInheritingSensitivityResult: .success(true)),
            featureFlagHiddenNodes: false)
        
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
    func testConfigureCell_whenCalledMoreThanOnce_shouldReturnSameTask() {
        
        let node = NodeEntity(handle: 1, isMarkedSensitive: true)

        let viewModel = sut(
            node: node,
            sensitiveNodeUseCase: MockSensitiveNodeUseCase(
                isAccessible: true,
                isInheritingSensitivityResult: .success(true)),
            featureFlagHiddenNodes: false)
        
        let taskFirstCall = viewModel.configureCell()
        let taskSecondCall = viewModel.configureCell()
        
        XCTAssertEqual(taskFirstCall, taskSecondCall)
    } 
    
    @MainActor
    func testThumbnailLoading_whenNodeHasValidThumbnail_shouldReturnCachedImage() async throws {
        let imageUrl = try makeImageURL()
        let node = NodeEntity(handle: 1, hasThumbnail: true, isMarkedSensitive: true)

        let viewModel = sut(
            node: node,
            sensitiveNodeUseCase: MockSensitiveNodeUseCase(
                isAccessible: true,
                isInheritingSensitivityResult: .success(true)),
            thumbnailUseCase: MockThumbnailUseCase(
                loadThumbnailResult: .success(.init(url: imageUrl, type: .thumbnail))))
        
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
            node: node,
            sensitiveNodeUseCase: MockSensitiveNodeUseCase(isInheritingSensitivityResult: .success(true)),
            nodeIconUseCase: nodeIconUseCase)
        
        await viewModel.configureCell().value
        
        let result = viewModel.thumbnail?.pngData()
        XCTAssertEqual(result?.hashValue, imageData.hashValue)
    }
}

extension ItemCollectionViewCellViewModelTests {
    @MainActor
    func sut(node: NodeEntity,
             sensitiveNodeUseCase: some SensitiveNodeUseCaseProtocol = MockSensitiveNodeUseCase(),
             nodeIconUseCase: some NodeIconUsecaseProtocol = MockNodeIconUsecase(stubbedIconData: Data()),
             thumbnailUseCase: some ThumbnailUseCaseProtocol = MockThumbnailUseCase(),
             featureFlagHiddenNodes: Bool = false) -> ItemCollectionViewCellViewModel {
        ItemCollectionViewCellViewModel(
            node: node,
            sensitiveNodeUseCase: sensitiveNodeUseCase,
            thumbnailUseCase: thumbnailUseCase,
            nodeIconUseCase: nodeIconUseCase,
            featureFlagProvider: MockFeatureFlagProvider(
                list: [.hiddenNodes: featureFlagHiddenNodes]))
    }
}
