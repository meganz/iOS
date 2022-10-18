import MEGADomain
import MEGAData

@available(iOS 14.0, *)
final class ChatRoomsListRouter: ChatRoomsListRouting {
    private(set) weak var navigationController: UINavigationController?
    
    func build() -> UIViewController {
        let viewModel = ChatRoomsListViewModel(
            router: self,
            chatUseCase: ChatUseCase(chatRepo: ChatRepository(sdk: MEGASdkManager.sharedMEGAChatSdk())),
            contactsUseCase: ContactsUseCase(repository: ContactsRepository()),
            networkMonitorUseCase: NetworkMonitorUseCase(repo: NetworkMonitorRepository()),
            userUseCase: UserUseCase(repo: .live)
        )
        let viewController = ChatRoomsListViewController(viewModel: viewModel)
        let navigation = MEGANavigationController(rootViewController: viewController)
        navigation.tabBarItem = UITabBarItem(title: nil, image: Asset.Images.TabBarIcons.chatIcon.image, tag: 2)
        navigationController = navigation
        viewModel.configureMyAvatarManager()

        return navigation
    }
    
    func start() { }
    
    func presentStartConversation() {
        NewChatRouter(navigationController: navigationController, tabBarController: nil).presentNewChat(from: navigationController)
    }
    
    func showInviteContactScreen() {
        let controller = UIStoryboard(name: "InviteContact", bundle: nil).instantiateViewController(withIdentifier: "InviteContactViewControllerID")
        navigationController?.pushViewController(controller, animated: true)
    }
    
    func showContactsOnMegaScreen() {
        let controller = UIStoryboard(name: "InviteContact", bundle: nil).instantiateViewController(withIdentifier: "ContactsOnMegaViewControllerID")
        navigationController?.pushViewController(controller, animated: true)
    }
            
    func presentMeetingAlreayExists() {
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
    
    func presentScheduleMeetingScreen() {
        
    }
        
    func showDetails(forChatId chatId: HandleEntity) {
        guard let navigationController else { return }
        let chatRoomViewController = ChatViewController(chatId: chatId)
        navigationController.pushViewController(chatRoomViewController, animated: true)
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
                image: Asset.Images.Chat.ContextualMenu.markUnreadMenu.image,
                style: .default) {
                    markAsReadAction()
                }
        }
        
        let dndSheetAction = ActionSheetAction(
            title: dndEnabled ?  Strings.Localizable.unmute : Strings.Localizable.mute,
            detail: nil,
            accessoryView: nil,
            image: Asset.Images.Chat.ContextualMenu.mutedChatMenu.image,
            style: .default) {
                dndAction()
            }
        
        let infoSheetAction = ActionSheetAction(
            title: Strings.Localizable.info,
            detail: nil,
            accessoryView: nil,
            image: Asset.Images.Generic.info.image,
            style: .default) {
                infoAction()
            }
        
        let archiveChatSheetAction = ActionSheetAction(
            title: Strings.Localizable.archiveChat,
            detail: nil,
            accessoryView: nil,
            image: Asset.Images.Chat.archiveChat.image,
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
    
    func showGroupChatInfo(forChatId chatId: HandleEntity) {
        guard let groupChatDetailsController = UIStoryboard(name: "Chat", bundle: nil).instantiateViewController(withIdentifier: "GroupChatDetailsViewControllerID") as? GroupChatDetailsViewController else {
            return
        }
        
        groupChatDetailsController.chatId = chatId
        navigationController?.pushViewController(groupChatDetailsController, animated: true)
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
        guard let archivedChatRoomsViewController = UIStoryboard(name: "Chat", bundle: nil).instantiateViewController(withIdentifier: "ChatRoomsViewControllerID") as? ChatRoomsViewController else {
            return
        }
        archivedChatRoomsViewController.chatRoomsType = .archived
        navigationController?.pushViewController(archivedChatRoomsViewController, animated: true)
    }
}
