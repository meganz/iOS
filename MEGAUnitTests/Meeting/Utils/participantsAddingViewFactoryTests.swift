import XCTest
@testable import MEGA

final class ParticipantsAddingViewFactoryTests: XCTestCase {

    func test_shouldShowAddParticipantsScreen_hasNoVisibleContacts() {
        let participantsAddingViewFactory = ParticipantsAddingViewFactory(
            userUseCase: MockUserUseCase(contacts: []),
            chatRoomUseCase: MockChatRoomUseCase(),
            chatId: .invalid
        )
        
        let hasVisibleContacts = participantsAddingViewFactory.hasVisibleContacts
        XCTAssertFalse(hasVisibleContacts)
    }
    
    func test_shouldShowAddParticipantsScreen_hasNonAddedVisibleContacts() {
        let userUseCase = MockUserUseCase(contacts: [
            UserSDKEntity(
                email: "user@email.com",
                handle: 101,
                base64Handle: nil,
                change: nil,
                contact: UserSDKEntity.Contact(
                    withBecomingContactDate: Date(),
                    contactVisibility: .visible
                )
            )
        ])
        
        let participantsAddingViewFactory = ParticipantsAddingViewFactory(
            userUseCase: userUseCase,
            chatRoomUseCase: MockChatRoomUseCase(),
            chatId: .invalid
        )
        
        let hasNonAddedVisibleContacts = participantsAddingViewFactory.hasNonAddedVisibleContacts(withExcludedHandles: [])
        XCTAssertTrue(hasNonAddedVisibleContacts)
        
        let hasVisibleContacts = participantsAddingViewFactory.hasVisibleContacts
        XCTAssertTrue(hasVisibleContacts)
    }
    
    func test_shouldShowAddParticipantsScreen_AllContactsAlreadyAdded() {
        let userUseCase = MockUserUseCase(contacts: [
            UserSDKEntity(
                email: "user@email.com",
                handle: 101,
                base64Handle: nil,
                change: nil,
                contact: UserSDKEntity.Contact(
                    withBecomingContactDate: Date(),
                    contactVisibility: .visible
                )
            )
        ])
        
        let chatRoomUseCase = MockChatRoomUseCase(myPeerHandles: [101])
        
        let participantsAddingViewFactory = ParticipantsAddingViewFactory(
            userUseCase: userUseCase,
            chatRoomUseCase: chatRoomUseCase,
            chatId: .invalid
        )
        
        let shouldShowAddParticipantsScreen = participantsAddingViewFactory.hasNonAddedVisibleContacts(withExcludedHandles: [])
        XCTAssertFalse(shouldShowAddParticipantsScreen)
    }
}
