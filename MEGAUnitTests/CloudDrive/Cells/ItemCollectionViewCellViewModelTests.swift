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
    
    func testConfigureCell_whenFeatureFlagOnAndNodeIsSensitive_shouldSetIsSensitiveTrue() async {
        let node = NodeEntity(handle: 1, isMarkedSensitive: true)
        let viewModel = sut(
            node: node,
            nodeUseCase: MockNodeDataUseCase(isInheritingSensitivityResult: .success(false)),
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
        
    func testConfigureCell_whenFeatureFlagOffAndNodeIsSensitive_shouldSetIsSensitiveFalse() async {
        let node = NodeEntity(handle: 1, isMarkedSensitive: true)

        let viewModel = sut(
            node: node,
            nodeUseCase: MockNodeDataUseCase(isInheritingSensitivityResult: .success(false)),
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
    
    func testConfigureCell_whenFeatureFlagOnAndNodeInheritedSensitivity_shouldSetIsSensitiveTrue() async {
        let node = NodeEntity(handle: 1, isMarkedSensitive: false)

        let viewModel = sut(
            node: node,
            nodeUseCase: MockNodeDataUseCase(isInheritingSensitivityResult: .success(true)),
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
        
    func testConfigureCell_whenFeatureFlagOffAndNodeInheritedSensitivity_shouldSetIsSensitiveFalse() async {
        let node = NodeEntity(handle: 1, isMarkedSensitive: true)

        let viewModel = sut(
            node: node,
            nodeUseCase: MockNodeDataUseCase(isInheritingSensitivityResult: .success(true)),
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

    func testConfigureCell_whenCalledMoreThanOnce_shouldReturnSameTask() {
        
        let node = NodeEntity(handle: 1, isMarkedSensitive: true)

        let viewModel = sut(
            node: node,
            nodeUseCase: MockNodeDataUseCase(isInheritingSensitivityResult: .success(true)),
            featureFlagHiddenNodes: false)
        
        let taskFirstCall = viewModel.configureCell()
        let taskSecondCall = viewModel.configureCell()
        
        XCTAssertEqual(taskFirstCall, taskSecondCall)
    } 
    
    func testThumbnailLoading_whenNodeHasValidThumbnail_shouldReturnCachedImage() async throws {
        let imageUrl = try makeImageURL()
        let node = NodeEntity(handle: 1, hasThumbnail: true, isMarkedSensitive: true)

        let viewModel = sut(
            node: node,
            nodeUseCase: MockNodeDataUseCase(isInheritingSensitivityResult: .success(true)),
            thumbnailUseCase: MockThumbnailUseCase(
                loadThumbnailResult: .success(.init(url: imageUrl, type: .thumbnail))))
        
        await viewModel.configureCell().value
        
        let result = viewModel.thumbnail?.pngData()
        let expected = UIImage(contentsOfFile: imageUrl.path())?.pngData()
        
        XCTAssertEqual(result, expected)
        try cleanUpFile(atPath: imageUrl.path())
    }
    
    func testThumbnailLoading_whenNodeHasThumbnailAndFailsToLoad_shouldReturnFileTypeImage() async throws {
        let node = NodeEntity(nodeType: .file, name: "test.txt", handle: 1, hasThumbnail: true, isMarkedSensitive: true)
        
        let nodeIconUseCase = MockNodeIconUsecase(stubbedIconData: try XCTUnwrap(UIImage(systemName: "heart.fill")?.pngData()))
        let viewModel = sut(
            node: node,
            nodeUseCase: MockNodeDataUseCase(isInheritingSensitivityResult: .success(true)),
            nodeIconUseCase: nodeIconUseCase)
        
        await viewModel.configureCell().value
        
        let result = viewModel.thumbnail?.pngData()
        let expected = nodeIconUseCase.iconData(for: node)
        
        XCTAssertEqual(result?.hashValue, expected.hashValue)
    }
}

extension ItemCollectionViewCellViewModelTests {
    func sut(node: NodeEntity,
             nodeUseCase: some NodeUseCaseProtocol = MockNodeDataUseCase(),
             nodeIconUseCase: some NodeIconUsecaseProtocol = MockNodeIconUsecase(stubbedIconData: Data()),
             thumbnailUseCase: some ThumbnailUseCaseProtocol = MockThumbnailUseCase(),
             featureFlagHiddenNodes: Bool = false) -> ItemCollectionViewCellViewModel {
        ItemCollectionViewCellViewModel(
            node: node,
            nodeUseCase: nodeUseCase, 
            thumbnailUseCase: thumbnailUseCase, 
            nodeIconUseCase: nodeIconUseCase,
            featureFlagProvider: MockFeatureFlagProvider(
                list: [.hiddenNodes: featureFlagHiddenNodes]))
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
