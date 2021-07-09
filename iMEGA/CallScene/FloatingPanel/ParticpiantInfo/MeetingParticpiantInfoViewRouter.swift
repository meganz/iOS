

protocol MeetingParticpiantInfoViewRouting: Routing {
    func showInfo()
    func openChatRoom(withChatId chatId: UInt64)
    func showInviteSuccess(email: String)
    func showInviteError(_ error: InviteError, email: String)
    func updateAttendeeAsModerator()
    func updateAttendeeAsParticipant()
}

struct MeetingParticpiantInfoViewRouter: MeetingParticpiantInfoViewRouting {
    private let sender: UIButton
    private weak var presenter: UIViewController?
    private let attendee: CallParticipantEntity
    private let isMyselfModerator: Bool
    private weak var meetingFloatingPanelModel: MeetingFloatingPanelViewModel?
    
    init(presenter: UIViewController,
         sender: UIButton,
         attendee: CallParticipantEntity,
         isMyselfModerator: Bool,
         meetingFloatingPanelModel: MeetingFloatingPanelViewModel) {
        self.presenter = presenter
        self.sender = sender
        self.attendee = attendee
        self.isMyselfModerator = isMyselfModerator
        self.meetingFloatingPanelModel = meetingFloatingPanelModel
    }
    
    func build() -> UIViewController {
        let userImageUseCase = UserImageUseCase(
            userImageRepo: UserImageRepository(sdk: MEGASdkManager.sharedMEGASdk()),
            userStoreRepo: UserStoreRepository(store: MEGAStore.shareInstance()),
            appGroupFilePathUseCase: MEGAAppGroupFilePathUseCase(fileManager: FileManager.default)
        )
        
        let chatRoomRepository = ChatRoomRepository(sdk: MEGASdkManager.sharedMEGAChatSdk())
        let chatRoomUseCase = ChatRoomUseCase(chatRoomRepo: chatRoomRepository,
                                               userStoreRepo: UserStoreRepository(store: MEGAStore.shareInstance()))

        let userInviteUseCase = UserInviteUseCase(repo: UserInviteRepository(sdk: MEGASdkManager.sharedMEGASdk()))
        
        let viewModel = MeetingParticpiantInfoViewModel(attendee: attendee,
                                                        userImageUseCase: userImageUseCase,
                                                        chatRoomUseCase: chatRoomUseCase,
                                                        userInviteUseCase: userInviteUseCase,
                                                        isMyselfModerator: isMyselfModerator,
                                                        router: self)
        let participantInfoViewController = MeetingParticipantInfoViewController(viewModel: viewModel, sender: sender)
        if #available(iOS 13.0, *) {
            participantInfoViewController.overrideUserInterfaceStyle = .dark
        }
    
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
        contactDetailsVC.userEmail = attendee.email
        contactDetailsVC.userHandle = attendee.participantId
        
        presenter?.present(MEGANavigationController(rootViewController: contactDetailsVC), animated: true)
    }
    
    func updateAttendeeAsModerator() {
        meetingFloatingPanelModel?.dispatch(.makeModerator(participant: attendee))
    }
    
    func updateAttendeeAsParticipant() {
        meetingFloatingPanelModel?.dispatch(.removeModerator(participant: attendee))
    }
    
    func openChatRoom(withChatId chatId: UInt64) {
        presenter?.present(MEGANavigationController(rootViewController: ChatViewController(chatId: chatId)),
                           animated: true)
    }
    
    func showInviteSuccess(email: String) {
        let customModalAlertViewController = CustomModalAlertViewController()
        customModalAlertViewController.image = UIImage(named: "inviteSent")
        customModalAlertViewController.viewTitle = NSLocalizedString("inviteSent", comment: "")
        customModalAlertViewController.detail = NSLocalizedString("theUsersHaveBeenInvited", comment: "")
        customModalAlertViewController.boldInDetail = email
        customModalAlertViewController.firstButtonTitle = NSLocalizedString("close", comment: "")
        customModalAlertViewController.firstCompletion = { [weak customModalAlertViewController] in
            customModalAlertViewController?.dismiss(animated: true, completion: nil)
        }
        
        presenter?.present(customModalAlertViewController, animated: true)
    }

    func showInviteError(_ error: InviteError, email: String) {
        switch error {
        case .generic(let errorString):
            SVProgressHUD.showError(withStatus: errorString)
        case .ownEmailEntered:
            SVProgressHUD.showError(withStatus: NSLocalizedString("noNeedToAddYourOwnEmailAddress", comment: ""))
        case .alreadyAContact:
            let errorString = NSLocalizedString("alreadyAContact", comment: "").replacingOccurrences(of: "%s", with: email)
            SVProgressHUD.showError(withStatus: errorString)
        case .isInOutgoingContactRequest:
            SVProgressHUD.showError(withStatus: NSLocalizedString("theUserHasBeenInvited", comment: ""))
        }
    }

}
