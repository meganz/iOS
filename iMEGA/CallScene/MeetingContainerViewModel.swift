
enum MeetingContainerAction: ActionType {
    case onViewReady
    case hangCall(presenter: UIViewController)
    case tapOnBackButton
    case changeMenuVisibility
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
    private var call: CallEntity

    init(router: MeetingContainerRouting,
         chatRoom: ChatRoomEntity,
         call: CallEntity,
         callsUseCase: CallsUseCaseProtocol,
         callManagerUseCase: CallManagerUseCaseProtocol,
         userUseCase: UserUseCaseProtocol) {
        self.router = router
        self.chatRoom = chatRoom
        self.call = call
        self.callsUseCase = callsUseCase
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
        case .dismissCall(let completion):
            dismissCall(completion: completion)
        }
    }
    
    
    private func hangCall(presenter: UIViewController) {
        if userUseCase.hasUserLoggedIn {
            dismissCall(completion: nil)
        } else {
            router.showEndMeetingOptions(presenter: presenter, meetingContainerViewModel: self)
        }
    }
    
    private func dismissCall(completion: (() -> Void)?) {
        callManagerUseCase.endCall(callId: call.callId, chatId: chatRoom.chatId)
        callsUseCase.hangCall(for: call.callId)
        router.dismiss(completion: completion)
    }
    
}
