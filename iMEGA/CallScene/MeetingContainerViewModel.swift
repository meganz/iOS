
enum MeetingContainerAction: ActionType {
    case onViewReady
    case hangCall(presenter: UIViewController, sender: UIButton)
    case tapOnBackButton
    case changeMenuVisibility
    case showOptionsMenu(presenter: UIViewController, sender: UIBarButtonItem, isMyselfModerator: Bool)
    case hideOptionsMenu
    case shareLink(presenter: UIViewController?, sender: AnyObject, completion: UIActivityViewController.CompletionWithItemsHandler?)
    case renameChat
    case dismissCall(completion: (() -> Void)?)
    case endGuestUserCall(completion: (() -> Void)?)
    case speakerEnabled(_ enabled: Bool)
    case onAddingParticipant
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
    private let authUseCase: AuthUseCaseProtocol
    private var call: CallEntity
    private let isAnsweredFromCallKit: Bool

    init(router: MeetingContainerRouting,
         chatRoom: ChatRoomEntity,
         call: CallEntity,
         callsUseCase: CallsUseCaseProtocol,
         chatRoomUseCase: ChatRoomUseCaseProtocol,
         callManagerUseCase: CallManagerUseCaseProtocol,
         userUseCase: UserUseCaseProtocol,
         authUseCase: AuthUseCaseProtocol,
         isAnsweredFromCallKit: Bool) {
        self.router = router
        self.chatRoom = chatRoom
        self.call = call
        self.callsUseCase = callsUseCase
        self.chatRoomUseCase = chatRoomUseCase
        self.callManagerUseCase = callManagerUseCase
        self.userUseCase = userUseCase
        self.authUseCase = authUseCase
        self.isAnsweredFromCallKit = isAnsweredFromCallKit
    }
    
    var invokeCommand: ((Command) -> Void)?
    
    func dispatch(_ action: MeetingContainerAction) {
        switch action {
        case .onViewReady:
            if !isAnsweredFromCallKit {
                callManagerUseCase.addCall(call)
                callManagerUseCase.startCall(call)
            }
            router.showMeetingUI(containerViewModel: self)
        case.hangCall(let presenter, let sender):
            hangCall(presenter: presenter, sender: sender)
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
                guard let self = self else { return }
                switch result {
                case .success(let link):
                    self.router.shareLink(presenter: presenter,
                                          sender: sender,
                                          link: link,
                                          isGuestAccount: self.userUseCase.isGuestAccount,
                                          completion: completion)
                case .failure(_):
                    self.router.showShareMeetingError()
                }
            }
        case .renameChat:
            router.renameChat()
        case .dismissCall(let completion):
            dismissCall(completion: completion)
        case .endGuestUserCall(let completion):
            dismissCall {
                if self.userUseCase.isGuestAccount {
                    self.authUseCase.logout()
                }
                
                guard let completion = completion else { return }
                completion()
            }
        case .speakerEnabled(let speakerEnabled):
            router.enableSpeaker(speakerEnabled)
        case .onAddingParticipant:
            if (chatRoomUseCase.chatRoom(forChatId: call.chatId)?.peerCount ?? 0) == 0 {
                router.didAddFirstParticipant()
            }
        }
    }
    
    
    private func hangCall(presenter: UIViewController, sender: UIButton) {
        if !userUseCase.isGuestAccount {
            dismissCall(completion: nil)
        } else {
            router.showEndMeetingOptions(presenter: presenter,
                                         meetingContainerViewModel: self,
                                         sender: sender)
        }
    }
    
    private func dismissCall(completion: (() -> Void)?) {
        if let call = callsUseCase.call(for: call.chatId) {
            if let callId = MEGASdk.base64Handle(forUserHandle: call.callId),
               let chatId = MEGASdk.base64Handle(forUserHandle: call.chatId) {
                MEGALogDebug("Meeting: Container view model - Hang call for call id \(callId) and chat id \(chatId)")
            } else {
                MEGALogDebug("Meeting: Container view model -Hang call - cannot get the call id and chat id string")
            }

            callsUseCase.hangCall(for: call.callId)
            callManagerUseCase.endCall(call)
        }
       
        router.dismiss(completion: completion)
    }
    
}
