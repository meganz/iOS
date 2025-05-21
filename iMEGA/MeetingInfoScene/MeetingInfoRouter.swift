import ChatRepo
import Combine
import MEGAAppSDKRepo
import MEGAAssets
import MEGADomain
import MEGAL10n
import MEGAPreference
import MEGARepo

@MainActor
final class MeetingInfoRouter: NSObject, MeetingInfoRouting {
    private(set) var presenter: UINavigationController
    private let scheduledMeeting: ScheduledMeetingEntity
    private var inviteToMegaNavigationController: MEGANavigationController?
    private var sendToChatWrapper: SendToChatWrapper?

    init(presenter: UINavigationController,
         scheduledMeeting: ScheduledMeetingEntity) {
        self.presenter = presenter
        self.scheduledMeeting = scheduledMeeting
    }
    
    func build() -> UIViewController {
        let chatRoomUseCase = ChatRoomUseCase(chatRoomRepo: ChatRoomRepository.newRepo)
        
        let chatRoomUserUseCase = ChatRoomUserUseCase(
            chatRoomRepo: ChatRoomUserRepository.newRepo,
            userStoreRepo: UserStoreRepository(store: .shareInstance())
        )
        
        let userImageUseCase = UserImageUseCase(
            userImageRepo: UserImageRepository(sdk: MEGASdk.shared),
            userStoreRepo: UserStoreRepository(store: MEGAStore.shareInstance()),
            thumbnailRepo: ThumbnailRepository.newRepo,
            fileSystemRepo: FileSystemRepository.sharedRepo
        )
        
        let viewModel = MeetingInfoViewModel(
            scheduledMeeting: scheduledMeeting,
            router: self,
            chatRoomUseCase: chatRoomUseCase,
            chatRoomUserUseCase: chatRoomUserUseCase,
            userImageUseCase: userImageUseCase,
            chatUseCase: ChatUseCase(chatRepo: ChatRepository.newRepo),
            accountUseCase: AccountUseCase(repository: AccountRepository.newRepo),
            chatLinkUseCase: ChatLinkUseCase(chatLinkRepository: ChatLinkRepository.newRepo),
            megaHandleUseCase: MEGAHandleUseCase(repo: MEGAHandleRepository.newRepo)
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
        ManageChatHistoryViewRouter(chatId: chatRoom.chatId, isChatTypeMeeting: true, navigationController: presenter).start()
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
    
    func showShareMeetingLinkActivity(_ link: String, metadataItemSource: ChatLinkPresentationItemSource) {
        guard let sourceView = presenter.viewControllers.first?.view else { return }
        let shareActivity = UIActivityViewController(activityItems: [metadataItemSource], applicationActivities: [SendToChatActivity(text: link)])
        shareActivity.popoverPresentationController?.sourceView = sourceView
        presenter.present(shareActivity, animated: true)
    }

    func sendLinkToChat(_ link: String) {
        let sendToChatWrapper = SendToChatWrapper(link: link)
        self.sendToChatWrapper = sendToChatWrapper
        sendToChatWrapper.showSendToChat(presenter: presenter)
    }

    func showLinkCopied() {
        SVProgressHUD.show(MEGAAssets.UIImage.hudSuccess, status: Strings.Localizable.Meetings.Info.ShareOptions.ShareLink.linkCopied)
    }
    
    func showParticipantDetails(email: String, userHandle: HandleEntity, chatRoom: ChatRoomEntity, didUpdatePeerPermission: @escaping (ChatRoomParticipantPrivilege) -> Void) {
        guard let contactDetailsVC = UIStoryboard(name: "Contacts", bundle: nil).instantiateViewController(withIdentifier: "ContactDetailsViewControllerID") as? ContactDetailsViewController else {
            return
        }
        contactDetailsVC.contactDetailsMode = .fromGroupChat
        contactDetailsVC.userEmail = email
        contactDetailsVC.userHandle = userHandle
        contactDetailsVC.groupChatRoom = chatRoom.toMEGAChatRoom()
        contactDetailsVC.didUpdatePeerPermission = { peerPrivilege in
            didUpdatePeerPermission(peerPrivilege.toChatRoomPrivilegeEntity().toChatRoomParticipantPrivilege())
        }
        
        presenter.pushViewController(contactDetailsVC, animated: true)
    }
    
    func inviteParticipants(
        withParticipantsAddingViewFactory participantsAddingViewFactory: ParticipantsAddingViewFactory,
        excludeParticipantsId: Set<HandleEntity>,
        selectedUsersHandler: @escaping (([HandleEntity]) -> Void)
    ) {
        guard let contactsNavigationController = participantsAddingViewFactory.addContactsViewController(
            withContactsMode: .inviteParticipants,
            additionallyExcludedParticipantsId: excludeParticipantsId,
            selectedUsersHandler: selectedUsersHandler
        ) else { return }
        
        presenter.present(contactsNavigationController, animated: true)
    }
    
    func showAllContactsAlreadyAddedAlert(withParticipantsAddingViewFactory participantsAddingViewFactory: ParticipantsAddingViewFactory) {
        showContactsAlert(withParticipantsAddingViewFactory: participantsAddingViewFactory,
                          action: participantsAddingViewFactory.allContactsAlreadyAddedAlert)
        
    }
    
    func showNoAvailableContactsAlert(withParticipantsAddingViewFactory participantsAddingViewFactory: ParticipantsAddingViewFactory) {
        showContactsAlert(withParticipantsAddingViewFactory: participantsAddingViewFactory,
                          action: participantsAddingViewFactory.noAvailableContactsAlert)
    }
    
    func edit(meeting: ScheduledMeetingEntity) -> AnyPublisher<ScheduledMeetingEntity, Never> {
        let viewConfiguration = ScheduleMeetingUpdateViewConfiguration(
            scheduledMeeting: meeting,
            chatUseCase: ChatUseCase(chatRepo: ChatRepository.newRepo),
            chatRoomUseCase: ChatRoomUseCase(chatRoomRepo: ChatRoomRepository.newRepo),
            chatLinkUseCase: ChatLinkUseCase(chatLinkRepository: ChatLinkRepository.newRepo),
            scheduledMeetingUseCase: ScheduledMeetingUseCase(repository: ScheduledMeetingRepository.newRepo)
        )
        
        let router = ScheduleMeetingRouter(
            presenter: presenter,
            viewConfiguration: viewConfiguration,
            shareLinkRouter: ShareLinkDialogRouter(presenter: presenter)
        )
        router.start()
        return router.onMeetingUpdate()
    }
    
    // MARK: - Private methods.
    
    private func showInviteToMega(_ inviteContactsViewController: InviteContactViewController) {
        let navigationController = MEGANavigationController(rootViewController: inviteContactsViewController)
        
        let backBarButton = UIBarButtonItem(
            image: MEGAAssets.UIImage.backArrow,
            style: .plain,
            target: self,
            action: #selector(self.dismissInviteContactsScreen)
        )
        
        navigationController.addLeftDismissBarButton(backBarButton)
        navigationController.overrideUserInterfaceStyle = .dark
        self.inviteToMegaNavigationController = navigationController
        presenter.present(navigationController, animated: true)
    }
    
    private func showContactsAlert(
        withParticipantsAddingViewFactory participantsAddingViewFactory: ParticipantsAddingViewFactory,
        action: (@escaping () -> Void) -> UIAlertController
    ) {
        let contactsAlert = action {
            guard let inviteContactController = participantsAddingViewFactory.inviteContactController() else { return }
            self.showInviteToMega(inviteContactController)
        }
        
        contactsAlert.overrideUserInterfaceStyle = .dark
        presenter.present(contactsAlert, animated: true)
    }
    
    @objc private func dismissInviteContactsScreen() {
        self.inviteToMegaNavigationController?.dismiss(animated: true)
        self.inviteToMegaNavigationController = nil
    }
}
