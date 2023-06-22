@testable import MEGA
import MEGADomain
import MEGADomainMock
import XCTest

final class ImportAlbumViewModelTests: XCTestCase {
    
    func testCheckPublicLink_onCollectionLinkOpen_publicLinkStatusShouldBeNeedsDescryptionKey() throws {
        let sut = ImportAlbumViewModel(
            shareAlbumUseCase: MockShareAlbumUseCase(),
            publicLink: try XCTUnwrap(URL(string: "https://mega.nz/collection/yro2RbQAx")))
        
        sut.checkPublicLink()
        
        XCTAssertEqual(sut.publicLinkStatus, .requireDecryptionKey)
    }
    
    func testCheckPublicLink_onCollectionLinkOpen_publicLinkStatusShouldBeNone() throws {
        let sut = ImportAlbumViewModel(
            shareAlbumUseCase: MockShareAlbumUseCase(),
            publicLink: try XCTUnwrap(URL(string: "https://mega.nz/collection/p3IBQCiZ#Nt8-bopPB8em4cOlKas")))
        
        sut.checkPublicLink()
        
        XCTAssertEqual(sut.publicLinkStatus, .none)
    }

}
