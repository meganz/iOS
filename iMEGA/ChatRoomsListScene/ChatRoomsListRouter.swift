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
            networkMonitorUseCase: NetworkMonitorUseCase(repo: NetworkMonitorRepository())
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
        
    func openChatRoom(_ chatId: HandleEntity) {
        guard let navigationController else { return }
        let chatRoomViewController = ChatViewController(chatId: chatId)
        navigationController.pushViewController(chatRoomViewController, animated: true)
    }
}
