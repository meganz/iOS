@testable import MEGA
import MEGADomain
import MEGADomainMock
import MEGAL10n
import XCTest

final class MeetingParticipantInfoViewModelTests: XCTestCase {
    
    @MainActor func testAction_onViewReady_MyselfAsModerator_ParticipantIsAModeratorAndIsInContactList() {
        let participant = CallParticipantEntity(chatId: 100, participantId: 100, clientId: 100, isModerator: true, canReceiveVideoHiRes: true)
        let chatRoomUseCase = MockChatRoomUseCase(chatRoomEntity: ChatRoomEntity(), contactEmail: "test@email.com")
        let chatRoomUserUseCase = MockChatRoomUserUseCase(userDisplayNameForPeerResult: .success("Test"))
        let userImageUseCase = MockUserImageUseCase()
        let megaHandleUseCase = MockMEGAHandleUseCase(base64Handle: Base64HandleEntity(100))
        let contactsUseCase = MockContactsUseCase(contact: UserEntity(handle: 200))
        let router = MockMeetingParticipantInfoViewRouter()

        let viewModel = MeetingParticipantInfoViewModel(participant: participant,
                                                        userImageUseCase: userImageUseCase,
                                                        chatRoomUseCase: chatRoomUseCase,
                                                        chatRoomUserUseCase: chatRoomUserUseCase,
                                                        megaHandleUseCase: megaHandleUseCase, 
                                                        contactsUseCase: contactsUseCase,
                                                        isMyselfModerator: true,
                                                        router: router)
        test(viewModel: viewModel,
             action: .onViewReady,
             expectedCommands: [
                .configView(actions: [
                    infoAction(), sendMessageAction(), removeModeratorAction(), displayInMainViewAction(), removeContactAction()
                ]),
                .updateEmail(email: "test@email.com"),
                .updateName(name: "Test"),
                .updateAvatarImage(image: UIImage.iconContacts)
             ])
    }
    
    @MainActor func testAction_onViewReady_MyselfAsModerator_ParticipantIsAModeratorAndNotInContactList() {
        let participant = CallParticipantEntity(chatId: 100, participantId: 100, clientId: 100, isModerator: true, canReceiveVideoHiRes: true)
        let chatRoomUseCase = MockChatRoomUseCase(chatRoomEntity: ChatRoomEntity(), contactEmail: "test@email.com")
        let chatRoomUserUseCase = MockChatRoomUserUseCase(userDisplayNameForPeerResult: .success("Test"))
        let userImageUseCase = MockUserImageUseCase()
        let megaHandleUseCase = MockMEGAHandleUseCase(base64Handle: Base64HandleEntity(100))
        let contactsUseCase = MockContactsUseCase()
        let router = MockMeetingParticipantInfoViewRouter()
        
        let viewModel = MeetingParticipantInfoViewModel(participant: participant,
                                                        userImageUseCase: userImageUseCase,
                                                        chatRoomUseCase: chatRoomUseCase,
                                                        chatRoomUserUseCase: chatRoomUserUseCase,
                                                        megaHandleUseCase: megaHandleUseCase, 
                                                        contactsUseCase: contactsUseCase,
                                                        isMyselfModerator: true,
                                                        router: router)
        test(viewModel: viewModel,
             action: .onViewReady,
             expectedCommands: [
                .configView(actions: [
                    removeModeratorAction(), displayInMainViewAction(), removeContactAction()
                ]),
                .updateEmail(email: "test@email.com"),
                .updateName(name: "Test"),
                .updateAvatarImage(image: UIImage.iconContacts)
             ])
    }
    
    @MainActor func testAction_onViewReady_MyselfAsModerator_ParticipantIsNotAModeratorAndAlsoInContactList() {
        let participant = CallParticipantEntity(chatId: 100, participantId: 100, clientId: 100, isModerator: false, canReceiveVideoHiRes: true)
        let chatRoomUseCase = MockChatRoomUseCase(chatRoomEntity: ChatRoomEntity(), contactEmail: "test@email.com")
        let chatRoomUserUseCase = MockChatRoomUserUseCase(userDisplayNameForPeerResult: .success("Test"))
        let userImageUseCase = MockUserImageUseCase()
        let megaHandleUseCase = MockMEGAHandleUseCase(base64Handle: Base64HandleEntity(100))
        let contactsUseCase = MockContactsUseCase(contact: UserEntity(handle: 200))
        let router = MockMeetingParticipantInfoViewRouter()
        
        let viewModel = MeetingParticipantInfoViewModel(participant: participant,
                                                        userImageUseCase: userImageUseCase,
                                                        chatRoomUseCase: chatRoomUseCase,
                                                        chatRoomUserUseCase: chatRoomUserUseCase,
                                                        megaHandleUseCase: megaHandleUseCase,
                                                        contactsUseCase: contactsUseCase,
                                                        isMyselfModerator: true,
                                                        router: router)
        
        test(viewModel: viewModel,
             action: .onViewReady,
             expectedCommands: [
                .configView(actions: [
                    infoAction(), sendMessageAction(), makeModeratorAction(), displayInMainViewAction(), removeContactAction()
                ]),
                .updateEmail(email: "test@email.com"),
                .updateName(name: "Test"),
                .updateAvatarImage(image: UIImage.iconContacts)
             ])
    }
    
    @MainActor func testAction_onViewReady_MyselfAsModerator_ParticipantIsNotAModeratorAndNotInContactList() {
        let participant = CallParticipantEntity(chatId: 100, participantId: 100, clientId: 100, isModerator: false, canReceiveVideoHiRes: true)
        let chatRoomUseCase = MockChatRoomUseCase(chatRoomEntity: ChatRoomEntity())
        let chatRoomUserUseCase = MockChatRoomUserUseCase(userDisplayNameForPeerResult: .success("Test"))
        let userImageUseCase = MockUserImageUseCase()
        let megaHandleUseCase = MockMEGAHandleUseCase(base64Handle: Base64HandleEntity(100))
        let contactsUseCase = MockContactsUseCase()
        let router = MockMeetingParticipantInfoViewRouter()
        
        let viewModel = MeetingParticipantInfoViewModel(participant: participant,
                                                        userImageUseCase: userImageUseCase,
                                                        chatRoomUseCase: chatRoomUseCase,
                                                        chatRoomUserUseCase: chatRoomUserUseCase,
                                                        megaHandleUseCase: megaHandleUseCase,
                                                        contactsUseCase: contactsUseCase,
                                                        isMyselfModerator: true,
                                                        router: router)
        
        test(viewModel: viewModel,
             action: .onViewReady,
             expectedCommands: [
                .configView(actions: [
                    makeModeratorAction(), displayInMainViewAction(), removeContactAction()
                ]),
                .updateEmail(email: nil),
                .updateName(name: "Test"),
                .updateAvatarImage(image: UIImage.iconContacts)
             ])
    }
    
    @MainActor func testAction_onViewReady_MyselfAsParticipant_ParticipantIsNotAModeratorAndAlsoInContactList() {
        let participant = CallParticipantEntity(chatId: 100, participantId: 100, clientId: 100, isModerator: false, canReceiveVideoHiRes: true)
        let chatRoomUseCase = MockChatRoomUseCase(chatRoomEntity: ChatRoomEntity(), contactEmail: "test@email.com")
        let chatRoomUserUseCase = MockChatRoomUserUseCase(userDisplayNameForPeerResult: .success("Test"))
        let userImageUseCase = MockUserImageUseCase()
        let megaHandleUseCase = MockMEGAHandleUseCase(base64Handle: Base64HandleEntity(100))
        let contactsUseCase = MockContactsUseCase(contact: UserEntity(handle: 200))
        let router = MockMeetingParticipantInfoViewRouter()
        
        let viewModel = MeetingParticipantInfoViewModel(participant: participant,
                                                        userImageUseCase: userImageUseCase,
                                                        chatRoomUseCase: chatRoomUseCase,
                                                        chatRoomUserUseCase: chatRoomUserUseCase,
                                                        megaHandleUseCase: megaHandleUseCase,
                                                        contactsUseCase: contactsUseCase,
                                                        isMyselfModerator: false,
                                                        router: router)
        
        test(viewModel: viewModel,
             action: .onViewReady,
             expectedCommands: [
                .configView(actions: [
                    infoAction(), sendMessageAction(), displayInMainViewAction()
                ]),
                .updateEmail(email: "test@email.com"),
                .updateName(name: "Test"),
                .updateAvatarImage(image: UIImage.iconContacts)
             ])
    }
    
    @MainActor func testAction_onViewReady_MyselfAsParticipant_ParticipantIsNotAModeratorAndNotInContactList() {
        let participant = CallParticipantEntity(chatId: 100, participantId: 100, clientId: 100, isModerator: false, canReceiveVideoHiRes: true)
        let chatRoomUseCase = MockChatRoomUseCase(chatRoomEntity: ChatRoomEntity(), contactEmail: "test@email.com")
        let chatRoomUserUseCase = MockChatRoomUserUseCase(userDisplayNameForPeerResult: .success("Test"), contactEmail: "test@email.com")
        let userImageUseCase = MockUserImageUseCase()
        let megaHandleUseCase = MockMEGAHandleUseCase(base64Handle: Base64HandleEntity(100))
        let contactsUseCase = MockContactsUseCase()
        let router = MockMeetingParticipantInfoViewRouter()
        
        let viewModel = MeetingParticipantInfoViewModel(participant: participant,
                                                        userImageUseCase: userImageUseCase,
                                                        chatRoomUseCase: chatRoomUseCase,
                                                        chatRoomUserUseCase: chatRoomUserUseCase,
                                                        megaHandleUseCase: megaHandleUseCase,
                                                        contactsUseCase: contactsUseCase,
                                                        isMyselfModerator: false,
                                                        router: router)
        test(viewModel: viewModel,
             action: .onViewReady,
             expectedCommands: [
                .configView(actions: [
                    displayInMainViewAction()
                ]),
                .updateEmail(email: "test@email.com"),
                .updateName(name: "Test"),
                .updateAvatarImage(image: UIImage.iconContacts)
             ])
    }
    
    @MainActor func testAction_onViewReady_ParticipantIsAGuest() {
        let participant = CallParticipantEntity(chatId: 100, participantId: 100, clientId: 100, isModerator: false, canReceiveVideoHiRes: true)
        let chatRoomUseCase = MockChatRoomUseCase(chatRoomEntity: ChatRoomEntity(), contactEmail: nil)
        let chatRoomUserUseCase = MockChatRoomUserUseCase(userDisplayNameForPeerResult: .success("Test"))
        let userImageUseCase = MockUserImageUseCase()
        let megaHandleUseCase = MockMEGAHandleUseCase(base64Handle: Base64HandleEntity(100))
        let contactsUseCase = MockContactsUseCase()
        let router = MockMeetingParticipantInfoViewRouter()
        
        let viewModel = MeetingParticipantInfoViewModel(participant: participant,
                                                        userImageUseCase: userImageUseCase,
                                                        chatRoomUseCase: chatRoomUseCase,
                                                        chatRoomUserUseCase: chatRoomUserUseCase,
                                                        megaHandleUseCase: megaHandleUseCase,
                                                        contactsUseCase: contactsUseCase,
                                                        isMyselfModerator: true,
                                                        router: router)
        
        test(viewModel: viewModel,
             action: .onViewReady,
             expectedCommands: [
                .configView(actions: [
                    makeModeratorAction(), displayInMainViewAction(), removeContactAction()
                ]),
                .updateEmail(email: nil),
                .updateName(name: "Test"),
                .updateAvatarImage(image: UIImage.iconContacts)
             ])
    }
    
    func testAction_showInfo() {
        let participant = CallParticipantEntity(chatId: 100, participantId: 100, clientId: 100, isModerator: false, canReceiveVideoHiRes: true)
        let chatRoomUseCase = MockChatRoomUseCase()
        let chatRoomUserUseCase = MockChatRoomUserUseCase(userDisplayNameForPeerResult: .success("Test"))
        let userImageUseCase = MockUserImageUseCase()
        let router = MockMeetingParticipantInfoViewRouter()
        
        let viewModel = MeetingParticipantInfoViewModel(participant: participant,
                                                        userImageUseCase: userImageUseCase,
                                                        chatRoomUseCase: chatRoomUseCase,
                                                        chatRoomUserUseCase: chatRoomUserUseCase,
                                                        megaHandleUseCase: MockMEGAHandleUseCase(),
                                                        contactsUseCase: MockContactsUseCase(),
                                                        isMyselfModerator: true,
                                                        router: router)
        
        viewModel.dispatch(.showInfo)
        XCTAssert(router.showInfo_calledTimes == 1)
    }
    
    func testAction_sendMessage() {
        let participant = CallParticipantEntity(chatId: 100, participantId: 100, clientId: 100, isModerator: false, canReceiveVideoHiRes: true)
        let chatRoomEntity = ChatRoomEntity(ownPrivilege: .moderator, chatType: .meeting)
        let chatRoomUseCase = MockChatRoomUseCase(chatRoomEntity: chatRoomEntity)
        let userImageUseCase = MockUserImageUseCase()
        let router = MockMeetingParticipantInfoViewRouter()
        
        let viewModel = MeetingParticipantInfoViewModel(participant: participant,
                                                        userImageUseCase: userImageUseCase,
                                                        chatRoomUseCase: chatRoomUseCase,
                                                        chatRoomUserUseCase: MockChatRoomUserUseCase(),
                                                        megaHandleUseCase: MockMEGAHandleUseCase(),
                                                        contactsUseCase: MockContactsUseCase(),
                                                        isMyselfModerator: true,
                                                        router: router)
        
        viewModel.dispatch(.sendMessage)
        XCTAssert(router.openChatRoom_calledTimes == 1)
    }
    
    func testAction_makeModerator() {
        let participant = CallParticipantEntity(chatId: 100, participantId: 100, clientId: 100, isModerator: false, canReceiveVideoHiRes: true)
        let chatRoomUseCase = MockChatRoomUseCase()
        let chatRoomUserUseCase = MockChatRoomUserUseCase(userDisplayNameForPeerResult: .success("Test"))
        let userImageUseCase = MockUserImageUseCase()
        let router = MockMeetingParticipantInfoViewRouter()
        
        let viewModel = MeetingParticipantInfoViewModel(participant: participant,
                                                        userImageUseCase: userImageUseCase,
                                                        chatRoomUseCase: chatRoomUseCase,
                                                        chatRoomUserUseCase: chatRoomUserUseCase,
                                                        megaHandleUseCase: MockMEGAHandleUseCase(),
                                                        contactsUseCase: MockContactsUseCase(),
                                                        isMyselfModerator: true,
                                                        router: router)
        
        viewModel.dispatch(.makeModerator)
        XCTAssert(router.makeParticipantAsModerator_calledTimes == 1)
    }
    
    func testAction_removeParticipant() {
        let participant = CallParticipantEntity(chatId: 100, participantId: 100, clientId: 100, isModerator: false, canReceiveVideoHiRes: true)
        let chatRoomUseCase = MockChatRoomUseCase()
        let chatRoomUserUseCase = MockChatRoomUserUseCase(userDisplayNameForPeerResult: .success("Test"))
        let userImageUseCase = MockUserImageUseCase()
        let router = MockMeetingParticipantInfoViewRouter()
        
        let viewModel = MeetingParticipantInfoViewModel(participant: participant,
                                                        userImageUseCase: userImageUseCase,
                                                        chatRoomUseCase: chatRoomUseCase,
                                                        chatRoomUserUseCase: chatRoomUserUseCase,
                                                        megaHandleUseCase: MockMEGAHandleUseCase(),
                                                        contactsUseCase: MockContactsUseCase(),
                                                        isMyselfModerator: true,
                                                        router: router)
        
        viewModel.dispatch(.removeParticipant)
        XCTAssert(router.removeParticipant_calledTimes == 1)
    }
    
    func testAction_displayInMainView() {
        let participant = CallParticipantEntity(chatId: 100, participantId: 100, clientId: 100, isModerator: false, canReceiveVideoHiRes: true)
        let chatRoomUseCase = MockChatRoomUseCase()
        let chatRoomUserUseCase = MockChatRoomUserUseCase(userDisplayNameForPeerResult: .success("Test"))
        let userImageUseCase = MockUserImageUseCase()
        let router = MockMeetingParticipantInfoViewRouter()
        
        let viewModel = MeetingParticipantInfoViewModel(participant: participant,
                                                        userImageUseCase: userImageUseCase,
                                                        chatRoomUseCase: chatRoomUseCase,
                                                        chatRoomUserUseCase: chatRoomUserUseCase,
                                                        megaHandleUseCase: MockMEGAHandleUseCase(),
                                                        contactsUseCase: MockContactsUseCase(),
                                                        isMyselfModerator: true,
                                                        router: router)
        
        viewModel.dispatch(.displayInMainView)
        XCTAssert(router.displayInMainView_calledTimes == 1)
    }
    
    func testAction_muteParticipant_shouldShowActionSheetForMuteParticipant() {
        let participant = CallParticipantEntity(chatId: 100, participantId: 100, clientId: 100, isModerator: false, canReceiveVideoHiRes: true)
        let chatRoomUseCase = MockChatRoomUseCase()
        let chatRoomUserUseCase = MockChatRoomUserUseCase(userDisplayNameForPeerResult: .success("Test"))
        let userImageUseCase = MockUserImageUseCase()
        let router = MockMeetingParticipantInfoViewRouter()
        
        let viewModel = MeetingParticipantInfoViewModel(
            participant: participant,
            userImageUseCase: userImageUseCase,
            chatRoomUseCase: chatRoomUseCase,
            chatRoomUserUseCase: chatRoomUserUseCase,
            megaHandleUseCase: MockMEGAHandleUseCase(), 
            contactsUseCase: MockContactsUseCase(),
            isMyselfModerator: true,
            router: router
        )
        
        viewModel.dispatch(.muteParticipant)
        XCTAssert(router.muteParticipant_calledTimes == 1)
    }
    
    @MainActor func testAction_onViewReadyAndMyselfAsModerator_participantIsNotMutedAndNotInContactList() {
        let participant = CallParticipantEntity(chatId: 100, participantId: 100, clientId: 100, isModerator: true, audio: .on, canReceiveVideoHiRes: true)
        let chatRoomUseCase = MockChatRoomUseCase(chatRoomEntity: ChatRoomEntity())
        let chatRoomUserUseCase = MockChatRoomUserUseCase(userDisplayNameForPeerResult: .success("Test"))
        let userImageUseCase = MockUserImageUseCase()
        let megaHandleUseCase = MockMEGAHandleUseCase(base64Handle: Base64HandleEntity(100))
        let router = MockMeetingParticipantInfoViewRouter()
        
        let viewModel = MeetingParticipantInfoViewModel(
            participant: participant,
            userImageUseCase: userImageUseCase,
            chatRoomUseCase: chatRoomUseCase,
            chatRoomUserUseCase: chatRoomUserUseCase,
            megaHandleUseCase: megaHandleUseCase, 
            contactsUseCase: MockContactsUseCase(),
            isMyselfModerator: true,
            router: router
        )
        
        test(viewModel: viewModel,
             action: .onViewReady,
             expectedCommands: [
                .configView(actions: [
                    muteParticipantAction(), removeModeratorAction(), displayInMainViewAction(), removeContactAction()
                ]),
                .updateEmail(email: nil),
                .updateName(name: "Test"),
                .updateAvatarImage(image: UIImage.iconContacts)
             ])
    }
    
    // MARK: - Private methods
    
    private func infoAction() -> ActionSheetAction {
        ActionSheetAction(title: Strings.Localizable.info,
                          detail: nil,
                          image: UIImage.infoMeetings,
                          style: .default) {}
    }
    
    private func sendMessageAction() -> ActionSheetAction {
        ActionSheetAction(title: Strings.Localizable.sendMessage,
                          detail: nil,
                          image: UIImage.sendMessageMeetings,
                          style: .default) {}
    }
    
    private func makeModeratorAction() -> ActionSheetAction {
        ActionSheetAction(title: Strings.Localizable.Meetings.Participant.makeModerator,
                          detail: nil,
                          image: UIImage.moderatorMeetings,
                          style: .default) {}
    }
    
    private func removeModeratorAction() -> ActionSheetAction {
        ActionSheetAction(title: Strings.Localizable.Meetings.Participant.removeModerator,
                          detail: nil,
                          image: UIImage.removeModerator,
                          style: .default) {}
    }
    
    private func addContactAction() -> ActionSheetAction {
        ActionSheetAction(title: Strings.Localizable.addContact,
                          detail: nil,
                          image: UIImage.addContactMeetings,
                          style: .default) {}
    }
    
    private func removeContactAction() -> ActionSheetAction {
        ActionSheetAction(title: Strings.Localizable.removeParticipant,
                          detail: nil,
                          image: UIImage.delete,
                          style: .destructive) {}
    }
    
    private func displayInMainViewAction() -> ActionSheetAction {
        ActionSheetAction(title: Strings.Localizable.Meetings.DisplayInMainView.title,
                          detail: nil,
                          image: UIImage.speakerView,
                          style: .default) {}
    }
    
    private func muteParticipantAction() -> ActionSheetAction {
        ActionSheetAction(title: Strings.Localizable.Calls.Panel.ParticipantsInCall.ParticipantContextMenu.Actions.mute,
                          detail: nil,
                          image: UIImage(resource: .muteParticipant),
                          style: .default) { }
    }
}

final class MockMeetingParticipantInfoViewRouter: MeetingParticipantInfoViewRouting {
    var showInfo_calledTimes = 0
    var openChatRoom_calledTimes = 0
    var showInviteSuccess_calledTimes = 0
    var showInviteErrorMessage_calledTimes = 0
    var makeParticipantAsModerator_calledTimes = 0
    var removeParticipantAsModerator_calledTimes = 0
    var removeParticipant_calledTimes = 0
    var displayInMainView_calledTimes = 0
    var muteParticipant_calledTimes = 0

    func showInfo(withEmail email: String?) {
        showInfo_calledTimes += 1
    }
    
    func openChatRoom(_ chatRoom: ChatRoomEntity) {
        openChatRoom_calledTimes += 1
    }
    
    func makeParticipantAsModerator() {
        makeParticipantAsModerator_calledTimes += 1
    }
        
    func removeModeratorPrivilege() {
        removeParticipantAsModerator_calledTimes += 1
    }
    
    func removeParticipant() {
        removeParticipant_calledTimes += 1
    }
    
    func displayInMainView() {
        displayInMainView_calledTimes += 1
    }
    
    func muteParticipant(_ participant: CallParticipantEntity) {
        muteParticipant_calledTimes += 1
    }
}
