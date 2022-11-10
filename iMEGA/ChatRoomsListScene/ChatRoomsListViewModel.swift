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
    func showDetails(forChatId chatId: HandleEntity, unreadMessagesCount: Int)
    func openChatRoom(withChatId chatId: ChatId, publicLink: String?, unreadMessageCount: Int)
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
    func joinActiveCall(_ call: CallEntity)
}

final class ChatRoomsListViewModel: ObservableObject {
    let router: ChatRoomsListRouting
    private let chatUseCase: ChatUseCaseProtocol
    private let chatRoomUseCase: ChatRoomUseCaseProtocol
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

    @Published var chatViewMode: ChatViewMode
    @Published var chatStatus: ChatStatusEntity?
    @Published var title: String = Strings.Localizable.Chat.title
    @Published var myAvatarBarButton: UIBarButtonItem?
    @Published var isConnectedToNetwork: Bool
    @Published var bottomViewHeight: CGFloat = 0
    @Published var displayChatRooms: [ChatRoomViewModel]?
    @Published var activeCallViewModel: ActiveCallViewModel?
    @Published var searchText: String {
        didSet {
            filterChats()
        }
    }
    @Published var isSearchActive: Bool
    
    private var chatRooms: [ChatRoomViewModel]?
    private var filteredChatRooms: [ChatRoomViewModel]?
    private var subscriptions = Set<AnyCancellable>()
    private var isViewOnScreen = false
    
    init(router: ChatRoomsListRouting,
         chatUseCase: ChatUseCaseProtocol,
         chatRoomUseCase: ChatRoomUseCaseProtocol,
         contactsUseCase: ContactsUseCaseProtocol,
         networkMonitorUseCase: NetworkMonitorUseCaseProtocol,
         userUseCase: UserUseCaseProtocol,
         notificationCenter: NotificationCenter = NotificationCenter.default,
         chatType: ChatViewType = .regular,
         chatViewMode: ChatViewMode = .chats
    ) {
        self.router = router
        self.chatUseCase = chatUseCase
        self.contactsUseCase = contactsUseCase
        self.chatRoomUseCase = chatRoomUseCase
        self.networkMonitorUseCase = networkMonitorUseCase
        self.userUseCase = userUseCase
        self.notificationCenter = notificationCenter
        self.chatViewType = chatType
        self.chatViewMode = chatViewMode
        self.isConnectedToNetwork = networkMonitorUseCase.isConnected()
        self.searchText = ""
        self.isSearchActive = false
        
        configureTitle()
    }
    
    func loadChatRooms() {
        isViewOnScreen = true
        chatUseCase.retryPendingConnections()
        
        if chatUseCase.chatConnectionStatus() == .online {
            fetchChats()
        }
        
        let isConnectedToNetwork = networkMonitorUseCase.isConnected()
        if self.isConnectedToNetwork != isConnectedToNetwork {
            self.isConnectedToNetwork = isConnectedToNetwork
        }
        
        if let activeCall = chatUseCase.activeCall() {
            updateActiveCall(activeCall)
        }
        
        listenToChatListUpdate()
        monitorChatConnectionStatusUpdate()
        listenToChatStatusUpdate()
        monitorNetworkChanges()
        monitorActiveCallChanges()
    }
    
    func cancelLoading() {
        isViewOnScreen = false
        subscriptions.forEach { $0.cancel() }
        subscriptions = []
    }
    
    func fetchChats() {
        guard let chatListItems = chatUseCase.chatsList(ofType: chatViewMode == .chats ? .nonMeeting : .meeting), isViewOnScreen else {
            MEGALogDebug("Unable to fetch chat list items")
            return 
        }
        
        chatRooms = chatListItems.map(constructChatRoomViewModel)
        filterChats()
    }
    
    func filterChats() {
        if searchText.isNotEmpty {
            filteredChatRooms = chatRooms?.filter { $0.contains(searchText: searchText)}
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
    
    func searchEmptyViewState() -> ChatRoomsEmptyViewState {
        ChatRoomsEmptyViewState(
            contactsOnMega: nil,
            centerImageAsset: Asset.Images.EmptyStates.searchEmptyState,
            centerTitle: Strings.Localizable.noResults,
            centerDescription: nil,
            bottomButtonTitle: nil,
            bottomButtonAction: nil,
            bottomButtonMenus: nil
        )
    }
    
    func noNetworkEmptyViewState() -> ChatRoomsEmptyViewState {
        ChatRoomsEmptyViewState(
            contactsOnMega: contactsOnMegaViewState(),
            centerImageAsset: Asset.Images.EmptyStates.noInternetEmptyState,
            centerTitle: chatViewMode == .chats ? Strings.Localizable.Chat.Chats.EmptyState.title : Strings.Localizable.Chat.Meetings.EmptyState.title,
            centerDescription: chatViewMode == .chats ? Strings.Localizable.Chat.Chats.EmptyState.description : Strings.Localizable.Chat.Meetings.EmptyState.description,
            bottomButtonTitle: nil,
            bottomButtonAction: nil,
            bottomButtonMenus: nil
        )
    }
    
    func emptyChatRoomsViewState() -> ChatRoomsEmptyViewState {
        ChatRoomsEmptyViewState(
            contactsOnMega: contactsOnMegaViewState(),
            centerImageAsset: chatViewMode == .chats ? Asset.Images.EmptyStates.chatEmptyState : Asset.Images.EmptyStates.meetingEmptyState,
            centerTitle: chatViewMode == .chats ? Strings.Localizable.Chat.Chats.EmptyState.title : Strings.Localizable.Chat.Meetings.EmptyState.title,
            centerDescription: chatViewMode == .chats ? Strings.Localizable.Chat.Chats.EmptyState.description : Strings.Localizable.Chat.Meetings.EmptyState.description,
            bottomButtonTitle: chatViewMode == .chats ? Strings.Localizable.Chat.Chats.EmptyState.Button.title : Strings.Localizable.Chat.Meetings.EmptyState.Button.title,
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
            chatUseCase: ChatUseCase(
                chatRepo: ChatRepository(
                    sdk: MEGASdkManager.sharedMEGASdk(),
                    chatSDK: MEGASdkManager.sharedMEGAChatSdk())
            ),
            userUseCase: UserUseCase(repo: .live),
            chatNotificationControl: chatNotificationControl
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
    
    private func listenToChatStatusUpdate() {
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
            .receive(on: DispatchQueue.main)
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
    
    private func monitorActiveCallChanges() {
        chatUseCase
            .monitorChatCallStatusUpdate()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] call in
                self?.updateActiveCall(call)
            }
            .store(in: &subscriptions)
    }
    
    private func monitorChatConnectionStatusUpdate() {
        chatUseCase
            .monitorChatConnectionStatusUpdate(forChatId: .invalid)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] connectionStatus in
                if connectionStatus == .online {
                    self?.fetchChats()
                }
            }
            .store(in: &subscriptions)
    }
    
    private func updateActiveCall(_ call: CallEntity) {
        if call.status == .inProgress {
            activeCallViewModel = ActiveCallViewModel(
                call: call,
                router: router,
                activeCallUseCase: ActiveCallUseCase(callRepository: CallRepository(chatSdk: MEGASdkManager.sharedMEGAChatSdk(), callActionManager: CallActionManager.shared))
            )
        } else {
            activeCallViewModel = nil
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
        guard doesBelongToCurrentTab(chatListItem), let changes = chatListItem.changeType else { return }
        
        switch changes {
        case .unreadCount, .title, .lastMessage, .lastTimestamp, .participants, .noChanges:
            updateList(withChatListItem: chatListItem)
        case .closed, .previewClosed, .archived:
            if let chatRooms, let chatRoomIndex = index(forChatListItem: chatListItem, in: chatRooms) {
                self.chatRooms?.remove(at: chatRoomIndex)
                
                if let displayChatRooms, let filteredIndex = index(forChatListItem: chatListItem, in: displayChatRooms) {
                    self.displayChatRooms?.remove(at: filteredIndex)
                }
            }
        default:
            break
        }
    }
    
    private func updateList(withChatListItem chatListItem: ChatListItemEntity) {
        if let chatRooms {
            let chatRoomViewModel = constructChatRoomViewModel(forChatListItem: chatListItem)
            update(&self.chatRooms, with: chatRoomViewModel, at: index(forChatListItem: chatListItem, in: chatRooms))
            update(&self.displayChatRooms, with: chatRoomViewModel, at: index(forChatListItem: chatListItem, in: chatRooms))
        } else {
            fetchChats()
        }
    }
    
    private func update(_ list: inout [ChatRoomViewModel]?, with chatRoomViewModel: ChatRoomViewModel, at index: Int? = nil) {
        if let index {
            list?[index] = chatRoomViewModel
        } else {
            list?.append(chatRoomViewModel)
            
        }
    }
    
    private func index(forChatListItem chatListItem: ChatListItemEntity, in list: [ChatRoomViewModel]) -> Int? {
        list.firstIndex { $0.chatListItem == chatListItem }
    }
    
    
    private func doesBelongToCurrentTab(_ chatListItem: ChatListItemEntity) -> Bool {
        guard let chatRoom = chatRoomUseCase.chatRoom(forChatId: chatListItem.chatId),
                chatRoom.isArchived == false else {
            return false
        }
        
        return (chatRoom.chatType == .meeting && chatViewMode == .meetings) || (!(chatRoom.chatType == .meeting) && chatViewMode == .chats)
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
        chatRooms?.forEach { $0.pushNotificationSettingsChanged() }
    }
    
    func pushNotificationSettingsLoaded() {
        notificationCenter.post(name: .chatDoNotDisturbUpdate, object: nil)
    }
}
                       
