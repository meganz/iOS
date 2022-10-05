import MEGADomain

@available(iOS 14.0, *)
final class ChatRoomsListRouter: ChatRoomsListRouting {
    
    private weak var navigationController: UINavigationController?
    
    func build() -> UIViewController {
        let viewModel = ChatRoomsListViewModel(router: self,
                                               chatUseCase: ChatUseCase(chatRepo: ChatRepository(sdk: MEGASdkManager.sharedMEGAChatSdk()))
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
}
