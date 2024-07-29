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
    
    func testOpenSharedDialog_shareKeyCreated() async {
        let mockShareUseCase = MockShareUseCase()
        let sut = makeSUT(node: MockNode(handle: 1, nodeType: .folder), shareUseCase: mockShareUseCase)
        let expectation = expectation(description: "Task has started")

        Task {
            await sut.openSharedDialog()
            expectation.fulfill()
        }
        
        await fulfillment(of: [expectation], timeout: 1.0)
        
        XCTAssertTrue(mockShareUseCase.createShareKeyFunctionHasBeenCalled)
    }
    
    func testOpenSharedDialog_shareKeyNotCreated() async {
        let mockShareUseCase = MockShareUseCase()
        let sut = makeSUT(node: MockNode(handle: 1, nodeType: .file), shareUseCase: mockShareUseCase)
        let expectation = expectation(description: "Task has started")

        Task {
            await sut.openSharedDialog()
            expectation.fulfill()
        }
        
        await fulfillment(of: [expectation], timeout: 1.0)
        
        XCTAssertFalse(mockShareUseCase.createShareKeyFunctionHasBeenCalled)
    }

    func testShouldShowNodeDescription_whenFeatureFlagIsOff_shouldReturnFalse() {
        let provider = MockFeatureFlagProvider(list: [.nodeDescription: false])
        assertShouldShowNodeDescription(featureFlagProvider: provider, expectedResult: false)
    }

    func testShouldShowNodeDescription_whenFeatureFlagIsOnAndDescriptionIsNotPresent_shouldReturnTrue() {
        let node = MockNode(handle: 100, description: nil)
        assertShouldShowNodeDescription(node: node, expectedResult: true)
    }

    func testShouldShowNodeDescription_whenFeatureFlagIsOnAndDescriptionIsEmptyString_shouldReturnTrue() {
        let node = MockNode(handle: 100, description: "")
        assertShouldShowNodeDescription(node: node, expectedResult: true)
    }

    func testShouldShowNodeDescription_whenFeatureFlagIsOnAndDescriptionIsNonEmpty_shouldReturnFalse() {
        let node = MockNode(handle: 100, description: "text")
        assertShouldShowNodeDescription(node: node, expectedResult: false)
    }

    private func makeSUT(
        node: MockNode = MockNode(handle: 0),
        shareUseCase: ShareUseCaseProtocol = MockShareUseCase(),
        featureFlagProvider: some FeatureFlagProviderProtocol = MockFeatureFlagProvider(list: [:]),
        file: StaticString = #file,
        line: UInt = #line
    ) -> NodeInfoViewModel {
        let sut = NodeInfoViewModel(
            withNode: node,
            shareUseCase: shareUseCase,
            featureFlagProvider: featureFlagProvider
        )
        trackForMemoryLeaks(on: sut, file: file, line: line)
        return sut
    }

    private func assertShouldShowNodeDescription(
        node: MockNode = MockNode(handle: 100),
        featureFlagProvider: some FeatureFlagProviderProtocol = MockFeatureFlagProvider(list: [.nodeDescription: true]),
        expectedResult: Bool,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let sut = makeSUT(node: node, featureFlagProvider: featureFlagProvider)
        let result = sut.shouldShowNodeDescription()
        XCTAssertEqual(result, expectedResult, file: file, line: line)
    }
}
