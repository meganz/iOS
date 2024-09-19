import Combine
@testable import MEGA
import MEGADomain
import MEGADomainMock
import MEGAFoundation
import MEGAPresentation
import MEGAPresentationMock
import MEGASwift
import MEGASwiftUI
import MEGATest
import SwiftUI
import XCTest

final class PhotoCardViewModelTests: XCTestCase {
    private var subscriptions = Set<AnyCancellable>()
    
    @MainActor
    func testInit_defaultValue() throws {
        let sut = makeSUT()
        
        XCTAssertTrue(sut.thumbnailContainer.isEqual(ImageContainer(image: Image(.photoCardPlaceholder), type: .placeholder)))
    }
    
    @MainActor
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
    
    @MainActor
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
    
    @MainActor
    func testMonitorInheritedSensitivityChanges_photoNotSensitive_shouldUpdateImageContainerWithInitialResultFirst() async throws {
        let photo = NodeEntity(handle: 65, isMarkedSensitive: false)
        
        let imageContainer = ImageContainer(image: Image("folder"), type: .thumbnail)
        let isInheritedSensitivity = false
        let isInheritedSensitivityUpdate = true
        let monitorInheritedSensitivityForNode = SingleItemAsyncSequence(item: isInheritedSensitivityUpdate)
            .eraseToAnyAsyncThrowingSequence()
        let sensitiveNodeUseCase = MockSensitiveNodeUseCase(
            isInheritingSensitivityResult: .success(isInheritedSensitivity),
            monitorInheritedSensitivityForNode: monitorInheritedSensitivityForNode
        )
        let nodeUseCase = MockNodeDataUseCase(
            isInheritingSensitivityResult: .success(isInheritedSensitivity),
            monitorInheritedSensitivityForNode: monitorInheritedSensitivityForNode
        )
        let sut = makeSUT(
            coverPhoto: photo,
            thumbnailLoader: MockThumbnailLoader(initialImage: imageContainer),
            nodeUseCase: nodeUseCase,
            sensitiveNodeUseCase: sensitiveNodeUseCase,
            featureFlagProvider: MockFeatureFlagProvider(list: [.hiddenNodes: true])
        )
        
        var expectedImageContainer = [
            imageContainer.toSensitiveImageContaining(isSensitive: isInheritedSensitivity),
            imageContainer.toSensitiveImageContaining(isSensitive: isInheritedSensitivityUpdate)
        ]
        
        let exp = expectation(description: "Should update photo with initial then from monitor")
        exp.expectedFulfillmentCount = expectedImageContainer.count
        
        let subscription = thumbnailContainerUpdates(on: sut) {
            XCTAssertTrue($0.isEqual(expectedImageContainer.removeFirst()))
            exp.fulfill()
        }
        
        let task = Task { await sut.monitorInheritedSensitivityChanges() }
        
        await fulfillment(of: [exp], timeout: 1.0)
        task.cancel()
        subscription.cancel()
    }
    
    @MainActor
    func testMonitorInheritedSensitivityChanges_inheritedSensitivityChange_shouldNotUpdateIfImageContainerTheSame() async throws {
        let photo = NodeEntity(handle: 65, isMarkedSensitive: false)
        let imageContainer = SensitiveImageContainer(image: Image("folder"), type: .thumbnail, isSensitive: photo.isMarkedSensitive)
        
        let monitorInheritedSensitivityForNode = SingleItemAsyncSequence(item: photo.isMarkedSensitive)
            .eraseToAnyAsyncThrowingSequence()
        let nodeUseCase = MockNodeDataUseCase(
            node: photo,
            monitorInheritedSensitivityForNode: monitorInheritedSensitivityForNode)
        
        let sut = makeSUT(coverPhoto: photo,
                          thumbnailLoader: MockThumbnailLoader(initialImage: imageContainer),
                          nodeUseCase: nodeUseCase,
                          featureFlagProvider: MockFeatureFlagProvider(list: [.hiddenNodes: true]))
        
        let exp = expectation(description: "Should not update image container")
        exp.isInverted = true
        
        let subscription = thumbnailContainerUpdates(on: sut) { _ in
            exp.fulfill()
        }
        
        let task = Task { await sut.monitorInheritedSensitivityChanges() }
        
        await fulfillment(of: [exp], timeout: 1.0)
        task.cancel()
        subscription.cancel()
    }
    
    @MainActor
    func testMonitorInheritedSensitivityChanges_thumbnailContainerPlaceholder_shouldNotUpdateImageContainer() async throws {
        let photo = NodeEntity(handle: 65, isMarkedSensitive: false)
        let imageContainer = ImageContainer(image: Image("folder"), type: .placeholder)
        
        let monitorInheritedSensitivityForNode = SingleItemAsyncSequence(item: !photo.isMarkedSensitive)
            .eraseToAnyAsyncThrowingSequence()
        let nodeUseCase = MockNodeDataUseCase(
            node: photo,
            monitorInheritedSensitivityForNode: monitorInheritedSensitivityForNode)
        
        let sut = makeSUT(coverPhoto: photo,
                          thumbnailLoader: MockThumbnailLoader(initialImage: imageContainer),
                          nodeUseCase: nodeUseCase,
                          featureFlagProvider: MockFeatureFlagProvider(list: [.hiddenNodes: true]))
        
        let exp = expectation(description: "Should not update image container")
        exp.isInverted = true
        
        let subscription = thumbnailContainerUpdates(on: sut) { _ in
            exp.fulfill()
        }
        let cancelledExp = expectation(description: "cancelled")
        let task = Task {
            await sut.monitorInheritedSensitivityChanges()
            cancelledExp.fulfill()
        }
        
        await fulfillment(of: [exp], timeout: 1.0)
        task.cancel()
        await fulfillment(of: [cancelledExp], timeout: 0.5)
        subscription.cancel()
    }
    
    @MainActor
    func testMonitorInheritedSensitivityChanges_photoMarkedSensitive_shouldNotUpdateImageContainer() async throws {
        let photo = NodeEntity(handle: 65, isMarkedSensitive: true)
        let imageContainer = ImageContainer(image: Image("folder"), type: .placeholder)
        
        let monitorInheritedSensitivityForNode = SingleItemAsyncSequence(item: photo.isMarkedSensitive)
            .eraseToAnyAsyncThrowingSequence()
        let nodeUseCase = MockNodeDataUseCase(
            node: photo,
            monitorInheritedSensitivityForNode: monitorInheritedSensitivityForNode)
        
        let sut = makeSUT(coverPhoto: photo,
                          thumbnailLoader: MockThumbnailLoader(initialImage: imageContainer),
                          nodeUseCase: nodeUseCase,
                          featureFlagProvider: MockFeatureFlagProvider(list: [.hiddenNodes: true]))
        
        let exp = expectation(description: "Should not update image container")
        exp.isInverted = true
        
        let subscription = thumbnailContainerUpdates(on: sut) { _ in
            exp.fulfill()
        }
        let cancelledExp = expectation(description: "cancelled")
        let task = Task {
            await sut.monitorInheritedSensitivityChanges()
            cancelledExp.fulfill()
        }
        
        await fulfillment(of: [exp], timeout: 1.0)
        task.cancel()
        await fulfillment(of: [cancelledExp], timeout: 0.5)
        subscription.cancel()
    }
    
    @MainActor
    func testMonitorPhotoSensitivityChanges_nodeSensitivityUpdated_shouldUpdateTheImageContainer() async throws {
        let photo = NodeEntity(handle: 65, isMarkedSensitive: false)
        let imageContainer = ImageContainer(image: Image("folder"), type: .thumbnail)
        
        let (nodeSensitivityStream, nodeSensitivityContinuation) = AsyncStream.makeStream(of: Bool.self)
        let (inheritedStream, _) = AsyncThrowingStream.makeStream(of: Bool.self)
        
        let nodeUseCase = MockNodeDataUseCase(
            node: photo,
            isInheritingSensitivityResult: .success(false),
            monitorInheritedSensitivityForNode: inheritedStream.eraseToAnyAsyncThrowingSequence(),
            sensitivityChangesForNode: nodeSensitivityStream.eraseToAnyAsyncSequence())
        
        let sensitiveNodeUseCase = MockSensitiveNodeUseCase(
            isInheritingSensitivityResult: .success(false),
            monitorInheritedSensitivityForNode: inheritedStream.eraseToAnyAsyncThrowingSequence(),
            sensitivityChangesForNode: nodeSensitivityStream.eraseToAnyAsyncSequence()
        )
        
        let sut = makeSUT(coverPhoto: photo,
                          thumbnailLoader: MockThumbnailLoader(initialImage: imageContainer),
                          nodeUseCase: nodeUseCase,
                          sensitiveNodeUseCase: sensitiveNodeUseCase,
                          featureFlagProvider: MockFeatureFlagProvider(list: [.hiddenNodes: true]))
        
        var expectedImageContainers = [
            imageContainer.toSensitiveImageContaining(isSensitive: false),
            imageContainer.toSensitiveImageContaining(isSensitive: true)
        ]
        
        let exp = expectation(description: "Should update image container with sensitivity")
        exp.expectedFulfillmentCount = expectedImageContainers.count
        
        let subscription = thumbnailContainerUpdates(on: sut) {
            XCTAssertTrue($0.isEqual(expectedImageContainers.removeFirst()))
            exp.fulfill()
        }
        
        let startedExp = expectation(description: "started")
        let cancelledExp = expectation(description: "cancelled")
        let task = Task {
            startedExp.fulfill()
            await sut.monitorPhotoSensitivityChanges()
            cancelledExp.fulfill()
        }
        await fulfillment(of: [startedExp], timeout: 0.1)
        
        try await Task.sleep(nanoseconds: 50_000_000)
        nodeSensitivityContinuation.yield(true)
        
        await fulfillment(of: [exp], timeout: 1.0)
        task.cancel()
        await fulfillment(of: [cancelledExp], timeout: 0.5)
        subscription.cancel()
    }
    
    @MainActor
    func testMonitorPhotoSensitivityChanges_nodeNotSensitiveInheritUpdated_shouldUpdateTheImageContainer() async throws {
        let photo = NodeEntity(handle: 65, isMarkedSensitive: false)
        let imageContainer = ImageContainer(image: Image("folder"), type: .thumbnail)
        
        let (nodeSensitivityStream, _) = AsyncStream.makeStream(of: Bool.self)
        let (inheritedStream, inheritedContinuation) = AsyncThrowingStream.makeStream(of: Bool.self)
        let nodeUseCase = MockNodeDataUseCase(
            node: photo,
            isInheritingSensitivityResult: .success(false),
            monitorInheritedSensitivityForNode: inheritedStream.eraseToAnyAsyncThrowingSequence(),
            sensitivityChangesForNode: nodeSensitivityStream.eraseToAnyAsyncSequence())
        
        let sensitiveNodeUseCase = MockSensitiveNodeUseCase(
            isInheritingSensitivityResult: .success(false),
            monitorInheritedSensitivityForNode: inheritedStream.eraseToAnyAsyncThrowingSequence(),
            sensitivityChangesForNode: nodeSensitivityStream.eraseToAnyAsyncSequence()
        )
        
        let sut = makeSUT(coverPhoto: photo,
                          thumbnailLoader: MockThumbnailLoader(initialImage: imageContainer),
                          nodeUseCase: nodeUseCase,
                          sensitiveNodeUseCase: sensitiveNodeUseCase,
                          featureFlagProvider: MockFeatureFlagProvider(list: [.hiddenNodes: true]))
        
        var expectedImageContainers = [
            imageContainer.toSensitiveImageContaining(isSensitive: false),
            imageContainer.toSensitiveImageContaining(isSensitive: true)
        ]
        
        let exp = expectation(description: "Should update image container with sensitivity")
        exp.expectedFulfillmentCount = expectedImageContainers.count
        
        let subscription = thumbnailContainerUpdates(on: sut) {
            XCTAssertTrue($0.isEqual(expectedImageContainers.removeFirst()))
            exp.fulfill()
        }
        
        let startedExp = expectation(description: "started")
        let cancelledExp = expectation(description: "cancelled")
        let task = Task {
            startedExp.fulfill()
            await sut.monitorPhotoSensitivityChanges()
            cancelledExp.fulfill()
        }
        await fulfillment(of: [startedExp], timeout: 0.1)
        
        try await Task.sleep(nanoseconds: 50_000_000)
        inheritedContinuation.yield(true)
        
        await fulfillment(of: [exp], timeout: 1.0)
        task.cancel()
        await fulfillment(of: [cancelledExp], timeout: 0.5)
        subscription.cancel()
    }
    
    @MainActor
    private func makeSUT(
        coverPhoto: NodeEntity? = nil,
        thumbnailLoader: some ThumbnailLoaderProtocol = MockThumbnailLoader(),
        nodeUseCase: some NodeUseCaseProtocol = MockNodeDataUseCase(),
        sensitiveNodeUseCase: some SensitiveNodeUseCaseProtocol = MockSensitiveNodeUseCase(),
        featureFlagProvider: some FeatureFlagProviderProtocol = MockFeatureFlagProvider(list: [:]),
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> PhotoCardViewModel {
        let sut = PhotoCardViewModel(
            coverPhoto: coverPhoto, 
            thumbnailLoader: thumbnailLoader,
            nodeUseCase: nodeUseCase,
            sensitiveNodeUseCase: sensitiveNodeUseCase,
            featureFlagProvider: featureFlagProvider)
        trackForMemoryLeaks(on: sut, file: file, line: line)
        return sut
    }
    
    @MainActor
    private func thumbnailContainerUpdates(on sut: PhotoCardViewModel, action: @escaping (any ImageContaining) -> Void) -> AnyCancellable {
        sut.$thumbnailContainer
            .dropFirst()
            .sink(receiveValue: action)
    }
}
