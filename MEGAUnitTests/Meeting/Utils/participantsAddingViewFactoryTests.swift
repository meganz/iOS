import XCTest
@testable import MEGA

final class ParticipantsAddingViewFactoryTests: XCTestCase {

    func test_shouldShowAddParticipantsScreen_hasNoVisibleContacts() {
        let participantsAddingViewFactory = ParticipantsAddingViewFactory(
            userUseCase: MockUserUseCase(contacts: []),
            chatRoomUseCase: MockChatRoomUseCase(),
            chatId: .invalid
        )
        
        let shouldShowAddParticipantsScreen = participantsAddingViewFactory.shouldShowAddParticipantsScreen(withExcludedHandles: [])
        XCTAssertTrue(shouldShowAddParticipantsScreen)
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
        
        let shouldShowAddParticipantsScreen = participantsAddingViewFactory.shouldShowAddParticipantsScreen(withExcludedHandles: [])
        XCTAssertTrue(shouldShowAddParticipantsScreen)
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
        
        let shouldShowAddParticipantsScreen = participantsAddingViewFactory.shouldShowAddParticipantsScreen(withExcludedHandles: [])
        XCTAssertFalse(shouldShowAddParticipantsScreen)
    }
}
