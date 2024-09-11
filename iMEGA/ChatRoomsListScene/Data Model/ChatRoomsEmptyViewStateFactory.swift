import MEGAL10n
import SwiftUI

struct ChatRoomsEmptyViewStateFactory {
    var designTokenEnabled: Bool
    
    struct ChatEmptyViewActions {
        var startMeeting: () -> Void
        var scheduleMeeting: () -> Void
        var inviteFriend: () -> Void
        var newChat: () -> Void
        var linkTappedAction: () -> Void
        
        static let preview = ChatEmptyViewActions(
            startMeeting: {},
            scheduleMeeting: {},
            inviteFriend: {},
            newChat: {},
            linkTappedAction: {}
        )
    }
    
    init() {
        self.designTokenEnabled = true
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
            show: hasArchivedChats,
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
        actions: ChatEmptyViewActions,
        bottomButtonMenus: [MenuButtonModel.Menu]
    ) -> ChatRoomsEmptyViewState {
        newEmptyChatRoomsViewState(
            chatViewMode: chatViewMode,
            hasContacts: hasContacts,
            actions: actions
        )
    }
    
    private func chatsTabBottomButtons(
        hasContacts: Bool,
        actions: ChatEmptyViewActions
    ) -> [MenuButtonModel] {
        let invite = MenuButtonModel(
            theme: .dark,
            title: Strings.Localizable.Chat.Chats.EmptyState.V2.Button.Invite.title,
            interaction: .action(actions.inviteFriend),
            isDesignTokenEnabled: designTokenEnabled
        )
        let newChat = MenuButtonModel(
            theme: .light,
            title: Strings.Localizable.Chat.Chats.EmptyState.Button.title,
            interaction: .action(actions.newChat),
            isDesignTokenEnabled: designTokenEnabled
        )
        
        return if hasContacts {
            [newChat]
        } else {
            [invite, newChat]
        }
    }
    
    private func meetingsTabBottomButtons(
        actions: ChatEmptyViewActions
    ) -> [MenuButtonModel] {
        let startMeeting = MenuButtonModel(
            theme: .dark,
            title: Strings.Localizable.Chat.Meetings.EmptyState.V2.Button.startMeetingNow,
            interaction: .action(actions.startMeeting),
            isDesignTokenEnabled: designTokenEnabled
        )
        let scheduleMeeting = MenuButtonModel(
            theme: .light,
            title: Strings.Localizable.Chat.Meetings.EmptyState.V2.Button.scheduleMeeting,
            interaction: .action(actions.scheduleMeeting),
            isDesignTokenEnabled: designTokenEnabled
        )
        
        return [startMeeting, scheduleMeeting]
    }
    
    private func emptyChatBottomButtons(
        chatViewMode: ChatViewMode,
        hasContacts: Bool,
        actions: ChatEmptyViewActions
    ) -> [MenuButtonModel] {
        let buttons: () -> [MenuButtonModel] = {
            switch chatViewMode {
            case .chats: chatsTabBottomButtons(hasContacts: hasContacts, actions: actions)
            case .meetings: meetingsTabBottomButtons(actions: actions)
            }
        }
        
        let themes: [MenuButtonModel.Theme] = [.dark, .light]
        
        // zipping here to guarantee first button is dark
        // and second button is light, even if there's single button in the array
        return zip(buttons(), themes).map { button, theme in
            button.applying(theme: theme)
        }
    }
    
    private func center(
        chatViewMode: ChatViewMode,
        actions: ChatEmptyViewActions
    ) -> ChatRoomsEmptyCenterViewState {
        switch chatViewMode {
        case .chats:
                .init(
                    image: .chatEmptyStateNew,
                    title: Strings.Localizable.Chat.Chats.EmptyState.V2.title,
                    titleBold: true,
                    description: Strings.Localizable.Chat.Chats.EmptyState.V2.description,
                    linkTapped: actions.linkTappedAction
                )
        case .meetings:
                .init(
                    image: .meetingsEmptyStateNew,
                    title: Strings.Localizable.Chat.Meetings.EmptyState.V2.title,
                    titleBold: true,
                    description: Strings.Localizable.Chat.Meetings.EmptyState.V2.description,
                    linkTapped: actions.linkTappedAction
                )
        }
    }
    
    private func newEmptyChatRoomsViewState(
        chatViewMode: ChatViewMode,
        hasContacts: Bool,
        actions: ChatEmptyViewActions
    ) -> ChatRoomsEmptyViewState {
        .init(
            topRows: [],
            center: center(
                chatViewMode: chatViewMode,
                actions: actions
            ),
            bottomButtons: emptyChatBottomButtons(
                chatViewMode: chatViewMode,
                hasContacts: hasContacts,
                actions: actions
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
        emptyViewState: ChatRoomsEmptyViewStateFactory()
            .noNetworkEmptyViewState(
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
        emptyViewState: ChatRoomsEmptyViewStateFactory()
            .emptyChatRoomsViewState(
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
            actions: .preview,
            bottomButtonMenus: []
        )
    )
}

#Preview("EmptyChats-DT") {
    ChatRoomsEmptyView(
        emptyViewState: ChatRoomsEmptyViewStateFactory()
            .emptyChatRoomsViewState(
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
            actions: .preview,
            bottomButtonMenus: []
        )
    )
}

#Preview("EmptyMeetings-NonDT") {
    ChatRoomsEmptyView(
        emptyViewState: ChatRoomsEmptyViewStateFactory()
            .emptyChatRoomsViewState(
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
            actions: .preview,
            bottomButtonMenus: []
        )
    )
}

#Preview("EmptyMeetings-DT") {
    ChatRoomsEmptyView(
        emptyViewState: ChatRoomsEmptyViewStateFactory()
            .emptyChatRoomsViewState(
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
            actions: .preview,
            bottomButtonMenus: []
        )
    )
}

#Preview("NewEmptyChats-DT") {
    NewChatRoomsEmptyView(
        state: ChatRoomsEmptyViewStateFactory()
            .emptyChatRoomsViewState(
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
            actions: .preview,
            bottomButtonMenus: []
        )
    )
}

#Preview("EmptySearch-NonDT") {
    ChatRoomsEmptyView(
        emptyViewState: ChatRoomsEmptyViewStateFactory().searchEmptyViewState()
    )
}

#Preview("EmptySearch-DT") {
    ChatRoomsEmptyView(
        emptyViewState: ChatRoomsEmptyViewStateFactory().searchEmptyViewState()
    )
}
