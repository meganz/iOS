@testable import MEGA
import MEGADomain
import MEGADomainMock
import MEGAPresentation
import MEGAPresentationMock
import MEGASDKRepoMock
import XCTest

final class NodeInfoViewModelTests: XCTestCase {
    
    func testIsContactVerified_Verified() {
        let mockUser = MockUser()
        let mockShareUseCase = MockShareUseCase(areUserCredentialsVerified: true, user: mockUser.toUserEntity())
        
        let sut = makeSUT(shareUseCase: mockShareUseCase)
        
        XCTAssertTrue(sut.isContactVerified())
    }
    
    func testIsContactVerified_NotVerified() {
        let mockShareUseCase = MockShareUseCase(areUserCredentialsVerified: false)
        let sut = makeSUT(shareUseCase: mockShareUseCase)
        
        XCTAssertFalse(sut.isContactVerified())
    }
    
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

    func testShouldShowNodeTags_whenFeatureToggleIsOn_shouldReturnTrue() {
        assertShouldShowNodeTags(whenFeatureToggleIsOn: true, shouldReturn: true)
    }

    func testShouldShowNodeTags_whenFeatureToggleIsOff_shouldReturnTrue() {
        assertShouldShowNodeTags(whenFeatureToggleIsOn: false, shouldReturn: false)
    }

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

    private func makeSUT(
        node: MockNode = MockNode(handle: 0),
        shareUseCase: some ShareUseCaseProtocol = MockShareUseCase(),
        nodeUseCase: some NodeUseCaseProtocol = MockNodeDataUseCase(),
        featureFlagProvider: some FeatureFlagProviderProtocol = MockFeatureFlagProvider(list: [:]),
        file: StaticString = #file,
        line: UInt = #line
    ) -> NodeInfoViewModel {
        let sut = NodeInfoViewModel(
            withNode: node,
            shareUseCase: shareUseCase,
            nodeUseCase: nodeUseCase,
            featureFlagProvider: featureFlagProvider
        )
        trackForMemoryLeaks(on: sut, file: file, line: line)
        return sut
    }
}
