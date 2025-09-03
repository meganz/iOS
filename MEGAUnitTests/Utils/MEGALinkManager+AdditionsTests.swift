import ChatRepoMock
@testable import MEGA
import MEGAAppPresentation
import XCTest

final class MEGALinkManager_AdditionsTests: XCTestCase {
    func testAlbumPublicLink_noLinkSet_shouldReturnNil() {
        MEGALinkManager.linkURL = nil
        
        XCTAssertNil(MEGALinkManager.albumPublicLink())
    }
    
    func testAlbumPublicLink_onNormalLink_shouldStayTheSame() {
        for urlString in ["https://mega.nz/collection/p3IBQCiZ#Nt8-bopPB8em4cOlKFqStA", "https://mega.app/collection/p3IBQCiZ#Nt8-bopPB8em4cOlKFqStA"] {
            let link = URL(string: urlString)
            MEGALinkManager.linkURL = link

            XCTAssertEqual(MEGALinkManager.albumPublicLink(), link)
        }
    }
    
    func testAlbumPublicLink_onMegaSchemeLink_convertsUrlCorrectly() {
        MEGALinkManager.linkURL = URL(string: "mega://collection/p3IBQCiZ#Nt8-bopPB8em4cOlKFqStA")
        
        XCTAssertEqual(MEGALinkManager.albumPublicLink(),
                       URL(string: "https://\(DIContainer.domainName)/collection/p3IBQCiZ#Nt8-bopPB8em4cOlKFqStA"))
    }
    
    func testShouldOpenWaitingRoom_forWaitingRoomEnabledAndOwnPrivilegeNotModerator_shouldReturnTrue() {
        let request = MockChatRequest()
        let chatSdk = MockChatSDK(
            chatRoom: MockChatRoom(ownPrivilage: .standard),
            hasChatOptionEnabled: true
        )
        let result = MEGALinkManager.shouldOpenWaitingRoom(request: request, chatSdk: chatSdk)
        
        XCTAssertTrue(result)
    }
    
    func testShouldOpenWaitingRoom_forWaitingRoomEnabledAndOwnPrivilegeModerator_shouldReturnFalse() {
        let request = MockChatRequest()
        let chatSdk = MockChatSDK(
            chatRoom: MockChatRoom(ownPrivilage: .moderator),
            hasChatOptionEnabled: true
        )
        let result = MEGALinkManager.shouldOpenWaitingRoom(request: request, chatSdk: chatSdk)
        
        XCTAssertFalse(result)
    }
    
    func testShouldOpenWaitingRoom_forWaitingRoomNotEnabledAndOwnPrivilegeNotModerator_shouldReturnFalse() {
        let request = MockChatRequest()
        let chatSdk = MockChatSDK(
            chatRoom: MockChatRoom(ownPrivilage: .standard),
            hasChatOptionEnabled: false
        )
        let result = MEGALinkManager.shouldOpenWaitingRoom(request: request, chatSdk: chatSdk)
        
        XCTAssertFalse(result)
    }
    
    func testIsHostInWaitingRoom_forWaitingRoomEnabledAndOwnPrivilegeModerator_shouldReturnTrue() {
        let request = MockChatRequest()
        let chatSdk = MockChatSDK(
            chatRoom: MockChatRoom(ownPrivilage: .moderator),
            hasChatOptionEnabled: true
        )
        let result = MEGALinkManager.isHostInWaitingRoom(request: request, chatSdk: chatSdk)
        
        XCTAssertTrue(result)
    }
    
    func testIsHostInWaitingRoom_forWaitingRoomEnabledAndOwnPrivilegeNotModerator_shouldReturnFalse() {
        let request = MockChatRequest()
        let chatSdk = MockChatSDK(
            chatRoom: MockChatRoom(ownPrivilage: .standard),
            hasChatOptionEnabled: true
        )
        let result = MEGALinkManager.isHostInWaitingRoom(request: request, chatSdk: chatSdk)
        
        XCTAssertFalse(result)
    }
    
    func testIsHostInWaitingRoom_forWaitingRoomNotEnabledAndOwnPrivilegeModerator_shouldReturnFalse() {
        let request = MockChatRequest()
        let chatSdk = MockChatSDK(
            chatRoom: MockChatRoom(ownPrivilage: .moderator),
            hasChatOptionEnabled: false
        )
        let result = MEGALinkManager.isHostInWaitingRoom(request: request, chatSdk: chatSdk)
        
        XCTAssertFalse(result)
    }
}
