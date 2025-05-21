@testable import MEGA
import MEGAAssets
import MEGADomain
import MEGADomainMock
import MEGAL10n
import XCTest

final class MeetingParticipantInfoViewModelTests: XCTestCase {
    
    @MainActor func testAction_onViewReady_MyselfAsModerator_ParticipantIsAModeratorAndIsInContactList() {
        let chatRoomUseCase = MockChatRoomUseCase(chatRoomEntity: ChatRoomEntity(), contactEmail: "test@email.com")
        let megaHandleUseCase = MockMEGAHandleUseCase(base64Handle: Base64HandleEntity(100))
        let contactsUseCase = MockContactsUseCase(contact: UserEntity(handle: 200))
        let viewModel = makeSUT(
            participant: Self.mockParticipant(isModerator: true),
            chatRoomUseCase: chatRoomUseCase,
            megaHandleUseCase: megaHandleUseCase,
            contactsUseCase: contactsUseCase
        )
        
        test(viewModel: viewModel,
             action: .onViewReady,
             expectedCommands: [
                .configView(actions: [
                    infoAction(), sendMessageAction(), removeModeratorAction(), displayInMainViewAction(), removeContactAction()
                ]),
                .updateEmail(email: "test@email.com"),
                .updateName(name: "Test"),
                .updateAvatarImage(image: MEGAAssets.UIImage.iconContacts)
             ])
    }
    
    @MainActor func testAction_onViewReady_MyselfAsModerator_ParticipantIsAModeratorAndNotInContactList() {
        let chatRoomUseCase = MockChatRoomUseCase(chatRoomEntity: ChatRoomEntity(), contactEmail: "test@email.com")
        let megaHandleUseCase = MockMEGAHandleUseCase(base64Handle: Base64HandleEntity(100))

        let viewModel = makeSUT(
            participant: Self.mockParticipant(isModerator: true),
            chatRoomUseCase: chatRoomUseCase,
            megaHandleUseCase: megaHandleUseCase
        )
        
        test(viewModel: viewModel,
             action: .onViewReady,
             expectedCommands: [
                .configView(actions: [
                    removeModeratorAction(), displayInMainViewAction(), removeContactAction()
                ]),
                .updateEmail(email: "test@email.com"),
                .updateName(name: "Test"),
                .updateAvatarImage(image: MEGAAssets.UIImage.iconContacts)
             ])
    }
    
    @MainActor func testAction_onViewReady_MyselfAsModerator_ParticipantIsNotAModeratorAndAlsoInContactList() {
        let chatRoomUseCase = MockChatRoomUseCase(chatRoomEntity: ChatRoomEntity(), contactEmail: "test@email.com")
        let megaHandleUseCase = MockMEGAHandleUseCase(base64Handle: Base64HandleEntity(100))
        let contactsUseCase = MockContactsUseCase(contact: UserEntity(handle: 200))

        let viewModel = makeSUT(
            chatRoomUseCase: chatRoomUseCase,
            megaHandleUseCase: megaHandleUseCase,
            contactsUseCase: contactsUseCase
        )
        
        test(viewModel: viewModel,
             action: .onViewReady,
             expectedCommands: [
                .configView(actions: [
                    infoAction(), sendMessageAction(), makeModeratorAction(), displayInMainViewAction(), removeContactAction()
                ]),
                .updateEmail(email: "test@email.com"),
                .updateName(name: "Test"),
                .updateAvatarImage(image: MEGAAssets.UIImage.iconContacts)
             ])
    }
    
    @MainActor func testAction_onViewReady_MyselfAsModerator_ParticipantIsNotAModeratorAndNotInContactList() {
        let chatRoomUseCase = MockChatRoomUseCase(chatRoomEntity: ChatRoomEntity())
        let megaHandleUseCase = MockMEGAHandleUseCase(base64Handle: Base64HandleEntity(100))

        let viewModel = makeSUT(
            chatRoomUseCase: chatRoomUseCase,
            megaHandleUseCase: megaHandleUseCase
        )
        
        test(viewModel: viewModel,
             action: .onViewReady,
             expectedCommands: [
                .configView(actions: [
                    makeModeratorAction(), displayInMainViewAction(), removeContactAction()
                ]),
                .updateEmail(email: nil),
                .updateName(name: "Test"),
                .updateAvatarImage(image: MEGAAssets.UIImage.iconContacts)
             ])
    }
    
    @MainActor func testAction_onViewReady_MyselfAsParticipant_ParticipantIsNotAModeratorAndAlsoInContactList() {
        let chatRoomUseCase = MockChatRoomUseCase(chatRoomEntity: ChatRoomEntity(), contactEmail: "test@email.com")
        let megaHandleUseCase = MockMEGAHandleUseCase(base64Handle: Base64HandleEntity(100))
        let contactsUseCase = MockContactsUseCase(contact: UserEntity(handle: 200))

        let viewModel = makeSUT(
            chatRoomUseCase: chatRoomUseCase,
            megaHandleUseCase: megaHandleUseCase,
            contactsUseCase: contactsUseCase,
            isMyselfModerator: false
        )
        
        test(viewModel: viewModel,
             action: .onViewReady,
             expectedCommands: [
                .configView(actions: [
                    infoAction(), sendMessageAction(), displayInMainViewAction()
                ]),
                .updateEmail(email: "test@email.com"),
                .updateName(name: "Test"),
                .updateAvatarImage(image: MEGAAssets.UIImage.iconContacts)
             ])
    }
    
    @MainActor func testAction_onViewReady_MyselfAsParticipant_ParticipantIsNotAModeratorAndNotInContactList() {
        let chatRoomUseCase = MockChatRoomUseCase(chatRoomEntity: ChatRoomEntity(), contactEmail: "test@email.com")
        let chatRoomUserUseCase = MockChatRoomUserUseCase(userDisplayNameForPeerResult: .success("Test"), contactEmail: "test@email.com")
        let megaHandleUseCase = MockMEGAHandleUseCase(base64Handle: Base64HandleEntity(100))

        let viewModel = makeSUT(
            chatRoomUseCase: chatRoomUseCase,
            chatRoomUserUseCase: chatRoomUserUseCase,
            megaHandleUseCase: megaHandleUseCase,
            isMyselfModerator: false
        )
        
        test(viewModel: viewModel,
             action: .onViewReady,
             expectedCommands: [
                .configView(actions: [
                    displayInMainViewAction()
                ]),
                .updateEmail(email: "test@email.com"),
                .updateName(name: "Test"),
                .updateAvatarImage(image: MEGAAssets.UIImage.iconContacts)
             ])
    }
    
    @MainActor func testAction_onViewReady_ParticipantIsAGuest() {
        let chatRoomUseCase = MockChatRoomUseCase(chatRoomEntity: ChatRoomEntity(), contactEmail: nil)
        let megaHandleUseCase = MockMEGAHandleUseCase(base64Handle: Base64HandleEntity(100))
   
        let viewModel = makeSUT(
            chatRoomUseCase: chatRoomUseCase,
            megaHandleUseCase: megaHandleUseCase
        )
        
        test(viewModel: viewModel,
             action: .onViewReady,
             expectedCommands: [
                .configView(actions: [
                    makeModeratorAction(), displayInMainViewAction(), removeContactAction()
                ]),
                .updateEmail(email: nil),
                .updateName(name: "Test"),
                .updateAvatarImage(image: MEGAAssets.UIImage.iconContacts)
             ])
    }
    
    @MainActor func testAction_showInfo() {
        let router = MockMeetingParticipantInfoViewRouter()
        let viewModel = makeSUT(router: router)
        viewModel.dispatch(.showInfo)
        XCTAssert(router.showInfo_calledTimes == 1)
    }
    
    @MainActor func testSendMessage_chatRoomExists_shouldOpenChatRoom() {
        let chatRoomEntity = ChatRoomEntity(ownPrivilege: .moderator, chatType: .meeting)
        let chatRoomUseCase = MockChatRoomUseCase(chatRoomEntity: chatRoomEntity)
        let router = MockMeetingParticipantInfoViewRouter()
        
        let viewModel = makeSUT(chatRoomUseCase: chatRoomUseCase,
                                isMyselfModerator: true,
                                router: router)
        viewModel.dispatch(.sendMessage)
        XCTAssert(router.openChatRoom_calledTimes == 1)
    }
    
    @MainActor func testSendMessage_noChatRoomExists_shouldCreateAndOpenNewChatRoom() {
        let chatRoomEntity = ChatRoomEntity(ownPrivilege: .moderator, chatType: .meeting)
        let chatRoomUseCase = MockChatRoomUseCase(createChatRoomResult: .success(chatRoomEntity))
        let router = MockMeetingParticipantInfoViewRouter()
        let expectation = expectation(description: #function)
        router.createChatRoomCompletion = { newChatRoom in
            expectation.fulfill()
            XCTAssert(router.openChatRoom_calledTimes == 1)
            XCTAssertEqual(chatRoomEntity, newChatRoom)
        }
                
        let viewModel = makeSUT(chatRoomUseCase: chatRoomUseCase, router: router)
        viewModel.dispatch(.sendMessage)
        wait(for: [expectation], timeout: 1)
    }

    @MainActor func testAction_makeModerator() {
        let router = MockMeetingParticipantInfoViewRouter()
        
        let viewModel = makeSUT(router: router)
        viewModel.dispatch(.makeModerator)
        XCTAssert(router.makeParticipantAsModerator_calledTimes == 1)
    }
    
    @MainActor func testAction_removeParticipant() {
        let router = MockMeetingParticipantInfoViewRouter()
        let viewModel = makeSUT(router: router)
        
        viewModel.dispatch(.removeParticipant)
        XCTAssert(router.removeParticipant_calledTimes == 1)
    }
    
    @MainActor func testAction_displayInMainView() {
        let router = MockMeetingParticipantInfoViewRouter()
        let viewModel = makeSUT(router: router)
        
        viewModel.dispatch(.displayInMainView)
        XCTAssert(router.displayInMainView_calledTimes == 1)
    }
    
    @MainActor func testAction_muteParticipant_shouldShowActionSheetForMuteParticipant() {
        let router = MockMeetingParticipantInfoViewRouter()
        let viewModel = makeSUT(router: router)
        
        viewModel.dispatch(.muteParticipant)
        XCTAssert(router.muteParticipant_calledTimes == 1)
    }
    
    @MainActor func testAction_onViewReadyAndMyselfAsModerator_participantIsNotMutedAndNotInContactList() {
        let participant = CallParticipantEntity(chatId: 100, participantId: 100, clientId: 100, isModerator: true, audio: .on, canReceiveVideoHiRes: true)
        let chatRoomUseCase = MockChatRoomUseCase(chatRoomEntity: ChatRoomEntity())
        let megaHandleUseCase = MockMEGAHandleUseCase(base64Handle: Base64HandleEntity(100))
    
        let viewModel = makeSUT(
            participant: participant,
            chatRoomUseCase: chatRoomUseCase,
            megaHandleUseCase: megaHandleUseCase
        )
        
        test(viewModel: viewModel,
             action: .onViewReady,
             expectedCommands: [
                .configView(actions: [
                    muteParticipantAction(), removeModeratorAction(), displayInMainViewAction(), removeContactAction()
                ]),
                .updateEmail(email: nil),
                .updateName(name: "Test"),
                .updateAvatarImage(image: MEGAAssets.UIImage.iconContacts)
             ]
        )
    }
    
    // MARK: - Private methods
    
    private static func mockParticipant(isModerator: Bool) -> CallParticipantEntity {
        CallParticipantEntity(
            chatId: 100,
            participantId: 100,
            clientId: 100,
            isModerator: isModerator,
            canReceiveVideoHiRes: true
        )
    }
    
    private static func mockChatRoomUserUseCase() -> MockChatRoomUserUseCase {
        MockChatRoomUserUseCase(userDisplayNameForPeerResult: .success("Test"))
    }
    
    @MainActor private func makeSUT(
        participant: CallParticipantEntity = mockParticipant(isModerator: false),
        userImageUseCase: some UserImageUseCaseProtocol = MockUserImageUseCase(),
        chatRoomUseCase: some ChatRoomUseCaseProtocol = MockChatRoomUseCase(),
        chatRoomUserUseCase: some ChatRoomUserUseCaseProtocol = mockChatRoomUserUseCase(),
        megaHandleUseCase: some MEGAHandleUseCaseProtocol = MockMEGAHandleUseCase(),
        contactsUseCase: some ContactsUseCaseProtocol = MockContactsUseCase(),
        isMyselfModerator: Bool = true,
        router: some MeetingParticipantInfoViewRouting = MockMeetingParticipantInfoViewRouter()
    ) -> MeetingParticipantInfoViewModel {
        let sut = MeetingParticipantInfoViewModel(
            participant: participant,
            userImageUseCase: userImageUseCase,
            chatRoomUseCase: chatRoomUseCase,
            chatRoomUserUseCase: chatRoomUserUseCase,
            megaHandleUseCase: megaHandleUseCase,
            contactsUseCase: contactsUseCase,
            isMyselfModerator: isMyselfModerator,
            router: router
        )
        trackForMemoryLeaks(on: sut)
        return sut
    }
    
    private func infoAction() -> ActionSheetAction {
        ActionSheetAction(title: Strings.Localizable.info,
                          detail: nil,
                          image: MEGAAssets.UIImage.infoMeetings,
                          style: .default) {}
    }
    
    private func sendMessageAction() -> ActionSheetAction {
        ActionSheetAction(title: Strings.Localizable.sendMessage,
                          detail: nil,
                          image: MEGAAssets.UIImage.sendMessageMeetings,
                          style: .default) {}
    }
    
    private func makeModeratorAction() -> ActionSheetAction {
        ActionSheetAction(title: Strings.Localizable.Meetings.Participant.makeModerator,
                          detail: nil,
                          image: MEGAAssets.UIImage.moderatorMeetings,
                          style: .default) {}
    }
    
    private func removeModeratorAction() -> ActionSheetAction {
        ActionSheetAction(title: Strings.Localizable.Meetings.Participant.removeModerator,
                          detail: nil,
                          image: MEGAAssets.UIImage.removeModerator,
                          style: .default) {}
    }
    
    private func addContactAction() -> ActionSheetAction {
        ActionSheetAction(title: Strings.Localizable.addContact,
                          detail: nil,
                          image: MEGAAssets.UIImage.addContactMeetings,
                          style: .default) {}
    }
    
    private func removeContactAction() -> ActionSheetAction {
        ActionSheetAction(title: Strings.Localizable.removeParticipant,
                          detail: nil,
                          image: MEGAAssets.UIImage.delete,
                          style: .destructive) {}
    }
    
    private func displayInMainViewAction() -> ActionSheetAction {
        ActionSheetAction(title: Strings.Localizable.Meetings.DisplayInMainView.title,
                          detail: nil,
                          image: MEGAAssets.UIImage.speakerView,
                          style: .default) {}
    }
    
    private func muteParticipantAction() -> ActionSheetAction {
        ActionSheetAction(title: Strings.Localizable.Calls.Panel.ParticipantsInCall.ParticipantContextMenu.Actions.mute,
                          detail: nil,
                          image: MEGAAssets.UIImage.muteParticipant,
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
    
    var createChatRoomCompletion: ((ChatRoomEntity) -> Void)?

    nonisolated init() {}
    
    func showInfo(withEmail email: String?) {
        showInfo_calledTimes += 1
    }
    
    func openChatRoom(_ chatRoom: ChatRoomEntity) {
        openChatRoom_calledTimes += 1
        createChatRoomCompletion?(chatRoom)
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
