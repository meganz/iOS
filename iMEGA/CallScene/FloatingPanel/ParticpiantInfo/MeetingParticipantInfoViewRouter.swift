import ChatRepo
import MEGAAppPresentation
import MEGADomain
import MEGAL10n
import MEGARepo
import MEGASDKRepo

protocol MeetingParticipantInfoViewRouting: Routing {
    func showInfo(withEmail email: String?)
    func openChatRoom(_ chatRoom: ChatRoomEntity)
    func makeParticipantAsModerator()
    func removeModeratorPrivilege()
    func removeParticipant()
    func displayInMainView()
    func muteParticipant(_ participant: CallParticipantEntity)
}

struct MeetingParticipantInfoViewRouter: MeetingParticipantInfoViewRouting {
    private let sender: UIButton
    private var presenter: UIViewController
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
            userImageRepo: UserImageRepository.newRepo,
            userStoreRepo: UserStoreRepository(store: MEGAStore.shareInstance()),
            thumbnailRepo: ThumbnailRepository.newRepo,
            fileSystemRepo: FileSystemRepository.newRepo
        )
        
        let chatRoomUseCase = ChatRoomUseCase(chatRoomRepo: ChatRoomRepository.newRepo)
        let chatRoomUserUseCase = ChatRoomUserUseCase(chatRoomRepo: ChatRoomUserRepository.newRepo,
                                                      userStoreRepo: UserStoreRepository(store: MEGAStore.shareInstance()))
        
        let megaHandleUseCase = MEGAHandleUseCase(repo: MEGAHandleRepository.newRepo)
        
        let viewModel = MeetingParticipantInfoViewModel(participant: participant,
                                                        userImageUseCase: userImageUseCase,
                                                        chatRoomUseCase: chatRoomUseCase,
                                                        chatRoomUserUseCase: chatRoomUserUseCase,
                                                        megaHandleUseCase: megaHandleUseCase,
                                                        contactsUseCase: ContactsUseCase(repository: ContactsRepository.newRepo),
                                                        isMyselfModerator: isMyselfModerator,
                                                        router: self)
        let participantInfoViewController = MeetingParticipantInfoViewController(viewModel: viewModel, sender: sender)
        participantInfoViewController.overrideUserInterfaceStyle = .dark
        participantInfoViewController.popoverPresentationController?.backgroundColor = .clear
    
        return participantInfoViewController
    }
    
    func start() {
        presenter.present(build(), animated: true)
    }
    
    // MARK: - Actions
    
    func showInfo(withEmail email: String?) {
        guard let contactDetailsVC = UIStoryboard(name: "Contacts", bundle: nil).instantiateViewController(withIdentifier: "ContactDetailsViewControllerID") as? ContactDetailsViewController else {
            return
        }
        
        contactDetailsVC.contactDetailsMode = .meeting
        contactDetailsVC.userEmail = email
        contactDetailsVC.userHandle = participant.participantId
        
        presenter.present(MEGANavigationController(rootViewController: contactDetailsVC), animated: true)
    }
    
    func makeParticipantAsModerator() {
        meetingFloatingPanelModel?.dispatch(.makeModerator(participant: participant))
    }
    
    func removeModeratorPrivilege() {
        meetingFloatingPanelModel?.dispatch(.removeModeratorPrivilege(forParticipant: participant))
    }
    
    func removeParticipant() {
        meetingFloatingPanelModel?.dispatch(.removeParticipant(participant: participant))
    }
    
    func openChatRoom(_ chatRoom: ChatRoomEntity) {
        ChatContentRouter(chatRoom: chatRoom, presenter: presenter, chatContentRoutingStyle: .present).start()
    }

    func displayInMainView() {
        meetingFloatingPanelModel?.dispatch(.displayParticipantInMainView(participant))
    }
    
    func muteParticipant(_ participant: CallParticipantEntity) {
        meetingFloatingPanelModel?.dispatch(.muteParticipant(participant))
    }
}
