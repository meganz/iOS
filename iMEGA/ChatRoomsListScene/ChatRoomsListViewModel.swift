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


protocol ChatRoomsListRouting: Routing {
    var navigationController: UINavigationController? { get }
    func presentStartConversation()
    func presentMeetingAlreayExists()
    func presentCreateMeeting()
    func presentEnterMeeting()
    func presentScheduleMeetingScreen()
    func showInviteContactScreen()
    func showContactsOnMegaScreen()
}

final class ChatRoomsListViewModel: ObservableObject {
    private let router: ChatRoomsListRouting
    private let chatUseCase: ChatUseCaseProtocol
    private let contactsUseCase: ContactsUseCaseProtocol
    private let networkMonitorUseCase: NetworkMonitorUseCaseProtocol
    private let notificationCenter: NotificationCenter
    private let chatType: ChatType
    
    lazy var contextMenuManager = ContextMenuManager(chatMenuDelegate: self,
                                                     meetingContextMenuDelegate: self,
                                                     createContextMenuUseCase: CreateContextMenuUseCase(repo: CreateContextMenuRepository.newRepo))
    private var myAvatarManager: MyAvatarManager?
    lazy private var globalDNDNotificationControl = GlobalDNDNotificationControl(delegate: self)

    @Published var chatMode: ChatMode = .chats
    @Published var chatStatus: ChatStatusEntity?
    @Published var title: String = Strings.Localizable.Chat.title
    @Published var myAvatarBarButton: UIBarButtonItem?
    @Published var isConnectedToNetwork: Bool

    private var subscriptions = Set<AnyCancellable>()

    init(router: ChatRoomsListRouting,
         chatUseCase: ChatUseCaseProtocol,
         contactsUseCase: ContactsUseCaseProtocol,
         networkMonitorUseCase: NetworkMonitorUseCaseProtocol,
         notificationCenter: NotificationCenter = NotificationCenter.default,
         chatType: ChatType = .regular
    ) {
        self.router = router
        self.chatUseCase = chatUseCase
        self.contactsUseCase = contactsUseCase
        self.networkMonitorUseCase = networkMonitorUseCase
        self.notificationCenter = notificationCenter
        self.chatType = chatType
        self.isConnectedToNetwork = networkMonitorUseCase.isConnected()
        
        configureTitle()
        listeningForChatStatusUpdate()
        monitorNetworkChanges()
    }
    
    func contextMenuConfiguration() -> CMConfigEntity {
        CMConfigEntity(menuType: .menu(type: .chat),
                       isDoNotDisturbEnabled: globalDNDNotificationControl.isGlobalDNDEnabled,
                       timeRemainingToDeactiveDND: globalDNDNotificationControl.timeRemainingToDeactiveDND ?? "",
                       chatStatus: chatUseCase.chatStatus())
    }
    
    func selectChatMode(_ mode: ChatMode) {
        guard mode != chatMode else { return }
        chatMode = mode
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
    
    func emptyViewState() -> ChatRoomsEmptyViewState {
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
            centerImageAsset: isConnectedToNetwork ? (chatMode == .chats ? Asset.Images.EmptyStates.chatEmptyState : Asset.Images.EmptyStates.meetingEmptyState) : Asset.Images.EmptyStates.noInternetEmptyState,
            centerTitle: chatMode == .chats ? Strings.Localizable.Chat.Chats.EmptyState.title : Strings.Localizable.Chat.Meetings.EmptyState.title,
            centerDescription: chatMode == .chats ? Strings.Localizable.Chat.Chats.EmptyState.description : Strings.Localizable.Chat.Meetings.EmptyState.description,
            bottomButtonTitle: isConnectedToNetwork ? (chatMode == .chats ? Strings.Localizable.Chat.Chats.EmptyState.Button.title : Strings.Localizable.Chat.Meetings.EmptyState.Button.title) : nil,
            bottomButtonAction: { [weak self] in
                guard let self else { return }
                if self.chatMode == .chats {
                    self.addChatButtonTapped()
                }
            },
            bottomButtonMenus: chatMode == .meetings && isConnectedToNetwork ? [startMeetingMenu(), joinMeetingMenu(), scheduleMeetingMenu()] : nil
        )
    }
    
    //MARK: - Private
    private func configureTitle() {
        switch chatType {
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
    
    private func listeningForChatStatusUpdate () {
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
    
    private func monitorNetworkChanges() {
        networkMonitorUseCase.networkPathChanged { [weak self] isConnectedToNetwork in
            guard let self else { return }
            self.isConnectedToNetwork = isConnectedToNetwork
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
    func pushNotificationSettingsLoaded() {
        notificationCenter.post(name: .chatDoNotDisturbUpdate, object: nil)
    }
}
