@testable import MEGA
import XCTest

final class MEGALinkManager_AdditionsTests: XCTestCase {
    func testAlbumPublicLink_noLinkSet_shouldReturnNil() {
        MEGALinkManager.linkURL = nil
        
        XCTAssertNil(MEGALinkManager.albumPublicLink())
    }
    
    func testAlbumPublicLink_onNormalLink_shouldStayTheSame() {
        let link = URL(string: "https://mega.nz/collection/p3IBQCiZ#Nt8-bopPB8em4cOlKFqStA")
        MEGALinkManager.linkURL = link
        
        XCTAssertEqual(MEGALinkManager.albumPublicLink(), link)
    }
    
    func testAlbumPublicLink_onMegaSchemeLink_convertsUrlCorrectly() {
        MEGALinkManager.linkURL = URL(string: "mega://collection/p3IBQCiZ#Nt8-bopPB8em4cOlKFqStA")
        
        XCTAssertEqual(MEGALinkManager.albumPublicLink(),
                       URL(string: "https://mega.nz/collection/p3IBQCiZ#Nt8-bopPB8em4cOlKFqStA"))
    }
}
