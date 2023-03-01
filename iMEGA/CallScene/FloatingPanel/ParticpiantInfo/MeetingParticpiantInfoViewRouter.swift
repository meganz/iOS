import MEGADomain
import MEGAPresentation

protocol MeetingParticpiantInfoViewRouting: Routing {
    func showInfo()
    func openChatRoom(withChatId chatId: UInt64)
    func showInviteSuccess(email: String)
    func showInviteErrorMessage(_ message: String)
    func makeParticipantAsModerator()
    func removeModeratorPrivilage()
    func removeParticipant()
    func displayInMainView()
}

struct MeetingParticpiantInfoViewRouter: MeetingParticpiantInfoViewRouting {
    private let sender: UIButton
    private weak var presenter: UIViewController?
    private let participant: CallParticipantEntity
    private let isMyselfModerator: Bool
    private weak var meetingFloatingPanelModel: MeetingFloatingPanelViewModel?
    
    init(presenter: UIViewController,
         sender: UIButton,
         participant: CallParticipantEntity,
         isMyselfModerator: Bool,
         meetingFloatingPanelModel: MeetingFloatingPanelViewModel) {
        self.presenter = presenter
        self.sender = sender
        self.participant = participant
        self.isMyselfModerator = isMyselfModerator
        self.meetingFloatingPanelModel = meetingFloatingPanelModel
    }
    
    func build() -> UIViewController {
        let userImageUseCase = UserImageUseCase(
            userImageRepo: UserImageRepository(sdk: MEGASdkManager.sharedMEGASdk()),
            userStoreRepo: UserStoreRepository(store: MEGAStore.shareInstance()),
            thumbnailRepo: ThumbnailRepository.newRepo,
            fileSystemRepo: FileSystemRepository.newRepo
        )
        
        let chatRoomUseCase = ChatRoomUseCase(chatRoomRepo: ChatRoomRepository.sharedRepo)
        let chatRoomUserUseCase = ChatRoomUserUseCase(chatRoomRepo: ChatRoomUserRepository.newRepo,
                                                      userStoreRepo: UserStoreRepository(store: MEGAStore.shareInstance()))

        let userInviteUseCase = UserInviteUseCase(repo: UserInviteRepository(sdk: MEGASdkManager.sharedMEGASdk()))
        
        let viewModel = MeetingParticpiantInfoViewModel(participant: participant,
                                                        userImageUseCase: userImageUseCase,
                                                        chatRoomUseCase: chatRoomUseCase,
                                                        chatRoomUserUseCase: chatRoomUserUseCase,
                                                        userInviteUseCase: userInviteUseCase,
                                                        isMyselfModerator: isMyselfModerator,
                                                        router: self)
        let participantInfoViewController = MeetingParticipantInfoViewController(viewModel: viewModel, sender: sender)
        participantInfoViewController.overrideUserInterfaceStyle = .dark
        participantInfoViewController.popoverPresentationController?.backgroundColor = .clear
    
        return participantInfoViewController
    }
    
    func start() {
        presenter?.present(build(), animated: true)
    }
    
    // MARK:- Actions
    
    func showInfo() {
        guard let contactDetailsVC = UIStoryboard(name: "Contacts", bundle: nil).instantiateViewController(withIdentifier: "ContactDetailsViewControllerID") as? ContactDetailsViewController else {
            return
        }
        
        contactDetailsVC.contactDetailsMode = .meeting
        contactDetailsVC.userEmail = participant.email
        contactDetailsVC.userHandle = participant.participantId
        
        presenter?.present(MEGANavigationController(rootViewController: contactDetailsVC), animated: true)
    }
    
    func makeParticipantAsModerator() {
        meetingFloatingPanelModel?.dispatch(.makeModerator(participant: participant))
    }
    
    func removeModeratorPrivilage() {
        meetingFloatingPanelModel?.dispatch(.removeModeratorPrivilage(forParticipant: participant))
    }
    
    func removeParticipant() {
        meetingFloatingPanelModel?.dispatch(.removeParticipant(participant: participant))
    }
    
    func openChatRoom(withChatId chatId: UInt64) {
        guard let chatViewController = ChatViewController(chatId: chatId) else { return }
        presenter?.present(MEGANavigationController(rootViewController: chatViewController),
                           animated: true)
    }
    
    func showInviteSuccess(email: String) {
        let customModalAlertViewController = CustomModalAlertViewController()
        customModalAlertViewController.image = Asset.Images.Contacts.inviteSent.image
        customModalAlertViewController.viewTitle = Strings.Localizable.inviteSent
        customModalAlertViewController.detail = Strings.Localizable.theUsersHaveBeenInvited
        customModalAlertViewController.boldInDetail = email
        customModalAlertViewController.firstButtonTitle = Strings.Localizable.close
        customModalAlertViewController.firstCompletion = { [weak customModalAlertViewController] in
            customModalAlertViewController?.dismiss(animated: true, completion: nil)
        }
        
        presenter?.present(customModalAlertViewController, animated: true)
    }

    func showInviteErrorMessage(_ message: String) {
        SVProgressHUD.showError(withStatus: message)
    }

    func displayInMainView() {
        meetingFloatingPanelModel?.dispatch(.displayParticipantInMainView(participant))
    }
}
