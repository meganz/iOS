import Combine
import MEGADomain
import MEGAL10n
import MEGAPresentation
import MEGASDKRepo

protocol MainTabBarCallsRouting: AnyObject {
    func showOneUserWaitingRoomDialog(
        for username: String,
        chatName: String,
        isCallUIVisible: Bool,
        shouldUpdateDialog: Bool,
        shouldBlockAddingUsersToCall: Bool,
        admitAction: @escaping () -> Void,
        denyAction: @escaping () -> Void
    )
    func showSeveralUsersWaitingRoomDialog(
        for participantsCount: Int,
        chatName: String,
        isCallUIVisible: Bool,
        shouldUpdateDialog: Bool,
        shouldBlockAddingUsersToCall: Bool,
        admitAction: @escaping () -> Void,
        seeWaitingRoomAction: @escaping () -> Void
    )
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
    func startCallUI(chatRoom: ChatRoomEntity, call: CallEntity, isSpeakerEnabled: Bool)
}

struct CXCallUpdateFactory {
    let builder: () -> CXCallUpdate
    init(builder: @escaping () -> CXCallUpdate) {
        self.builder = builder
    }
    
    func createCallUpdate(
        title: String
    ) -> CXCallUpdate {
        let update = builder()
        update.remoteHandle = CXHandle(
            type: .generic,
            value: title
        )
        update.localizedCallerName = title
        return update
    }
    
    static var defaultFactory: Self {
        .init {
            CXCallUpdate()
        }
    }
}

enum MainTabBarCallsAction: ActionType { }

class MainTabBarCallsViewModel: ViewModelType {
    
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
    private let callManager: any CallManagerProtocol
    private let featureFlagProvider: any FeatureFlagProviderProtocol

    private var providerDelegate: CallKitProviderDelegate?
    private var voipPushDelegate: VoIPPushDelegate?

    private var callUpdateSubscription: AnyCancellable?
    private(set) var callWaitingRoomUsersUpdateSubscription: AnyCancellable?
    private(set) var callSessionUpdateSubscription: AnyCancellable?
    // we cache this value here to be able to reload
    // waiting room alert when needed -> so do it also when waiting room users are not changed
    // but call count is changed -> this could result in change of state of "admit\admit all"
    // alert button when call has some participants limits [MEET-3401]
    private var callCount = 0
    private var currentWaitingRoomUserHandles: [HandleEntity] = []
    
    @PreferenceWrapper(key: .isCallUIVisible, defaultValue: false, useCase: PreferenceUseCase.default)
    var isCallUIVisible: Bool
    @PreferenceWrapper(key: .isWaitingRoomListVisible, defaultValue: false, useCase: PreferenceUseCase.default)
    var isWaitingRoomListVisible: Bool
    
    private(set) var screenRecordingAlertShownForCall: Bool = false

    private var callWillEndTimer: Timer?
    private var callWillEndCountdown: Int = 10
    private let uuidFactory: () -> UUID
    private let callUpdateFactory: CXCallUpdateFactory
    init(
        router: some MainTabBarCallsRouting,
        chatUseCase: some ChatUseCaseProtocol,
        callUseCase: some CallUseCaseProtocol,
        chatRoomUseCase: some ChatRoomUseCaseProtocol,
        chatRoomUserUseCase: some ChatRoomUserUseCaseProtocol,
        callSessionUseCase: some CallSessionUseCaseProtocol,
        accountUseCase: some AccountUseCaseProtocol,
        callKitManager: some CallKitManagerProtocol,
        callManager: some CallManagerProtocol,
        uuidFactory: @escaping () -> UUID,
        callUpdateFactory: CXCallUpdateFactory,
        featureFlagProvider: some FeatureFlagProviderProtocol
    ) {
        self.router = router
        self.chatUseCase = chatUseCase
        self.callUseCase = callUseCase
        self.chatRoomUseCase = chatRoomUseCase
        self.chatRoomUserUseCase = chatRoomUserUseCase
        self.callSessionUseCase = callSessionUseCase
        self.accountUseCase = accountUseCase
        self.callKitManager = callKitManager
        self.callManager = callManager
        self.uuidFactory = uuidFactory
        self.callUpdateFactory = callUpdateFactory
        self.featureFlagProvider = featureFlagProvider
        
        if featureFlagProvider.isFeatureFlagEnabled(for: .callKitRefactor) {
            self.providerDelegate = CallKitProviderDelegate(callCoordinator: self, callManager: callManager)
            self.voipPushDelegate = VoIPPushDelegate(
                callCoordinator: self,
                voIpTokenUseCase: VoIPTokenUseCase(repo: VoIPTokenRepository.newRepo),
                megaHandleUseCase: MEGAHandleUseCase(repo: MEGAHandleRepository.newRepo)
            )
        }
        
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
        case .callComposition:
            MEGALogDebug("[CallLimitations] MainTabBarCalls: call composition changed: [participants: \(call.numberOfParticipants)]")
            manageWaitingRoom(for: call)
        default:
            break
        }
    }
    
    private var chatMonetisationFeatureEnabled: Bool {
        featureFlagProvider.isFeatureFlagEnabled(for: .chatMonetization)
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
            callCount = 0
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
        guard !isCallUIVisible, chatMonetisationFeatureEnabled else { return }
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
        MEGALogDebug("[CallLimitations] waitingRoomUserHandles : \(waitingRoomUserHandles)")
        let waitingRoomNonModeratorUserHandles = waitingRoomUserHandles.filter { chatRoomUseCase.peerPrivilege(forUserHandle: $0, chatRoom: chatRoom).isUserInWaitingRoom }
        
        guard waitingRoomNonModeratorUserHandles.isNotEmpty else {
            currentWaitingRoomUserHandles.removeAll()
            router.dismissWaitingRoomDialog(animated: true)
            return
        }
        
        let waitingRoomHasChanged = waitingRoomNonModeratorUserHandles != currentWaitingRoomUserHandles
        MEGALogDebug("[CallLimitations] old call count : \(callCount), new call count: \(call.numberOfParticipants)")
        let callParticipantsHasChanged = callCount != call.numberOfParticipants
        callCount = call.numberOfParticipants
        
        let waitingRoomOrCallCountChanged = waitingRoomHasChanged || callParticipantsHasChanged
        MEGALogDebug("[CallLimitations] waitingRoomHasChanged : \(waitingRoomHasChanged), callParticipantsHasChanged: \(callParticipantsHasChanged)")
        guard waitingRoomOrCallCountChanged else {
            MEGALogDebug("[CallLimitations] conditions for waiting room alert did not change")
            return
        }
        
        currentWaitingRoomUserHandles = waitingRoomNonModeratorUserHandles
        
        showWaitingRoomAlert(chatRoom, call)
    }
    
    private func showWaitingRoomAlert(_ chatRoom: ChatRoomEntity, _ call: CallEntity) {
        
        // Show appropriate copy and disable admit button when limit of free participants is each reached
        //
        // Note: The logic of disabling 'Admit' or 'Admit all' button, in essence is that,
        // it should be disabled, when number of call participants plus waiting room users is greater than limit
        // ie. they would simply not fit into call limit if all admitted, hence we disable 'Admit all'.
        // Example: Limit 100
        // a) in-call 95, waiting room 3 (sum is 98, below limit -> `Admit all` enabled
        // b) in-call 95, waiting room 6 (sum is 101, above limit -> `Admit all` disabled
        // c) in-call 99, waiting room 1 (sum is 100, at limit -> `Admit` enabled
        //
        // We still allow user to go to waiting room user list and admit participants one by one.
        let shouldBlockAddingUsersToCall = CallLimitations.callParticipantsPlusAdditionalUsersLimitPassed(
            featureFlagEnabled: chatMonetisationFeatureEnabled,
            isMyselfModerator: chatRoom.ownPrivilege == .moderator,
            currentLimit: call.callLimits.maxUsers,
            callParticipantCount: call.numberOfParticipants,
            additionalParticipantCount: currentWaitingRoomUserHandles.count
        )
        
        // 'shouldBlockAddingUsersToCall' controls both 
        // 1. "Admit" button state when there's 1 person in the waiting room
        // 2. "Admit all" button state when there are more than 1 persons in the waiting room.
        
        MEGALogDebug("[CallLimitations] should block adding from waiting room \(shouldBlockAddingUsersToCall)")
        if currentWaitingRoomUserHandles.count == 1 {
            guard let userHandle = currentWaitingRoomUserHandles.first else { return }
            showOneUserWaitingRoomAlert(
                withUserHandle: userHandle,
                inChatRoom: chatRoom,
                forCall: call,
                shouldBlockAddingUsersToCall: shouldBlockAddingUsersToCall
            )
        } else {
            showSeveralUsersWaitingRoomAlert(
                userHandles: currentWaitingRoomUserHandles,
                inChatRoom: chatRoom,
                forCall: call,
                shouldBlockAddingUsersToCall: shouldBlockAddingUsersToCall
            )
        }
    }
    
    private func showOneUserWaitingRoomAlert(
        withUserHandle userHandle: UInt64,
        inChatRoom chatRoom: ChatRoomEntity,
        forCall call: CallEntity,
        shouldBlockAddingUsersToCall: Bool
    ) {
        Task { @MainActor in
            do {
                let username = try await chatRoomUserUseCase.userDisplayName(forPeerId: userHandle, in: chatRoom)
                router.showOneUserWaitingRoomDialog(
                    for: username,
                    chatName: chatRoom.title ?? "",
                    isCallUIVisible: isCallUIVisible,
                    shouldUpdateDialog: call.changeType != .waitingRoomUsersLeave,
                    shouldBlockAddingUsersToCall: shouldBlockAddingUsersToCall
                ) { [weak self] in
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
    
    private func showSeveralUsersWaitingRoomAlert(
        userHandles: [UInt64],
        inChatRoom chatRoom: ChatRoomEntity,
        forCall call: CallEntity,
        shouldBlockAddingUsersToCall: Bool
    ) {
        router.showSeveralUsersWaitingRoomDialog(
            for: userHandles.count,
            chatName: chatRoom.title ?? "",
            isCallUIVisible: isCallUIVisible,
            shouldUpdateDialog: call.changeType != .waitingRoomUsersLeave,
            shouldBlockAddingUsersToCall: shouldBlockAddingUsersToCall
        ) { [weak self] in
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

extension MainTabBarCallsViewModel: CallsCoordinatorProtocol {
    func startCall(_ callActionSync: CallActionSync) async -> Bool {
        let isSpeakerEnabled = callActionSync.videoEnabled || callActionSync.chatRoom.isMeeting
        do {
            let call = try await callUseCase.startCall(for: callActionSync.chatRoom.chatId, enableVideo: callActionSync.videoEnabled, enableAudio: callActionSync.audioEnabled, notRinging: callActionSync.notRinging)
            router.startCallUI(chatRoom: callActionSync.chatRoom, call: call, isSpeakerEnabled: isSpeakerEnabled)
            return true
        } catch {
            MEGALogError("Cannot start call in chat room \(callActionSync.chatRoom.chatId)")
            return false
        }
    }
    
    func answerCall(_ callActionSync: CallActionSync) async -> Bool {
        do {
            let call = try await callUseCase.answerCall(for: callActionSync.chatRoom.chatId, enableVideo: callActionSync.videoEnabled, enableAudio: callActionSync.audioEnabled)
            router.startCallUI(chatRoom: callActionSync.chatRoom, call: call, isSpeakerEnabled: callActionSync.chatRoom.isMeeting)
            return true
        } catch {
            MEGALogError("Cannot answer call in chat room \(callActionSync.chatRoom.chatId)")
            return false
        }
    }
    
    func endCall(_ callActionSync: CallActionSync) async -> Bool {
        guard let call = callUseCase.call(for: callActionSync.chatRoom.chatId) else { return false }
        
        if callActionSync.endForAll {
            callUseCase.endCall(for: call.callId)
        } else {
            callUseCase.hangCall(for: call.callId)
        }
        return true
    }
    
    func muteCall(_ callActionSync: CallActionSync) async -> Bool {
        do {
            if callActionSync.audioEnabled {
                try await callUseCase.enableAudioForCall(in: callActionSync.chatRoom)
                return true
            } else {
                try await callUseCase.disableAudioForCall(in: callActionSync.chatRoom)
                return true
            }
        } catch {
            return false
        }
    }
    
    func reportIncomingCall(in chatId: ChatIdEntity, completion: @escaping () -> Void) {
        guard let chatRoom = chatRoomUseCase.chatRoom(forChatId: chatId) else {
            return
        }
        
        let incomingCallUUID = uuidFactory()
        
        callManager.addCall(
            withUUID: incomingCallUUID,
            chatRoom: chatRoom
        )

        let update = callUpdateFactory.createCallUpdate(title: chatRoom.title ?? "Unknown")
        
        MEGALogDebug("[CallKit] Provider report new incoming call")
        providerDelegate?.provider.reportNewIncomingCall(with: incomingCallUUID, update: update) { error in
            guard error == nil else {
                MEGALogError("[CallKit] Provider Error reporting incoming call: \(String(describing: error))")
                return
            }
            completion()
        }
    }
    
    func reportEndCall(_ call: CallEntity) {
        MEGALogDebug("[CallKit] Report end call \(call)")

        guard let chatRoom = chatRoomUseCase.chatRoom(forChatId: call.chatId),
              let callUUID = callManager.callUUID(forChatRoom: chatRoom) else { return }
        
        var callEndedReason: CXCallEndedReason?
        switch call.termCodeType {
        case .invalid, .error, .tooManyParticipants, .tooManyClients, .protocolVersion:
            callEndedReason = .failed
        case .reject, .userHangup, .noParticipate, .kicked, .callDurationLimit, .callUsersLimit:
            callEndedReason = .remoteEnded
        case .waitingRoomTimeout:
            callEndedReason = .unanswered
        default:
            for handle in call.participants where chatUseCase.myUserHandle() == handle {
                callEndedReason = .answeredElsewhere
                break
            }
        }
        
        callManager.removeCall(withUUID: callUUID)
        guard let callEndedReason else { return }
        MEGALogDebug("[CallKit] Report end call reason \(callEndedReason.rawValue)")
        providerDelegate?.provider.reportCall(with: callUUID, endedAt: nil, reason: callEndedReason)
    }
}
