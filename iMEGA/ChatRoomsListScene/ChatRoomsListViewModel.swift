import Foundation
import MEGADomain
import Combine

enum ChatViewMode {
    case chats
    case meetings
}

enum ChatViewType {
    case regular
    case archived
}

protocol ChatRoomsListRouting {
    var navigationController: UINavigationController? { get }
    func presentStartConversation()
    func presentMeetingAlreayExists()
    func presentCreateMeeting()
    func presentEnterMeeting()
    func presentScheduleMeetingScreen()
    func showInviteContactScreen()
    func showContactsOnMegaScreen()
    func showDetails(forChatId chatId: HandleEntity)
    func present(alert: UIAlertController, animated: Bool)
    func presentMoreOptionsForChat(
        withDNDEnabled dndEnabled: Bool,
        dndAction: @escaping () -> Void,
        markAsReadAction: (() -> Void)?,
        infoAction: @escaping () -> Void,
        archiveAction: @escaping () -> Void
    )
    func showGroupChatInfo(forChatId chatId: HandleEntity)
    func showContactDetailsInfo(forUseHandle userHandle: HandleEntity, userEmail: String)
    func showArchivedChatRooms()
}

final class ChatRoomsListViewModel: ObservableObject {
    private let router: ChatRoomsListRouting
    private let chatUseCase: ChatUseCaseProtocol
    private let contactsUseCase: ContactsUseCaseProtocol
    private let networkMonitorUseCase: NetworkMonitorUseCaseProtocol
    private let userUseCase: UserUseCaseProtocol
    private let notificationCenter: NotificationCenter
    private let chatViewType: ChatViewType
    
    lazy var contextMenuManager = ContextMenuManager(chatMenuDelegate: self,
                                                     meetingContextMenuDelegate: self,
                                                     createContextMenuUseCase: CreateContextMenuUseCase(repo: CreateContextMenuRepository.newRepo))
    private var myAvatarManager: MyAvatarManager?
    
    lazy private var globalDNDNotificationControl = GlobalDNDNotificationControl(delegate: self)
    lazy private var chatNotificationControl = ChatNotificationControl(delegate: self)

    @Published var chatViewMode: ChatViewMode = .chats
    @Published var chatStatus: ChatStatusEntity?
    @Published var title: String = Strings.Localizable.Chat.title
    @Published var myAvatarBarButton: UIBarButtonItem?
    @Published var isConnectedToNetwork: Bool
    @Published var bottomViewHeight: CGFloat = 0
    @Published var displayChatRooms: [ChatRoomViewModel]?
    @Published var searchText: String {
        didSet {
            filterChats()
        }
    }
    
    private var chatRooms: [ChatRoomViewModel]?
    private var filteredChatRooms: [ChatRoomViewModel]?
    private var subscriptions = Set<AnyCancellable>()
    private let isRightToLeftLanguage: Bool
    
    init(router: ChatRoomsListRouting,
         chatUseCase: ChatUseCaseProtocol,
         contactsUseCase: ContactsUseCaseProtocol,
         networkMonitorUseCase: NetworkMonitorUseCaseProtocol,
         userUseCase: UserUseCaseProtocol,
         isRightToLeftLanguage: Bool,
         notificationCenter: NotificationCenter = NotificationCenter.default,
         chatType: ChatViewType = .regular
    ) {
        self.router = router
        self.chatUseCase = chatUseCase
        self.contactsUseCase = contactsUseCase
        self.networkMonitorUseCase = networkMonitorUseCase
        self.userUseCase = userUseCase
        self.isRightToLeftLanguage = isRightToLeftLanguage
        self.notificationCenter = notificationCenter
        self.chatViewType = chatType
        self.isConnectedToNetwork = networkMonitorUseCase.isConnected()
        self.searchText = ""
        
        configureTitle()
        listenorToChatStatusUpdate()
        listenToChatListUpdate()
        monitorNetworkChanges()
        fetchChats()
    }
    
    func fetchChats() {
        guard let chatListItems = chatUseCase.chatsList(ofType: chatViewMode == .chats ? .nonMeeting : .meeting) else {
            MEGALogDebug("Unable to fetch chat list items")
            return 
        }
        
        chatRooms = chatListItems.map(constructChatRoomViewModel)
        displayChatRooms = chatRooms
    }
    
    func filterChats() {
        if searchText.isNotEmpty {
            filteredChatRooms = chatRooms?.filter { $0.chatListItem.searchString.localizedCaseInsensitiveContains(searchText)}
            displayChatRooms = filteredChatRooms
        } else {
            displayChatRooms = chatRooms
        }
    }
    
    func contextMenuConfiguration() -> CMConfigEntity {
        CMConfigEntity(menuType: .menu(type: .chat),
                       isDoNotDisturbEnabled: globalDNDNotificationControl.isGlobalDNDEnabled,
                       timeRemainingToDeactiveDND: globalDNDNotificationControl.timeRemainingToDeactiveDND ?? "",
                       chatStatus: chatUseCase.chatStatus())
    }
    
    func selectChatMode(_ mode: ChatViewMode) {
        guard mode != chatViewMode else { return }
        chatViewMode = mode
        fetchChats()
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
    
    func contactsOnMegaViewState() -> ChatRoomsTopRowViewState {
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
        
        return ChatRoomsTopRowViewState(
            image: Asset.Images.Chat.inviteToChat.image,
            description: topRowDescription) { [weak self] in
                self?.topRowViewTapped()
            }
    }
    
    func archiveChatsViewState() -> ChatRoomsTopRowViewState? {
        guard chatUseCase.archivedChatListCount() > 0 else { return nil }
        
        return ChatRoomsTopRowViewState(
            image: Asset.Images.Chat.archiveChat.image,
            description: Strings.Localizable.archivedChats,
            rightDetail: "\(chatUseCase.archivedChatListCount())") { [weak self] in
                self?.router.showArchivedChatRooms()
            }
    }
    
    func emptyViewState() -> ChatRoomsEmptyViewState {
        ChatRoomsEmptyViewState(
            contactsOnMega: contactsOnMegaViewState(),
            centerImageAsset: isConnectedToNetwork ? (chatViewMode == .chats ? Asset.Images.EmptyStates.chatEmptyState : Asset.Images.EmptyStates.meetingEmptyState) : Asset.Images.EmptyStates.noInternetEmptyState,
            centerTitle: chatViewMode == .chats ? Strings.Localizable.Chat.Chats.EmptyState.title : Strings.Localizable.Chat.Meetings.EmptyState.title,
            centerDescription: chatViewMode == .chats ? Strings.Localizable.Chat.Chats.EmptyState.description : Strings.Localizable.Chat.Meetings.EmptyState.description,
            bottomButtonTitle: isConnectedToNetwork ? (chatViewMode == .chats ? Strings.Localizable.Chat.Chats.EmptyState.Button.title : Strings.Localizable.Chat.Meetings.EmptyState.Button.title) : nil,
            bottomButtonAction: { [weak self] in
                guard let self else { return }
                if self.chatViewMode == .chats {
                    self.addChatButtonTapped()
                }
            },
            bottomButtonMenus: chatViewMode == .meetings && isConnectedToNetwork ? [startMeetingMenu(), joinMeetingMenu(), scheduleMeetingMenu()] : nil
        )
    }
    
    //MARK: - Private
    private func constructChatRoomViewModel(forChatListItem chatListItem: ChatListItemEntity) -> ChatRoomViewModel {
        let chatRoomUseCase = ChatRoomUseCase(chatRoomRepo: ChatRoomRepository.sharedRepo,
                                              userStoreRepo: UserStoreRepository(store: MEGAStore.shareInstance()))
        let userImageUseCase = UserImageUseCase(
            userImageRepo: UserImageRepository(sdk: MEGASdkManager.sharedMEGASdk()),
            userStoreRepo: UserStoreRepository(store: MEGAStore.shareInstance()),
            thumbnailRepo: ThumbnailRepository.newRepo,
            fileSystemRepo: FileSystemRepository.newRepo
        )
        
        return ChatRoomViewModel(
            chatListItem: chatListItem,
            router: router,
            chatRoomUseCase: chatRoomUseCase,
            userImageUseCase: userImageUseCase,
            chatUseCase: ChatUseCase(chatRepo: ChatRepository(sdk: MEGASdkManager.sharedMEGAChatSdk())),
            userUseCase: UserUseCase(repo: .live),
            chatNotificationControl: chatNotificationControl,
            isRightToLeftLanguage: isRightToLeftLanguage
        )
    }
    
    private func configureTitle() {
        switch chatViewType {
        case .regular:
            title = Strings.Localizable.Chat.title
        case .archived:
            title = Strings.Localizable.archivedChats
        }
    }
    
    private func startMeetingMenu() -> ChatRoomsEmptyBottomButtonMenu {
        ChatRoomsEmptyBottomButtonMenu(
            name: Strings.Localizable.Meetings.StartConversation.ContextMenu.startMeeting,
            image: Asset.Images.Meetings.startMeeting
        ) { [weak self] in
            guard let self else { return }
            self.router.presentCreateMeeting()
        }
    }
    
    private func joinMeetingMenu() -> ChatRoomsEmptyBottomButtonMenu {
        ChatRoomsEmptyBottomButtonMenu(
            name: Strings.Localizable.Meetings.StartConversation.ContextMenu.joinMeeting,
            image: Asset.Images.Meetings.joinAMeeting
        ) { [weak self] in
            guard let self else { return }
            self.router.presentEnterMeeting()
        }
    }
    
    private func scheduleMeetingMenu() -> ChatRoomsEmptyBottomButtonMenu {
        ChatRoomsEmptyBottomButtonMenu(
            name: Strings.Localizable.Meetings.StartConversation.ContextMenu.scheduleMeeting,
            image: Asset.Images.Meetings.scheduleMeeting
        ) { [weak self] in
            guard let self else { return }
            self.router.presentScheduleMeetingScreen()
        }
    }
    
    private func listenorToChatStatusUpdate() {
        guard let myHandle = userUseCase.myHandle else { return }
        
        chatUseCase
            .monitorChatStatusChange(forUserHandle: myHandle)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { error in
                MEGALogDebug("error fetching the changed status \(error)")
            }, receiveValue: { [weak self] status in
                self?.chatStatus = status
            })
            .store(in: &subscriptions)
    }
    
    private func listenToChatListUpdate() {
        chatUseCase
            .monitorChatListItemUpdate()
            .sink { [weak self] chatListItem in
                self?.onChatListItemUpdate(chatListItem)
            }
            .store(in: &subscriptions)
    }
    
    private func monitorNetworkChanges() {
        networkMonitorUseCase.networkPathChanged { [weak self] isConnectedToNetwork in
            guard let self else { return }
            self.isConnectedToNetwork = isConnectedToNetwork
        }
    }
    
    private func topRowViewTapped() {
        let contactsOnMegaCount = ContactsOnMegaManager.shared.contactsOnMegaCount()

        if contactsUseCase.isAuthorizedToAccessPhoneContacts, contactsOnMegaCount == 0 {
            router.showInviteContactScreen()
        } else {
            router.showContactsOnMegaScreen()
        }
    }
    
    private func onChatListItemUpdate(_ chatListItem: ChatListItemEntity) {
        if chatListItem.changeType == .archived {
            fetchChats()
        } else {
            guard let chatRooms,
                  let index = chatRooms.firstIndex(where: { $0.chatListItem == chatListItem }) else {
                return
            }
            
            self.chatRooms?[index] = constructChatRoomViewModel(forChatListItem: chatListItem)
            self.chatRooms?.sort { $0.chatListItem.lastMessageDate > $1.chatListItem.lastMessageDate }
            displayChatRooms = self.chatRooms
            objectWillChange.send()
        }
    }
}

//MARK: - ChatMenuDelegate
extension ChatRoomsListViewModel: ChatMenuDelegate {
    
    func chatStatusMenu(didSelect action: ChatStatusEntity) {
        changeChatStatus(to: action)
    }
    
    func chatDoNotDisturbMenu(didSelect option: DNDTurnOnOption) {
        globalDNDNotificationControl.turnOnDND(dndTurnOnOption: option) { [weak self] in
            self?.notificationCenter.post(name: .chatDoNotDisturbUpdate, object: nil)
        }
    }
    
    func chatDisableDoNotDisturb() {
        guard globalDNDNotificationControl.isGlobalDNDEnabled else {
            return
        }
        
        globalDNDNotificationControl.turnOffDND { [weak self] in
            self?.notificationCenter.post(name: .chatDoNotDisturbUpdate, object: nil)
        }
    }
    
    func showActionSheet(with actions: [ContextActionSheetAction]) {
        // iOS 13 not supported for this class
    }
}

//MARK: - MeetingContextMenuDelegate
extension ChatRoomsListViewModel: MeetingContextMenuDelegate {
    func meetingContextMenu(didSelect action: MeetingActionEntity) {
        if chatUseCase.existsActiveCall() {
            router.presentMeetingAlreayExists()
            return
        }
        
        switch action {
        case .startMeeting:
            router.presentCreateMeeting()
        case .joinMeeting:
            router.presentEnterMeeting()
        case .scheduleMeeting:
            break
        }
    }
}

//MARK: - MyAvatarPresenterProtocol
extension ChatRoomsListViewModel: MyAvatarPresenterProtocol {
    func setupMyAvatar(barButton: UIBarButtonItem) {
        myAvatarBarButton = barButton
        refreshMyAvatar()
    }
    
    func configureMyAvatarManager() {
        guard let navController = router.navigationController else { return }
        myAvatarManager = MyAvatarManager(navigationController: navController, delegate: self)
        myAvatarManager?.setup()
    }
    
    func refreshMyAvatar() {
        myAvatarManager?.refreshMyAvatar()
    }
}

//MARK: - PushNotificationControlProtocol
extension ChatRoomsListViewModel :PushNotificationControlProtocol {
    func presentAlertController(_ alert: UIAlertController) {
        router.present(alert: alert, animated: true)
    }
    
    func reloadDataIfNeeded() {
        chatRooms?.forEach { $0.updateContextMenuOptions() }
    }
    
    func pushNotificationSettingsLoaded() {
        notificationCenter.post(name: .chatDoNotDisturbUpdate, object: nil)
    }
}
