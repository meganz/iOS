import ChatRepo
import MEGADomain
import MEGAL10n
import MEGAPermissions
import MEGARepo
import MEGASDKRepo

@MainActor
final class ChatRoomsListRouter: ChatRoomsListRouting {
    private(set) weak var navigationController: UINavigationController?
    private weak var chatRoomsListViewController: ChatRoomsListViewController?
    private weak var tabBarController: MainTabBarController?
    private lazy var newChatRouter = NewChatRouter(navigationController: navigationController, tabBarController: tabBarController)
    
    init(tabBarController: MainTabBarController?) {
        self.tabBarController = tabBarController
    }
    
    func build() -> UIViewController {
        let chatRoomUseCase = ChatRoomUseCase(chatRoomRepo: ChatRoomRepository.newRepo)
        let permissionHandler = DevicePermissionsHandler.makeHandler()
        let viewModel = ChatRoomsListViewModel(
            router: self,
            chatUseCase: ChatUseCase(chatRepo: ChatRepository.newRepo),
            chatRoomUseCase: chatRoomUseCase,
            networkMonitorUseCase: NetworkMonitorUseCase(repo: NetworkMonitorRepository.newRepo),
            accountUseCase: AccountUseCase(repository: AccountRepository.newRepo),
            scheduledMeetingUseCase: ScheduledMeetingUseCase(repository: ScheduledMeetingRepository(chatSDK: MEGAChatSdk.shared)),
            userAttributeUseCase: UserAttributeUseCase(repo: UserAttributeRepository.newRepo),
            permissionHandler: permissionHandler,
            permissionAlertRouter: PermissionAlertRouter.makeRouter(deviceHandler: permissionHandler),
            chatListItemCacheUseCase: ChatListItemCacheUseCase(repository: ChatListItemCacheRepository.newRepo),
            retryPendingConnectionsUseCase: RetryPendingConnectionsUseCase(repo: RetryPendingConnectionsRepository.newRepo),
            urlOpener: { UIApplication.shared.open($0) }
        )
        let viewController = ChatRoomsListViewController(viewModel: viewModel)
        let navigation = MEGANavigationController(rootViewController: viewController)
        navigation.tabBarItem = UITabBarItem(title: nil, image: UIImage(resource: .chatIcon), tag: 2)
        navigationController = navigation
        viewModel.configureMyAvatarManager()
        chatRoomsListViewController = viewController
        return navigation
    }
    
    func presentStartConversation() {
        newChatRouter.presentNewChat(from: navigationController, chatOptionType: .nonMeeting)
    }
    
    func showInviteContactScreen() {
        let controller = UIStoryboard(name: "InviteContact", bundle: nil).instantiateViewController(withIdentifier: "InviteContactViewControllerID")
        navigationController?.pushViewController(controller, animated: true)
    }
            
    func presentMeetingAlreadyExists() {
        guard let navigationController else { return }
        MeetingAlreadyExistsAlert.show(presenter: navigationController)
    }
    
    func presentCreateMeeting() {
        guard let navigationController else { return }
        MeetingCreatingViewRouter(
            viewControllerToPresent: navigationController,
            type: .start,
            link: nil,
            userhandle: 0
        ).start()
    }
    
    func presentEnterMeeting() {
        guard let navigationController else { return }
        EnterMeetingLinkRouter(
            viewControllerToPresent: navigationController,
            isGuest: false
        ).start()
    }
    
    func presentScheduleMeeting() {
        guard let navigationController else { return }
        let viewConfiguration = ScheduleMeetingNewViewConfiguration(
            chatRoomUseCase: ChatRoomUseCase(chatRoomRepo: ChatRoomRepository.newRepo),
            chatLinkUseCase: ChatLinkUseCase(chatLinkRepository: ChatLinkRepository.newRepo),
            scheduledMeetingUseCase: ScheduledMeetingUseCase(repository: ScheduledMeetingRepository.newRepo)
        )
        ScheduleMeetingRouter(
            presenter: navigationController,
            viewConfiguration: viewConfiguration,
            shareLinkRouter: ShareLinkDialogRouter(
                presenter: navigationController
            )
        ).start()
    }
    
    func presentWaitingRoom(for scheduledMeeting: ScheduledMeetingEntity) {
        WaitingRoomViewRouter(presenter: chatRoomsListViewController, scheduledMeeting: scheduledMeeting).start()
    }
    
    func chatRoomFor(_ chatId: ChatIdEntity) -> ChatRoomEntity? {
        ChatRoomUseCase(chatRoomRepo: ChatRoomRepository.newRepo)
            .chatRoom(forChatId: chatId)
    }
        
    func showDetails(forChatId chatId: HandleEntity) {
        guard let navigationController, let chatRoom = chatRoomFor(chatId) else { return }
        ChatContentRouter(
            chatRoom: chatRoom,
            presenter: navigationController
        ).start()
    }
    
    func openChatRoom(withChatId chatId: ChatIdEntity, publicLink: String?) {
        guard let navigationController else { return }
        
        if let chatViewController = navigationController.viewControllers[safe: 1] as? ChatViewController {
            let chatRoomAlreadyOpen: Bool
            if let publicLink {
                chatRoomAlreadyOpen = chatViewController.publicChatWithLinkCreated && chatViewController.publicChatLink?.absoluteString == publicLink
            } else {
                chatRoomAlreadyOpen = chatViewController.chatRoom.chatId == chatId
            }
            
            if chatRoomAlreadyOpen {
                if navigationController.viewControllers.count != 2 {
                    navigationController.popToViewController(chatViewController, animated: true)
                }
                return
            } else {
                chatViewController.closeChatRoom()
                navigationController.popViewController(animated: false)
            }
        }
        
        if let chatRoom = ChatRoomUseCase(
            chatRoomRepo: ChatRoomRepository.newRepo
        ).chatRoom(forChatId: chatId) {
            ChatContentRouter(
                chatRoom: chatRoom,
                presenter: navigationController,
                publicLink: publicLink,
                showShareLinkViewAfterOpenChat: (publicLink != nil) ? true : false
            ).start()
        }
    }
    
    func present(alert: UIAlertController, animated: Bool) {
        navigationController?.present(alert, animated: animated)
    }
    
    func presentMoreOptionsForChat(
        withDNDEnabled dndEnabled: Bool,
        dndAction: @escaping () -> Void,
        markAsReadAction: (() -> Void)?,
        infoAction: @escaping () -> Void,
        archiveAction: @escaping () -> Void
    ) {
        var markAsReadSheetAction: ActionSheetAction?
        if let markAsReadAction {
            markAsReadSheetAction = ActionSheetAction(
                title: Strings.Localizable.markAsRead,
                detail: nil,
                accessoryView: nil,
                image: UIImage(resource: .markUnreadMenu),
                style: .default) {
                    markAsReadAction()
                }
        }
        
        let dndSheetAction = ActionSheetAction(
            title: dndEnabled ?  Strings.Localizable.unmute : Strings.Localizable.mute,
            detail: nil,
            accessoryView: nil,
            image: UIImage(resource: .mutedChatMenu),
            style: .default) {
                dndAction()
            }
        
        let infoSheetAction = ActionSheetAction(
            title: Strings.Localizable.info,
            detail: nil,
            accessoryView: nil,
            image: UIImage(resource: .info),
            style: .default) {
                infoAction()
            }
        
        let archiveChatSheetAction = ActionSheetAction(
            title: Strings.Localizable.archiveChat,
            detail: nil,
            accessoryView: nil,
            image: UIImage(resource: .archiveChat),
            style: .default) {
                archiveAction()
            }
        
        let actions = [markAsReadSheetAction,
                       dndSheetAction,
                       infoSheetAction,
                       archiveChatSheetAction].compactMap({ $0 })
        
        let actionSheetController = ActionSheetViewController(
            actions: actions,
            headerTitle: nil,
            dismissCompletion: nil,
            sender: nil
        )
        
        navigationController?.present(actionSheetController, animated: true)
    }
    
    func showGroupChatInfo(forChatRoom chatRoom: ChatRoomEntity) {
        guard let megaChatRoom = chatRoom.toMEGAChatRoom(), let groupChatDetailsController = UIStoryboard(name: "Chat", bundle: nil).instantiateViewController(withIdentifier: "GroupChatDetailsViewControllerID") as? GroupChatDetailsViewController else {
            return
        }
        
        groupChatDetailsController.chatRoom = megaChatRoom
        navigationController?.pushViewController(groupChatDetailsController, animated: true)
    }
    
    func showMeetingInfo(for scheduledMeeting: ScheduledMeetingEntity) {
        guard let navigationController else {
            return
        }
        
        MeetingInfoRouter(presenter: navigationController, scheduledMeeting: scheduledMeeting).start()
    }
    
    func showMeetingOccurrences(for scheduledMeeting: ScheduledMeetingEntity) {
        guard let navigationController else {
            return
        }
        
        ScheduledMeetingOccurrencesRouter(presenter: navigationController, scheduledMeeting: scheduledMeeting).start()
    }
    
    func showContactDetailsInfo(forUseHandle userHandle: HandleEntity, userEmail: String) {
        guard let contactDetailsViewController = UIStoryboard(name: "Contacts", bundle: nil).instantiateViewController(withIdentifier: "ContactDetailsViewControllerID") as? ContactDetailsViewController else {
            return
        }
        
        contactDetailsViewController.contactDetailsMode = .fromChat
        contactDetailsViewController.userHandle = userHandle
        contactDetailsViewController.userEmail = userEmail
        navigationController?.pushViewController(contactDetailsViewController, animated: true)
    }
    
    func showArchivedChatRooms() {
        guard let archivedChatRoomsViewController = UIStoryboard(name: "Chat", bundle: nil).instantiateViewController(withIdentifier: "ArchivedChatRoomsViewControllerID") as? ArchivedChatRoomsViewController else {
            return
        }
        navigationController?.pushViewController(archivedChatRoomsViewController, animated: true)
    }
    
    @MainActor 
    func openCallView(for call: CallEntity, in chatRoom: ChatRoomEntity) {
        guard let navigationController else {
            return
        }
        
        MeetingContainerRouter(
            presenter: navigationController,
            chatRoom: chatRoom,
            call: call
        ).start()
    }
    
    func showErrorMessage(_ message: String) {
        SVProgressHUD.showError(withStatus: message)
    }
    
    func showSuccessMessage(_ message: String) {
        SVProgressHUD.showSuccess(withStatus: message)
    }
    
    func edit(scheduledMeeting: ScheduledMeetingEntity) {
        guard let navigationController else { return }
        let viewConfiguration = ScheduleMeetingUpdateViewConfiguration(
            scheduledMeeting: scheduledMeeting,
            chatUseCase: ChatUseCase(chatRepo: ChatRepository.newRepo),
            chatRoomUseCase: ChatRoomUseCase(chatRoomRepo: ChatRoomRepository.newRepo),
            chatLinkUseCase: ChatLinkUseCase(chatLinkRepository: ChatLinkRepository.newRepo),
            scheduledMeetingUseCase: ScheduledMeetingUseCase(repository: ScheduledMeetingRepository.newRepo)
        )
        ScheduleMeetingRouter(
            presenter: navigationController,
            viewConfiguration: viewConfiguration,
            shareLinkRouter: ShareLinkDialogRouter(presenter: navigationController)
        ).start()
    }
}
