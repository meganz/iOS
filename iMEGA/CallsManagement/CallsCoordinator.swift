import CallKit
import ChatRepo
import Combine
import CombineSchedulers
import MEGADomain
import MEGAL10n
import MEGAPresentation
import MEGASwift

protocol CallsCoordinatorFactoryProtocol {
    func makeCallsCoordinator(
        scheduler: AnySchedulerOf<DispatchQueue>,
        callUseCase: some CallUseCaseProtocol,
        callUpdateUseCase: some CallUpdateUseCaseProtocol,
        chatRoomUseCase: some ChatRoomUseCaseProtocol,
        chatUseCase: some ChatUseCaseProtocol,
        sessionUpdateUseCase: some SessionUpdateUseCaseProtocol,
        noUserJoinedUseCase: some MeetingNoUserJoinedUseCaseProtocol,
        captureDeviceUseCase: some CaptureDeviceUseCaseProtocol,
        audioSessionUseCase: some AudioSessionUseCaseProtocol,
        callManager: some CallManagerProtocol,
        passcodeManager: some PasscodeManagerProtocol,
        uuidFactory: @escaping () -> UUID,
        callUpdateFactory: CXCallUpdateFactory
    ) -> CallsCoordinator
}

@objc class CallsCoordinatorFactory: NSObject, CallsCoordinatorFactoryProtocol {
    func makeCallsCoordinator(
        scheduler: AnySchedulerOf<DispatchQueue>,
        callUseCase: some CallUseCaseProtocol,
        callUpdateUseCase: some CallUpdateUseCaseProtocol,
        chatRoomUseCase: some ChatRoomUseCaseProtocol,
        chatUseCase: some ChatUseCaseProtocol,
        sessionUpdateUseCase: some SessionUpdateUseCaseProtocol,
        noUserJoinedUseCase: some MeetingNoUserJoinedUseCaseProtocol,
        captureDeviceUseCase: some CaptureDeviceUseCaseProtocol,
        audioSessionUseCase: some AudioSessionUseCaseProtocol,
        callManager: some CallManagerProtocol,
        passcodeManager: some PasscodeManagerProtocol,
        uuidFactory: @escaping () -> UUID,
        callUpdateFactory: CXCallUpdateFactory
    ) -> CallsCoordinator {
        CallsCoordinator(
            scheduler: scheduler,
            callUseCase: callUseCase,
            callUpdateUseCase: callUpdateUseCase,
            chatRoomUseCase: chatRoomUseCase,
            chatUseCase: chatUseCase,
            sessionUpdateUseCase: sessionUpdateUseCase,
            noUserJoinedUseCase: noUserJoinedUseCase,
            captureDeviceUseCase: captureDeviceUseCase,
            audioSessionUseCase: audioSessionUseCase,
            callManager: callManager,
            passcodeManager: passcodeManager,
            uuidFactory: uuidFactory,
            callUpdateFactory: callUpdateFactory,
            callKitProviderDelegateFactory: CallKitProviderDelegateProvider()
        )
    }
}

protocol CallKitProviderDelegateProviding {
    func build(
        callCoordinator: any CallsCoordinatorProtocol,
        callManager: any CallManagerProtocol
    ) -> any CallKitProviderDelegateProtocol
}

struct CallKitProviderDelegateProvider: CallKitProviderDelegateProviding {
    func build(
        callCoordinator: any CallsCoordinatorProtocol,
        callManager: any CallManagerProtocol
    ) -> any CallKitProviderDelegateProtocol {
        CallKitProviderDelegate(
            callCoordinator: callCoordinator,
            callManager: callManager
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
    
    private let callManager: any CallManagerProtocol
    
    @Atomic private var providerDelegate: (any CallKitProviderDelegateProtocol)?
    
    private let passcodeManager: any PasscodeManagerProtocol
    
    private let uuidFactory: () -> UUID
    private let callUpdateFactory: CXCallUpdateFactory
    
    @Atomic private var callUpdateTask: Task<Void, Never>?
    @Atomic private var callSessionUpdateTask: Task<Void, Never>?
    
    var incomingCallForUnknownChat: IncomingCallForUnknownChat?
    
    let scheduler: AnySchedulerOf<DispatchQueue>

    @PreferenceWrapper(key: .presentPasscodeLater, defaultValue: false, useCase: PreferenceUseCase.default)
    var presentPasscodeLater: Bool
    
    init(
        scheduler: AnySchedulerOf<DispatchQueue>,
        callUseCase: some CallUseCaseProtocol,
        callUpdateUseCase: some CallUpdateUseCaseProtocol,
        chatRoomUseCase: some ChatRoomUseCaseProtocol,
        chatUseCase: some ChatUseCaseProtocol,
        sessionUpdateUseCase: some SessionUpdateUseCaseProtocol,
        noUserJoinedUseCase: some MeetingNoUserJoinedUseCaseProtocol,
        captureDeviceUseCase: some CaptureDeviceUseCaseProtocol,
        audioSessionUseCase: some AudioSessionUseCaseProtocol,
        callManager: some CallManagerProtocol,
        passcodeManager: some PasscodeManagerProtocol,
        uuidFactory: @escaping () -> UUID,
        callUpdateFactory: CXCallUpdateFactory,
        callKitProviderDelegateFactory: some CallKitProviderDelegateProviding
    ) {
        self.scheduler = scheduler
        self.callUseCase = callUseCase
        self.callUpdateUseCase = callUpdateUseCase
        self.chatRoomUseCase = chatRoomUseCase
        self.chatUseCase = chatUseCase
        self.sessionUpdateUseCase = sessionUpdateUseCase
        self.noUserJoinedUseCase = noUserJoinedUseCase
        self.captureDeviceUseCase = captureDeviceUseCase
        self.audioSessionUseCase = audioSessionUseCase
        self.callManager = callManager
        self.passcodeManager = passcodeManager
        self.uuidFactory = uuidFactory
        self.callUpdateFactory = callUpdateFactory
        
        super.init()
        
        self.$providerDelegate.mutate {
            $0 = callKitProviderDelegateFactory.build(
                callCoordinator: self,
                callManager: callManager
            )
        }

        onCallUpdateListener()
        monitorOnChatConnectionStateUpdate()
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
                MEGALogError("[CallsCoordinator] monitorOnChatConnectionStateUpdate failed: \(error.localizedDescription)")
            }
        }
    }
    
    private func onChatConnectionStateUpdate(chatId: ChatIdEntity, connectionStatus: ChatConnectionStatus) {
        guard let incomingCallForUnknownChat,
              incomingCallForUnknownChat.chatId == chatId,
              connectionStatus == .online else {
            return
        }
        guard let chatRoom = chatRoomUseCase.chatRoom(forChatId: chatId) else {
            MEGALogDebug("[CallsCoordinator] Report end call for incoming call in new chat room that could not be fetched")
            providerDelegate?.provider.reportCall(
                with: incomingCallForUnknownChat.callUUID,
                endedAt: nil,
                reason: .failed
            )
            return
        }
        callManager.addIncomingCall(
            withUUID: incomingCallForUnknownChat.callUUID,
            chatRoom: chatRoom
        )
        updateCallTitle(chatId)
        MEGALogDebug("[CallsCoordinator] Call in new chat room title updated after chat connection state changed to online")
        
        if let answeredCompletion = incomingCallForUnknownChat.answeredCompletion {
            MEGALogDebug("[CallKit] [CallsCoordinator] Call in new chat room answered after chat room connected to online")
            answeredCompletion()
        }
    }
    
    private func removeCallListeners() {
        callSessionUpdateTask?.cancel()
        $callSessionUpdateTask.mutate { $0 = nil }
    }
    
    private func reportCallStartedConnectingIfNeeded(_ call: CallEntity) {
        guard let providerDelegate,
              let callUUID = uuidToReportCallConnectChanges(for: call)
        else { return }
        
        guard (callManager.call(forUUID: callUUID)?.isJoiningActiveCall ?? false) || call.isOwnClientCaller
        else { return }
        
        providerDelegate.provider.reportOutgoingCall(with: callUUID, startedConnectingAt: nil)
    }
    
    private func reportCallConnectedIfNeeded(_ call: CallEntity) {
        guard let providerDelegate,
              let callUUID = uuidToReportCallConnectChanges(for: call)
        else { return }
        
        guard (callManager.call(forUUID: callUUID)?.isJoiningActiveCall ?? false) || call.isOwnClientCaller
        else { return }
        
        providerDelegate.provider.reportOutgoingCall(with: callUUID, connectedAt: nil)
    }
    
    private func uuidToReportCallConnectChanges(for call: CallEntity) -> UUID? {
        guard let chatRoom = chatRoomUseCase.chatRoom(forChatId: call.chatId),
              let callUUID = callManager.callUUID(forChatRoom: chatRoom) else { return nil }
        return callUUID
    }
    
    private func updateCallTitle(_ chatId: ChatIdEntity) {
        guard let chatRoom = chatRoomUseCase.chatRoom(forChatId: chatId),
              let chatTitle = chatRoom.title,
              let callUUID = callManager.callUUID(forChatRoom: chatRoom) else { return }
        
        providerDelegate?.provider.reportCall(with: callUUID, updated: callUpdateFactory.callUpdate(withChatTitle: chatTitle))
    }
    
    private func updateVideoForCall(_ call: CallEntity) {
        guard let chatRoom = chatRoomUseCase.chatRoom(forChatId: call.chatId),
              let callUUID = callManager.callUUID(forChatRoom: chatRoom) else { return }
        
        var video = call.hasLocalVideo
        
        for session in call.clientSessions where session.hasVideo == true {
            video = true
            break
        }
        
        providerDelegate?.provider.reportCall(with: callUUID, updated: callUpdateFactory.callUpdate(withVideo: video))
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
        Task {
            await MeetingContainerRouter(
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
            for handle in call.participants where chatUseCase.myUserHandle() == handle {
                reportEndCall(call)
                break
            }
        }
    }
    
    /// This happens when call is ringing (possibly VoIP call notification presented)
    /// and answered in other device by same user
    private func endCallWhenRingingStopAndUserNotPresent(_ call: CallEntity) {
        if call.status == .userNoPresent && !call.isRinging {
            reportEndCall(call)
        }
    }
}

extension CallsCoordinator: CallsCoordinatorProtocol {
    func startCall(_ callActionSync: CallActionSync) async -> Bool {
        do {
            let call = try await callUseCase.startCall(
                for: callActionSync.chatRoom.chatId,
                enableVideo: callActionSync.videoEnabled,
                enableAudio: callActionSync.audioEnabled,
                notRinging: callActionSync.notRinging,
                localizedCameraName: localizedCameraName
            )
            noUserJoinedUseCase.start(timerDuration: 60*5, chatId: callActionSync.chatRoom.chatId)
            if callActionSync.speakerEnabled {
                audioSessionUseCase.enableLoudSpeaker(completion: nil)
            }
            if !isWaitingRoomOpened(inChatRoom: callActionSync.chatRoom) {
                startCallUI(chatRoom: callActionSync.chatRoom, call: call)
            }
            return true
        } catch {
            MEGALogError("[CallsCoordinator] Cannot start call in chat room \(callActionSync.chatRoom.chatId)")
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
            MEGALogError("[CallsCoordinator] Cannot answer call in chat room \(callActionSync.chatRoom.chatId)")
            return false
        }
    }
    
    func endCall(_ callActionSync: CallActionSync) async -> Bool {
        guard let call = callUseCase.call(for: callActionSync.chatRoom.chatId) else { return false }
        
        // If call is reported but user ignored CallKit notification or the call was missed, we need to report end call and remove the it from our calls dictionary
        if call.status == .userNoPresent {
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
        guard userIsNotParticipatingInCall(inChat: chatId) else {
            MEGALogDebug("[CallKit] Provider avoid reporting new incoming call as user is already participating in a call with the same chatId")
            /// According to Apple forums https://forums.developer.apple.com/forums/thread/117939
            /// While your app currently has an active call (ringing or answered), your app is not required to create additional calls for VoIP pushes received during this call. This is intended to be used to support advanced functionality like dynamic call priority, but it could also be used to cancel an incoming call.
            /// We use this functionality to avoid reporting new incoming call when user is already participating in a call in the same chat, what could happen due race conditions between joining a call and VoIP push.
            return
        }
        
        var incomingCallUUID: UUID
        var update: CXCallUpdate
        if let chatRoom = chatRoomUseCase.chatRoom(forChatId: chatId) {
            if let callInProgressUUID = callManager.callUUID(forChatRoom: chatRoom) {
                MEGALogDebug("[CallKit] Provider report new incoming call that already exists")
                incomingCallUUID = callInProgressUUID
            } else {
                MEGALogDebug("[CallKit] Provider report new incoming call")
                incomingCallUUID = uuidFactory()
                callManager.addIncomingCall(
                    withUUID: incomingCallUUID,
                    chatRoom: chatRoom
                )
            }
            update = callUpdateFactory.createCallUpdate(title: chatRoom.title ?? "Unknown")
        } else {
            MEGALogDebug("[CallKit] Provider report new incoming call in chat room that does not exists, save and wait for chat connection")
            incomingCallUUID = uuidFactory()
            update = callUpdateFactory.createCallUpdate(title: Strings.Localizable.connecting)
            incomingCallForUnknownChat = IncomingCallForUnknownChat(chatId: chatId, callUUID: incomingCallUUID)
        }
        
        providerDelegate?.provider.reportNewIncomingCall(with: incomingCallUUID, update: update) { [weak self] error in
            if let error {
                CrashlyticsLogger.log("[CallKit] Provider Error reporting incoming call: \(String(describing: error))")
                MEGALogError("[CallKit] Provider Error reporting incoming call: \(String(describing: error))")
                if (error as NSError?)?.code == CXErrorCodeIncomingCallError.Code.filteredByDoNotDisturb.rawValue {
                    MEGALogDebug("[CallKit] Do not disturb enabled")
                }
            } else {
                self?.checkIfIncomingCallHasBeenAlreadyAnsweredElsewhere(for: chatId)
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
        
        sendAudioPlayerInterruptDidEndNotificationIfNeeded()
    }
    
    func disablePassCodeIfNeeded() {
        if passcodeManager.shouldPresentPasscodeViewLater() {
            presentPasscodeLater = true
            passcodeManager.closePasscodeView()
        }
        passcodeManager.disablePasscodeWhenApplicationEntersBackground()
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
}
