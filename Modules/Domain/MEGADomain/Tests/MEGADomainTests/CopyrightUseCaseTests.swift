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
        let userAlbumRepository = MockUserAlbumRepository(albums: [SetEntity(handle: 3, isExported: true)])
        let sut = makeCopyrightUseCase(userAlbumRepository: userAlbumRepository)
        
        let shouldAutoApprove = await sut.shouldAutoApprove()
        
        XCTAssertTrue(shouldAutoApprove)
    }
    
    func testShouldAutoApprove_noPublicLinksSharedAndNoAlbumsShared_shouldReturnFalse() async {
        let sut = makeCopyrightUseCase()
        
        let shouldAutoApprove = await sut.shouldAutoApprove()
        
        XCTAssertFalse(shouldAutoApprove)
    }
    
    // MARK: - Helpers
    private func makeCopyrightUseCase(shareUseCase: some ShareUseCaseProtocol = MockShareUseCase(),
                                      userAlbumRepository: some UserAlbumRepositoryProtocol = MockUserAlbumRepository()) -> some CopyrightUseCaseProtocol {
        CopyrightUseCase(shareUseCase: shareUseCase,
                         userAlbumRepository: userAlbumRepository)
    }
}
