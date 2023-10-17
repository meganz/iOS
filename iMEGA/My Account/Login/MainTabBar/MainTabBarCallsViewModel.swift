import Combine
import MEGADomain
import MEGAL10n
import MEGAPresentation

protocol MainTabBarCallsRouting: AnyObject {
    func showOneUserWaitingRoomDialog(for username: String, chatName: String, isCallUIVisible: Bool, shouldUpdateDialog: Bool, admitAction: @escaping () -> Void, denyAction: @escaping () -> Void)
    func showSeveralUsersWaitingRoomDialog(for participantsCount: Int, chatName: String, isCallUIVisible: Bool, shouldUpdateDialog: Bool, admitAction: @escaping () -> Void, seeWaitingRoomAction: @escaping () -> Void)
    func dismissWaitingRoomDialog(animated: Bool)
    func showConfirmDenyAction(for username: String, isCallUIVisible: Bool, confirmDenyAction: @escaping () -> Void, cancelDenyAction: @escaping () -> Void)
    func showParticipantsJoinedTheCall(message: String)
    func showWaitingRoomListFor(call: CallEntity, in chatRoom: ChatRoomEntity)
}

enum MainTabBarCallsAction: ActionType { }

@objc class MainTabBarCallsViewModel: NSObject, ViewModelType {
    
    enum Command: CommandType, Equatable {
        case showActiveCallIcon
        case hideActiveCallIcon
        case navigateToChatTab
    }
    
    var invokeCommand: ((Command) -> Void)?

    private let router: any MainTabBarCallsRouting
    private let chatUseCase: any ChatUseCaseProtocol
    private let callUseCase: any CallUseCaseProtocol
    private let chatRoomUseCase: any ChatRoomUseCaseProtocol
    private let chatRoomUserUseCase: any ChatRoomUserUseCaseProtocol

    private var callUpdateSubscription: AnyCancellable?
    private (set) var callWaitingRoomUsersUpdateSubscription: AnyCancellable?
    
    private var currentWaitingRoomHandles: [HandleEntity] = []
    
    @PreferenceWrapper(key: .isCallUIVisible, defaultValue: false, useCase: PreferenceUseCase.default)
    var isCallUIVisible: Bool
    @PreferenceWrapper(key: .isWaitingRoomListVisible, defaultValue: false, useCase: PreferenceUseCase.default)
    var isWaitingRoomListVisible: Bool
    
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
            .debounce(for: 1, scheduler: DispatchQueue.main)
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
                manageWaitingRoom(for: call)
            }
            
        case .destroyed, .terminatingUserParticipation:
            currentWaitingRoomHandles.removeAll()
            router.dismissWaitingRoomDialog(animated: false)
            if !chatUseCase.existsActiveCall() {
                invokeCommand?(.hideActiveCallIcon)
            }
            removeWaitingRoomListener()
            
        default:
            break
        }
    }
    
    private func manageWaitingRoom(for call: CallEntity) {
        guard call.changeType != .waitingRoomUsersAllow,
              let waitingRoomHandles = call.waitingRoom?.sessionClientIds,
              let chatRoom = chatRoomUseCase.chatRoom(forChatId: call.chatId),
                !isWaitingRoomListVisible else { return }
        let waitingRoomNonModeratorHandles = waitingRoomHandles.filter { chatRoomUseCase.peerPrivilege(forUserHandle: $0, chatRoom: chatRoom).isUserInWaitingRoom }
        
        guard waitingRoomNonModeratorHandles.isNotEmpty else {
            currentWaitingRoomHandles.removeAll()
            router.dismissWaitingRoomDialog(animated: true)
            return
        }
        
        guard waitingRoomNonModeratorHandles != currentWaitingRoomHandles else { return }
        
        currentWaitingRoomHandles = waitingRoomNonModeratorHandles
        
        if waitingRoomHandles.count == 1 {
            guard let userHandle = currentWaitingRoomHandles.first else { return }
            showOneUserWaitingRoomAlert(withUserHandle: userHandle, inChatRoom: chatRoom, forCall: call)
        } else {
            showSeveralUsersWaitingRoomAlert(userHandles: currentWaitingRoomHandles, inChatRoom: chatRoom, forCall: call)
        }
    }
    
    private func showOneUserWaitingRoomAlert(withUserHandle userHandle: UInt64, inChatRoom chatRoom: ChatRoomEntity, forCall call: CallEntity) {
        Task { @MainActor in
            do {
                let username = try await chatRoomUserUseCase.userDisplayName(forPeerId: userHandle, in: chatRoom)
                router.showOneUserWaitingRoomDialog(for: username, chatName: chatRoom.title ?? "", isCallUIVisible: isCallUIVisible, shouldUpdateDialog: call.changeType != .waitingRoomUsersLeave) { [weak self] in
                    guard let self else { return}
                    callUseCase.allowUsersJoinCall(call, users: [userHandle])
                    if !isCallUIVisible {
                        showParticipantsJoinedMessage(for: [userHandle], in: chatRoom)
                    }
                } denyAction: { [weak self] in
                    self?.showConfirmDenyWaitingRoomAlert(for: username, userHandle: userHandle, call: call)
                }
            } catch {
                MEGALogError("Failed to get username for participant in call waiting room")
            }
        }
    }
    
    private func showSeveralUsersWaitingRoomAlert(userHandles: [UInt64], inChatRoom chatRoom: ChatRoomEntity, forCall call: CallEntity) {
        router.showSeveralUsersWaitingRoomDialog(for: userHandles.count, chatName: chatRoom.title ?? "", isCallUIVisible: isCallUIVisible, shouldUpdateDialog: call.changeType != .waitingRoomUsersLeave) { [weak self] in
            guard let self else { return}
            callUseCase.allowUsersJoinCall(call, users: userHandles)
            if !isCallUIVisible {
                showParticipantsJoinedMessage(for: userHandles, in: chatRoom)
            }
        } seeWaitingRoomAction: { [weak self] in
            guard let self else { return}
            invokeCommand?(.navigateToChatTab)
            if isCallUIVisible {
                NotificationCenter.default.post(name: .seeWaitingRoomListEvent, object: nil)
            } else {
                router.showWaitingRoomListFor(call: call, in: chatRoom)
            }
        }
    }
    
    private func showConfirmDenyWaitingRoomAlert(for username: String, userHandle: UInt64, call: CallEntity) {
        router.showConfirmDenyAction(for: username, isCallUIVisible: isCallUIVisible) { [weak self] in
            self?.callUseCase.kickUsersFromCall(call, users: [userHandle])
        } cancelDenyAction: { [weak self] in
            self?.manageWaitingRoom(for: call)
        }
    }
    
    private func showParticipantsJoinedMessage(for userHandles: [UInt64], in chatRoom: ChatRoomEntity) {
        Task { @MainActor in
            do {
                guard let firstUserHandle = userHandles[safe: 0] else { return }
                let firstUsername = try await chatRoomUserUseCase.userDisplayName(forPeerId: firstUserHandle, in: chatRoom)
                switch userHandles.count {
                case 1:
                    router.showParticipantsJoinedTheCall(message: Strings.Localizable.Meetings.Notification.singleUserJoined(firstUsername))
                case 2:
                    guard let secondUserHandle = userHandles[safe: 1] else { return }
                    let secondUsername = try await chatRoomUserUseCase.userDisplayName(forPeerId: secondUserHandle, in: chatRoom)
                    router.showParticipantsJoinedTheCall(message: Strings.Localizable.Meetings.Notification.twoUsersJoined(firstUsername, secondUsername))
                default:
                    router.showParticipantsJoinedTheCall(message: Strings.Localizable.Meetings.Notification.moreThanTwoUsersJoined(firstUsername, userHandles.count - 1))
                }
            } catch {
                MEGALogError("Failed to get username for participant(s) in call waiting room")
            }
        }
    }
}
