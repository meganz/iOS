import XCTest
import Combine
@testable import MEGA
import MEGADomain
import MEGADomainMock
import MEGADataMock

final class MediaDiscoveryViewModelTests: XCTestCase {
    // MARK: - Action Command tests
    
    func testAction_onViewReady_withEmptyMediaFiles() throws {
        let sut = makeMediaDiscoveryViewModel()
        test(viewModel: sut, action: .onViewReady, expectedCommands: [.loadMedia(nodes: [])])
    }
    
    func testAction_onViewReady_loadedNodesRequestLoadMedia() throws {
        let expected = [NodeEntity(handle: 1)]
        let mediaDiscoveryUseCase = MockMediaDiscoveryUseCase(nodes: expected)
        let sut = makeMediaDiscoveryViewModel(mediaDiscoveryUseCase: mediaDiscoveryUseCase)
        
        test(viewModel: sut, action: .onViewReady, expectedCommands: [.loadMedia(nodes: expected)])
    }
    
    func testSendEvent_onMediaDiscoveryVisited_shouldReturnTrue() throws {
        let analyticsUseCase = MockMediaDiscoveryAnalyticsUseCase()
        let sut = makeMediaDiscoveryViewModel(analyticsUseCase: analyticsUseCase)
        test(viewModel: sut, action: .onViewReady, expectedCommands: [.loadMedia(nodes: [])])
        
        XCTAssertTrue(analyticsUseCase.hasPageVisitedCalled)
    }
    
    func testSendEvent_onMediaDiscoveryExit_shouldReturnTrue() throws {
        let analyticsUseCase = MockMediaDiscoveryAnalyticsUseCase()
        let sut = makeMediaDiscoveryViewModel(analyticsUseCase: analyticsUseCase)
        test(viewModel: sut, action: .onViewWillDisAppear, expectedCommands: [])
        
        XCTAssertTrue(analyticsUseCase.hasPageStayCalled)
    }
    
    func testAction_downloadPhotos_shouldDownloadTransfersAndSetFolderLinkFlag() {
        let router = MockMediaDiscoveryRouter()
        let sut = makeMediaDiscoveryViewModel(router: router)
        let selectedPhotos = [
            NodeEntity(handle: 3, isFile: true),
            NodeEntity(handle: 4, isFile: true)
        ]
        test(viewModel: sut, action: .downloadSelectedPhotos(selectedPhotos), expectedCommands: [
            .endEditingMode])
        XCTAssertEqual(router.showDownloadCalled, 1)
    }
    
    func testAction_downloadPhotosWithNothingSelected_shouldNotDoAnything() {
        let sut = makeMediaDiscoveryViewModel()
        let exp = expectation(description: "Should not call any action")
        exp.isInverted = true
        sut.invokeCommand = { _ in
            exp.fulfill()
        }
        sut.dispatch(.downloadSelectedPhotos([]))
        wait(for: [exp], timeout: 1.0)
    }
    
    func testAction_saveToPhotos_shouldSaveSelectedPhotosAndEndEditingMode() {
        let saveMediaUseCase = MockSaveMediaToPhotosUseCase(saveToPhotosResult: .success)
        let sut = makeMediaDiscoveryViewModel(saveMediaUseCase: saveMediaUseCase)
        test(viewModel: sut, action: .saveToPhotos([NodeEntity(handle: 1)]), expectedCommands: [
            .endEditingMode
        ])
    }
            
    func testAction_saveToPhotosFailed_shouldShowError() {
        let error = SaveMediaToPhotosErrorEntity.downloadFailed
        let saveMediaUseCase = MockSaveMediaToPhotosUseCase(saveToPhotosResult: .failure(error))
        let sut = makeMediaDiscoveryViewModel(saveMediaUseCase: saveMediaUseCase)
        test(viewModel: sut, action: .saveToPhotos([NodeEntity(handle: 1)]), expectedCommands: [
            .endEditingMode,
            .showSaveToPhotosError(error.localizedDescription)
        ])
    }
    
    func testAction_saveToPhotos_shouldDoNothingIfThereAreNoPhotosToSave() {
        let sut = makeMediaDiscoveryViewModel()
        let exp = expectation(description: "Should not call any action")
        exp.isInverted = true
        sut.invokeCommand = { _ in
            exp.fulfill()
        }
        sut.dispatch(.saveToPhotos([]))
        wait(for: [exp], timeout: 1.0)
    }
    
    func testAction_importPhotos_shouldEndEditingModeAndImportPhotosWithCorrectFolderLink() {
        let router = MockMediaDiscoveryRouter()
        let sut = makeMediaDiscoveryViewModel(router: router)
        test(viewModel: sut, action: .importPhotos([NodeEntity(handle: 4)]),
             expectedCommands: [.endEditingMode])
        XCTAssertEqual(router.showImportLocationCalled, 1)
    }
    
    func testAction_importPhotos_shouldDoNothingIfThereAreNoPhotosToImport() {
        let sut = makeMediaDiscoveryViewModel()
        let exp = expectation(description: "Should not call any action")
        exp.isInverted = true
        sut.invokeCommand = { _ in
            exp.fulfill()
        }
        sut.dispatch(.importPhotos([]))
        wait(for: [exp], timeout: 1.0)
    }
    
    func testAction_shareLink_shouldShowShareLinkWithFolderLink() {
        let router = MockMediaDiscoveryRouter()
        let sut = makeMediaDiscoveryViewModel(router: router)
        test(viewModel: sut, action: .shareLink(nil),
             expectedCommands: [.endEditingMode])
        XCTAssertEqual(router.showShareLinkCalled, 1)
    }
    
    // MARK: - Node updates tests
    
    func testSubscription_onNodesUpdate_shouldReload() throws {
        let expectedNodes = [NodeEntity(handle: 1)]
        let nodeUpdatesPublisher = PassthroughSubject<[NodeEntity], Never>()
        let mediaDiscoveryUseCase = MockMediaDiscoveryUseCase(nodeUpdates: AnyPublisher(nodeUpdatesPublisher), nodes: expectedNodes)
        let sut = makeMediaDiscoveryViewModel(mediaDiscoveryUseCase: mediaDiscoveryUseCase)
        
        var results = [[NodeEntity]]()
        let loadMediaExpectation = expectation(description: "load and reload triggers")
        loadMediaExpectation.expectedFulfillmentCount = 2
        
        sut.invokeCommand = { command in
            switch command {
            case .loadMedia(nodes: let nodes):
                results.append(nodes)
                loadMediaExpectation.fulfill()
            default:
                XCTFail("Invalid command")
            }
        }
        sut.dispatch(.onViewReady)

        nodeUpdatesPublisher.send([NodeEntity(handle: 2)])
        
        wait(for: [loadMediaExpectation], timeout: 2)
        XCTAssertEqual(results.first, expectedNodes)
        XCTAssertEqual(results.last, expectedNodes)
    }
    
    func testSubscription_onNodesUpdate_shouldDoNothingIfReloadIsNotRequired() throws {
        let expectedNodes = [NodeEntity(handle: 1)]
        let nodeUpdatesPublisher = PassthroughSubject<[NodeEntity], Never>()
        let mediaDiscoveryUseCase = MockMediaDiscoveryUseCase(nodeUpdates: AnyPublisher(nodeUpdatesPublisher), nodes: expectedNodes,
                                                              shouldReload: false)
        let sut = makeMediaDiscoveryViewModel(mediaDiscoveryUseCase: mediaDiscoveryUseCase)
        
        let loadMediaExpectation = expectation(description: "should not trigger reload")
        loadMediaExpectation.isInverted = true
        
        sut.invokeCommand = { command in
            switch command {
            case .loadMedia:
                loadMediaExpectation.fulfill()
            default:
                XCTFail("Invalid command")
            }
        }
        nodeUpdatesPublisher.send([NodeEntity(handle: 2)])
        
        wait(for: [loadMediaExpectation], timeout: 2)
    }
    
    // MARK: Private
    
    private func makeMediaDiscoveryViewModel(parentNode: NodeEntity = NodeEntity(),
                                             router: some MediaDiscoveryRouting = MockMediaDiscoveryRouter(),
                                             analyticsUseCase: some MediaDiscoveryAnalyticsUseCaseProtocol = MockMediaDiscoveryAnalyticsUseCase(),
                                             mediaDiscoveryUseCase: some MediaDiscoveryUseCaseProtocol = MockMediaDiscoveryUseCase(),
                                             saveMediaUseCase: some SaveMediaToPhotosUseCaseProtocol = MockSaveMediaToPhotosUseCase()
    ) -> MediaDiscoveryViewModel {
        MediaDiscoveryViewModel(parentNode: parentNode,
                                router: router,
                                analyticsUseCase: analyticsUseCase,
                                mediaDiscoveryUseCase: mediaDiscoveryUseCase,
                                saveMediaUseCase: saveMediaUseCase)
    }
}

final class MockMediaDiscoveryRouter: MediaDiscoveryRouting {
    var showImportLocationCalled = 0
    var showShareLinkCalled = 0
    var showDownloadCalled = 0
    
    func showImportLocation(photos: [NodeEntity]) {
       showImportLocationCalled += 1
    }
    
    func showShareLink(sender: UIBarButtonItem?) {
        showShareLinkCalled += 1
    }
    
    func showDownload(photos: [NodeEntity]) {
        showDownloadCalled += 1
    }
}
