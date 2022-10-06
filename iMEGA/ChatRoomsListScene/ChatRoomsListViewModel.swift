import Foundation
import MEGADomain
import Combine

enum ChatMode {
    case chats
    case meetings
}

enum ChatType {
    case regular
    case archived
}

final class ChatRoomsListViewModel: ObservableObject {
    private let router: ChatRoomsListRouting
    private let chatUseCase: ChatUseCaseProtocol
    private let contactsUseCase: ContactsUseCaseProtocol

    private let chatType: ChatType
    
    @Published var chatMode: ChatMode = .chats
    @Published var chatStatus: ChatStatusEntity?
    @Published var title: String = Strings.Localizable.Chat.title
    @Published var emptyViewState: ChatRoomsEmptyViewState?

    private var subscriptions = Set<AnyCancellable>()

    init(router: ChatRoomsListRouting,
         chatUseCase: ChatUseCaseProtocol,
         contactsUseCase: ContactsUseCaseProtocol,
         chatType: ChatType = .regular
    ) {
        self.router = router
        self.chatUseCase = chatUseCase
        self.contactsUseCase = contactsUseCase
        self.chatType = chatType
        
        configureTitle()
        listeningForChatStatusUpdate()
    }
    
    func loadData() {
        emptyViewState = createEmptyViewState()
    }
    
    func listeningForChatStatusUpdate () {
        chatUseCase
            .monitorSelfChatStatusChange()
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { error in
                MEGALogDebug("error fetching the changed status \(error)")
            }, receiveValue: { [weak self] status in
                self?.chatStatus = status
            })
            .store(in: &subscriptions)
    }
    
    func selectChatMode(_ mode: ChatMode) {
        guard mode != chatMode else { return }
        chatMode = mode
        loadData()
    }
    
    func addChatButtonTapped() {
        router.presentStartConversation()
    }
    
    func changeChatStatus(to status: ChatStatusEntity) {
        guard status != chatStatus else {
            return
        }
        chatUseCase.changeChatStatus(to: status)
    }
    
    private func configureTitle() {
        switch chatType {
        case .regular:
            title = Strings.Localizable.Chat.title
        case .archived:
            title = Strings.Localizable.archivedChats
        }
    }
    
    private func createEmptyViewState() -> ChatRoomsEmptyViewState {
        ContactsOnMegaManager.shared.loadContactsOnMegaFromLocal()
        let contactsOnMegaCount = ContactsOnMegaManager.shared.contactsOnMegaCount()

        let topRowDescription: String

        if contactsUseCase.isAuthorizedToAccessPhoneContacts {
            if contactsOnMegaCount > 0 {
                topRowDescription = contactsOnMegaCount == 1 ?  Strings.Localizable._1ContactFoundOnMEGA : Strings.Localizable.xContactsFoundOnMEGA.replacingOccurrences(of: "[X]", with: "\(contactsOnMegaCount)")
            } else {
                topRowDescription = Strings.Localizable.inviteContactNow
            }
        } else {
            topRowDescription = Strings.Localizable.seeWhoSAlreadyOnMEGA
        }
        
        return ChatRoomsEmptyViewState(
            topRowImageAsset: Asset.Images.Chat.inviteToChat,
            topRowDescription: topRowDescription,
            topRowAction: { [weak self] in
                guard let self else { return }
                if self.contactsUseCase.isAuthorizedToAccessPhoneContacts, contactsOnMegaCount == 0 {
                    self.router.showInviteContactScreen()
                } else {
                    self.router.showContactsOnMegaScreen()
                }
            },
            centerImageAsset: chatMode == .chats ? Asset.Images.EmptyStates.chatEmptyState : Asset.Images.EmptyStates.meetingEmptyState,
            centerTitle: chatMode == .chats ? Strings.Localizable.Chat.Chats.EmptyState.title : Strings.Localizable.Chat.Meetings.EmptyState.title,
            centerDescription: chatMode == .chats ? Strings.Localizable.Chat.Chats.EmptyState.description : Strings.Localizable.Chat.Meetings.EmptyState.description,
            bottomButtonTitle: chatMode == .chats ? Strings.Localizable.Chat.Chats.EmptyState.Button.title : Strings.Localizable.Chat.Meetings.EmptyState.Button.title,
            bottomButtonAction: { [weak self] in
                guard let self else { return }
                if self.chatMode == .chats {
                    self.addChatButtonTapped()
                }
            },
            bottomButtonMenus: chatMode == .meetings ? [startMeetingMenu(), joinMeetingMenu(), scheduleMeetingMenu()] : nil
        )
    }
    
    private func startMeetingMenu() -> ChatRoomsEmptyBottomButtonMenu {
        ChatRoomsEmptyBottomButtonMenu(
            name: Strings.Localizable.Meetings.StartConversation.ContextMenu.startMeeting,
            image: Asset.Images.Meetings.startMeeting
        ) { [weak self] in
            guard let self else { return }
            self.router.showStartMeetingScreen()
        }
    }
    
    private func joinMeetingMenu() -> ChatRoomsEmptyBottomButtonMenu {
        ChatRoomsEmptyBottomButtonMenu(
            name: Strings.Localizable.Meetings.StartConversation.ContextMenu.joinMeeting,
            image: Asset.Images.Meetings.joinAMeeting
        ) { [weak self] in
            guard let self else { return }
            self.router.showJoinMeetingScreen()
        }
    }
    
    private func scheduleMeetingMenu() -> ChatRoomsEmptyBottomButtonMenu {
        ChatRoomsEmptyBottomButtonMenu(
            name: Strings.Localizable.Meetings.StartConversation.ContextMenu.scheduleMeeting,
            image: Asset.Images.Meetings.scheduleMeeting
        ) { [weak self] in
            guard let self else { return }
            self.router.showScheduleMeetingScreen()
        }
    }
}
