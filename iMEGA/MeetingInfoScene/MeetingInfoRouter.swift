import MEGADomain

@available(iOS 14.0, *)
final class MeetingInfoRouter: NSObject, MeetingInfoRouting {
    private(set) var presenter: UINavigationController
    private let scheduledMeeting: ScheduledMeetingEntity
    private var link: String?

    init(presenter: UINavigationController,
         scheduledMeeting: ScheduledMeetingEntity) {
        self.presenter = presenter
        self.scheduledMeeting = scheduledMeeting
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
            scheduledMeeting: scheduledMeeting,
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
    
    func showShareActivity(_ link: String, title: String?, description: String?) {
        guard let url = URL(string: link) else { return }
        let metadataItemSource = ContactLinkPresentationItemSource(title: title ?? "", description: description ?? "", icon: Asset.Images.Logo.megaShareContactLink, url: url)
        let shareActivity = UIActivityViewController(activityItems: [metadataItemSource], applicationActivities: [SendToChatActivity(text: link)])
        presenter.present(shareActivity, animated: true)
    }

    func showSendToChat(_ link: String) {
        self.link = link
        guard let navigationController =
                UIStoryboard(name: "Chat", bundle: nil).instantiateViewController(withIdentifier: "SendToNavigationControllerID") as? MEGANavigationController, let sendToViewController = navigationController.viewControllers.first as? SendToViewController else {
            return
        }
        
        sendToViewController.sendToChatActivityDelegate = self
        sendToViewController.sendMode = .text
        
        presenter.present(navigationController, animated: true)
    }

    func showLinkCopied() {
        SVProgressHUD.show(Asset.Images.Hud.hudSuccess.image, status: Strings.Localizable.Meetings.Info.ShareOptions.ShareLink.linkCopied)
    }
}

@available(iOS 14.0, *)
extension MeetingInfoRouter: SendToChatActivityDelegate {
    func send(_ viewController: SendToViewController!, didFinishActivity completed: Bool) {
        viewController.dismiss(animated: true)
    }
    
    func textToSend() -> String {
        link ?? ""
    }
}
