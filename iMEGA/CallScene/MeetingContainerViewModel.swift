
enum MeetingContainerAction: ActionType {
    case onViewReady
    case hangCall
    case tapOnBackButton
    case changeMenuVisibility
}

final class MeetingContainerViewModel: ViewModelType {
    enum Command: CommandType, Equatable {
    }
    
    private let router: MeetingContainerRouting
    private let chatRoom: ChatRoomEntity
    private let callsUseCase: CallsUseCaseProtocol
    private let callManagerUseCase: CallManagerUseCaseProtocol
    private var call: CallEntity

    init(router: MeetingContainerRouting,
         chatRoom: ChatRoomEntity,
         call: CallEntity,
         callsUseCase: CallsUseCaseProtocol,
         callManagerUseCase: CallManagerUseCaseProtocol) {
        self.router = router
        self.chatRoom = chatRoom
        self.call = call
        self.callsUseCase = callsUseCase
        self.callManagerUseCase = callManagerUseCase
    }
    
    var invokeCommand: ((Command) -> Void)?
    
    func dispatch(_ action: MeetingContainerAction) {
        switch action {
        case .onViewReady:
            callManagerUseCase.addCall(call)
            callManagerUseCase.startCall(call)
            router.showMeetingUI(containerViewModel: self)
        case.hangCall:
            hangCall()
        case .tapOnBackButton:
            router.dismiss()
        case .changeMenuVisibility:
            router.toggleFloatingPanel(containerViewModel: self)
        }
    }
    
    
    private func hangCall() {
        callManagerUseCase.endCall(callId: call.callId, chatId: chatRoom.chatId)
        callsUseCase.hangCall(for: call.callId)
        router.dismiss()
    }
    
}
