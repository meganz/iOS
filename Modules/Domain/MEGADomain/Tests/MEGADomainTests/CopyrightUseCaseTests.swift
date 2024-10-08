import MEGADomain
import MEGADomainMock
import XCTest

final class CopyrightUseCaseTests: XCTestCase {
    
    func testShouldAutoApprove_publicLinkSharedBefore_shouldReturnTrue() async {
        let shareUseCase = MockShareUseCase(nodes: [NodeEntity(handle: 4)])
        let sut = makeCopyrightUseCase(shareUseCase: shareUseCase)
        
        let shouldAutoApprove = await sut.shouldAutoApprove()
        
        XCTAssertTrue(shouldAutoApprove)
    }
    
    func testShouldAutoApprove_noPublicLinkSharedBeforeAlbumShared_shouldReturnTrue() async {
        let shareUseCase = MockShareUseCase(isAnyCollectionShared: true)
        let sut = makeCopyrightUseCase(shareUseCase: shareUseCase)
        
        let shouldAutoApprove = await sut.shouldAutoApprove()
        
        XCTAssertTrue(shouldAutoApprove)
    }
    
    func testShouldAutoApprove_noPublicLinksSharedAndNoAlbumsShared_shouldReturnFalse() async {
        let sut = makeCopyrightUseCase()
        
        let shouldAutoApprove = await sut.shouldAutoApprove()
        
        XCTAssertFalse(shouldAutoApprove)
    }
    
    // MARK: - Helpers
    private func makeCopyrightUseCase(shareUseCase: some ShareUseCaseProtocol = MockShareUseCase()) -> some CopyrightUseCaseProtocol {
        CopyrightUseCase(shareUseCase: shareUseCase)
    }
}
