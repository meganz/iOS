@testable import MEGA
import MEGAAppPresentation
import MEGAAppPresentationMock
import MEGAAppSDKRepo
import MEGAAppSDKRepoMock
import MEGADomain
import MEGADomainMock
import XCTest

final class NodeInfoViewModelTests: XCTestCase {
    
    @MainActor
    func testIsContactVerified_Verified() {
        let mockUser = MockUser()
        let mockShareUseCase = MockShareUseCase(areUserCredentialsVerified: true, user: mockUser.toUserEntity())
        
        let sut = makeSUT(shareUseCase: mockShareUseCase)
        
        XCTAssertTrue(sut.isContactVerified())
    }
    
    @MainActor
    func testIsContactVerified_NotVerified() {
        let mockShareUseCase = MockShareUseCase(areUserCredentialsVerified: false)
        let sut = makeSUT(shareUseCase: mockShareUseCase)
        
        XCTAssertFalse(sut.isContactVerified())
    }
    
    @MainActor
    func testOpenVerifyCredentials_methodCalled() {
        let mockShareUseCase = MockShareUseCase()
        let sut = makeSUT(shareUseCase: mockShareUseCase)
        
        sut.openVerifyCredentials(from: UINavigationController()) { }

        XCTAssertTrue(mockShareUseCase.userFunctionHasBeenCalled)
    }
    
    @MainActor
    func testOpenSharedDialog_shareKeyCreated() async {
        let mockShareUseCase = MockShareUseCase()
        let sut = makeSUT(node: MockNode(handle: 1, nodeType: .folder), shareUseCase: mockShareUseCase)
        
        await sut.openSharedDialog()
        
        XCTAssertTrue(mockShareUseCase.createShareKeyFunctionHasBeenCalled)
    }
    
    @MainActor
    func testOpenSharedDialog_shareKeyNotCreated() async {
        let mockShareUseCase = MockShareUseCase()
        let sut = makeSUT(node: MockNode(handle: 1, nodeType: .file), shareUseCase: mockShareUseCase)
        
        await sut.openSharedDialog()

        XCTAssertFalse(mockShareUseCase.createShareKeyFunctionHasBeenCalled)
    }
    
    @MainActor
    func testNodeInfoLocationViewModel_whenNodeIsNotVisualMedia_shouldReturnNil() {
        let node = MockNode(handle: 1, name: "test.txt")
        let sut = makeSUT(node: node)
        XCTAssertNil(sut.nodeInfoLocationViewModel)
    }
    
    @MainActor
    func testNodeInfoLocationViewModel_whenNodeIsVisualMedia_shouldReturnViewModel() async {
        for fileExtension in ["mp4", "png", "mov", "jpeg"] {
            let node = MockNode(handle: 1, name: "test.\(fileExtension)")
            let sut = makeSUT(
                node: node,
                nodeUseCase: MockNodeDataUseCase(
                    nodeAccessLevelVariable: .owner
                )
            )
            
            await test(viewModel: sut, action: .viewDidLoad, expectedCommands: [.reloadSections])
                        
            XCTAssertNotNil(sut.nodeInfoLocationViewModel)
        }
    }
    
    @MainActor
    func testNodeInfoLocationViewModel_whenNodeIsVisualMediaAndAccessLevelisSet_shouldReturnExpected() async throws {
        
        let scenarios: [NodeAccessTypeEntity: Bool] = [
            .full: true,
            .owner: false,
            .readWrite: true,
            .unknown: true
        ]
        
        for (accessType, isNil) in scenarios {
            let node = MockNode(handle: 1, name: "test.mp4")
            let sut = makeSUT(
                node: node,
                nodeUseCase: MockNodeDataUseCase(
                    nodeAccessLevelVariable: accessType
                )
            )
            
            await test(viewModel: sut, action: .viewDidLoad, expectedCommands: isNil ? [] : [.reloadSections])
            
            if isNil {
                XCTAssertNil(sut.nodeInfoLocationViewModel, "Expected \(accessType) to be nil")
            } else {
                XCTAssertNotNil(sut.nodeInfoLocationViewModel, "Expected \(accessType) to be not nil")
            }
        }
    }

    @MainActor
    func testShouldShowNodeTags_whenNodeInCloudDriveAndFeatureToggleOn_shouldReturnTrue() {
        assertShouldShowNodeTags(whenFeatureToggleIsOn: true, shouldReturn: true)
    }

    @MainActor
    func testShouldShowNodeTags_whenFeatureToggleIsOff_shouldReturnFalse() {
        assertShouldShowNodeTags(whenFeatureToggleIsOn: false, shouldReturn: false)
    }

    @MainActor
    func testShouldShowNodeTags_whenNodeInRubbishBin_shouldReturnFalse() {
        let nodeUseCase = MockNodeUseCase(isNodeInRubbishBin: true)
        let sut = makeSUT(nodeUseCase: nodeUseCase)
        XCTAssertFalse(sut.shouldShowNodeTags)
    }

    @MainActor
    func testShouldShowNodeTags_whenNodeInBackup_shouldReturnFalse() {
        let backupUseCase = MockBackupsUseCase(isBackupsNode: true)
        let sut = makeSUT(backupUseCase: backupUseCase)
        XCTAssertFalse(sut.shouldShowNodeTags)
    }

    @MainActor
    func testShouldShowNodeTags_whenNodeIsIncomingShareRoot_shouldReturnFalse() {
        let sut = makeSUT(node: MockNode(handle: 100, isInShare: true))
        XCTAssertFalse(sut.shouldShowNodeTags)
    }

    @MainActor
    func testShouldShowNodeTags_whenNodeIsIncomingShareChild_shouldReturnFalse() {
        let rootNode = MockNode(handle: 100, isInShare: true)
        let childNode = MockNode(handle: 101, parentHandle: 100, isInShare: false)
        let nodeUseCase = MockNodeUseCase(nodes: [100: rootNode.toNodeEntity()])
        let sut = makeSUT(node: childNode, nodeUseCase: nodeUseCase)
        XCTAssertFalse(sut.shouldShowNodeTags)
    }

    @MainActor
    private func assertShouldShowNodeTags(
        whenFeatureToggleIsOn flag: Bool,
        shouldReturn expectedResult: Bool,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        let featureFlagProvider = MockFeatureFlagProvider(list: [.nodeTags: flag])
        let sut = makeSUT(featureFlagProvider: featureFlagProvider)
        XCTAssertEqual(sut.shouldShowNodeTags, expectedResult, file: file, line: line)
    }

    @MainActor
    private func makeSUT(
        node: MockNode = MockNode(handle: 0),
        shareUseCase: some ShareUseCaseProtocol = MockShareUseCase(),
        nodeUseCase: some NodeUseCaseProtocol = MockNodeDataUseCase(),
        backupUseCase: some BackupsUseCaseProtocol = MockBackupsUseCase(),
        featureFlagProvider: some FeatureFlagProviderProtocol = MockFeatureFlagProvider(list: [:]),
        file: StaticString = #file,
        line: UInt = #line
    ) -> NodeInfoViewModel {
        let sut = NodeInfoViewModel(
            withNode: node,
            shareUseCase: shareUseCase,
            nodeUseCase: nodeUseCase,
            backupUseCase: backupUseCase,
            featureFlagProvider: featureFlagProvider
        )
        trackForMemoryLeaks(on: sut, file: file, line: line)
        return sut
    }
}
