import Foundation
import MEGADomain
import MEGAL10n
import MEGAPresentation

enum ChatContentAction: ActionType {
    case startOrJoinCallCleanUp
    case updateCallNavigationBarButtons(_ disableCalling: Bool, _ isVoiceRecordingInProgress: Bool,
                                        _ reachable: Bool, _ activeCall: Bool)
    case startMeetingNoRinging(_ videoCall: Bool, _ disableCalling: Bool, _ isVoiceRecordingInProgress: Bool,
                               _ reachable: Bool, _ activeCall: Bool)
    case startOutGoingCall(_ isVideoEnabled: Bool, _ disableCalling: Bool, _ isVoiceRecordingInProgress: Bool,
                           _ reachable: Bool, _ activeCall: Bool)
    case updateContent
    case updateCall(_ call: CallEntity?)
}

final class ChatContentViewModel: ViewModelType {
    
    enum Command: CommandType, Equatable {
        case configNavigationBar
        case tapToReturnToCallCleanUp
        case showStartOrJoinCallButton
        case initTimerForCall(_ call: CallEntity)
        case startOutGoingCall(_ enableVideo: Bool)
        case showTapToReturnToCall(_ title: String)
        case enableAudioVideoButtons(_ enable: Bool)
        case showCallEndTimerIfNeeded(_ call: CallEntity)
        case startMeetingNoRinging(_ videoCall: Bool, _ scheduledMeeting: ScheduledMeetingEntity)
        case startMeetingInWaitingRoomChat(_ videoCall: Bool, _ scheduledMeeting: ScheduledMeetingEntity)
        case hideStartOrJoinCallButton(_ hide: Bool)
    }
    
    var chatCall: CallEntity?
    var invokeCommand: ((Command) -> Void)?
    
    lazy var userHandle: HandleEntity = {
        chatUseCase.myUserHandle()
    }()
    
    lazy var isWaitingRoomFeatureEnabled = featureFlagProvider.isFeatureFlagEnabled(for: .waitingRoom)
    
    private let chatUseCase: any ChatUseCaseProtocol
    private let scheduledMeetingUseCase: any ScheduledMeetingUseCaseProtocol
    private let chatRoom: ChatRoomEntity
    private let featureFlagProvider: any FeatureFlagProviderProtocol

    init(chatRoom: ChatRoomEntity,
         chatUseCase: some ChatUseCaseProtocol,
         scheduledMeetingUseCase: some ScheduledMeetingUseCaseProtocol,
         featureFlagProvider: some FeatureFlagProviderProtocol = DIContainer.featureFlagProvider
    ) {
        self.chatRoom = chatRoom
        self.chatUseCase = chatUseCase
        self.scheduledMeetingUseCase = scheduledMeetingUseCase
        self.featureFlagProvider = featureFlagProvider
    }
    
    // MARK: - Dispatch actions
    
    func dispatch(_ action: ChatContentAction) {
        switch action {
        case .startOrJoinCallCleanUp:
            onUpdateStartOrJoinCallButtons()
        case .updateCallNavigationBarButtons(let disableCalling, let isVoiceRecordingInProgress,
                                             let reachable, let activeCall):
            onUpdateNavigationBarButtonItems(disableCalling, isVoiceRecordingInProgress, reachable, activeCall)
        case .startMeetingNoRinging(let videoCall, let disableCalling, let isVoiceRecordingInProgress,
                                    let reachable, let activeCall):
            if chatRoom.isWaitingRoomEnabled {
                startMeetingInWaitingRoomChat(videoCall, disableCalling, isVoiceRecordingInProgress, reachable, activeCall)
            } else {
                startMeetingNoRinging(videoCall, disableCalling, isVoiceRecordingInProgress, reachable, activeCall)
            }
        case .startOutGoingCall(let isVideoEnabled, let disableCalling, let isVoiceRecordingInProgress,
                                let reachable, let activeCall):
            startOutGoingCall(isVideoEnabled, disableCalling, isVoiceRecordingInProgress, reachable, activeCall)
        case .updateContent:
            updateContentIfNeeded()
        case .updateCall(let call):
            onChatCallUpdate(for: call)
        }
    }
    
    // MARK: - Public

    func shouldOpenWaitingRoom() -> Bool {
        let isModerator = chatRoom.ownPrivilege == .moderator
        return !isModerator && chatRoom.isWaitingRoomEnabled && isWaitingRoomFeatureEnabled
    }
    
    // MARK: - Private
    
    private func updateContentIfNeeded() {
        Task {
            let scheduledMeetings = await scheduledMeetingUseCase.scheduledMeetings(by: chatRoom.chatId)
            
            guard let call = await chatUseCase.chatCall(for: chatRoom.chatId),
                  await chatUseCase.chatConnectionStatus(for: chatRoom.chatId) == .online else {
                await updateReturnToCallCleanUpButton()
                await updateStartOrJoinCallButton(scheduledMeetings)
                
                return
            }
            
            await onUpdate(for: call, with: scheduledMeetings)
        }
    }
    
    private func onChatCallUpdate(for call: CallEntity?) {
        Task {
            let scheduledMeetings = await scheduledMeetingUseCase.scheduledMeetings(by: chatRoom.chatId)
            await onUpdate(for: call, with: scheduledMeetings)
        }
    }
    
    private func startMeetingNoRinging(_ videoCall: Bool,
                                       _ disableCalling: Bool,
                                       _ isVoiceRecordingInProgress: Bool,
                                       _ reachable: Bool,
                                       _ activeCall: Bool) {
        Task {
            let shouldEnable = await shouldEnableAudioVideoButtons(disableCalling, isVoiceRecordingInProgress,
                                                                   reachable, activeCall)
            let scheduledMeetings = await scheduledMeetingUseCase.scheduledMeetings(by: chatRoom.chatId)
            
            if shouldEnable && scheduledMeetings.isNotEmpty {
                await startMeetingNoRinging(videoCall, scheduledMeetings[0])
            }
        }
    }
    
    private func startMeetingInWaitingRoomChat(
        _ videoCall: Bool,
        _ disableCalling: Bool,
        _ isVoiceRecordingInProgress: Bool,
        _ reachable: Bool,
        _ activeCall: Bool
    ) {
        Task {
            let shouldEnable = await shouldEnableAudioVideoButtons(disableCalling, isVoiceRecordingInProgress,
                                                                   reachable, activeCall)
            let scheduledMeetings = await scheduledMeetingUseCase.scheduledMeetings(by: chatRoom.chatId)
            
            if shouldEnable && scheduledMeetings.isNotEmpty {
                await startMeetingInWaitingRoomChat(videoCall, scheduledMeetings[0])
            }
        }
    }
    
    private func startOutGoingCall(_ videoEnabled: Bool,
                                   _ disableCalling: Bool,
                                   _ isVoiceRecordingInProgress: Bool,
                                   _ reachable: Bool,
                                   _ activeCall: Bool) {
        Task {
            let shouldEnable = await shouldEnableAudioVideoButtons(disableCalling,
                                                                   isVoiceRecordingInProgress,
                                                                   reachable,
                                                                   activeCall)
            
            if shouldEnable {
                await startOutGoingCall(videoEnabled)
            }
        }
    }
    
    private func onUpdateStartOrJoinCallButtons() {
        Task {
            let scheduledMeetings = await scheduledMeetingUseCase.scheduledMeetings(by: chatRoom.chatId)
            await updateStartOrJoinCallButton(scheduledMeetings)
        }
    }
    
    private func onUpdateNavigationBarButtonItems(_ disableCalling: Bool,
                                                  _ isVoiceRecordingInProgress: Bool,
                                                  _ reachable: Bool,
                                                  _ activeCall: Bool) {
        Task {
            let shouldEnable = await shouldEnableAudioVideoButtons(disableCalling, isVoiceRecordingInProgress,
                                                                   reachable, activeCall)
            
            await enableNavigationBarButtonItems(shouldEnable)
        }
    }
    
    private func shouldEnableAudioVideoButtons(_ disableCalling: Bool,
                                               _ isVoiceRecordingInProgress: Bool,
                                               _ reachable: Bool,
                                               _ activeCall: Bool) async -> Bool {
        let connectionStatus = await chatUseCase.chatConnectionStatus(for: chatRoom.chatId)
        let call = await chatUseCase.chatCall(for: chatRoom.chatId)
        let ownPrivilegeSmallerThanStandard = chatRoom.ownPrivilege == .unknown ||
        chatRoom.ownPrivilege == .removed ||
        chatRoom.ownPrivilege == .readOnly
        let shouldEnable = !(disableCalling || ownPrivilegeSmallerThanStandard || connectionStatus != .online ||
                             !reachable || activeCall || call != nil || isVoiceRecordingInProgress)
        
        return shouldEnable
    }
    
    @MainActor
    private func enableNavigationBarButtonItems(_ enable: Bool) {
        invokeCommand?(.enableAudioVideoButtons(enable))
    }
    
    @MainActor
    private func startMeetingNoRinging(_ videoCall: Bool, _ scheduledMeeting: ScheduledMeetingEntity) {
        invokeCommand?(.startMeetingNoRinging(videoCall, scheduledMeeting))
    }
    
    @MainActor
    private func startMeetingInWaitingRoomChat(_ videoCall: Bool, _ scheduledMeeting: ScheduledMeetingEntity) {
        invokeCommand?(.startMeetingInWaitingRoomChat(videoCall, scheduledMeeting))
    }
    
    @MainActor
    private func startOutGoingCall(_ enableVideo: Bool) {
        invokeCommand?(.startOutGoingCall(enableVideo))
    }
    
    @MainActor
    private func updateStartOrJoinCallButton( _ scheduledMeetings: [ScheduledMeetingEntity]) {
        invokeCommand?(.hideStartOrJoinCallButton(shouldHideStartOrJoinCallButton(scheduledMeetings: scheduledMeetings)))
    }
    
    @MainActor
    private func updateReturnToCallCleanUpButton() {
        invokeCommand?(.tapToReturnToCallCleanUp)
    }
    
    @MainActor
    private func onUpdate(for call: CallEntity?, with scheduledMeetings: [ScheduledMeetingEntity]) {
        guard let call = call, call.chatId == chatRoom.chatId else { return }
        
        invokeCommand?(.configNavigationBar)
        
        chatCall = call
        
        switch call.status {
        case .initial, .joining, .userNoPresent:
            invokeCommand?(.hideStartOrJoinCallButton(shouldHideStartOrJoinCallButton(scheduledMeetings: scheduledMeetings)))
            invokeCommand?(.tapToReturnToCallCleanUp)
            invokeCommand?(.showStartOrJoinCallButton)
        case .inProgress:
            invokeCommand?(.hideStartOrJoinCallButton(shouldHideStartOrJoinCallButton(scheduledMeetings: scheduledMeetings)))
            invokeCommand?(.initTimerForCall(call))
            invokeCommand?(.showCallEndTimerIfNeeded(call))
        case .connecting:
            invokeCommand?(.showTapToReturnToCall(Strings.Localizable.reconnecting))
        case .destroyed, .terminatingUserParticipation, .undefined:
            invokeCommand?(.hideStartOrJoinCallButton(shouldHideStartOrJoinCallButton(scheduledMeetings: scheduledMeetings)))
            invokeCommand?(.tapToReturnToCallCleanUp)
        default:
            return
        }
    }
    
    private func shouldHideStartOrJoinCallButton(scheduledMeetings: [ScheduledMeetingEntity]) -> Bool {
        chatRoom.isArchived
        || chatRoom.chatType != .meeting
        || scheduledMeetings.isEmpty
        || chatUseCase.isCallInProgress(for: chatRoom.chatId)
        || !chatRoom.ownPrivilege.isUserInChat
    }
}
