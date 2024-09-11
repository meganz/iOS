@testable import MEGA
import MEGAL10n
import XCTest

final class ChatRoomsEmptyViewStateFactoryTests: XCTestCase {
    class Harness {
        var sut: ChatRoomsEmptyViewStateFactory
        init() {
            sut = .init()
        }
        
        func chatEmptyState(
            hasArchivedChats: Bool = false,
            hasContacts: Bool = true,
            chatViewMode: ChatViewMode = .chats
        ) -> ChatRoomsEmptyViewState {
            let contactsOnMega = ChatRoomsTopRowViewState(
                id: "contacts",
                image: UIImage(),
                description: "contacts",
                rightDetail: nil,
                hasDivider: false,
                action: {}
            )
            let archivedChats = ChatRoomsTopRowViewState(
                id: "archived",
                image: UIImage(),
                description: "archived",
                rightDetail: nil,
                hasDivider: false,
                action: {}
            )
            return sut.emptyChatRoomsViewState(
                hasArchivedChats: hasArchivedChats,
                hasContacts: hasContacts,
                chatViewMode: chatViewMode,
                contactsOnMega: contactsOnMega,
                archivedChats: archivedChats,
                actions: .init(
                    startMeeting: { [weak self] in
                        self?.startMeetingActionCallCount += 1
                    },
                    scheduleMeeting: { [weak self] in
                        self?.scheduleMeetingActionCallCount += 1
                    },
                    inviteFriend: { [weak self] in
                        self?.inviteFriendActionCallCount += 1
                    },
                    newChat: { [weak self] in
                        self?.newChatActionCallCount += 1
                    },
                    linkTappedAction: { [weak self] in
                        self?.linkTappedActionCallCount += 1
                    }
                ),
                bottomButtonMenus: []
            )
        }
        
        func newChat() -> ChatRoomsEmptyViewState {
            sut.newChatContactsEmptyScreen { [weak self] in
                self?.inviteFriendActionCallCount += 1
            }
        }
        var startMeetingActionCallCount = 0
        var scheduleMeetingActionCallCount = 0
        var newChatActionCallCount = 0
        var inviteFriendActionCallCount = 0
        var linkTappedActionCallCount = 0
    }
    
    // keep string here since it's very long and makes code ineligible
    let inviteTitle = Strings.Localizable.Chat.Chats.EmptyState.V2.Button.Invite.title
    let newChatTitle = Strings.Localizable.Chat.Chats.EmptyState.Button.title
    let startMeetingTitle = Strings.Localizable.Chat.Meetings.EmptyState.V2.Button.startMeetingNow
    let scheduleMeetingTitle = Strings.Localizable.Chat.Meetings.EmptyState.V2.Button.scheduleMeeting
    
    func testChatEmpty_InviteButtonTapped_TriggersAction() throws {
        let harness = Harness()
        let state = harness.chatEmptyState(hasContacts: false)
        let button = try XCTUnwrap(state.bottomButtonWith(title: inviteTitle))
        button.triggerAction()
        XCTAssertEqual(harness.inviteFriendActionCallCount, 1)
    }
    
    func testChatEmpty_NewChatButtonTapped_TriggersAction() throws {
        let harness = Harness()
        let state = harness.chatEmptyState(hasContacts: false)
        let button = try XCTUnwrap(state.bottomButtonWith(title: newChatTitle))
        button.triggerAction()
        XCTAssertEqual(harness.newChatActionCallCount, 1)
    }
    
    func testChatEmpty_IfHasContacts_DoNotShowInvite() {
        let harness = Harness()
        let state = harness.chatEmptyState(hasContacts: true)
        XCTAssertNil(state.bottomButtonWith(title: inviteTitle))
    }
    
    func testChatEmpty_IfNoContacts_ShowInvite() {
        let harness = Harness()
        let state = harness.chatEmptyState(hasContacts: false)
        XCTAssertNotNil(state.bottomButtonWith(title: inviteTitle))
    }
    
    func testChatEmpty_NoContacts_TwoButtonsShown() {
        let harness = Harness()
        let state = harness.chatEmptyState(hasContacts: false)
        XCTAssertEqual(state.bottomButtonTitles, [inviteTitle, newChatTitle])
    }
    
    func testChatEmpty_CenterLinkTapped_ActionTriggered() {
        let harness = Harness()
        let state = harness.chatEmptyState()
        state.center.linkTapped?()
        XCTAssertEqual(harness.linkTappedActionCallCount, 1)
    }
    
    func testMeetingEmpty_StartMeetingTapped_ActionTriggered() throws {
        let harness = Harness()
        let state = harness.chatEmptyState(chatViewMode: .meetings)
        let button = try XCTUnwrap(state.bottomButtonWith(title: startMeetingTitle))
        button.triggerAction()
        XCTAssertEqual(harness.startMeetingActionCallCount, 1)
    }
    
    func testMeetingEmpty_ScheduleMeetingTapped_ActionTriggered() throws {
        let harness = Harness()
        let state = harness.chatEmptyState(chatViewMode: .meetings)
        let button = try XCTUnwrap(state.bottomButtonWith(title: scheduleMeetingTitle))
        button.triggerAction()
        XCTAssertEqual(harness.scheduleMeetingActionCallCount, 1)
    }
    
    func testMeetingEmpty_CenterLinkTapped_ActionTriggered() {
        let harness = Harness()
        let state = harness.chatEmptyState(chatViewMode: .meetings)
        state.center.linkTapped?()
        XCTAssertEqual(harness.linkTappedActionCallCount, 1)
    }
    
    func testNewChat_InviteTapped_TriggersAction() throws {
        let harness = Harness()
        let state = harness.newChat()
        let button = try XCTUnwrap(state.bottomButtonWith(title: Strings.Localizable.invite))
        button.triggerAction()
        XCTAssertEqual(harness.inviteFriendActionCallCount, 1)
    }
}

extension ChatRoomsEmptyViewState {
    func bottomButtonWith(title: String) -> MenuButtonModel? {
        bottomButtons.first(where: {
            $0.title == title
        })
    }
    
    var bottomButtonTitles: [String] {
        bottomButtons.map(\.title)
    }
}

extension MenuButtonModel {
    func triggerAction() {
        if case .action(let action) = self.interaction {
            action()
        }
    }
}
