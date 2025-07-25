import ChatRepo
import Combine
import MEGAAppPresentation
import MEGADomain
import MEGAL10n
import MEGASwift

protocol CallsCoordinatorFactoryProtocol {
    func makeCallsCoordinator(
        callUseCase: some CallUseCaseProtocol,
        callUpdateUseCase: some CallUpdateUseCaseProtocol,
        chatRoomUseCase: some ChatRoomUseCaseProtocol,
        chatUseCase: some ChatUseCaseProtocol,
        sessionUpdateUseCase: some SessionUpdateUseCaseProtocol,
        noUserJoinedUseCase: some MeetingNoUserJoinedUseCaseProtocol,
        captureDeviceUseCase: some CaptureDeviceUseCaseProtocol,
        audioSessionUseCase: some AudioSessionUseCaseProtocol,
        callsManager: some CallsManagerProtocol,
        uuidFactory: @escaping () -> UUID
    ) -> CallsCoordinator
}

class CallsCoordinatorFactory: NSObject, CallsCoordinatorFactoryProtocol {
    func makeCallsCoordinator(
        callUseCase: some CallUseCaseProtocol,
        callUpdateUseCase: some CallUpdateUseCaseProtocol,
        chatRoomUseCase: some ChatRoomUseCaseProtocol,
        chatUseCase: some ChatUseCaseProtocol,
        sessionUpdateUseCase: some SessionUpdateUseCaseProtocol,
        noUserJoinedUseCase: some MeetingNoUserJoinedUseCaseProtocol,
        captureDeviceUseCase: some CaptureDeviceUseCaseProtocol,
        audioSessionUseCase: some AudioSessionUseCaseProtocol,
        callsManager: some CallsManagerProtocol,
        uuidFactory: @escaping () -> UUID
    ) -> CallsCoordinator {
        CallsCoordinator(
            callUseCase: callUseCase,
            callUpdateUseCase: callUpdateUseCase,
            chatRoomUseCase: chatRoomUseCase,
            chatUseCase: chatUseCase,
            sessionUpdateUseCase: sessionUpdateUseCase,
            noUserJoinedUseCase: noUserJoinedUseCase,
            captureDeviceUseCase: captureDeviceUseCase,
            audioSessionUseCase: audioSessionUseCase,
            callsManager: callsManager,
            uuidFactory: uuidFactory
        )
    }
}

@objc final class CallsCoordinator: NSObject, @unchecked Sendable {
    private let callUseCase: any CallUseCaseProtocol
    private let callUpdateUseCase: any CallUpdateUseCaseProtocol
    private let chatRoomUseCase: any ChatRoomUseCaseProtocol
    private let chatUseCase: any ChatUseCaseProtocol
    private let sessionUpdateUseCase: any SessionUpdateUseCaseProtocol
    private let noUserJoinedUseCase: any MeetingNoUserJoinedUseCaseProtocol
    private let captureDeviceUseCase: any CaptureDeviceUseCaseProtocol
    private let audioSessionUseCase: any AudioSessionUseCaseProtocol
    private let callsManager: any CallsManagerProtocol
    
    @Atomic private var providerDelegate: (any CallKitProviderDelegateProtocol)?
    
    private let uuidFactory: () -> UUID
    
    @Atomic private var callUpdateTask: Task<Void, Never>?
    @Atomic private var callSessionUpdateTask: Task<Void, Never>?
    
    var incomingCallForUnknownChat: IncomingCallForUnknownChat?
    
    private var logoutNotificationObserver: (any NSObjectProtocol)?
    
    @Atomic private var isCallAudioSessionActivated: Bool = false
    
    init(
        callUseCase: some CallUseCaseProtocol,
        callUpdateUseCase: some CallUpdateUseCaseProtocol,
        chatRoomUseCase: some ChatRoomUseCaseProtocol,
        chatUseCase: some ChatUseCaseProtocol,
        sessionUpdateUseCase: some SessionUpdateUseCaseProtocol,
        noUserJoinedUseCase: some MeetingNoUserJoinedUseCaseProtocol,
        captureDeviceUseCase: some CaptureDeviceUseCaseProtocol,
        audioSessionUseCase: some AudioSessionUseCaseProtocol,
        callsManager: some CallsManagerProtocol,
        uuidFactory: @escaping () -> UUID
    ) {
        self.callUseCase = callUseCase
        self.callUpdateUseCase = callUpdateUseCase
        self.chatRoomUseCase = chatRoomUseCase
        self.chatUseCase = chatUseCase
        self.sessionUpdateUseCase = sessionUpdateUseCase
        self.noUserJoinedUseCase = noUserJoinedUseCase
        self.captureDeviceUseCase = captureDeviceUseCase
        self.audioSessionUseCase = audioSessionUseCase
        self.callsManager = callsManager
        self.uuidFactory = uuidFactory
        
        super.init()
        
        onCallUpdateListener()
        monitorOnChatConnectionStateUpdate()
        logoutNotificationObserver = logoutNotificationsObserver()
    }
    
    deinit {
        callUpdateTask?.cancel()
    }
    
    // MARK: - Private
    
    private func onCallUpdateListener() {
        let callUpdates = callUpdateUseCase.monitorOnCallUpdate()
        callUpdateTask?.cancel()
        $callUpdateTask.mutate {
            $0 = Task { [weak self] in
                for await call in callUpdates {
                    self?.onCallUpdate(call)
                }
            }
        }
    }
    
    private func onCallUpdate(_ call: CallEntity) {
        switch call.changeType {
        case .status:
            manageCallStatusChange(for: call)
        case .localAVFlags:
            updateVideoForCall(call)
        case .ringingStatus:
            endCallWhenRingingStopAndUserNotPresent(call)
        case .callComposition:
            endCallIfSameUserJoinedCallInOtherDevice(call)
        default:
            break
        }
    }
    
    private func configureCallSessionsListener() {
        guard callSessionUpdateTask == nil else { return }
        let sessionUpdates = sessionUpdateUseCase.monitorOnSessionUpdate()
        $callSessionUpdateTask.mutate {
            $0 = Task { [weak self] in
                guard let self else { return }
                for await (session, call) in sessionUpdates {
                    switch session.changeType {
                    case .remoteAvFlags:
                        updateVideoForCall(call)
                    default:
                        break
                    }
                }
            }
        }
    }
    
    private func manageCallStatusChange(for call: CallEntity) {
        switch call.status {
        case .userNoPresent:
            if call.isRinging {
                sendAudioPlayerInterruptDidStartNotificationIfNeeded()
            }
        case .joining:
            updateCallTitle(call.chatId)
            reportCallStartedConnectingIfNeeded(call)
            callUseCase.enableAudioMonitor(forCall: call)
            configureCallSessionsListener()
        case .inProgress:
            reportCallConnectedIfNeeded(call)
        case .terminatingUserParticipation:
            reportEndCall(call)
            callUseCase.disableAudioMonitor(forCall: call)
            removeCallListeners()
        case .destroyed:
            reportEndCall(call)
        case .initial:
            sendAudioPlayerInterruptDidStartNotificationIfNeeded()
        default:
            break
        }
    }
    
    private func monitorOnChatConnectionStateUpdate() {
        let chatConnectionsStateUpdate = chatRoomUseCase.monitorOnChatConnectionStateUpdate()
        Task { [weak self] in
            do {
                for try await chatConnectionState in chatConnectionsStateUpdate {
                    self?.onChatConnectionStateUpdate(
                        chatId: chatConnectionState.chatId,
                        connectionStatus: chatConnectionState.connectionStatus
                    )
                }
            } catch {
                MEGALogError(
                    "[CallsCoordinator] monitorOnChatConnectionStateUpdate failed: \(error.localizedDescription)"
                )
            }
        }
    }
    
    private func onChatConnectionStateUpdate(
        chatId: ChatIdEntity, connectionStatus: ChatConnectionStatus
    ) {
        guard let incomingCallForUnknownChat,
              incomingCallForUnknownChat.chatId == chatId,
              connectionStatus == .online
        else {
            return
        }
        guard let chatRoom = chatRoomUseCase.chatRoom(forChatId: chatId) else {
            MEGALogDebug(
                "[CallsCoordinator] Report end call for incoming call in new chat room that could not be fetched"
            )
            providerDelegate?.reportEndedCall(
                with: incomingCallForUnknownChat.callUUID,
                reason: .failed
            )
            return
        }
        callsManager.addCall(
            CallActionSync(chatRoom: chatRoom),
            withUUID: incomingCallForUnknownChat.callUUID
        )
        updateCallTitle(chatId)
        MEGALogDebug(
            "[CallsCoordinator] Call in new chat room title updated after chat connection state changed to online"
        )
        
        if let answeredCompletion = incomingCallForUnknownChat.answeredCompletion {
            MEGALogDebug(
                "[CallsCoordinator] Call in new chat room answered after chat room connected to online"
            )
            answeredCompletion()
        }
    }
    
    private func removeCallListeners() {
        callSessionUpdateTask?.cancel()
        $callSessionUpdateTask.mutate { $0 = nil }
    }
    
    private func reportCallStateIfNeeded(
        _ call: CallEntity, report: (any CallKitProviderDelegateProtocol, UUID) -> Void
    ) {
        // Report outgoing call connect status just happens for outgoing calls (isOwnClientCaller)
        // or when joining an active call (isJoiningActiveCall) that is not ringing
        guard let providerDelegate,
              let callUUID = uuidToReportCallConnectChanges(for: call),
              (callsManager.call(forUUID: callUUID)?.isJoiningActiveCall ?? false)
                || call.isOwnClientCaller
        else { return }
        
        report(providerDelegate, callUUID)
    }
    
    private func reportCallStartedConnectingIfNeeded(_ call: CallEntity) {
        reportCallStateIfNeeded(call) { $0.reportOutgoingCallStartedConnecting(with: $1) }
    }
    
    private func reportCallConnectedIfNeeded(_ call: CallEntity) {
        reportCallStateIfNeeded(call) { $0.reportOutgoingCallConnected(with: $1) }
    }
    
    private func uuidToReportCallConnectChanges(for call: CallEntity) -> UUID? {
        guard let chatRoom = chatRoomUseCase.chatRoom(forChatId: call.chatId),
              let callUUID = callsManager.callUUID(forChatRoom: chatRoom)
        else { return nil }
        return callUUID
    }
    
    private func updateCallTitle(_ chatId: ChatIdEntity) {
        guard let providerDelegate,
              let chatRoom = chatRoomUseCase.chatRoom(forChatId: chatId),
              let chatTitle = chatRoom.title,
              let callUUID = callsManager.callUUID(forChatRoom: chatRoom)
        else { return }
        
        providerDelegate.updateCallTitle(chatTitle, for: callUUID)
    }
    
    private func updateVideoForCall(_ call: CallEntity) {
        guard let providerDelegate,
              let chatRoom = chatRoomUseCase.chatRoom(forChatId: call.chatId),
              let callUUID = callsManager.callUUID(forChatRoom: chatRoom)
        else { return }
        
        var video = call.hasLocalVideo
        
        for session in call.clientSessions where session.hasVideo == true {
            video = true
            break
        }
        
        providerDelegate.updateCallVideo(video, for: callUUID)
    }
    
    private func sendAudioPlayerInterruptDidStartNotificationIfNeeded() {
        guard AudioPlayerManager.shared.isPlayerAlive() else { return }
        AudioPlayerManager.shared.audioInterruptionDidStart()
    }
    
    private func sendAudioPlayerInterruptDidEndNotificationIfNeeded() {
        guard AudioPlayerManager.shared.isPlayerAlive() else { return }
        AudioPlayerManager.shared.audioInterruptionDidEndNeedToResume(true)
    }
    
    private func startCallUI(chatRoom: ChatRoomEntity, call: CallEntity) {
        Task { @MainActor in
            MeetingContainerRouter(
                presenter: UIApplication.mnz_presentingViewController(),
                chatRoom: chatRoom,
                call: call
            ).start()
        }
    }
    
    private func isWaitingRoomOpened(inChatRoom chatRoom: ChatRoomEntity) -> Bool {
        guard chatRoom.isWaitingRoomEnabled else { return false }
        return chatRoom.ownPrivilege != .moderator
    }
    
    private var localizedCameraName: String? {
        captureDeviceUseCase.wideAngleCameraLocalizedName(position: .front)
    }
    
    private func userIsNotParticipatingInCall(inChat chatId: ChatIdEntity) -> Bool {
        callUseCase.call(for: chatId)?.status != .inProgress
    }
    
    /// When a new incoming call is reported, we need to check that same user has not answered already in other device.
    /// If so, call must be reported as ended in order to dismiss VoIP call notification.
    private func checkIfIncomingCallHasBeenAlreadyAnsweredElsewhere(for chatId: ChatIdEntity) {
        if let call = callUseCase.call(for: chatId) {
            if call.participants.contains(where: { $0 == chatUseCase.myUserHandle() }) {
                MEGALogDebug(
                    "[CallsCoordinator] Provider reported new incoming call in chat room that has been already answered by same user in other device, report end call to dismiss incoming call notification"
                )
                reportEndCall(call)
            }
        }
    }
    
    /// Next functions:
    /// - `func endCallWhenRingingStopAndUserNotPresent(CallEntity)`
    /// - `func endCallIfSameUserJoinedCallInOtherDevice(CallEntity)`
    /// happens when call is ringing (possibly VoIP call notification presented),
    /// and answered in other device by same user.
    private func endCallWhenRingingStopAndUserNotPresent(_ call: CallEntity) {
        if call.status == .userNoPresent && !call.isRinging {
            reportEndCall(call)
        }
    }
    
    private func endCallIfSameUserJoinedCallInOtherDevice(_ call: CallEntity) {
        if call.status == .userNoPresent,
           call.callCompositionChange == .peerAdded,
           call.peeridCallCompositionChange == chatUseCase.myUserHandle() {
            MEGALogDebug(
                "[CallsCoordinator] Call update received while user is not participating in call and same user joined to the call in other device, report end call to dismiss incoming call notification"
            )
            reportEndCall(call)
        }
    }
    
    /// Obtains the call object from ChatSDK after performing a start call in CallKit.
    /// If user privilege is read only, means that call must be answered/joined as start call is not allowed,
    /// this happens because we allow through app UI to join a call after VoIP notification has been missed.
    /// In this scenario, call must be reported as start call to CallKit but as answer call to ChatSDK.
    private func callForAction(_ callActionSync: CallActionSync) async throws -> CallEntity {
        if callActionSync.chatRoom.ownPrivilege == .readOnly {
            return try await callUseCase.answerCall(
                for: callActionSync.chatRoom.chatId,
                enableVideo: callActionSync.videoEnabled,
                enableAudio: callActionSync.audioEnabled,
                localizedCameraName: localizedCameraName
            )
        } else {
            return try await callUseCase.startCall(
                for: callActionSync.chatRoom.chatId,
                enableVideo: callActionSync.videoEnabled,
                enableAudio: callActionSync.audioEnabled,
                notRinging: callActionSync.notRinging,
                localizedCameraName: localizedCameraName
            )
        }
    }
    
    private func reportEndCall(_ call: CallEntity) {
        MEGALogDebug("[CallsCoordinator] Report end call \(call)")
        
        guard let chatRoom = chatRoomUseCase.chatRoom(forChatId: call.chatId),
              let callUUID = callsManager.callUUID(forChatRoom: chatRoom)
        else {
            guard isCallAudioSessionActivated else {
                sendAudioPlayerInterruptDidEndNotificationIfNeeded()
                return
            }
            return
        }
        
        var endCallReason: EndCallReason?
        switch call.termCodeType {
        case .invalid, .error, .tooManyParticipants, .tooManyClients, .protocolVersion:
            endCallReason = .failed
        case .reject, .userHangup, .noParticipate, .kicked, .callDurationLimit, .callUsersLimit:
            endCallReason = .remoteEnded
        case .waitingRoomTimeout:
            endCallReason = .unanswered
        default:
            if call.participants.contains(where: { $0 == chatUseCase.myUserHandle() }) {
                endCallReason = .answeredElsewhere
            }
        }
        
        callsManager.removeCall(withUUID: callUUID)
        
        guard let providerDelegate, let endCallReason else { return }
        providerDelegate.reportEndedCall(with: callUUID, reason: endCallReason)
        
        guard isCallAudioSessionActivated else {
            sendAudioPlayerInterruptDidEndNotificationIfNeeded()
            return
        }
    }
    
    private func logoutNotificationsObserver() -> any NSObjectProtocol {
        NotificationCenter.default.addObserver(
            forName: Notification.Name.MEGAIsBeingLogout,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.didReceiveIsBeingLogoutNotification()
        }
    }
    
    private func didReceiveIsBeingLogoutNotification() {
        guard let callInProgress = chatUseCase.activeCall() else { return }
        MEGALogDebug("[CallsCoordinator] Hang active call because account is being logged out")
        callUseCase.hangCall(for: callInProgress.callId)
    }
}

extension CallsCoordinator: CallsCoordinatorProtocol {
    func startCall(_ callActionSync: CallActionSync) async -> Bool {
        do {
            let call = try await callForAction(callActionSync)
            if !callActionSync.isJoiningActiveCall {
                noUserJoinedUseCase.start(
                    timerDuration: 60 * 5, chatId: callActionSync.chatRoom.chatId)
            }
            if callActionSync.speakerEnabled {
                audioSessionUseCase.enableLoudSpeaker(completion: nil)
            }
            if !isWaitingRoomOpened(inChatRoom: callActionSync.chatRoom) {
                startCallUI(chatRoom: callActionSync.chatRoom, call: call)
            }
            return true
        } catch {
            MEGALogError(
                "[CallsCoordinator] Cannot start call in chat room \(callActionSync.chatRoom.chatId)"
            )
            return false
        }
    }
    
    func answerCall(_ callActionSync: CallActionSync) async -> Bool {
        do {
            let call = try await callUseCase.answerCall(
                for: callActionSync.chatRoom.chatId,
                enableVideo: callActionSync.videoEnabled,
                enableAudio: callActionSync.audioEnabled,
                localizedCameraName: localizedCameraName
            )
            if callActionSync.speakerEnabled {
                audioSessionUseCase.enableLoudSpeaker(completion: nil)
            }
            if !isWaitingRoomOpened(inChatRoom: callActionSync.chatRoom) {
                startCallUI(chatRoom: callActionSync.chatRoom, call: call)
            }
            return true
        } catch {
            MEGALogError(
                "[CallsCoordinator] Cannot answer call in chat room \(callActionSync.chatRoom.chatId)"
            )
            return false
        }
    }
    
    func endCall(_ callActionSync: CallActionSync) async -> Bool {
        guard let call = callUseCase.call(for: callActionSync.chatRoom.chatId) else { return false }
        
        // If call is reported but user ignored CallKit notification or the call was missed, we need to report end call and remove it from our calls dictionary
        if call.status == .userNoPresent {
            // Call is one to one and user is not present when performing ending call action, so user is rejecting the call and we should inform the caller
            if callActionSync.chatRoom.chatType == .oneToOne {
                callUseCase.hangCall(for: call.callId)
            }
            reportEndCall(call)
        } else {
            if callActionSync.endForAll {
                callUseCase.endCall(for: call.callId)
            } else {
                callUseCase.hangCall(for: call.callId)
            }
        }
        return true
    }
    
    func muteCall(_ callActionSync: CallActionSync) async -> Bool {
        do {
            if callActionSync.audioEnabled {
                try await callUseCase.enableAudioForCall(in: callActionSync.chatRoom)
            } else {
                try await callUseCase.disableAudioForCall(in: callActionSync.chatRoom)
            }
            return true
        } catch {
            MEGALogDebug("[CallsCoordinator] muteCall failed: \(error.localizedDescription)")
            return false
        }
    }
    
    func reportIncomingCall(in chatId: ChatIdEntity, completion: @escaping () -> Void) {
        guard let providerDelegate else { return }
        guard userIsNotParticipatingInCall(inChat: chatId) else {
            MEGALogDebug(
                "[CallsCoordinator] Avoid reporting new incoming call as user is already participating in a call with the same chatId"
            )
            /// According to Apple forums https://forums.developer.apple.com/forums/thread/117939
            /// While your app currently has an active call (ringing or answered), your app is not required to create additional calls for VoIP pushes received during this call. This is intended to be used to support advanced functionality like dynamic call priority, but it could also be used to cancel an incoming call.
            /// We use this functionality to avoid reporting new incoming call when user is already participating in a call in the same chat, what could happen due race conditions between joining a call and VoIP push.
            return
        }
        
        var incomingCallUUID: UUID
        var title: String
        if let chatRoom = chatRoomUseCase.chatRoom(forChatId: chatId) {
            if let callInProgressUUID = callsManager.callUUID(forChatRoom: chatRoom) {
                MEGALogDebug(
                    "[CallsCoordinator] Provider reported new incoming call that already exists")
                incomingCallUUID = callInProgressUUID
            } else {
                MEGALogDebug("[CallsCoordinator] Provider reported new incoming call")
                incomingCallUUID = uuidFactory()
                callsManager.addCall(
                    CallActionSync(chatRoom: chatRoom),
                    withUUID: incomingCallUUID
                )
            }
            title = chatRoom.title ?? "Unknown"
        } else {
            MEGALogDebug(
                "[CallsCoordinator] Provider reported new incoming call in chat room that does not exists, save and wait for chat connection"
            )
            incomingCallUUID = uuidFactory()
            title = Strings.Localizable.connecting
            incomingCallForUnknownChat = IncomingCallForUnknownChat(
                chatId: chatId, callUUID: incomingCallUUID)
        }
        
        providerDelegate.reportNewIncomingCall(with: incomingCallUUID, title: title) { [weak self] succeeded in
            if succeeded {
                self?.checkIfIncomingCallHasBeenAlreadyAnsweredElsewhere(for: chatId)
            }
            
            completion()
        }
    }
    
    // Callkit abnormal behaviour when trying to enable loudspeaker from the lock screen.
    // Solution provided in the below link.
    // https://stackoverflow.com/questions/48023629/abnormal-behavior-of-speaker-button-on-system-provided-call-screen?rq=1
    func configureWebRTCAudioSession() {
        RTCDispatcher.dispatchAsync(on: .typeAudioSession) {
            let audioSession = RTCAudioSession.sharedInstance()
            audioSession.lockForConfiguration()
            let configuration = RTCAudioSessionConfiguration.webRTC()
            configuration.categoryOptions = [.allowBluetooth, .allowBluetoothA2DP]
            try? audioSession.setConfiguration(configuration)
            audioSession.unlockForConfiguration()
        }
    }
    
    func setupProviderDelegate(_ provider: any CallKitProviderDelegateProtocol) {
        $providerDelegate.mutate {
            $0 = provider
        }
    }
    
    func didActivateCallAudioSession() {
        $isCallAudioSessionActivated.mutate { $0 = true }
    }
    
    func didDeactivateCallAudioSession() {
        $isCallAudioSessionActivated.mutate { $0 = false }
        sendAudioPlayerInterruptDidEndNotificationIfNeeded()
    }
}

enum EndCallReason: Int {
    case failed = 1
    case remoteEnded
    case unanswered
    case answeredElsewhere
    case declinedElsewhere
}
