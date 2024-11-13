import MEGADomain
import MEGAPresentation

struct MeetingOptionsMenuRouter: Routing {
    private let sender: UIBarButtonItem
    private weak var presenter: UIViewController?
    private let isMyselfModerator: Bool
    private let chatRoom: ChatRoomEntity
    private weak var containerViewModel: MeetingContainerViewModel?

    init(presenter: UIViewController,
         sender: UIBarButtonItem,
         isMyselfModerator: Bool,
         chatRoom: ChatRoomEntity,
         containerViewModel: MeetingContainerViewModel) {
        self.presenter = presenter
        self.sender = sender
        self.isMyselfModerator = isMyselfModerator
        self.chatRoom = chatRoom
        self.containerViewModel = containerViewModel
    }
    
    func build() -> UIViewController {
        let viewModel = MeetingOptionsMenuViewModel(
            chatRoom: chatRoom,
            isMyselfModerator: isMyselfModerator,
            containerViewModel: containerViewModel,
            sender: sender,
            tracker: DIContainer.tracker
        )
        
        return MeetingOptionsMenuViewController(viewModel: viewModel, sender: sender)
    }
    
    func start() {
        presenter?.present(build(), animated: true)
    }
}
