import MEGADomain

@available(iOS 14.0, *)
final class MeetingInfoRouter: MeetingInfoRouting {
    private(set) var presenter: UINavigationController
    private let chatListItem: ChatListItemEntity

    init(presenter: UINavigationController,
         chatListItem: ChatListItemEntity) {
        self.presenter = presenter
        self.chatListItem = chatListItem
    }
    
    func build() -> UIViewController {
        let chatRoomUseCase = ChatRoomUseCase(
            chatRoomRepo: ChatRoomRepository.sharedRepo,
            userStoreRepo: UserStoreRepository(store: .shareInstance())
        )
        
        let userImageUseCase = UserImageUseCase(
            userImageRepo: UserImageRepository(sdk: MEGASdkManager.sharedMEGASdk()),
            userStoreRepo: UserStoreRepository(store: MEGAStore.shareInstance()),
            thumbnailRepo: ThumbnailRepository.newRepo,
            fileSystemRepo: FileSystemRepository.newRepo
        )
        
        let viewModel = MeetingInfoViewModel(
            chatListItem: chatListItem,
            router: self,
            chatRoomUseCase: chatRoomUseCase,
            userImageUseCase: userImageUseCase,
            chatUseCase: ChatUseCase(
                chatRepo: ChatRepository(
                    sdk: MEGASdkManager.sharedMEGASdk(),
                    chatSDK: MEGASdkManager.sharedMEGAChatSdk())
            ),
            userUseCase: UserUseCase(repo: .live),
            chatLinkUseCase: ChatLinkUseCase(chatLinkRepository: ChatLinkRepository.newRepo)
        )
        let viewController = MeetingInfoViewController(viewModel: viewModel)
        
        return viewController
    }
    
    func start() {
        presenter.pushViewController(build(), animated: true)
    }
    
    func showSharedFiles(for chatRoom: ChatRoomEntity) {
        guard let MEGAChatRoom = chatRoom.toMEGAChatRoom() else {
            return
        }
        presenter.pushViewController(ChatSharedItemsViewController.instantiate(with: MEGAChatRoom), animated: true)
    }

    func showManageChatHistory(for chatRoom: ChatRoomEntity) {
        ManageChatHistoryViewRouter(chatId: chatRoom.chatId, navigationController: presenter).start()
    }
    
    func showEnableKeyRotation(for chatRoom: ChatRoomEntity) {
        CustomModalAlertRouter(.enableKeyRotation, presenter: presenter, chatId: chatRoom.chatId).start()
    }

    func showChatLinksMustHaveCustomTitleAlert() {
        let alertController = UIAlertController(title: Strings.Localizable.chatLink, message: Strings.Localizable.toCreateAChatLinkYouMustNameTheGroup, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: Strings.Localizable.cancel, style: .cancel))
        alertController.addAction(UIAlertAction(title: Strings.Localizable.ok, style: .default))
        presenter.present(alertController, animated: true)
    }
    
    func closeMeetingInfoView() {
        presenter.popViewController(animated: true)
    }
    
    func showLeaveChatAlert(leaveAction: @escaping(() -> Void)) {
        let alertController = UIAlertController(title: Strings.Localizable.youWillNoLongerHaveAccessToThisConversation, message: nil, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: Strings.Localizable.cancel, style: .cancel))
        alertController.addAction(UIAlertAction(title: Strings.Localizable.leave, style: .default) { _ in
            leaveAction()
        })
        presenter.present(alertController, animated: true)
    }
}
