import XCTest
@testable import MEGA
import MEGADomain
import MEGADomainMock

final class ParticipantsAddingViewFactoryTests: XCTestCase {

    func test_shouldShowAddParticipantsScreen_hasNoVisibleContacts() {
        let participantsAddingViewFactory = ParticipantsAddingViewFactory(
            accountUseCase: MockAccountUseCase(),
            chatRoomUseCase: MockChatRoomUseCase(),
            chatId: .invalid
        )
        
        let hasVisibleContacts = participantsAddingViewFactory.hasVisibleContacts
        XCTAssertFalse(hasVisibleContacts)
    }
    
    func test_shouldShowAddParticipantsScreen_hasNonAddedVisibleContacts() {
        let mockAccountUseCase = MockAccountUseCase(contacts: [
            UserEntity(email: "user@email.com", handle: 101, visibility: .visible)
        ])
        let participantsAddingViewFactory = ParticipantsAddingViewFactory(
            accountUseCase: mockAccountUseCase,
            chatRoomUseCase: MockChatRoomUseCase(),
            chatId: .invalid
        )
        
        let hasNonAddedVisibleContacts = participantsAddingViewFactory.hasNonAddedVisibleContacts(withExcludedHandles: [])
        XCTAssertTrue(hasNonAddedVisibleContacts)
        
        let hasVisibleContacts = participantsAddingViewFactory.hasVisibleContacts
        XCTAssertTrue(hasVisibleContacts)
    }
    
    func test_shouldShowAddParticipantsScreen_AllContactsAlreadyAdded() {
        let mockAccountUseCase = MockAccountUseCase(contacts: [
            UserEntity(email: "user@email.com", handle: 101, visibility: .visible)
        ])
        let chatRoomUseCase = MockChatRoomUseCase(myPeerHandles: [101])
        let participantsAddingViewFactory = ParticipantsAddingViewFactory(
            accountUseCase: mockAccountUseCase,
            chatRoomUseCase: chatRoomUseCase,
            chatId: .invalid
        )
        
        let shouldShowAddParticipantsScreen = participantsAddingViewFactory.hasNonAddedVisibleContacts(withExcludedHandles: [])
        XCTAssertFalse(shouldShowAddParticipantsScreen)
    }
}
