@testable import MEGA
import MEGADomain
import MEGADomainMock
import XCTest

final class ChatRoomParticipantViewModelTests: XCTestCase {
    func testPrivilegeTapped_forOwnPrivilegeModeratorAndPariticipantIsMyself_shouldNotShowPrivilegeOptions() {
        let chatUseCase = MockChatUseCase(myUserHandle: 1)
        let chatRoom = ChatRoomEntity(ownPrivilege: .moderator)
        let sut = ChatRoomParticipantViewModel(
            chatUseCase: chatUseCase,
            chatParticipantId: 1,
            chatRoom: chatRoom
        )
        sut.privilegeTapped()
        
        XCTAssertFalse(sut.showPrivilegeOptions)
    }
    
    func testPrivilegeTapped_forOwnPrivilegeModeratorAndPariticipantIsNotMyself_shouldShowPrivilegeOptions() {
        let chatUseCase = MockChatUseCase(myUserHandle: 1)
        let chatRoom = ChatRoomEntity(ownPrivilege: .moderator)
        let sut = ChatRoomParticipantViewModel(
            chatUseCase: chatUseCase,
            chatParticipantId: 2,
            chatRoom: chatRoom
        )
        sut.privilegeTapped()
        
        XCTAssertTrue(sut.showPrivilegeOptions)
    }
    
    func testPrivilegeTapped_forOwnPrivilegeNotModeratorAndIsNotMyself_shouldNotShowPrivilegeOptions() {
        let chatUseCase = MockChatUseCase(myUserHandle: 1)
        let chatRoom = ChatRoomEntity(ownPrivilege: .standard)
        let sut = ChatRoomParticipantViewModel(
            chatUseCase: chatUseCase,
            chatParticipantId: 2,
            chatRoom: chatRoom
        )
        sut.privilegeTapped()
        
        XCTAssertFalse(sut.showPrivilegeOptions)
    }
    
    func testPrivilegeTapped_forOwnPrivilegeNotModeratorAndIsMyself_shouldNotShowPrivilegeOptions() {
        let chatUseCase = MockChatUseCase(myUserHandle: 1)
        let chatRoom = ChatRoomEntity(ownPrivilege: .standard)
        let sut = ChatRoomParticipantViewModel(
            chatUseCase: chatUseCase,
            chatParticipantId: 1,
            chatRoom: chatRoom
        )
        sut.privilegeTapped()
        
        XCTAssertFalse(sut.showPrivilegeOptions)
    }
    
    func testPrivilegeOptionTapped_forNewPrivilegeUnknown_shouldNotChangePrivilege() {
        let chatRoomUseCase = MockChatRoomUseCase(peerPrivilege: .standard)
        let sut = ChatRoomParticipantViewModel(chatRoomUseCase: chatRoomUseCase, chatParticipantId: 1)
        XCTAssertEqual(sut.participantPrivilege, .standard)
        
        sut.privilegeOptionTapped(.unknown)
        
        evaluate {
            sut.participantPrivilege == .standard
        }
    }
    
    func testPrivilegeOptionTapped_forNewPrivilegeRemoved_shouldNotChangePrivilege() {
        let chatRoomUseCase = MockChatRoomUseCase(peerPrivilege: .standard)
        let sut = ChatRoomParticipantViewModel(chatRoomUseCase: chatRoomUseCase, chatParticipantId: 1)
        XCTAssertEqual(sut.participantPrivilege, .standard)
        
        sut.privilegeOptionTapped(.removed)
        
        evaluate {
            sut.participantPrivilege == .standard
        }
    }
    
    func testPrivilegeOptionTapped_forOldPrivilegeStandardAndNewPrivilegeModerator_shouldChangeToModerator() {
        let chatRoomUseCase = MockChatRoomUseCase(peerPrivilege: .standard, updatedChatPrivilegeResult: .success(.moderator))
        let sut = ChatRoomParticipantViewModel(chatRoomUseCase: chatRoomUseCase, chatParticipantId: 1)
        XCTAssertEqual(sut.participantPrivilege, .standard)
        
        sut.privilegeOptionTapped(.moderator)
        
        evaluate {
            sut.participantPrivilege == .moderator
        }
    }
    
    func testPrivilegeOptionTapped_forOldPrivilegeModeratorAndNewPrivilegeStandard_shouldChangeToStandard() {
        let chatRoomUseCase = MockChatRoomUseCase(peerPrivilege: .moderator, updatedChatPrivilegeResult: .success(.standard))
        let sut = ChatRoomParticipantViewModel(chatRoomUseCase: chatRoomUseCase, chatParticipantId: 1)
        XCTAssertEqual(sut.participantPrivilege, .moderator)
        
        sut.privilegeOptionTapped(.standard)
        
        evaluate {
            sut.participantPrivilege == .standard
        }
    }
    
    @MainActor
    func testChatParticipantTapped_onDidUpdatePariticipantPrivilegeInDetailScreen_shouldUpdateParticipantPrivilege() {
        let router = MockMeetingInfoRouter()
        router.didUpdatePeerPermissionResult = .readOnly
        let chatUseCase = MockChatUseCase(myUserHandle: 1)
        let chatRoomUserUseCase = MockChatRoomUserUseCase(userEmail: .success("Participant Email"))
        let chatRoom = ChatRoomEntity(ownPrivilege: .standard)
        let sut = ChatRoomParticipantViewModel(
            router: router,
            chatRoomUserUseCase: chatRoomUserUseCase,
            chatUseCase: chatUseCase,
            chatParticipantId: 2,
            chatRoom: chatRoom
        )
        
        sut.chatParticipantTapped()
        
        evaluate {
            sut.participantPrivilege == .readOnly
        }
    }
}
