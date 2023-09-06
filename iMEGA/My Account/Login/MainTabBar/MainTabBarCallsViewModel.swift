import Combine
import MEGADomain
import MEGAPresentation

protocol MainTabBarCallsRouting: AnyObject {
    func showOneUserWaitingRoomDialog(for username: String, admitAction: @escaping () -> Void, denyAction: @escaping () -> Void)
    func showSeveralUsersWaitingRoomDialog(for participantsCount: Int, admitAction: @escaping () -> Void, seeWaitingRoomAction: @escaping () -> Void)
    func dismissWaitingRoomDialog(animated: Bool)
}

enum MainTabBarCallsAction: ActionType { }

@objc class MainTabBarCallsViewModel: NSObject, ViewModelType {
    
    enum Command: CommandType, Equatable {
        case showActiveCallIcon
        case hideActiveCallIcon
    }
    var invokeCommand: ((Command) -> Void)?

    private let router: any MainTabBarCallsRouting
    private let chatUseCase: any ChatUseCaseProtocol
    private let callUseCase: any CallUseCaseProtocol
    private let chatRoomUseCase: any ChatRoomUseCaseProtocol
    private let chatRoomUserUseCase: any ChatRoomUserUseCaseProtocol

    private var callUpdateSubscription: AnyCancellable?
    private var callWaitingRoomUsersUpdateSubscription: AnyCancellable?
    
    init(
        router: some MainTabBarCallsRouting,
        chatUseCase: some ChatUseCaseProtocol,
        callUseCase: some CallUseCaseProtocol,
        chatRoomUseCase: some ChatRoomUseCaseProtocol,
        chatRoomUserUseCase: some ChatRoomUserUseCaseProtocol
    ) {
        self.router = router
        self.chatUseCase = chatUseCase
        self.callUseCase = callUseCase
        self.chatRoomUseCase = chatRoomUseCase
        self.chatRoomUserUseCase = chatRoomUserUseCase
        
        super.init()
        
        onCallUpdateListener()
    }
    
    // MARK: - Dispatch actions
    
    func dispatch(_ action: MainTabBarCallsAction) { }
    
    // MARK: - Private

    private func onCallUpdateListener() {
        callUpdateSubscription = callUseCase.onCallUpdate()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] call in
                self?.onCallUpdate(call)
            }
    }
    
    private func configureWaitingRoomListener(forCall call: CallEntity) {
        callWaitingRoomUsersUpdateSubscription = callUseCase.callWaitingRoomUsersUpdate(forCall: call)
            .throttle(for: 1, scheduler: DispatchQueue.main, latest: true)
            .sink { [weak self] call in
                self?.manageWaitingRoom(for: call)
            }
    }
    
    private func removeWaitingRoomListener() {
        callWaitingRoomUsersUpdateSubscription?.cancel()
        callWaitingRoomUsersUpdateSubscription = nil
    }
    
    private func onCallUpdate(_ call: CallEntity) {
        switch call.status {
        case .inProgress:
            invokeCommand?(.showActiveCallIcon)
            guard callWaitingRoomUsersUpdateSubscription == nil, let chatRoom = chatRoomUseCase.chatRoom(forChatId: call.chatId) else { return }
            if chatRoom.isWaitingRoomEnabled && chatRoom.ownPrivilege == .moderator {
                configureWaitingRoomListener(forCall: call)
            }
            
        case .destroyed, .terminatingUserParticipation:
            if !chatUseCase.existsActiveCall() {
                invokeCommand?(.hideActiveCallIcon)
            }
            removeWaitingRoomListener()
            
        default:
            break
        }
    }
    
    private func manageWaitingRoom(for call: CallEntity) {
        guard let waitingRoomHandles = call.waitingRoom?.sessionClientIds, let chatRoom = chatRoomUseCase.chatRoom(forChatId: call.chatId) else { return }
        let waitingRoomNonModeratorHandles = waitingRoomHandles.filter { chatRoomUseCase.peerPrivilege(forUserHandle: $0, chatRoom: chatRoom).isUserInWaitingRoom }
        
        guard waitingRoomNonModeratorHandles.isNotEmpty else {
            router.dismissWaitingRoomDialog(animated: true)
            return
        }
        
        if waitingRoomNonModeratorHandles.count == 1 {
            guard let userHandle = waitingRoomNonModeratorHandles.first else { return }
            Task { @MainActor in
                do {
                    let username = try await chatRoomUserUseCase.userDisplayName(forPeerId: userHandle, in: chatRoom)
                    router.showOneUserWaitingRoomDialog(for: username) { [weak self] in
                        self?.callUseCase.allowUsersJoinCall(call, users: [userHandle])
                    } denyAction: { [weak self] in
                        self?.callUseCase.kickUsersFromCall(call, users: [userHandle])
                    }
                } catch {
                    MEGALogError("Failed to get username for participant in call waiting room")
                }
            }
        } else {
            router.showSeveralUsersWaitingRoomDialog(for: waitingRoomNonModeratorHandles.count) { [weak self] in
                self?.callUseCase.allowUsersJoinCall(call, users: waitingRoomNonModeratorHandles)
            } seeWaitingRoomAction: {
                // Waiting Room UI will be implemented in next tickets
            }
        }
    }
}
