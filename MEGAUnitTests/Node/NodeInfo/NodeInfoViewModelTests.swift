@testable import MEGA

import MEGADomain
import MEGADomainMock
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
    
    private func makeSUT(
        node: MockNode = MockNode(handle: 0),
        shareUseCase: ShareUseCaseProtocol = MockShareUseCase(),
        file: StaticString = #file,
        line: UInt = #line
    ) -> NodeInfoViewModel {
        let sut = NodeInfoViewModel(withNode: node, shareUseCase: shareUseCase)
        trackForMemoryLeaks(on: sut, file: file, line: line)
        return sut
    }
}
