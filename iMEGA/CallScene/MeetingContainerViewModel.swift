import Combine
import MEGADomain
import MEGAPresentation

enum MeetingContainerAction: ActionType {
    case onViewReady
    case hangCall(presenter: UIViewController?, sender: UIButton?)
    case tapOnBackButton
    case changeMenuVisibility
    case showOptionsMenu(presenter: UIViewController, sender: UIBarButtonItem, isMyselfModerator: Bool)
    case hideOptionsMenu
    case shareLink(presenter: UIViewController?, sender: AnyObject, completion: UIActivityViewController.CompletionWithItemsHandler?)
    case renameChat
    case dismissCall(completion: (() -> Void)?)
    case endGuestUserCall(completion: (() -> Void)?)
    case speakerEnabled(_ enabled: Bool)
    case displayParticipantInMainView(_ participant: CallParticipantEntity)
    case didDisplayParticipantInMainView(_ participant: CallParticipantEntity)
    case didSwitchToGridView
    case participantAdded
    case participantRemoved
    case showEndCallDialogIfNeeded
    case removeEndCallAlertAndEndCall
    case showJoinMegaScreen
    case showHangOrEndCallDialog
    case endCallForAll
}

final class MeetingContainerViewModel: ViewModelType {
    enum Command: CommandType, Equatable {
    }
    
    private enum Constants {
        static let muteMicTimerDuration = 60 // 1 minute
    }
    
    private let router: MeetingContainerRouting
    private let chatRoom: ChatRoomEntity
    private let callUseCase: CallUseCaseProtocol
    private let callCoordinatorUseCase: CallCoordinatorUseCaseProtocol
    private let userUseCase: UserUseCaseProtocol
    private let chatRoomUseCase: ChatRoomUseCaseProtocol
    private let authUseCase: AuthUseCaseProtocol
    private let noUserJoinedUseCase: MeetingNoUserJoinedUseCaseProtocol
    private let analyticsEventUseCase: AnalyticsEventUseCaseProtocol
    private var noUserJoinedSubscription: AnyCancellable?
    private var muteMicSubscription: AnyCancellable?

    private var call: CallEntity? {
        callUseCase.call(for: chatRoom.chatId)
    }
    
    private var isOneToOneChat: Bool {
        chatRoomUseCase.chatRoom(forChatId: chatRoom.chatId)?.chatType == .oneToOne
    }

    init(router: MeetingContainerRouting,
         chatRoom: ChatRoomEntity,
         callUseCase: CallUseCaseProtocol,
         chatRoomUseCase: ChatRoomUseCaseProtocol,
         callCoordinatorUseCase: CallCoordinatorUseCaseProtocol,
         userUseCase: UserUseCaseProtocol,
         authUseCase: AuthUseCaseProtocol,
         noUserJoinedUseCase: MeetingNoUserJoinedUseCaseProtocol,
         analyticsEventUseCase: AnalyticsEventUseCaseProtocol) {
        self.router = router
        self.chatRoom = chatRoom
        self.callUseCase = callUseCase
        self.chatRoomUseCase = chatRoomUseCase
        self.callCoordinatorUseCase = callCoordinatorUseCase
        self.userUseCase = userUseCase
        self.authUseCase = authUseCase
        self.noUserJoinedUseCase = noUserJoinedUseCase
        self.analyticsEventUseCase = analyticsEventUseCase
        
        let callUUID = callUseCase.call(for: chatRoom.chatId)?.uuid
        self.callCoordinatorUseCase.addCallRemoved { [weak self] uuid in
            guard let uuid = uuid, let self = self, callUUID == uuid else { return }
            self.callCoordinatorUseCase.removeCallRemovedHandler()
            router.dismiss(animated: false, completion: nil)
        }
    }
    
    var invokeCommand: ((Command) -> Void)?
    
    func dispatch(_ action: MeetingContainerAction) {
        switch action {
        case .onViewReady:
            router.showMeetingUI(containerViewModel: self)
            if isOneToOneChat == false {
                muteMicSubscription = Just(Void.self)
                    .delay(for: .seconds(Constants.muteMicTimerDuration), scheduler: RunLoop.main)
                    .sink() { [weak self] _ in
                        guard let self = self else { return }

                        self.muteMicrophoneIfNoOtherParticipantsArePresent()
                        self.muteMicSubscription = nil
                    }
                
                noUserJoinedSubscription = noUserJoinedUseCase
                    .monitor
                    .receive(on: DispatchQueue.main)
                    .sink() { [weak self] in
                        guard let self = self else { return }
                        
                        self.showEndCallDialogIfNeeded {
                            self.cancelNoUserJoinedSubscription()
                        }
                        self.noUserJoinedSubscription = nil
                }
            }
        case .hangCall(let presenter, let sender):
            hangCall(presenter: presenter, sender: sender)
        case .tapOnBackButton:
            router.dismiss(animated: true, completion: nil)
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
                                          isGuestAccount: self.userUseCase.isGuest,
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
                if self.userUseCase.isGuest {
                    self.authUseCase.logout()
                }
                
                guard let completion = completion else { return }
                completion()
            }
        case .speakerEnabled(let speakerEnabled):
            router.enableSpeaker(speakerEnabled)
        case .displayParticipantInMainView(let participant):
            router.displayParticipantInMainView(participant)
        case .didDisplayParticipantInMainView(let participant):
            router.didDisplayParticipantInMainView(participant)
        case .didSwitchToGridView:
            router.didSwitchToGridView()
        case .participantAdded:
            cancelMuteMicrophoneSubscription()
            cancelNoUserJoinedSubscription()
            router.removeEndCallDialog(completion: nil)
        case .participantRemoved:
            muteMicrophoneIfNoOtherParticipantsArePresent()
        case .showEndCallDialogIfNeeded:
            showEndCallDialogIfNeeded()
        case .removeEndCallAlertAndEndCall:
            removeEndCallAlertAndEndCall()
        case .showJoinMegaScreen:
            router.showJoinMegaScreen()
        case .showHangOrEndCallDialog:
            router.showHangOrEndCallDialog(containerViewModel: self)
        case .endCallForAll:
            endCallForAll()
        }
    }
    
    //MARK: -Private
    private func hangCall(presenter: UIViewController?, sender: UIButton?) {
        if !userUseCase.isGuest {
            dismissCall(completion: nil)
        } else {
            guard let presenter = presenter, let sender = sender else {
                return
            }
            router.showEndMeetingOptions(presenter: presenter,
                                         meetingContainerViewModel: self,
                                         sender: sender)
        }
    }
    
    private func endCallForAll() {
        if let call = call {
            if let callId = MEGASdk.base64Handle(forUserHandle: call.callId),
               let chatId = MEGASdk.base64Handle(forUserHandle: call.chatId) {
                MEGALogDebug("Meeting: Container view model - End call for all - for call id \(callId) and chat id \(chatId)")
            } else {
                MEGALogDebug("Meeting: Container view model - End call for all - cannot get the call id and chat id string")
            }
            
            callCoordinatorUseCase.removeCallRemovedHandler()
            callUseCase.endCall(for: call.callId)
            callCoordinatorUseCase.endCall(call)
        }
        
        router.dismiss(animated: true, completion: nil)
    }
    
    private func dismissCall(completion: (() -> Void)?) {
        if let call = call {
            if let callId = MEGASdk.base64Handle(forUserHandle: call.callId),
               let chatId = MEGASdk.base64Handle(forUserHandle: call.chatId) {
                MEGALogDebug("Meeting: Container view model - Hang call for call id \(callId) and chat id \(chatId)")
            } else {
                MEGALogDebug("Meeting: Container view model -Hang call - cannot get the call id and chat id string")
            }

            callCoordinatorUseCase.removeCallRemovedHandler()
            callUseCase.hangCall(for: call.callId)
            callCoordinatorUseCase.endCall(call)
        }
       
        router.dismiss(animated: true, completion: completion)
    }
    
    private func muteMicrophoneIfNoOtherParticipantsArePresent() {
        if let call = call,
           call.hasLocalAudio,
           isOneToOneChat == false,
           isOnlyMyselfInTheMeeting() {
            callCoordinatorUseCase.muteUnmuteCall(call, muted: true)
        }
    }
    
    private func isOnlyMyselfInTheMeeting() -> Bool {
        guard let call = call,
           call.numberOfParticipants == 1,
           call.participants.first == userUseCase.myHandle else {
            return false
        }
        
        return true
    }
    
    private func showEndCallDialogIfNeeded(stayOnCallCompletion: (() -> Void)? = nil) {
        guard isOnlyMyselfInTheMeeting() else { return }
        router.showEndCallDialog { [weak self] in
            guard let self = self else { return }
            self.analyticsEventUseCase.sendAnalyticsEvent(.meetings(.endCallInNoParticipantsPopup))
            self.endCall()
        } stayOnCallCompletion: { [weak self] in
            guard let self = self else { return }
            self.analyticsEventUseCase.sendAnalyticsEvent(.meetings(.stayOnCallInNoParticipantsPopup))
            stayOnCallCompletion?()
        }
    }
    
    private func cancelMuteMicrophoneSubscription() {
        muteMicSubscription?.cancel()
        muteMicSubscription = nil
    }
    
    private func cancelNoUserJoinedSubscription() {
        noUserJoinedSubscription?.cancel()
        noUserJoinedSubscription = nil
    }
    
    private func removeEndCallAlertAndEndCall() {
        router.removeEndCallDialog { [weak self] in
            guard let self = self else { return }
            self.endCall()
        }
    }
    
    private func endCall() {
        if self.userUseCase.isGuest {
            self.dispatch(.endGuestUserCall {
                self.dispatch(.showJoinMegaScreen)
            })
        } else {
            self.dismissCall(completion: nil)
        }
    }
    
    deinit {
        cancelMuteMicrophoneSubscription()
        cancelNoUserJoinedSubscription()
        self.callCoordinatorUseCase.removeCallRemovedHandler()
    }
    
}
