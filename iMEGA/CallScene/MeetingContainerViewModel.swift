
enum MeetingContainerAction: ActionType {
    case onViewReady
    case hangCall(presenter: UIViewController)
    case tapOnBackButton
    case changeMenuVisibility
    case showOptionsMenu(presenter: UIViewController, sender: UIBarButtonItem, isMyselfModerator: Bool)
    case hideOptionsMenu
    case shareLink(presenter: UIViewController?, sender: AnyObject, completion: UIActivityViewController.CompletionWithItemsHandler?)
    case renameChat
    case dismissCall(completion: (() -> Void)?)
}

final class MeetingContainerViewModel: ViewModelType {
    enum Command: CommandType, Equatable {
    }
    
    private let router: MeetingContainerRouting
    private let chatRoom: ChatRoomEntity
    private let callsUseCase: CallsUseCaseProtocol
    private let callManagerUseCase: CallManagerUseCaseProtocol
    private let userUseCase: UserUseCaseProtocol
    private let chatRoomUseCase: ChatRoomUseCaseProtocol
    private var call: CallEntity

    init(router: MeetingContainerRouting,
         chatRoom: ChatRoomEntity,
         call: CallEntity,
         callsUseCase: CallsUseCaseProtocol,
         chatRoomUseCase: ChatRoomUseCaseProtocol,
         callManagerUseCase: CallManagerUseCaseProtocol,
         userUseCase: UserUseCaseProtocol) {
        self.router = router
        self.chatRoom = chatRoom
        self.call = call
        self.callsUseCase = callsUseCase
        self.chatRoomUseCase = chatRoomUseCase
        self.callManagerUseCase = callManagerUseCase
        self.userUseCase = userUseCase
    }
    
    var invokeCommand: ((Command) -> Void)?
    
    func dispatch(_ action: MeetingContainerAction) {
        switch action {
        case .onViewReady:
            callManagerUseCase.addCall(call)
            callManagerUseCase.startCall(call)
            router.showMeetingUI(containerViewModel: self)
        case.hangCall(let presenter):
            hangCall(presenter: presenter)
        case .tapOnBackButton:
            router.dismiss(completion: nil)
        case .changeMenuVisibility:
            router.toggleFloatingPanel(containerViewModel: self)
        case .showOptionsMenu(let presenter, let sender, let isMyselfModerator):
            router.toggleFloatingPanel(containerViewModel: self)
            router.showOptionsMenu(presenter: presenter, sender: sender, isMyselfModerator: isMyselfModerator, containerViewModel: self)
        case .hideOptionsMenu:
            router.toggleFloatingPanel(containerViewModel: self)
        case .shareLink(let presenter, let sender, let completion):
            chatRoomUseCase.fetchPublicLink(forChatRoom: chatRoom) { [weak self] result in
                switch result {
                case .success(let link):
                    self?.router.shareLink(presenter: presenter, sender: sender, link: link, completion: completion)
                case .failure(_):
                    MEGALogDebug("Could not get the chat link")
                }
            }
        case .renameChat:
            router.renameChat()
        case .dismissCall(let completion):
            dismissCall(completion: completion)
        }
    }
    
    
    private func hangCall(presenter: UIViewController) {
        if userUseCase.hasUserLoggedIn {
            if MEGASdkManager.sharedMEGASdk().mnz_isGuestAccount {
                MEGASdkManager.sharedMEGASdk().logout()
            }
            dismissCall(completion: nil)
        } else {
            router.showEndMeetingOptions(presenter: presenter, meetingContainerViewModel: self)
        }
    }
    
    private func dismissCall(completion: (() -> Void)?) {
        callsUseCase.hangCall(for: call.callId)
        callManagerUseCase.endCall(call)
        router.dismiss(completion: completion)
    }
    
}
