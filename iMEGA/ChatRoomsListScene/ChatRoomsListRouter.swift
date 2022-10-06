import MEGADomain

protocol ChatRoomsListRouting: Routing {
    func presentStartConversation()
    func showInviteContactScreen()
    func showContactsOnMegaScreen()
    func showStartMeetingScreen()
    func showJoinMeetingScreen()
    func showScheduleMeetingScreen()
}

@available(iOS 14.0, *)
final class ChatRoomsListRouter: ChatRoomsListRouting {
    
    private weak var navigationController: UINavigationController?
    
    func build() -> UIViewController {
        let viewModel = ChatRoomsListViewModel(
            router: self,
            chatUseCase: ChatUseCase(chatRepo: ChatRepository(sdk: MEGASdkManager.sharedMEGAChatSdk())),
            contactsUseCase: ContactsUseCase(repository: ContactsRepository())
        )
        let viewController = ChatRoomsListViewController(viewModel: viewModel)
        let navigation = MEGANavigationController(rootViewController: viewController)
        viewController.configureMyAvatarManager()

        navigation.tabBarItem = UITabBarItem(title: nil, image: Asset.Images.TabBarIcons.chatIcon.image, tag: 2)
        navigationController = navigation
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
    
    func showStartMeetingScreen() {
        guard let navigationController else { return }
        
        MeetingCreatingViewRouter(
            viewControllerToPresent: navigationController,
            type: .start,
            link: nil,
            userhandle: 0
        ).start()
    }
    
    func showJoinMeetingScreen() {
        guard let navigationController else { return }

        EnterMeetingLinkRouter(
            viewControllerToPresent: navigationController,
            isGuest: false
        ).start()
    }
    
    func showScheduleMeetingScreen() {
        
    }
}
