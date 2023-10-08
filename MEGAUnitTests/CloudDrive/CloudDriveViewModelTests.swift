@testable import MEGA
import MEGADomain
import MEGADomainMock
import MEGAPresentation
import MEGAPresentationMock
import MEGASDKRepoMock
import MEGATest
import XCTest

class CloudDriveViewModelTests: XCTestCase {
    
    func testUpdateEditModeActive_changeActiveToTrueWhenCurrentlyActive_shouldInvokeOnlyOnce() {
        
        // Arrange
        let sut = makeSUT()
        
        var commands = [CloudDriveViewModel.Command]()
        sut.invokeCommand = { viewCommand in
            commands.append(viewCommand)
        }
        
        // Act
        sut.dispatch(.updateEditModeActive(true))
        sut.dispatch(.updateEditModeActive(true))
        
        // Assert
        XCTAssertEqual(commands, [.enterSelectionMode])
    }
    
    func testUpdateEditModeActive_changeActiveToFalseWhenCurrentlyNotActive_shouldInvokeNotInvoke() {
        
        // Arrange
        let sut = makeSUT()
        
        var commands = [CloudDriveViewModel.Command]()
        sut.invokeCommand = { viewCommand in
            commands.append(viewCommand)
        }
        
        // Act
        sut.dispatch(.updateEditModeActive(false))
        sut.dispatch(.updateEditModeActive(false))
        
        // Assert
        XCTAssertEqual(commands, [])
    }
    
    func testUpdateEditModeActive_changeActiveToFalseWhenCurrentlyActive_shouldInvokeEnterAndExitCommands() {
        
        // Arrange
        let sut = makeSUT()
        
        var commands = [CloudDriveViewModel.Command]()
        sut.invokeCommand = { viewCommand in
            commands.append(viewCommand)
        }
        
        // Act
        sut.dispatch(.updateEditModeActive(true))
        sut.dispatch(.updateEditModeActive(false))
        
        // Assert
        XCTAssertEqual(commands, [.enterSelectionMode, .exitSelectionMode])
    }
    
    func testShouldShowMediaDiscoveryAutomatically_onFeatureTurnedOff_shouldReturnFalse() {
        let featureFlagProvider = MockFeatureFlagProvider(list: [.cloudDriveMediaDiscoveryIntegration: false])
        let sut = makeSUT(featureFlagProvider: featureFlagProvider)
        
        let nodes = MockNodeList(nodes: [MockNode(handle: 1, name: "test.jpg")])
        XCTAssertFalse(sut.shouldShowMediaDiscoveryAutomatically(forNodes: nodes))
    }
    
    func testShouldShowMediaDiscoveryAutomatically_containsNonMediaFiles_shouldReturnFalse() {
        let featureFlagProvider = MockFeatureFlagProvider(list: [.cloudDriveMediaDiscoveryIntegration: true])
        let preferenceUseCase = MockPreferenceUseCase(dict: [.shouldDisplayMediaDiscoveryWhenMediaOnly: true])
        let sut = makeSUT(featureFlagProvider: featureFlagProvider,
                          preferenceUseCase: preferenceUseCase)
        
        let nodes = MockNodeList(nodes: [MockNode(handle: 1, name: "test.pdf"),
                                         MockNode(handle: 2, name: "test.jpg")])
        XCTAssertFalse(sut.shouldShowMediaDiscoveryAutomatically(forNodes: nodes))
    }
    
    func testShouldShowMediaDiscoveryAutomatically_containsOnlyMediaFiles_shouldReturnTrue() {
        let featureFlagProvider = MockFeatureFlagProvider(list: [.cloudDriveMediaDiscoveryIntegration: true])
        let preferenceUseCase = MockPreferenceUseCase(dict: [.shouldDisplayMediaDiscoveryWhenMediaOnly: true])
        let sut = makeSUT(featureFlagProvider: featureFlagProvider,
                          preferenceUseCase: preferenceUseCase)
        
        let nodes = MockNodeList(nodes: [MockNode(handle: 1, name: "test.mp4"),
                                         MockNode(handle: 2, name: "test.jpg")])
        XCTAssertTrue(sut.shouldShowMediaDiscoveryAutomatically(forNodes: nodes))
    }
    
    func testShouldShowMediaDiscoveryAutomatically_preferenceOff_shouldReturnFalse() {
        let featureFlagProvider = MockFeatureFlagProvider(list: [.cloudDriveMediaDiscoveryIntegration: true])
        let preferenceUseCase = MockPreferenceUseCase(dict: [.shouldDisplayMediaDiscoveryWhenMediaOnly: false])
        let sut = makeSUT(featureFlagProvider: featureFlagProvider,
                          preferenceUseCase: preferenceUseCase)
        
        let nodes = MockNodeList(nodes: [MockNode(handle: 1, name: "test.jpg")])
        XCTAssertFalse(sut.shouldShowMediaDiscoveryAutomatically(forNodes: nodes))
    }
    
    func testHasMediaFiles_nodesContainVisualMediaFile_shouldReturnTrue() {
        let sut = makeSUT()
        
        let nodes = MockNodeList(nodes: [MockNode(handle: 1, name: "test.mp4"),
                                         MockNode(handle: 2, name: "test.jpg")])
        XCTAssertTrue(sut.hasMediaFiles(nodes: nodes))
    }
    
    func testHasMediaFiles_nodesDoesNotContainVisualMediaFile_shouldReturnFalse() {
        let sut = makeSUT()
        
        let nodes = MockNodeList(nodes: [MockNode(handle: 1, name: "test.pdf"),
                                         MockNode(handle: 2, name: "test.docx")])
        XCTAssertFalse(sut.hasMediaFiles(nodes: nodes))
    }
    
    func makeSUT(
        parentNode: MEGANode = MockNode(handle: 1),
        shareUseCase: some ShareUseCaseProtocol = MockShareUseCase(),
        featureFlagProvider: some FeatureFlagProviderProtocol = MockFeatureFlagProvider(list: [:]),
        preferenceUseCase: some PreferenceUseCaseProtocol = MockPreferenceUseCase(dict: [:]),
        file: StaticString = #file,
        line: UInt = #line
    ) -> CloudDriveViewModel {
        let sut = CloudDriveViewModel(
            parentNode: parentNode,
            shareUseCase: shareUseCase,
            featureFlagProvider: featureFlagProvider,
            preferenceUseCase: preferenceUseCase)
        trackForMemoryLeaks(on: sut, file: file, line: line)
        return sut
    }
}
