import CallKit
import Chat
import Combine
import Intents
import MEGAAnalyticsiOS
import MEGADomain
import MEGAL10n
import MEGAPresentation
import MEGASDKRepo

@MainActor
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
    
    func callUpdate(
        withVideo video: Bool
    ) -> CXCallUpdate {
        let update = builder()
        update.hasVideo = video
        return update
    }
    
    func callUpdate(
        withChatTitle title: String
    ) -> CXCallUpdate {
        let update = builder()
        update.localizedCallerName = title
        return update
    }
    
    static var defaultFactory: Self {
        .init {
            CXCallUpdate()
        }
    }
}

enum MainTabBarCallsAction: ActionType { 
    case startCallIntent(INStartCallIntent)
    case didTapCloudDriveTab
    case didTapChatRoomsTab
}

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
    private let sessionUpdateUseCase: any SessionUpdateUseCaseProtocol
    private let accountUseCase: any AccountUseCaseProtocol
    private let handleUseCase: any MEGAHandleUseCaseProtocol
    private let callManager: any CallManagerProtocol
    private let featureFlagProvider: any FeatureFlagProviderProtocol

    private var callUpdateSubscription: AnyCancellable?
    private(set) var callWaitingRoomUsersUpdateSubscription: AnyCancellable?
    private(set) var callSessionUpdateTask: Task<Void, Never>?

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
    private let callUpdateFactory: CXCallUpdateFactory
    
    private let tonePlayer = TonePlayer()
    
    private let tracker: any AnalyticsTracking

    init(
        router: some MainTabBarCallsRouting,
        chatUseCase: some ChatUseCaseProtocol,
        callUseCase: some CallUseCaseProtocol,
        chatRoomUseCase: some ChatRoomUseCaseProtocol,
        chatRoomUserUseCase: some ChatRoomUserUseCaseProtocol,
        sessionUpdateUseCase: some SessionUpdateUseCaseProtocol,
        accountUseCase: some AccountUseCaseProtocol,
        handleUseCase: some MEGAHandleUseCaseProtocol,
        callManager: some CallManagerProtocol,
        callUpdateFactory: CXCallUpdateFactory,
        featureFlagProvider: some FeatureFlagProviderProtocol,
        tracker: some AnalyticsTracking
    ) {
        self.router = router
        self.chatUseCase = chatUseCase
        self.callUseCase = callUseCase
        self.chatRoomUseCase = chatRoomUseCase
        self.chatRoomUserUseCase = chatRoomUserUseCase
        self.sessionUpdateUseCase = sessionUpdateUseCase
        self.accountUseCase = accountUseCase
        self.handleUseCase = handleUseCase
        self.callManager = callManager
        self.callUpdateFactory = callUpdateFactory
        self.featureFlagProvider = featureFlagProvider
        self.tracker = tracker
        
        onCallUpdateListener()
    }
    
    // MARK: - Dispatch actions
    
    func dispatch(_ action: MainTabBarCallsAction) {
        switch action {
        case .startCallIntent(let intent):
           startCall(fromIntent: intent)
        case .didTapCloudDriveTab:
            trackCloudDriveTabEvent()
        case .didTapChatRoomsTab:
            trackChatRoomsTabEvent()
        }
    }
    
    // MARK: - Private

    private func onCallUpdateListener() {
        callUpdateSubscription = callUseCase.onCallUpdate()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] call in
                self?.onCallUpdate(call)
            }
    }
    
    private func configureCallSessionsListener(forCall call: CallEntity) {
        guard callSessionUpdateTask == nil else { return }
        let sessionUpdates = sessionUpdateUseCase.monitorOnSessionUpdate()
        callSessionUpdateTask = Task { [weak self] in
            for await (session, call) in sessionUpdates {
                self?.onSessionUpdate(session, call)
            }
        }
    }
    
    private func onSessionUpdate(_ session: ChatSessionEntity, _ call: CallEntity) {
        switch session.changeType {
        case .status:
            switch session.statusType {
            case .inProgress:
                if session.onRecording {
                    manageOnRecordingSession(session: session, in: call)
                }
                stopOutgoingToneIfNeeded(for: call)
            case .destroyed:
                playCallEndedToneIfNeeded(for: call, with: session)
            default:
                break
            }
        case .onRecording:
            manageOnRecordingSession(session: session, in: call)
        default:
            break
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
            guard let chatRoom = chatRoomUseCase.chatRoom(forChatId: call.chatId) else { return }
            callManager.endCall(in: chatRoom, endForAll: false)
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
        callSessionUpdateTask?.cancel()
        callSessionUpdateTask = nil
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
    
    private func manageCallStatusChange(for call: CallEntity) {
        switch call.status {
        case .joining:
            startOutgoingToneIfNeeded(for: call)
            configureCallSessionsListener(forCall: call)
        case .inProgress:
            invokeCommand?(.showActiveCallIcon)
            guard callWaitingRoomUsersUpdateSubscription == nil, let chatRoom = chatRoomUseCase.chatRoom(forChatId: call.chatId) else { return }
            if chatRoom.isWaitingRoomEnabled && chatRoom.ownPrivilege == .moderator {
                configureWaitingRoomListener(forCall: call)
                manageWaitingRoom(for: call)
            }
        case .terminatingUserParticipation:
            manageTerminatingUserParticipation(call)
        default:
            break
        }
    }
    
    private func manageTerminatingUserParticipation(_ call: CallEntity) {
        currentWaitingRoomUserHandles.removeAll()
        router.dismissWaitingRoomDialog(animated: false)
        callCount = 0
        if !chatUseCase.existsActiveCall() {
            invokeCommand?(.hideActiveCallIcon)
        }
        screenRecordingAlertShownForCall = false
        manageCallTerminatedErrorIfNeeded(call)
        stopOutgoingToneIfNeeded(for: call)
        removeCallListeners()
    }
    
    private func manageCallTerminatedErrorIfNeeded(_ call: CallEntity) {
        guard !isCallUIVisible else { return }
        if call.termCodeType == .callDurationLimit {
            if call.isOwnClientCaller { // or is chat room organiser - future implementation
                guard let accountDetails = accountUseCase.currentAccountDetails else { return }
                tracker.trackAnalyticsEvent(with: MainTabBarScreenEvent())
                tracker.trackAnalyticsEvent(with: UpgradeToProToGetUnlimitedCallsDialogEvent())
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
    
    private func startCall(fromIntent intent: INStartCallIntent) {
        guard let personHandle = intent.contacts?.first?.personHandle,
              personHandle.type == .unknown,
              let chatIdBase64Handle = personHandle.value,
              let chatId = handleUseCase.handle(forBase64UserHandle: chatIdBase64Handle),
              let chatRoom = chatRoomUseCase.chatRoom(forChatId: chatId)
        else {
            MEGALogDebug("Failed to start call from intent")
            return
        }
        
        callManager.startCall(
            with: CallActionSync(
                chatRoom: chatRoom,
                videoEnabled: intent.callCapability == .videoCall,
                isJoiningActiveCall: callUseCase.call(for: chatRoom.chatId) != nil
            )
        )
    }
    
    private func startOutgoingToneIfNeeded(for call: CallEntity) {
        guard let chatRoom = chatRoomUseCase.chatRoom(forChatId: call.chatId),
              chatRoom.chatType == .oneToOne,
              call.isOwnClientCaller else { return }
        tonePlayer.play(tone: .outgoingTone, numberOfLoops: -1)
    }
    
    private func stopOutgoingToneIfNeeded(for call: CallEntity) {
        guard let chatRoom = chatRoomUseCase.chatRoom(forChatId: call.chatId),
              chatRoom.chatType == .oneToOne,
              call.isOwnClientCaller else { return }
        tonePlayer.stopAudioPlayer()
    }
    
    private func playCallEndedToneIfNeeded(for call: CallEntity, with session: ChatSessionEntity) {
        guard let chatRoom = chatRoomUseCase.chatRoom(forChatId: call.chatId),
              chatRoom.chatType == .oneToOne,
              session.termCode == .nonRecoverable else { return }
        tonePlayer.play(tone: .callEnded)
    }
    
    private func trackCloudDriveTabEvent() {
        tracker.trackAnalyticsEvent(with: CloudDriveBottomNavigationItemEvent())
    }
    
    private func trackChatRoomsTabEvent() {
        tracker.trackAnalyticsEvent(with: ChatRoomsBottomNavigationItemEvent())
    }
}
