import MEGAL10n
import SwiftUI

struct ChatRoomsEmptyViewStateFactory {
    let newEmptyStates: Bool
    
    init(
        // not used yet, part of ongoing [MEET-4054]
        newEmptyStates: Bool
    ) {
        self.newEmptyStates = newEmptyStates
    }
    
    func searchEmptyViewState() -> ChatRoomsEmptyViewState {
        ChatRoomsEmptyViewState(
            contactsOnMega: nil,
            archivedChats: nil,
            centerImageResource: .searchEmptyState,
            centerTitle: Strings.Localizable.noResults,
            centerDescription: nil,
            bottomButtonTitle: nil,
            bottomButtonAction: nil,
            bottomButtonMenus: nil
        )
    }
    
    func noNetworkEmptyViewState(
        chatViewMode: ChatViewMode,
        contactsOnMega: ChatRoomsTopRowViewState?,
        archivedChats: ChatRoomsTopRowViewState?
    ) -> ChatRoomsEmptyViewState {
        let isChatsViewMode = chatViewMode == .chats
        
        return ChatRoomsEmptyViewState(
            contactsOnMega: isChatsViewMode ? contactsOnMega : nil,
            archivedChats: archivedChats,
            centerImageResource: .noInternetEmptyState,
            centerTitle: isChatsViewMode ? Strings.Localizable.Chat.Chats.EmptyState.title : Strings.Localizable.Chat.Meetings.EmptyState.title,
            centerDescription: isChatsViewMode ? Strings.Localizable.Chat.Chats.EmptyState.description : Strings.Localizable.Chat.Meetings.EmptyState.description,
            bottomButtonTitle: nil,
            bottomButtonAction: nil,
            bottomButtonMenus: nil
        )
    }
    
    func emptyChatRoomsViewState(
        chatViewMode: ChatViewMode,
        contactsOnMega: ChatRoomsTopRowViewState?,
        archivedChats: ChatRoomsTopRowViewState?,
        bottomButtonAction: @escaping () -> Void,
        bottomButtonMenus: [ChatRoomsEmptyBottomButtonMenu]?
    ) -> ChatRoomsEmptyViewState {
        let isChatViewMode = chatViewMode == .chats
        
        return ChatRoomsEmptyViewState(
            contactsOnMega: isChatViewMode ? contactsOnMega : nil,
            archivedChats: archivedChats,
            centerImageResource: isChatViewMode  ? .chatEmptyState : .meetingEmptyState,
            centerTitle: isChatViewMode ? Strings.Localizable.Chat.Chats.EmptyState.title : Strings.Localizable.Chat.Meetings.EmptyState.title,
            centerDescription: isChatViewMode ? Strings.Localizable.Chat.Chats.EmptyState.description : Strings.Localizable.Chat.Meetings.EmptyState.description,
            bottomButtonTitle: isChatViewMode ? Strings.Localizable.Chat.Chats.EmptyState.Button.title : Strings.Localizable.Chat.Meetings.EmptyState.Button.title,
            bottomButtonAction: bottomButtonAction,
            bottomButtonMenus: bottomButtonMenus
        )
    }
}

#Preview("Offline") {
    ChatRoomsEmptyView(
        emptyViewState: ChatRoomsEmptyViewStateFactory(
            newEmptyStates: false
        ).noNetworkEmptyViewState(
            chatViewMode: .chats,
            contactsOnMega: .contactsOnMega(
                designTokenEnabled: true,
                action: {}
            ),
            archivedChats: .archivedChatsViewState(
                count: 1,
                action: {}
            )
        ),
        isDesignTokenEnabled: true
    )
}

#Preview("EmptyChats-NonDt") {
    ChatRoomsEmptyView(
        emptyViewState: ChatRoomsEmptyViewStateFactory(
            newEmptyStates: false
        ).emptyChatRoomsViewState(
            chatViewMode: .chats,
            contactsOnMega: .contactsOnMega(
                designTokenEnabled: false,
                action: {}
            ),
            archivedChats: .archivedChatsViewState(
                count: 1,
                action: {}
            ),
            bottomButtonAction: {},
            bottomButtonMenus: nil
        ),
        isDesignTokenEnabled: false
    )
}

#Preview("EmptyChats-DT") {
    ChatRoomsEmptyView(
        emptyViewState: ChatRoomsEmptyViewStateFactory(
            newEmptyStates: false
        ).emptyChatRoomsViewState(
            chatViewMode: .chats,
            contactsOnMega: .contactsOnMega(
                designTokenEnabled: true,
                action: {}
            ),
            archivedChats: .archivedChatsViewState(
                count: 1,
                action: {}
            ),
            bottomButtonAction: {},
            bottomButtonMenus: nil
        ),
        isDesignTokenEnabled: true
    )
}

#Preview("EmptyMeetings-NonDT") {
    ChatRoomsEmptyView(
        emptyViewState: ChatRoomsEmptyViewStateFactory(
            newEmptyStates: false
        ).emptyChatRoomsViewState(
            chatViewMode: .meetings,
            contactsOnMega: .contactsOnMega(
                designTokenEnabled: false,
                action: {}
            ),
            archivedChats: .archivedChatsViewState(
                count: 1,
                action: {}
            ),
            bottomButtonAction: {},
            bottomButtonMenus: nil
        ),
        isDesignTokenEnabled: false
    )
}

#Preview("EmptyMeetings-DT") {
    ChatRoomsEmptyView(
        emptyViewState: ChatRoomsEmptyViewStateFactory(
            newEmptyStates: false
        ).emptyChatRoomsViewState(
            chatViewMode: .meetings,
            contactsOnMega: .contactsOnMega(
                designTokenEnabled: true,
                action: {}
            ),
            archivedChats: .archivedChatsViewState(
                count: 1,
                action: {}
            ),
            bottomButtonAction: {},
            bottomButtonMenus: nil
        ),
        isDesignTokenEnabled: true
    )
}

#Preview("EmptySearch-NonDT") {
    ChatRoomsEmptyView(
        emptyViewState: ChatRoomsEmptyViewStateFactory(
            newEmptyStates: false
        ).searchEmptyViewState(),
        isDesignTokenEnabled: false
    )
}

#Preview("EmptySearch-DT") {
    ChatRoomsEmptyView(
        emptyViewState: ChatRoomsEmptyViewStateFactory(
            newEmptyStates: false
        ).searchEmptyViewState(),
        isDesignTokenEnabled: true
    )
}
