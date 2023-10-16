import Foundation
import MEGADomain
import MEGAL10n
import MEGAPresentation

enum ChatContentAction: ActionType {
    case startOrJoinCallCleanUp
    case updateCallNavigationBarButtons(_ disableCalling: Bool, 
                                        _ isVoiceRecordingInProgress: Bool,
                                        _ reachable: Bool)
    case startMeetingNoRinging(_ videoCall: Bool,
                               _ disableCalling: Bool,
                               _ isVoiceRecordingInProgress: Bool,
                               _ reachable: Bool)
    case startOutGoingCall(_ isVideoEnabled: Bool,
                           _ disableCalling: Bool,
                           _ isVoiceRecordingInProgress: Bool,
                           _ reachable: Bool)
    case updateContent
    case updateCall(_ call: CallEntity?)
    case updateChatRoom(_ chatRoom: ChatRoomEntity)
    case inviteParticipants(_ userHandles: [HandleEntity])
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
        case startMeetingInWaitingRoomChatNoRinging(_ videoCall: Bool, _ scheduledMeeting: ScheduledMeetingEntity)
        case hideStartOrJoinCallButton(_ hide: Bool)
    }
    
    var invokeCommand: ((Command) -> Void)?
    
    lazy var userHandle: HandleEntity = {
        chatUseCase.myUserHandle()
    }()
        
    private var chatRoom: ChatRoomEntity
    private let chatUseCase: any ChatUseCaseProtocol
    private let chatRoomUseCase: any ChatRoomUseCaseProtocol
    private let callUseCase: any CallUseCaseProtocol
    private let scheduledMeetingUseCase: any ScheduledMeetingUseCaseProtocol
    private let featureFlagProvider: any FeatureFlagProviderProtocol

    private var invitedUserIdsToBypassWaitingRoom = Set<HandleEntity>()

    init(chatRoom: ChatRoomEntity,
         chatUseCase: some ChatUseCaseProtocol,
         chatRoomUseCase: some ChatRoomUseCaseProtocol,
         callUseCase: some CallUseCaseProtocol,
         scheduledMeetingUseCase: some ScheduledMeetingUseCaseProtocol,
         featureFlagProvider: some FeatureFlagProviderProtocol = DIContainer.featureFlagProvider
    ) {
        self.chatRoom = chatRoom
        self.chatUseCase = chatUseCase
        self.chatRoomUseCase = chatRoomUseCase
        self.callUseCase = callUseCase
        self.scheduledMeetingUseCase = scheduledMeetingUseCase
        self.featureFlagProvider = featureFlagProvider
    }
    
    // MARK: - Dispatch actions
    
    func dispatch(_ action: ChatContentAction) {
        switch action {
        case .startOrJoinCallCleanUp:
            onUpdateStartOrJoinCallButtons()
        case .updateCallNavigationBarButtons(let disableCalling, 
                                             let isVoiceRecordingInProgress,
                                             let reachable):
            onUpdateNavigationBarButtonItems(disableCalling, isVoiceRecordingInProgress, reachable)
        case .startMeetingNoRinging(let videoCall, 
                                    let disableCalling,
                                    let isVoiceRecordingInProgress,
                                    let reachable):
            if chatRoom.isWaitingRoomEnabled {
                startMeetingInWaitingRoomChatNoRinging(videoCall, disableCalling, isVoiceRecordingInProgress, reachable)
            } else {
                startMeetingNoRinging(videoCall, disableCalling, isVoiceRecordingInProgress, reachable)
            }
        case .startOutGoingCall(let isVideoEnabled, 
                                let disableCalling,
                                let isVoiceRecordingInProgress,
                                let reachable):
            if chatRoom.isWaitingRoomEnabled {
                startMeetingInWaitingRoomChat(isVideoEnabled, disableCalling, isVoiceRecordingInProgress, reachable)
            } else {
                startOutGoingCall(isVideoEnabled, disableCalling, isVoiceRecordingInProgress, reachable)
            }
        case .updateContent:
            updateContentIfNeeded()
        case .updateCall(let call):
            onChatCallUpdate(for: call)
        case .updateChatRoom(let chatRoom):
            self.chatRoom = chatRoom
        case .inviteParticipants(let userHandles):
            inviteParticipants(userHandles)
        }
    }
    
    // MARK: - Public

    func shouldOpenWaitingRoom(isReturnToCall: Bool = false) -> Bool {
        let isModerator = chatRoom.ownPrivilege == .moderator
        return !isModerator && chatRoom.isWaitingRoomEnabled && !isReturnToCall
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
                                       _ reachable: Bool) {
        Task {
            let shouldEnable = await shouldEnableAudioVideoButtons(disableCalling, isVoiceRecordingInProgress, reachable)
            let scheduledMeetings = await scheduledMeetingUseCase.scheduledMeetings(by: chatRoom.chatId)
            if shouldEnable && scheduledMeetings.isNotEmpty {
                await startMeetingNoRinging(videoCall, scheduledMeetings[0])
            }
        }
    }
    
    private func startOutGoingCall(_ videoEnabled: Bool,
                                   _ disableCalling: Bool,
                                   _ isVoiceRecordingInProgress: Bool,
                                   _ reachable: Bool) {
        Task {
            let shouldEnable = await shouldEnableAudioVideoButtons(disableCalling, isVoiceRecordingInProgress, reachable)
            if shouldEnable {
                await startOutGoingCall(videoEnabled)
            }
        }
    }
    
    private func startMeetingInWaitingRoomChatNoRinging(
        _ videoCall: Bool,
        _ disableCalling: Bool,
        _ isVoiceRecordingInProgress: Bool,
        _ reachable: Bool
    ) {
        Task {
            let shouldEnable = await shouldEnableAudioVideoButtons(disableCalling, isVoiceRecordingInProgress, reachable)
            let scheduledMeetings = await scheduledMeetingUseCase.scheduledMeetings(by: chatRoom.chatId)
            if shouldEnable, let scheduledMeeting = scheduledMeetings.first {
                await startMeetingInWaitingRoomChatNoRinging(videoCall, scheduledMeeting)
            }
        }
    }
    
    private func startMeetingInWaitingRoomChat(
        _ videoCall: Bool,
        _ disableCalling: Bool,
        _ isVoiceRecordingInProgress: Bool,
        _ reachable: Bool
    ) {
        Task {
            let shouldEnable = await shouldEnableAudioVideoButtons(disableCalling, isVoiceRecordingInProgress, reachable)
            let scheduledMeetings = await scheduledMeetingUseCase.scheduledMeetings(by: chatRoom.chatId)
            if shouldEnable, let scheduledMeeting = scheduledMeetings.first {
                await startMeetingInWaitingRoomChat(videoCall, scheduledMeeting)
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
                                                  _ reachable: Bool) {
        Task {
            let shouldEnable = await shouldEnableAudioVideoButtons(disableCalling, isVoiceRecordingInProgress, reachable)
            await enableNavigationBarButtonItems(shouldEnable)
        }
    }
    
    private func shouldEnableAudioVideoButtons(_ disableCalling: Bool,
                                               _ isVoiceRecordingInProgress: Bool,
                                               _ reachable: Bool) async -> Bool {
        let connectionStatus = await chatUseCase.chatConnectionStatus(for: chatRoom.chatId)
        let call = await chatUseCase.chatCall(for: chatRoom.chatId)
        let privilege = chatRoom.ownPrivilege
        let ownPrivilegeSmallerThanStandard = [.unknown, .removed, .readOnly].contains(privilege)
        let existsActiveCall = chatUseCase.existsActiveCall()
        let isWaitingRoomNonHost = chatRoom.isWaitingRoomEnabled && privilege != .moderator
        let shouldEnable = !(disableCalling || ownPrivilegeSmallerThanStandard || connectionStatus != .online ||
                             !reachable || existsActiveCall || call != nil || isVoiceRecordingInProgress || isWaitingRoomNonHost)
        
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
    private func startOutGoingCall(_ enableVideo: Bool) {
        invokeCommand?(.startOutGoingCall(enableVideo))
    }
    
    @MainActor
    private func startMeetingInWaitingRoomChatNoRinging(_ videoCall: Bool, _ scheduledMeeting: ScheduledMeetingEntity) {
        invokeCommand?(.startMeetingInWaitingRoomChatNoRinging(videoCall, scheduledMeeting))
    }
    
    @MainActor
    private func startMeetingInWaitingRoomChat(_ videoCall: Bool, _ scheduledMeeting: ScheduledMeetingEntity) {
        invokeCommand?(.startMeetingInWaitingRoomChat(videoCall, scheduledMeeting))
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
        guard let call, call.chatId == chatRoom.chatId else { return }
        
        invokeCommand?(.configNavigationBar)
                
        if call.changeType == .waitingRoomUsersAllow {
            waitingRoomUsersAllow(userHandles: call.waitingRoomHandleList)
        }
        
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
}
