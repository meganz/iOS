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
    func showScreenRecordingAlert(isCallUIVisible: Bool, acceptAction: @escaping (Bool) -> Void, learnMoreAction: @escaping () -> Void, leaveCallAction: @escaping () -> Void)
    func showScreenRecordingNotification(started: Bool, username: String)
    func navigateToPrivacyPolice()
    func dismissCallUI()
    func showCallWillEndAlert(timeToEndCall: Double, isCallUIVisible: Bool)
    func showUpgradeToProDialog(_ account: AccountDetailsEntity)
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
    private var callSessionUseCase: any CallSessionUseCaseProtocol
    private let accountUseCase: any AccountUseCaseProtocol
    private let callKitManager: any CallKitManagerProtocol
    private let featureFlagProvider: any FeatureFlagProviderProtocol

    private var callUpdateSubscription: AnyCancellable?
    private(set) var callWaitingRoomUsersUpdateSubscription: AnyCancellable?
    private(set) var callSessionUpdateSubscription: AnyCancellable?

    private var currentWaitingRoomUserHandles: [HandleEntity] = []
    
    @PreferenceWrapper(key: .isCallUIVisible, defaultValue: false, useCase: PreferenceUseCase.default)
    var isCallUIVisible: Bool
    @PreferenceWrapper(key: .isWaitingRoomListVisible, defaultValue: false, useCase: PreferenceUseCase.default)
    var isWaitingRoomListVisible: Bool
    
    private(set) var screenRecordingAlertShownForCall: Bool = false

    private var callWillEndTimer: Timer?
    private var callWillEndCountdown: Int = 10
    
    init(
        router: some MainTabBarCallsRouting,
        chatUseCase: some ChatUseCaseProtocol,
        callUseCase: some CallUseCaseProtocol,
        chatRoomUseCase: some ChatRoomUseCaseProtocol,
        chatRoomUserUseCase: some ChatRoomUserUseCaseProtocol,
        callSessionUseCase: some CallSessionUseCaseProtocol,
        accountUseCase: some AccountUseCaseProtocol,
        callKitManager: some CallKitManagerProtocol,
        featureFlagProvider: some FeatureFlagProviderProtocol = DIContainer.featureFlagProvider
    ) {
        self.router = router
        self.chatUseCase = chatUseCase
        self.callUseCase = callUseCase
        self.chatRoomUseCase = chatRoomUseCase
        self.chatRoomUserUseCase = chatRoomUserUseCase
        self.callSessionUseCase = callSessionUseCase
        self.accountUseCase = accountUseCase
        self.callKitManager = callKitManager
        self.featureFlagProvider = featureFlagProvider
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
    
    private func configureCallSessionsListener(forCall call: CallEntity) {
        guard callSessionUpdateSubscription == nil else { return }
        callSessionUpdateSubscription = callSessionUseCase.onCallSessionUpdate()
            .sink { [weak self] session in
                switch session.changeType {
                case .status:
                    if session.statusType == .inProgress && session.onRecording {
                        self?.manageOnRecordingSession(session: session, in: call)
                    }
                case .onRecording:
                    self?.manageOnRecordingSession(session: session, in: call)
                default:
                    break
                }
            }
    }
    
    private func manageOnRecordingSession(session: ChatSessionEntity, in call: CallEntity) {
        guard let chatRoom = chatRoomUseCase.chatRoom(forChatId: call.chatId) else { return }
        Task { @MainActor in
            guard let username = try? await chatRoomUserUseCase.userDisplayName(forPeerId: session.peerId, in: chatRoom) else { return }
            if session.onRecording {
                guard screenRecordingAlertShownForCall == false else {
                    router.showScreenRecordingNotification(started: true, username: username)
                    return
                }
                screenRecordingAlertShownForCall = true
                showRecordingAlert(username, call)
            } else {
                router.showScreenRecordingNotification(started: false, username: username)
            }
        }
    }
    
    private func showRecordingAlert(_ username: String, _ call: CallEntity) {
        router.showScreenRecordingAlert(isCallUIVisible: isCallUIVisible) { [weak self] shouldCheckWaitingRoom in
            self?.router.showScreenRecordingNotification(started: true, username: username)
            if shouldCheckWaitingRoom {
                self?.showPendingWaitingRoomNotification(for: call)
            }
        } learnMoreAction: { [weak self] in
            self?.router.navigateToPrivacyPolice()
            self?.showRecordingAlert(username, call)
        } leaveCallAction: { [weak self] in
            guard let self else { return }
            if isCallUIVisible {
                router.dismissCallUI()
            } else {
                callUseCase.hangCall(for: call.callId)
            }
        }
    }
    
    private func showPendingWaitingRoomNotification(for call: CallEntity) {
        guard let chatRoom = chatRoomUseCase.chatRoom(forChatId: call.chatId),
              let call = callUseCase.call(for: chatRoom.chatId) else { return }
        showWaitingRoomAlert(chatRoom, call)
    }
    
    private func configureWaitingRoomListener(forCall call: CallEntity) {
        callWaitingRoomUsersUpdateSubscription = callUseCase.callWaitingRoomUsersUpdate(forCall: call)
            .debounce(for: 1, scheduler: DispatchQueue.main)
            .sink { [weak self] call in
                self?.manageWaitingRoom(for: call)
            }
    }
    
    private func removeCallListeners() {
        callWaitingRoomUsersUpdateSubscription?.cancel()
        callWaitingRoomUsersUpdateSubscription = nil
        callSessionUpdateSubscription?.cancel()
        callSessionUpdateSubscription = nil
    }
    
    private func onCallUpdate(_ call: CallEntity) {
        switch call.changeType {
        case .status:
            manageCallStatusChange(for: call)
        case .callWillEnd:
            showCallWillEndAlertIfNeeded(call)
        default:
            break
        }
    }
    
    /// If call UI is visible, then this event would be handled there. See MeetingParticipantsLayoutViewModel:manageCallWillEnd().
    /// If call UI is not visible, the call will end dialog will be presented just for moderators in the visible view.
    private func showCallWillEndAlertIfNeeded(_ call: CallEntity) {
        guard featureFlagProvider.isFeatureFlagEnabled(for: .chatMonetization), !isCallUIVisible, let chatRoom = chatRoomUseCase.chatRoom(forChatId: call.chatId), chatRoom.ownPrivilege == .moderator else { return }
        
        let secondsToCallWillEnd = Date(timeIntervalSince1970: TimeInterval(call.callWillEndTimestamp)).timeIntervalSinceNow
        router.showCallWillEndAlert(
            timeToEndCall: secondsToCallWillEnd,
            isCallUIVisible: isCallUIVisible)
    }
    
    private func manageCallStatusChange(for call: CallEntity) {
        switch call.status {
        case .joining:
            configureCallSessionsListener(forCall: call)
            callKitManager.notifyStartCallToCallKit(call)
        case .inProgress:
            invokeCommand?(.showActiveCallIcon)
            guard callWaitingRoomUsersUpdateSubscription == nil, let chatRoom = chatRoomUseCase.chatRoom(forChatId: call.chatId) else { return }
            if chatRoom.isWaitingRoomEnabled && chatRoom.ownPrivilege == .moderator {
                configureWaitingRoomListener(forCall: call)
                manageWaitingRoom(for: call)
            }
            
        case .terminatingUserParticipation:
            currentWaitingRoomUserHandles.removeAll()
            router.dismissWaitingRoomDialog(animated: false)
            if !chatUseCase.existsActiveCall() {
                invokeCommand?(.hideActiveCallIcon)
            }
            screenRecordingAlertShownForCall = false
            manageCallTerminatedErrorIfNeeded(call)
            removeCallListeners()
            
        default:
            break
        }
    }
    
    private func manageCallTerminatedErrorIfNeeded(_ call: CallEntity) {
        guard !isCallUIVisible, featureFlagProvider.isFeatureFlagEnabled(for: .chatMonetization) else { return }
        if call.termCodeType == .callDurationLimit {
            if call.isOwnClientCaller { // or is chat room organiser - future implementation
                guard let accountDetails = accountUseCase.currentAccountDetails else { return }
                router.showUpgradeToProDialog(accountDetails)
            }
        }
    }
    
    private func manageWaitingRoom(for call: CallEntity) {
        guard call.changeType != .waitingRoomUsersAllow,
              let waitingRoomUserHandles = call.waitingRoom?.userIds,
              let chatRoom = chatRoomUseCase.chatRoom(forChatId: call.chatId),
                !isWaitingRoomListVisible else { return }
        let waitingRoomNonModeratorUserHandles = waitingRoomUserHandles.filter { chatRoomUseCase.peerPrivilege(forUserHandle: $0, chatRoom: chatRoom).isUserInWaitingRoom }
        
        guard waitingRoomNonModeratorUserHandles.isNotEmpty else {
            currentWaitingRoomUserHandles.removeAll()
            router.dismissWaitingRoomDialog(animated: true)
            return
        }
        
        guard waitingRoomNonModeratorUserHandles != currentWaitingRoomUserHandles else { return }
        
        currentWaitingRoomUserHandles = waitingRoomNonModeratorUserHandles
        
        showWaitingRoomAlert(chatRoom, call)
    }
    
    private func showWaitingRoomAlert(_ chatRoom: ChatRoomEntity, _ call: CallEntity) {
        if currentWaitingRoomUserHandles.count == 1 {
            guard let userHandle = currentWaitingRoomUserHandles.first else { return }
            showOneUserWaitingRoomAlert(withUserHandle: userHandle, inChatRoom: chatRoom, forCall: call)
        } else {
            showSeveralUsersWaitingRoomAlert(userHandles: currentWaitingRoomUserHandles, inChatRoom: chatRoom, forCall: call)
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
