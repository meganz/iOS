import Combine
@testable import MEGA
import MEGADomain
import MEGADomainMock
import MEGASDKRepoMock
import XCTest

class MediaDiscoveryContentViewModelTests: XCTestCase {
    
    func testOnViewAppear_shouldSendPageVisitedEvent() {
        
        // Arrange
        let analyticsUseCase = MockMediaDiscoveryAnalyticsUseCase()
        let sut = makeSUT( analyticsUseCase: analyticsUseCase)
        
        // Act
        sut.onViewAppear()
        
        // Assert
        XCTAssertTrue(analyticsUseCase.hasPageVisitedCalled)
    }
    
    func testOnViewDisappear_shouldSendPageStayedEvent() {
        // Arrange
        let analyticsUseCase = MockMediaDiscoveryAnalyticsUseCase()
        let sut = makeSUT( analyticsUseCase: analyticsUseCase)
        
        // Act
        sut.onViewDisappear()
        
        // Assert
        XCTAssertTrue(analyticsUseCase.hasPageStayCalled)
    }
    
    func testSubscribeToNodeChanges_whenChangeOccursToNodes_shouldReloadPhotos() async {
        // Arrange
        let expectedNodes = [NodeEntity(name: "test.png", handle: 1)]
        let nodeUpdatesPublisher = PassthroughSubject<[NodeEntity], Never>()
        let mediaDiscoveryUseCase = MockMediaDiscoveryUseCase(nodeUpdates: AnyPublisher(nodeUpdatesPublisher), nodes: expectedNodes, shouldReload: true)
        let sut = makeSUT(mediaDiscoveryUseCase: mediaDiscoveryUseCase)
        
        // Act
        nodeUpdatesPublisher.send([NodeEntity(name: "test2.png", handle: 2)])
        
        // Assert
        let result = await sut.photoLibraryContentViewModel
            .$library
            .map(\.allPhotos)
            .values
            .first(where: { $0.count > 0 })
        
        XCTAssertEqual(expectedNodes, result)
    }
    
    func testSubscribeToNodeChanges_whenNoDiffereneceInChangeOccursToUpdatedNodes_shouldNotReloadPhotos() {
        // Arrange
        let expectedNodes = [NodeEntity(name: "test.png", handle: 1)]
        let nodeUpdatesPublisher = PassthroughSubject<[NodeEntity], Never>()
        let mediaDiscoveryUseCase = MockMediaDiscoveryUseCase(nodeUpdates: AnyPublisher(nodeUpdatesPublisher), nodes: expectedNodes, shouldReload: false)
        let sut = makeSUT(mediaDiscoveryUseCase: mediaDiscoveryUseCase)
        
        // Act
        let exp = expectation(description: "same node should not trigger a reload of photo library")
        exp.isInverted = true

        var result: PhotoLibrary?
        _ = sut.photoLibraryContentViewModel
            .$library
            .dropFirst(1)
            .sink(receiveValue: {
                result = $0
                exp.fulfill()
            })
        
        nodeUpdatesPublisher.send([NodeEntity(name: "test.png", handle: 1)])
        
        wait(for: [exp], timeout: 1)
        
        // Assert
        XCTAssertNil(result)
    }
    
    func testToggleAllSelected_toggleToOn_shouldReturnAllNodesAsSelected() async {
        // Arrange
        let expectedNodes = [
            NodeEntity(name: "test1.png", handle: 1),
            NodeEntity(name: "test2.png", handle: 2),
            NodeEntity(name: "test3.png", handle: 3)
        ]
        let delegate = MockMediaDiscoveryContentDelegate()
        let mediaDiscoveryUseCase = MockMediaDiscoveryUseCase(nodes: expectedNodes)
        let sut = makeSUT(delegate: delegate, mediaDiscoveryUseCase: mediaDiscoveryUseCase)
        
        await sut.loadPhotos()
        
        // Act
        sut.toggleAllSelected()
        
        let result = await sut.photoLibraryContentViewModel.selection.$photos
            .timeout(.milliseconds(500), scheduler: DispatchQueue.main)
            .last()
            .values
            .first(where: { _ in true })
            
        // Assert
        XCTAssertEqual(3, delegate.selectedPhotosDelegateCalledWithCount)
        XCTAssertEqual(result?.map(\.value).sorted(by: { $0.handle < $1.handle}), expectedNodes)
    }
    
    func testToggleAllSelected_toggleToOnThenOff_shouldReturnAllNodesAsSelected() async {
        // Arrange
        let expectedNodes = [
            NodeEntity(name: "test1.png", handle: 1),
            NodeEntity(name: "test2.png", handle: 2),
            NodeEntity(name: "test3.png", handle: 3)
        ]
        let delegate = MockMediaDiscoveryContentDelegate()
        let mediaDiscoveryUseCase = MockMediaDiscoveryUseCase(nodes: expectedNodes)
        let sut = makeSUT(delegate: delegate, mediaDiscoveryUseCase: mediaDiscoveryUseCase)
        await sut.loadPhotos()

        // Act
        sut.toggleAllSelected()
        sut.toggleAllSelected()

        let result = await sut.photoLibraryContentViewModel.selection.$photos
            .timeout(.milliseconds(500), scheduler: DispatchQueue.main)
            .last()
            .values
            .first(where: { _ in true })

        // Assert
        XCTAssertEqual(0, delegate.selectedPhotosDelegateCalledWithCount)
        XCTAssertEqual(result?.map(\.value), [])
    }
    
    func testLoadPhotos_returnsNonEmptyListOfNodes_shouldSetViewStateToNormal() async {
        // Arrange
        let expectedNodes = [
            NodeEntity(name: "test1.png", handle: 1),
            NodeEntity(name: "test2.png", handle: 2),
            NodeEntity(name: "test3.png", handle: 3)
        ]
        let mediaDiscoveryUseCase = MockMediaDiscoveryUseCase(nodes: expectedNodes)
        let sut = makeSUT(mediaDiscoveryUseCase: mediaDiscoveryUseCase)
        
        XCTAssertEqual(sut.viewState, .normal)
        
        // Act
        await sut.loadPhotos()
        
        // Assert
        XCTAssertEqual(sut.viewState, .normal)
    }
    
    func testLoadPhotos_returnsEmptyListOfNodes_shouldSetViewStateToEmpty() async {
        // Arrange
        let expectedNodes: [NodeEntity] = []
        let mediaDiscoveryUseCase = MockMediaDiscoveryUseCase(nodes: expectedNodes)
        let sut = makeSUT(mediaDiscoveryUseCase: mediaDiscoveryUseCase)
        
        XCTAssertEqual(sut.viewState, .normal)
        
        // Act
        await sut.loadPhotos()
        
        // Assert
        XCTAssertEqual(sut.viewState, .empty)
    }
    
    func testSubscribeToSelectionHidden_whenSelectionRequestHiddenEqualsTrue_shouldNotifyDelegateIsHiddenEqualsTrue() async {
        // Arrange
        let expectedNodes = [NodeEntity(name: "test1.png", handle: 1)]
        let delegate = MockMediaDiscoveryContentDelegate()
        let mediaDiscoveryUseCase = MockMediaDiscoveryUseCase(nodes: expectedNodes)
        let sut = makeSUT(delegate: delegate, mediaDiscoveryUseCase: mediaDiscoveryUseCase)
    
        // Act
        sut.photoLibraryContentViewModel.selection.isHidden = true
        
        _ = await sut.photoLibraryContentViewModel.selection.$isHidden
            .timeout(.milliseconds(300), scheduler: DispatchQueue.main)
            .values
            .first(where: { $0 })

        // Assert
        XCTAssertEqual(delegate.isMediaDiscoverySelectionDelegateIsHidden, true)
    }
    
    func testSubscribeToSelectionHidden_whenSelectionRequestHiddenEqualsFalse_shouldNotifyDelegateIsHiddenEqualsFalse() async {
        // Arrange
        let expectedNodes = [NodeEntity(name: "test1.png", handle: 1)]
        let delegate = MockMediaDiscoveryContentDelegate()
        let mediaDiscoveryUseCase = MockMediaDiscoveryUseCase(nodes: expectedNodes)
        let sut = makeSUT(delegate: delegate, mediaDiscoveryUseCase: mediaDiscoveryUseCase)
    
        // Act
        sut.photoLibraryContentViewModel.selection.isHidden = false
        
        _ = await sut.photoLibraryContentViewModel.selection.$isHidden
            .timeout(.milliseconds(300), scheduler: DispatchQueue.main)
            .values
            .first(where: { !$0 })

        // Assert
        XCTAssertEqual(delegate.isMediaDiscoverySelectionDelegateIsHidden, false)
    }
}

extension MediaDiscoveryContentViewModelTests {
    
    private func makeSUT(
        parentNode: NodeEntity = NodeEntity(),
        delegate: some MediaDiscoveryContentDelegate = MockMediaDiscoveryContentDelegate(),
        analyticsUseCase: some MediaDiscoveryAnalyticsUseCaseProtocol = MockMediaDiscoveryAnalyticsUseCase(),
        mediaDiscoveryUseCase: some MediaDiscoveryUseCaseProtocol = MockMediaDiscoveryUseCase(),
        file: StaticString = #filePath,
        line: UInt = #line) -> MediaDiscoveryContentViewModel {
            let viewModel = MediaDiscoveryContentViewModel(
                contentMode: .mediaDiscovery,
                parentNode: parentNode,
                delegate: delegate,
                analyticsUseCase: analyticsUseCase,
                mediaDiscoveryUseCase: mediaDiscoveryUseCase)
            
            trackForMemoryLeaks(on: viewModel, file: file, line: line)

            return viewModel
        }
}

final class MockMediaDiscoveryContentDelegate: MediaDiscoveryContentDelegate {
    
    var selectedPhotosDelegateCalledWithCount = 0
    var isMediaDiscoverySelectionDelegateIsHidden: Bool?
    func selectedPhotos(selected: [MEGADomain.NodeEntity], allPhotos: [MEGADomain.NodeEntity]) {
        selectedPhotosDelegateCalledWithCount = selected.count
    }
    
    func isMediaDiscoverySelection(isHidden: Bool) {
        isMediaDiscoverySelectionDelegateIsHidden = isHidden
    }
}
