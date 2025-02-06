import Combine
import Foundation
import MEGADomain
import MEGAL10n
import MEGAPresentation

protocol ChatContentRouting: Routing {
    func startCallUI(chatRoom: ChatRoomEntity, call: CallEntity, isSpeakerEnabled: Bool)
    func openWaitingRoom(scheduledMeeting: ScheduledMeetingEntity)
    func showCallAlreadyInProgress(endAndJoinAlertHandler: (() -> Void)?)
    func showEndCallDialog(stayOnCallCompletion: @escaping () -> Void, endCallCompletion: @escaping () -> Void)
    func removeEndCallDialogIfNeeded()
}

enum ChatContentAction: ActionType {
    case startOrJoinCallCleanUp
    case updateCallNavigationBarButtons(_ disableCalling: Bool, _ isVoiceRecordingInProgress: Bool)
    case updateContent
    case updateChatRoom(_ chatRoom: ChatRoomEntity)
    case inviteParticipants(_ userHandles: [HandleEntity])
    case startCallBarButtonTapped(isVideoEnabled: Bool)
    case startOrJoinFloatingButtonTapped
    case returnToCallBannerButtonTapped
    case requestLastGreenIfNeeded
    case resumeTransfers
    case checkTransferStatus
}

@MainActor
final class ChatContentViewModel: ViewModelType {
    
    enum Command: CommandType, Equatable {
        case configNavigationBar
        case tapToReturnToCallCleanUp
        case showStartOrJoinCallButton
        case showTapToReturnToCall(_ title: String)
        case enableAudioVideoButtons(_ enable: Bool)
        case hideStartOrJoinCallButton(_ hide: Bool)
        case updateLastGreenTime(_ lastGreenMinutes: Int) /// Minutes that have elapsed since the user was last online
        case showResumeTransfersAlert
    }
    
    struct NavBarRightItems: OptionSet {
        let rawValue: Int
        static let addParticipant = NavBarRightItems(rawValue: 1 << 0)
        static let audioCall = NavBarRightItems(rawValue: 1 << 1)
        static let videoCall = NavBarRightItems(rawValue: 1 << 2)
        static let cancel = NavBarRightItems(rawValue: 1 << 3)
        
        static let videoAndAudioCall: NavBarRightItems = [.videoCall, .audioCall]
        static let addParticipantAndAudioCall: NavBarRightItems = [.addParticipant, .audioCall]
    }
    
    var invokeCommand: ((Command) -> Void)?
        
    private var chatRoom: ChatRoomEntity
    private let chatUseCase: any ChatUseCaseProtocol
    private let chatRoomUseCase: any ChatRoomUseCaseProtocol
    private let callUseCase: any CallUseCaseProtocol
    private let callUpdateUseCase: any CallUpdateUseCaseProtocol
    private let scheduledMeetingUseCase: any ScheduledMeetingUseCaseProtocol
    private let audioSessionUseCase: any AudioSessionUseCaseProtocol
    private let analyticsEventUseCase: any AnalyticsEventUseCaseProtocol
    private let meetingNoUserJoinedUseCase: any MeetingNoUserJoinedUseCaseProtocol
    private let handleUseCase: any MEGAHandleUseCaseProtocol
    private let transfersListenerUseCase: any TransfersListenerUseCaseProtocol
    private let callController: any CallControllerProtocol
    private let callsManager: any CallsManagerProtocol

    private let router: any ChatContentRouting
    private let permissionRouter: any PermissionAlertRouting
    
    private let featureFlagProvider: any FeatureFlagProviderProtocol

    private var invitedUserIdsToBypassWaitingRoom = Set<HandleEntity>()

    var timer: Timer?
    var initDuration: TimeInterval?

    private var callUpdateSubscription: AnyCancellable?
    private var endCallSubscription: AnyCancellable?
    private var noUserJoinedSubscription: AnyCancellable?
    private var timerSubscription: AnyCancellable?

    private(set) lazy var tonePlayer = TonePlayer()
    
    private var updateNavigationBarTask: Task<Void, Never>?
    private var callTimeTrackingTask: Task<Void, Never>?
    private var updateContentTask: Task<Void, Never>?
    private var chatCallUpdateTask: Task<Void, Never>?

    private var isStartingOrJoiningCall: Bool = false
    
    init(chatRoom: ChatRoomEntity,
         chatUseCase: some ChatUseCaseProtocol,
         chatRoomUseCase: some ChatRoomUseCaseProtocol,
         callUseCase: some CallUseCaseProtocol,
         callUpdateUseCase: some CallUpdateUseCaseProtocol,
         scheduledMeetingUseCase: some ScheduledMeetingUseCaseProtocol,
         audioSessionUseCase: some AudioSessionUseCaseProtocol,
         transfersListenerUseCase: some TransfersListenerUseCaseProtocol,
         router: some ChatContentRouting,
         permissionRouter: some PermissionAlertRouting,
         analyticsEventUseCase: some AnalyticsEventUseCaseProtocol,
         meetingNoUserJoinedUseCase: some MeetingNoUserJoinedUseCaseProtocol,
         handleUseCase: some MEGAHandleUseCaseProtocol,
         callController: some CallControllerProtocol,
         callsManager: some CallsManagerProtocol,
         featureFlagProvider: some FeatureFlagProviderProtocol = DIContainer.featureFlagProvider
    ) {
        self.chatRoom = chatRoom
        self.chatUseCase = chatUseCase
        self.chatRoomUseCase = chatRoomUseCase
        self.callUseCase = callUseCase
        self.callUpdateUseCase = callUpdateUseCase
        self.scheduledMeetingUseCase = scheduledMeetingUseCase
        self.audioSessionUseCase = audioSessionUseCase
        self.transfersListenerUseCase = transfersListenerUseCase
        self.router = router
        self.permissionRouter = permissionRouter
        self.analyticsEventUseCase = analyticsEventUseCase
        self.meetingNoUserJoinedUseCase = meetingNoUserJoinedUseCase
        self.handleUseCase = handleUseCase
        self.callController = callController
        self.callsManager = callsManager
        self.featureFlagProvider = featureFlagProvider
        
        monitorOnCallUpdate()
        subscribeToNoUserJoinedNotification()
        monitorOnChatConnectionStateUpdate()
        monitorOnChatOnlineStatusUpdate()
        monitorOnChatPresenceLastGreenUpdate()
    }
    
    // MARK: - Dispatch actions
    
    func dispatch(_ action: ChatContentAction) {
        switch action {
        case .startOrJoinCallCleanUp:
            onUpdateStartOrJoinCallButtons()
        case .updateCallNavigationBarButtons(let disableCalling,
                                             let isVoiceRecordingInProgress):
            onUpdateNavigationBarButtonItems(disableCalling, isVoiceRecordingInProgress)
        case .updateContent:
            updateContentIfNeeded()
        case .updateChatRoom(let chatRoom):
            self.chatRoom = chatRoom
        case .inviteParticipants(let userHandles):
            inviteParticipants(userHandles)
        case .startCallBarButtonTapped(let isVideoEnabled):
            checkPermissionsAndStartCall(isVideoEnabled: isVideoEnabled, notRinging: false)
        case .startOrJoinFloatingButtonTapped:
            guard !existsOtherCallInProgress(),
                  !isStartingOrJoiningCall
            else { return }
            checkPermissionsAndStartCall(isVideoEnabled: false, notRinging: true)
        case .returnToCallBannerButtonTapped:
            returnToCallUI()
        case .requestLastGreenIfNeeded:
            // If chat room is one to one, ask for last time other user was online
            if let userHandle = chatRoom.oneToOneRoomOtherParticipantUserHandle() {
                chatRoomUseCase.requestLastGreen(for: userHandle)
            }
        case .resumeTransfers:
            transfersListenerUseCase.resumeTransfers()
        case .checkTransferStatus:
            if transfersListenerUseCase.areTransfersPaused() {
                invokeCommand?(.showResumeTransfersAlert)
            }
        }
    }
    
    // MARK: - Public
    
    func determineNavBarRightItems(isEditing: Bool = false) -> NavBarRightItems {
        if isEditing {
            return .cancel
        } else if chatRoom.chatType != .oneToOne {
            if (chatRoom.ownPrivilege == .moderator || chatRoom.isOpenInviteEnabled) && chatRoom.isActive {
                return .addParticipantAndAudioCall
            } else {
                return .audioCall
            }
        } else {
            return .videoAndAudioCall
        }
    }
    
    // MARK: - Private
    
    private func updateContentIfNeeded() {
        updateContentTask?.cancel()
        updateContentTask = Task {
            let scheduledMeetings = await scheduledMeetingUseCase.scheduledMeetings(by: chatRoom.chatId)
            
            guard let call = await chatUseCase.chatCall(for: chatRoom.chatId),
                  await chatUseCase.chatConnectionStatus(for: chatRoom.chatId) == .online else {
                updateReturnToCallCleanUpButton()
                updateStartOrJoinCallButton(scheduledMeetings)
                
                return
            }
            
            onUpdate(for: call, with: scheduledMeetings)
        }
    }
    
    private func onCallUpdate(_ call: CallEntity) {
        chatCallUpdateTask?.cancel()
        chatCallUpdateTask = Task {
            let scheduledMeetings = await scheduledMeetingUseCase.scheduledMeetings(by: chatRoom.chatId)
            onUpdate(for: call, with: scheduledMeetings)
        }
    }
    
    private func onUpdateStartOrJoinCallButtons() {
        Task {
            let scheduledMeetings = await scheduledMeetingUseCase.scheduledMeetings(by: chatRoom.chatId)
            updateStartOrJoinCallButton(scheduledMeetings)
        }
    }
    
    private func onUpdateNavigationBarButtonItems(
        _ disableCalling: Bool,
        _ isVoiceRecordingInProgress: Bool
    ) {
        updateNavigationBarTask?.cancel()
        updateNavigationBarTask = Task {
            let shouldEnable = await shouldEnableAudioVideoButtons(disableCalling, isVoiceRecordingInProgress)
            enableNavigationBarButtonItems(shouldEnable)
        }
    }
    
    private func shouldEnableAudioVideoButtons(
        _ disableCalling: Bool,
        _ isVoiceRecordingInProgress: Bool
    ) async -> Bool {
        let connectionStatus = await chatUseCase.chatConnectionStatus(for: chatRoom.chatId)
        let call = await chatUseCase.chatCall(for: chatRoom.chatId)
        let privilege = chatRoom.ownPrivilege
        let ownPrivilegeSmallerThanStandard = [.unknown, .removed, .readOnly].contains(privilege)
        let existsActiveCall = chatUseCase.existsActiveCall()
        let isWaitingRoomNonHost = chatRoom.isWaitingRoomEnabled && privilege != .moderator
        let shouldEnable = !(disableCalling || ownPrivilegeSmallerThanStandard || connectionStatus != .online ||
                             !MEGAReachabilityManager.isReachable() || existsActiveCall || call != nil || isVoiceRecordingInProgress || isWaitingRoomNonHost)
        
        return shouldEnable
    }
    
    private func enableNavigationBarButtonItems(_ enable: Bool) {
        invokeCommand?(.enableAudioVideoButtons(enable))
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timerSubscription?.cancel()
    }
    
    private func updateStartOrJoinCallButton( _ scheduledMeetings: [ScheduledMeetingEntity]) {
        stopTimer()
        isStartingOrJoiningCall = false
        invokeCommand?(.hideStartOrJoinCallButton(shouldHideStartOrJoinCallButton(scheduledMeetings: scheduledMeetings)))
    }
    
    private func updateReturnToCallCleanUpButton() {
        stopTimer()
        invokeCommand?(.tapToReturnToCallCleanUp)
    }
    
    private func onUpdate(for call: CallEntity?, with scheduledMeetings: [ScheduledMeetingEntity]) {
        guard let call, call.chatId == chatRoom.chatId else { return }
        
        invokeCommand?(.configNavigationBar)
                
        if call.changeType == .waitingRoomUsersAllow {
            waitingRoomUsersAllow(userHandles: call.waitingRoomHandleList)
        }
        
        switch call.status {
        case .initial, .joining, .userNoPresent:
            updateStartOrJoinCallButton(scheduledMeetings)
            updateReturnToCallCleanUpButton()
            invokeCommand?(.showStartOrJoinCallButton)
        case .inProgress:
            updateStartOrJoinCallButton(scheduledMeetings)
            initTimerForCall(call)
            showCallEndTimerIfNeeded(call: call)
        case .connecting:
            invokeCommand?(.showTapToReturnToCall(Strings.Localizable.reconnecting))
        case .destroyed, .terminatingUserParticipation, .undefined:
            updateStartOrJoinCallButton(scheduledMeetings)
            updateReturnToCallCleanUpButton()
        default:
            return
        }
    }
    
    private func initTimerForCall(_ call: CallEntity) {
        initDuration = TimeInterval(call.duration)
        if !(timer?.isValid ?? false) {
            let startTime = Date().timeIntervalSince1970
            updateTapToReturnToCallLabel(withStartTime: startTime)
                        
            timerSubscription = Timer.publish(every: 1, on: .current, in: .common)
                .autoconnect()
                .sink { [weak self] _ in
                    guard let self else { return }
                    callTimeTrackingTask?.cancel()
                    callTimeTrackingTask = Task { [weak self] in
                        guard let self else { return }
                        guard self.callUseCase.call(for: self.chatRoom.chatId)?.status != .connecting else { return }
                        self.updateTapToReturnToCallLabel(withStartTime: startTime)
                    }
                }
        }
    }
    
    private func updateTapToReturnToCallLabel(withStartTime startTime: TimeInterval) {
        guard let initDuration = initDuration else { return }
        
        let time = Date().timeIntervalSince1970 - startTime + initDuration
        let title = Strings.Localizable.Chat.CallInProgress.tapToReturnToCall(time.timeString)
        invokeCommand?(.showTapToReturnToCall(title))
    }
    
    private func shouldHideStartOrJoinCallButton(scheduledMeetings: [ScheduledMeetingEntity]) -> Bool {
        chatRoom.isArchived
        || chatRoom.chatType != .meeting
        || scheduledMeetings.isEmpty
        || chatUseCase.isCallInProgress(for: chatRoom.chatId)
        || !chatRoom.ownPrivilege.isUserInChat
        || (chatRoom.ownPrivilege == .readOnly && !chatUseCase.isCallInProgress(for: chatRoom.chatId))
    }
    
    private func inviteParticipants(_ userHandles: [HandleEntity]) {
        if let call = callUseCase.call(for: chatRoom.chatId),
           shouldInvitedParticipantsBypassWaitingRoom() {
            userHandles.forEach {
                invitedUserIdsToBypassWaitingRoom.insert($0)
            }
            callUseCase.allowUsersJoinCall(call, users: userHandles)
        } else {
            userHandles.forEach {
                chatRoomUseCase.invite(toChat: chatRoom, userId: $0)
            }
        }
    }
    
    private func shouldInvitedParticipantsBypassWaitingRoom() -> Bool {
        guard chatRoom.isWaitingRoomEnabled else { return false }
        let isModerator = chatRoom.ownPrivilege == .moderator
        let isOpenInviteEnabled = chatRoom.isOpenInviteEnabled
        return isModerator || isOpenInviteEnabled
    }
    
    private func waitingRoomUsersAllow(userHandles: [HandleEntity]) {
        guard let call = callUseCase.call(for: chatRoom.chatId) else { return }
        for userId in userHandles where invitedUserIdsToBypassWaitingRoom.contains(userId) {
            callUseCase.addPeer(toCall: call, peerId: userId)
            invitedUserIdsToBypassWaitingRoom.remove(userId)
        }
    }
    
    private func existsOtherCallInProgress() -> Bool {
        if chatUseCase.existsActiveCall() {
            guard let call = callUseCase.call(for: chatRoom.chatId), call.isActiveCall else {
                router.showCallAlreadyInProgress {[weak self] in
                    guard let self else { return }
                    endActiveCallAndJoinCurrentChatroomCall()
                }
                return true
            }
            return false
        } else {
            return false
        }
    }
    
    private func endActiveCallAndJoinCurrentChatroomCall() {
        if let activeCall = chatUseCase.activeCall() {
            endCall(activeCall)
        }
        checkPermissionsAndStartCall(isVideoEnabled: false, notRinging: false)
    }
    
    private func endCall(_ call: CallEntity) {
        callController.endCall(in: chatRoom, endForAll: false)
    }
    
    private func manageStartOrJoinCall(videoCall: Bool, notRinging: Bool) {
        isStartingOrJoiningCall = true
        if shouldOpenWaitingRoom() {
            openWaitingRoom()
        } else {
            if callUseCase.call(for: chatRoom.chatId) != nil {
                /// If there is a call notification in CallKit call can be answered,
                /// but if notification and therefore call has been missed (timeout or by user action),
                /// call must be reported to CallKit as start call (setting joining to true for connecting management),
                /// as CallKit can not longer answer a missed call.
                if let incomingCallUUID = uuidForActiveCallKitCall() {
                    callController.answerCall(in: chatRoom, withUUID: incomingCallUUID)
                } else {
                    startCallJoiningActiveCall(true, withVideo: videoCall, notRinging: notRinging)
                }
            } else {
                startCallJoiningActiveCall(false, withVideo: videoCall, notRinging: notRinging)
            }
        }
    }
    
    private func startCallJoiningActiveCall(_ joining: Bool, withVideo: Bool, notRinging: Bool) {
        callController.startCall(
            with: CallActionSync(
                chatRoom: chatRoom,
                speakerEnabled: chatRoom.isMeeting || withVideo,
                videoEnabled: withVideo,
                notRinging: notRinging,
                isJoiningActiveCall: joining
            )
        )
    }
    private func uuidForActiveCallKitCall() -> UUID? {
        callsManager.callUUID(forChatRoom: chatRoom)
    }
    
    private func checkPermissionsAndStartCall(isVideoEnabled: Bool, notRinging: Bool) {
        permissionRouter.requestPermissionsFor(videoCall: isVideoEnabled) { [weak self] in
            guard let self else { return }
            stopTimer()
            manageStartOrJoinCall(videoCall: isVideoEnabled, notRinging: notRinging)
        }
    }
    
    private func returnToCallUI() {
        guard let call = callUseCase.call(for: chatRoom.chatId) else { return }
        let isSpeakerEnabled = AVAudioSession.sharedInstance().isOutputEqualToPortType(.builtInSpeaker)
        router.startCallUI(chatRoom: chatRoom, call: call, isSpeakerEnabled: isSpeakerEnabled)
    }
    
    private func openWaitingRoom() {
        guard let scheduledMeeting = scheduledMeetingUseCase.scheduledMeetingsByChat(chatId: chatRoom.chatId).first else { return }
        router.openWaitingRoom(scheduledMeeting: scheduledMeeting)
    }
    
    private func shouldOpenWaitingRoom() -> Bool {
        guard chatRoom.isWaitingRoomEnabled else { return false }
        return chatRoom.ownPrivilege != .moderator
    }
    
    private func showCallEndDialog(withCall call: CallEntity) {   
        router.showEndCallDialog {  [weak self] in
            self?.analyticsEventUseCase.sendAnalyticsEvent(.meetings(.stayOnCallInNoParticipantsPopup))
            self?.cancelEndCallSubscription()
        } endCallCompletion: {[weak self] in
            self?.analyticsEventUseCase.sendAnalyticsEvent(.meetings(.endCallInNoParticipantsPopup))
            self?.endCall(call)
            self?.cancelEndCallSubscription()
        }
        
        endCallSubscription = Just(Void.self)
            .delay(for: .seconds(120), scheduler: RunLoop.main)
            .sink { [weak self] _ in
                guard let self else { return }
                tonePlayer.play(tone: .callEnded)
                analyticsEventUseCase.sendAnalyticsEvent(.meetings(.endCallWhenEmptyCallTimeout))
                
                // When ending call, CallKit deactivation will interrupt playing of tone.
                // Adding a delay of 0.7 seconds so there is enough time to play the tone
                Task { [weak self] in
                    guard let self else { return }
                    try await Task.sleep(nanoseconds: 700_000_000)
                    self.router.removeEndCallDialogIfNeeded()
                    self.endCall(call)
                    self.endCallSubscription = nil
                }
            }
    }
    
    private func cancelEndCallSubscription() {
        endCallSubscription?.cancel()
        endCallSubscription = nil
    }
    
    private func showCallEndTimerIfNeeded(call: CallEntity) {
        guard MeetingContainerRouter.isAlreadyPresented == false,
              call.changeType == .callComposition,
              call.numberOfParticipants == 1,
              call.participants.first == chatUseCase.myUserHandle() else {
            
            if call.changeType == .callComposition, call.numberOfParticipants > 1 {
                router.removeEndCallDialogIfNeeded()
                cancelEndCallSubscription()
            }
            
            return
        }
        
        showCallEndDialog(withCall: call)
    }
    
    private func subscribeToNoUserJoinedNotification() {
        noUserJoinedSubscription = meetingNoUserJoinedUseCase
            .monitor
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in
                guard let self else { return }
                Task {
                    guard MeetingContainerRouter.isAlreadyPresented == false,
                          let call = await self.chatUseCase.chatCall(for: self.chatRoom.chatId) else { return }
                    self.showCallEndDialog(withCall: call)
                }
            }
    }
    
    private func monitorOnCallUpdate() {
        let callUpdates = callUpdateUseCase.monitorOnCallUpdate()
        Task { [weak self] in
            for await call in callUpdates {
                self?.onCallUpdate(call)
            }
        }
    }
    
    // MARK: Chat connection state update
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
                MEGALogError("[ChatContentViewModel] monitorOnChatConnectionStateUpdate failed: \(error.localizedDescription)")
            }
        }
    }
    
    private func onChatConnectionStateUpdate(chatId: ChatIdEntity, connectionStatus: ChatConnectionStatus) {
        if chatRoom.chatId == chatId {
            invokeCommand?(.configNavigationBar)
            updateContentIfNeeded()
        }
    }
    
    // MARK: Chat online status update
    private func monitorOnChatOnlineStatusUpdate() {
        guard chatRoom.chatType == .oneToOne else { return } // For groups there are not online status
        let chatOnlineStatusUpdates = chatRoomUseCase.monitorOnChatOnlineStatusUpdate()
        Task { [weak self] in
            for try await chatOnlineStatusUpdate in chatOnlineStatusUpdates {
                self?.onChatOnlineStatusUpdate(chatOnlineStatusUpdate)
            }
        }
    }
    
    private func onChatOnlineStatusUpdate(_ chatOnlineStatus: (userHandle: HandleEntity, status: ChatStatusEntity, inProgress: Bool)) {
        // If the online status updated is not finalised (inProgress == true)
        // or the online status is from logged user (myUserHandle) return function,
        // as we just want to update for other participant in one to one chat room
        if chatOnlineStatus.inProgress || chatOnlineStatus.userHandle == chatUseCase.myUserHandle() {
            return
        }
        
        if chatRoom.oneToOneRoomOtherParticipantUserHandle() == chatOnlineStatus.userHandle,
           chatOnlineStatus.status != .invalid {
            invokeCommand?(.configNavigationBar)
            switch chatOnlineStatus.status {
            case .offline, .away:
                chatRoomUseCase.requestLastGreen(for: chatOnlineStatus.userHandle)
            default:
                break
            }
        }
    }
    
    // MARK: Chat presence last green update
    private func monitorOnChatPresenceLastGreenUpdate() {
        guard chatRoom.chatType == .oneToOne else { return } // For groups there are not presence last green
        let chatPresenceLastGreenUpdates = chatRoomUseCase.monitorOnPresenceLastGreenUpdates()
        Task { [weak self] in
            for try await chatPresenceLastGreenUpdate in chatPresenceLastGreenUpdates {
                self?.onPresenceLastGreenUpdate(chatPresenceLastGreenUpdate)
            }
        }
    }
    private func onPresenceLastGreenUpdate(_ presenceLastGreen: (userHandle: HandleEntity, lastGreen: Int)) {
        if presenceLastGreen.userHandle == chatRoom.peers.first?.handle {
            let status = chatRoomUseCase.userStatus(forUserHandle: presenceLastGreen.userHandle)
            switch status {
            case .offline, .away:
                invokeCommand?(.updateLastGreenTime(presenceLastGreen.lastGreen))
            default:
                break
            }
        }
    }
}
