import MEGAL10n
import SwiftUI

struct ChatRoomsEmptyViewStateFactory {
    var newEmptyStates: Bool
    var designTokenEnabled: Bool
    init(
        newEmptyStates: Bool,
        designTokenEnabled: Bool
    ) {
        self.newEmptyStates = newEmptyStates
        self.designTokenEnabled = designTokenEnabled
    }
    
    func searchEmptyViewState() -> ChatRoomsEmptyViewState {
        .init(
            topRows: [],
            center: .init(
                image: .searchEmptyState,
                title: Strings.Localizable.noResults,
                description: nil
            ),
            bottomButtons: []
        )
    }
    
    private func topRows(
        hasArchivedChats: Bool,
        showInviteRow: Bool,
        contactsOnMega: ChatRoomsTopRowViewState,
        archivedChats: ChatRoomsTopRowViewState
    ) -> [ChatRoomsTopRowViewState] {
        
        struct TopRow {
            var show: Bool // if this is true, compact map will return `state`
            var state: ChatRoomsTopRowViewState
        }
        let contacts = TopRow(
            show: showInviteRow,
            state: contactsOnMega
        )
        // we do not show archived row in new chat empty screens
        let archived = TopRow(
            show: hasArchivedChats && !newEmptyStates,
            state: archivedChats
        )
        // what we do here, is :
        // to show given top row, we check if a `show` flag is true
        // and collect results `state` and return the IN ORDER
        // this is simpler than long switch statement with 4 cases
        return [archived, contacts].compactMap { topRow in
            if topRow.show {
                topRow.state
            } else {
                nil
            }
        }
    }
    
    func noNetworkEmptyViewState(
        hasArchivedChats: Bool,
        chatViewMode: ChatViewMode,
        contactsOnMega: ChatRoomsTopRowViewState,
        archivedChats: ChatRoomsTopRowViewState
    ) -> ChatRoomsEmptyViewState {
        
        let isChatViewMode = chatViewMode == .chats
        
        func center() -> ChatRoomsEmptyCenterViewState {
            
            .init(
                image: .noInternetEmptyState,
                title: isChatViewMode ?
                    Strings.Localizable.Chat.Chats.EmptyState.title :
                    Strings.Localizable.Chat.Meetings.EmptyState.title,
                description: isChatViewMode ? Strings.Localizable.Chat.Chats.EmptyState.description : Strings.Localizable.Chat.Meetings.EmptyState.description
            )
        }
        
        return .init(
            topRows: topRows(
                hasArchivedChats: hasArchivedChats,
                showInviteRow: isChatViewMode,
                contactsOnMega: contactsOnMega,
                archivedChats: archivedChats
            ),
            center: center(),
            bottomButtons: []
        )
    }
    
    func emptyChatRoomsViewState(
        hasArchivedChats: Bool,
        hasContacts: Bool,
        chatViewMode: ChatViewMode,
        contactsOnMega: ChatRoomsTopRowViewState,
        archivedChats: ChatRoomsTopRowViewState,
        newChatAction: @escaping () -> Void,
        inviteFriendAction: @escaping () -> Void,
        linkTappedAction: @escaping () -> Void,
        bottomButtonMenus: [MenuButtonModel.Menu]
    ) -> ChatRoomsEmptyViewState {
        if newEmptyStates && chatViewMode == .chats {
            newEmptyChatRoomsViewState(
                hasArchivedChats: hasArchivedChats,
                chatViewMode: chatViewMode,
                hasContacts: hasContacts,
                contactsOnMega: contactsOnMega,
                archivedChats: archivedChats,
                newChatAction: newChatAction,
                inviteFriendAction: inviteFriendAction,
                linkTappedAction: linkTappedAction
            )
        } else {
            legacyEmptyChatRoomsViewState(
                hasArchivedChats: hasArchivedChats,
                chatViewMode: chatViewMode,
                contactsOnMega: contactsOnMega,
                archivedChats: archivedChats,
                bottomButtonAction: newChatAction,
                bottomButtonMenus: bottomButtonMenus
            )
        }
    }
    
    private func legacyEmptyChatRoomsViewState(
        hasArchivedChats: Bool,
        chatViewMode: ChatViewMode,
        contactsOnMega: ChatRoomsTopRowViewState,
        archivedChats: ChatRoomsTopRowViewState,
        bottomButtonAction: @escaping () -> Void,
        bottomButtonMenus: [MenuButtonModel.Menu]
    ) -> ChatRoomsEmptyViewState {
        
        let isChatViewMode = chatViewMode == .chats
        
        func center() -> ChatRoomsEmptyCenterViewState {
            .init(
                image: isChatViewMode  ? .chatEmptyState : .meetingEmptyState,
                title: isChatViewMode ? Strings.Localizable.Chat.Chats.EmptyState.title : Strings.Localizable.Chat.Meetings.EmptyState.title,
                description: isChatViewMode ? Strings.Localizable.Chat.Chats.EmptyState.description : Strings.Localizable.Chat.Meetings.EmptyState.description
            )
        }
        
        let interaction: () -> MenuButtonModel.Interaction = {
            if isChatViewMode {
                .action(bottomButtonAction)
            } else {
                .menu(bottomButtonMenus)
            }
        }
        
        let bottomButtons = [
            MenuButtonModel(
                title: isChatViewMode ? Strings.Localizable.Chat.Chats.EmptyState.Button.title : Strings.Localizable.Chat.Meetings.EmptyState.Button.title,
                interaction: interaction(),
                isDesignTokenEnabled: designTokenEnabled
            )
        ]
        
        return .init(
            topRows: topRows(
                hasArchivedChats: hasArchivedChats,
                showInviteRow: isChatViewMode,
                contactsOnMega: contactsOnMega,
                archivedChats: archivedChats
            ),
            center: center(),
            bottomButtons: bottomButtons
        )
    }
    
    private func emptyChatBottomButtons(
        hasContacts: Bool,
        inviteAction: @escaping () -> Void,
        newChatAction: @escaping () -> Void
    ) -> [MenuButtonModel] {
        let invite = MenuButtonModel(
            theme: .dark,
            title: Strings.Localizable.Chat.Chats.EmptyState.V2.Button.Invite.title,
            interaction: .action(inviteAction),
            isDesignTokenEnabled: designTokenEnabled
        )
        let newChat = MenuButtonModel(
            theme: .light,
            title: Strings.Localizable.Chat.Chats.EmptyState.Button.title,
            interaction: .action(newChatAction),
            isDesignTokenEnabled: designTokenEnabled
        )
        
        let themes: [MenuButtonModel.Theme] = [
            .dark, .light
        ]
        
        let buttons = if hasContacts {
            [newChat]
        } else {
            [invite, newChat]
        }
        
        // zipping here to guarantee first button is dark
        // and second button is light, even if there's single button in the array
        return zip(buttons, themes).map { button, theme in
            button.applying(theme: theme)
        }
    }
    
    private func newEmptyChatRoomsViewState(
        hasArchivedChats: Bool,
        chatViewMode: ChatViewMode,
        hasContacts: Bool,
        contactsOnMega: ChatRoomsTopRowViewState,
        archivedChats: ChatRoomsTopRowViewState,
        newChatAction: @escaping () -> Void,
        inviteFriendAction: @escaping () -> Void,
        linkTappedAction: @escaping () -> Void
    ) -> ChatRoomsEmptyViewState {
        
        func center() -> ChatRoomsEmptyCenterViewState {
            .init(
                image: .chatEmptyStateNew,
                title: Strings.Localizable.Chat.Chats.EmptyState.V2.title,
                titleBold: true,
                description: Strings.Localizable.Chat.Chats.EmptyState.V2.description,
                linkTapped: linkTappedAction
            )
        }
        
        return .init(
            topRows: topRows(
                hasArchivedChats: hasArchivedChats,
                showInviteRow: false,
                contactsOnMega: contactsOnMega,
                archivedChats: archivedChats
            ),
            center: center(),
            bottomButtons: emptyChatBottomButtons(
                hasContacts: hasContacts,
                inviteAction: inviteFriendAction,
                newChatAction: newChatAction
            )
        )
    }
    
    func newChatContactsEmptyScreen(
        goToInvite: @escaping () -> Void
    ) -> ChatRoomsEmptyViewState {
        .init(
            topRows: [],
            center: .init(
                image: .newChatEmptyContacts,
                title: Strings.Localizable.Chat.Chats.EmptyState.V2.Button.Invite.title,
                titleBold: true,
                description: Strings.Localizable.Chat.NewChat.EmptyState.description,
                linkTapped: nil
            ),
            bottomButtons: [
                .init(
                    theme: .dark,
                    title: Strings.Localizable.invite,
                    interaction: .action(goToInvite),
                    isDesignTokenEnabled: designTokenEnabled
                )
            ]
        )
        
    }
}

#Preview("Offline") {
    ChatRoomsEmptyView(
        emptyViewState: ChatRoomsEmptyViewStateFactory(
            newEmptyStates: false,
            designTokenEnabled: true
        ).noNetworkEmptyViewState(
            hasArchivedChats: true,
            chatViewMode: .chats,
            contactsOnMega: .contactsOnMega(
                designTokenEnabled: true,
                action: {}
            ),
            archivedChats: .archivedChatsViewState(
                count: 1,
                action: {}
            )
        )
    )
}

#Preview("EmptyChats-NonDt") {
    ChatRoomsEmptyView(
        emptyViewState: ChatRoomsEmptyViewStateFactory(
            newEmptyStates: false,
            designTokenEnabled: false
        ).emptyChatRoomsViewState(
            hasArchivedChats: true,
            hasContacts: false,
            chatViewMode: .chats,
            contactsOnMega: .contactsOnMega(
                designTokenEnabled: false,
                action: {}
            ),
            archivedChats: .archivedChatsViewState(
                count: 1,
                action: {}
            ),
            newChatAction: {},
            inviteFriendAction: {},
            linkTappedAction: {},
            bottomButtonMenus: []
        )
    )
}

#Preview("EmptyChats-DT") {
    ChatRoomsEmptyView(
        emptyViewState: ChatRoomsEmptyViewStateFactory(
            newEmptyStates: false,
            designTokenEnabled: true
        ).emptyChatRoomsViewState(
            hasArchivedChats: true,
            hasContacts: false,
            chatViewMode: .chats,
            contactsOnMega: .contactsOnMega(
                designTokenEnabled: false,
                action: {}
            ),
            archivedChats: .archivedChatsViewState(
                count: 1,
                action: {}
            ),
            newChatAction: {},
            inviteFriendAction: {},
            linkTappedAction: {},
            bottomButtonMenus: []
        )
    )
}

#Preview("EmptyMeetings-NonDT") {
    ChatRoomsEmptyView(
        emptyViewState: ChatRoomsEmptyViewStateFactory(
            newEmptyStates: false,
            designTokenEnabled: false
        ).emptyChatRoomsViewState(
            hasArchivedChats: true,
            hasContacts: false,
            chatViewMode: .meetings,
            contactsOnMega: .contactsOnMega(
                designTokenEnabled: false,
                action: {}
            ),
            archivedChats: .archivedChatsViewState(
                count: 1,
                action: {}
            ),
            newChatAction: {},
            inviteFriendAction: {},
            linkTappedAction: {},
            bottomButtonMenus: []
        )
    )
}

#Preview("EmptyMeetings-DT") {
    ChatRoomsEmptyView(
        emptyViewState: ChatRoomsEmptyViewStateFactory(
            newEmptyStates: false,
            designTokenEnabled: true
        ).emptyChatRoomsViewState(
            hasArchivedChats: true,
            hasContacts: false,
            chatViewMode: .meetings,
            contactsOnMega: .contactsOnMega(
                designTokenEnabled: false,
                action: {}
            ),
            archivedChats: .archivedChatsViewState(
                count: 1,
                action: {}
            ),
            newChatAction: {},
            inviteFriendAction: {},
            linkTappedAction: {},
            bottomButtonMenus: []
        )
    )
}

#Preview("NewEmptyChats-DT") {
    NewChatRoomsEmptyView(
        state: ChatRoomsEmptyViewStateFactory(
            newEmptyStates: true,
            designTokenEnabled: true
        ).emptyChatRoomsViewState(
            hasArchivedChats: true,
            hasContacts: false,
            chatViewMode: .chats,
            contactsOnMega: .contactsOnMega(
                designTokenEnabled: false,
                action: {}
            ),
            archivedChats: .archivedChatsViewState(
                count: 1,
                action: {}
            ),
            newChatAction: {},
            inviteFriendAction: {},
            linkTappedAction: {},
            bottomButtonMenus: []
        )
    )
}

#Preview("EmptySearch-NonDT") {
    ChatRoomsEmptyView(
        emptyViewState: ChatRoomsEmptyViewStateFactory(
            newEmptyStates: false,
            designTokenEnabled: false
        ).searchEmptyViewState()
    )
}

#Preview("EmptySearch-DT") {
    ChatRoomsEmptyView(
        emptyViewState: ChatRoomsEmptyViewStateFactory(
            newEmptyStates: false,
            designTokenEnabled: true
        ).searchEmptyViewState()
    )
}
