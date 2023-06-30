import Combine
import MEGADomain
import MEGAPresentation
import MEGAPermissions

enum MeetingFloatingPanelAction: ActionType {
    case onViewReady
    case hangCall(presenter: UIViewController, sender: UIButton)
    case shareLink(presenter: UIViewController, sender: UIButton)
    case inviteParticipants
    case onContextMenuTap(presenter: UIViewController, sender: UIButton, participant: CallParticipantEntity)
    case muteUnmuteCall(mute: Bool)
    case turnCamera(on: Bool)
    case switchCamera(backCameraOn: Bool)
    case enableLoudSpeaker
    case disableLoudSpeaker
    case makeModerator(participant: CallParticipantEntity)
    case removeModeratorPrivilage(forParticipant: CallParticipantEntity)
    case removeParticipant(participant: CallParticipantEntity)
    case displayParticipantInMainView(_ participant: CallParticipantEntity)
    case didDisplayParticipantInMainView(_ participant: CallParticipantEntity)
    case didSwitchToGridView
    case allowNonHostToAddParticipants(enabled: Bool)
}

final class MeetingFloatingPanelViewModel: ViewModelType {
    enum Command: CommandType, Equatable {
        case configView(canInviteParticipants: Bool,
                        isOneToOneMeeting: Bool,
                        isVideoEnabled: Bool,
                        cameraPosition: CameraPositionEntity?,
                        allowNonHostToAddParticipantsEnabled: Bool,
                        isMyselfAModerator: Bool)
        case enabledLoudSpeaker(enabled: Bool)
        case microphoneMuted(muted: Bool)
        case updatedCameraPosition(position: CameraPositionEntity)
        case cameraTurnedOn(on: Bool)
        case reloadParticpantsList(participants: [CallParticipantEntity])
        case updatedAudioPortSelection(audioPort: AudioPort, bluetoothAudioRouteAvailable: Bool)
        case transitionToShortForm
        case updateAllowNonHostToAddParticipants(enabled: Bool)
    }
    
    private let router: any MeetingFloatingPanelRouting
    private var chatRoom: ChatRoomEntity
    private var recentlyAddedHandles = [HandleEntity]()
    private var chatRoomParticipantsUpdatedTask: Task<Void, Never>?
    private var subscriptions = Set<AnyCancellable>()
    private var call: CallEntity? {
        return callUseCase.call(for: chatRoom.chatId)
    }
    private let callCoordinatorUseCase: CallCoordinatorUseCaseProtocol
    private let callUseCase: CallUseCaseProtocol
    private let audioSessionUseCase: any AudioSessionUseCaseProtocol
    private let permissionHandler: any DevicePermissionsHandling
    private let captureDeviceUseCase: any CaptureDeviceUseCaseProtocol
    private let localVideoUseCase: any CallLocalVideoUseCaseProtocol
    private let accountUseCase: any AccountUseCaseProtocol
    private var chatRoomUseCase: any ChatRoomUseCaseProtocol
    private let megaHandleUseCase: any MEGAHandleUseCaseProtocol
    private weak var containerViewModel: MeetingContainerViewModel?
    private var callParticipants = [CallParticipantEntity]()
    private var updateAllowNonHostToAddParticipantsTask: Task<Void, Never>?
    private var isSpeakerEnabled: Bool {
        didSet {
            containerViewModel?.dispatch(.speakerEnabled(isSpeakerEnabled))
        }
    }
    
    private var isVideoEnabled: Bool? {
        call?.hasLocalVideo
    }
    
    private var isMyselfAModerator: Bool {
        chatRoom.ownPrivilege == .moderator
    }
    
    private var canInviteParticipants: Bool {
        (isMyselfAModerator || chatRoom.isOpenInviteEnabled) && !accountUseCase.isGuest
    }
    
    var invokeCommand: ((Command) -> Void)?

    init(router: some MeetingFloatingPanelRouting,
         containerViewModel: MeetingContainerViewModel,
         chatRoom: ChatRoomEntity,
         isSpeakerEnabled: Bool,
         callCoordinatorUseCase: CallCoordinatorUseCaseProtocol,
         callUseCase: CallUseCaseProtocol,
         audioSessionUseCase: any AudioSessionUseCaseProtocol,
         permissionHandler: some DevicePermissionsHandling,
         captureDeviceUseCase: any CaptureDeviceUseCaseProtocol,
         localVideoUseCase: CallLocalVideoUseCaseProtocol,
         accountUseCase: any AccountUseCaseProtocol,
         chatRoomUseCase: any ChatRoomUseCaseProtocol,
         megaHandleUseCase: any MEGAHandleUseCaseProtocol) {
        self.router = router
        self.containerViewModel = containerViewModel
        self.chatRoom = chatRoom
        self.callCoordinatorUseCase = callCoordinatorUseCase
        self.callUseCase = callUseCase
        self.audioSessionUseCase = audioSessionUseCase
        self.permissionHandler = permissionHandler
        self.captureDeviceUseCase = captureDeviceUseCase
        self.localVideoUseCase = localVideoUseCase
        self.isSpeakerEnabled = isSpeakerEnabled
        self.accountUseCase = accountUseCase
        self.chatRoomUseCase = chatRoomUseCase
        self.megaHandleUseCase = megaHandleUseCase
    }
    
    deinit {
        callUseCase.stopListeningForCall()
        chatRoomParticipantsUpdatedTask?.cancel()
    }
    
    func dispatch(_ action: MeetingFloatingPanelAction) {
        switch action {
        case .onViewReady:
            audioSessionUseCase.routeChanged { [weak self] routeChangedReason, previousAudioPort in
                guard let self = self else { return }
                if previousAudioPort == nil,
                   self.chatRoom.chatType == .meeting,
                   self.audioSessionUseCase.currentSelectedAudioPort == .builtInReceiver {
                    self.enableLoudSpeaker()
                } else {
                    self.sessionRouteChanged(routeChangedReason: routeChangedReason)
                }
            }
            populateParticipants()
            callUseCase.startListeningForCallInChat(chatRoom.chatId, callbacksDelegate: self)
            configView()
            invokeCommand?(.reloadParticpantsList(participants: callParticipants))
            if let call = call, call.hasLocalVideo {
                checkForVideoPermission {
                    self.turnCamera(on: true) {
                        if self.isBackCameraSelected() {
                            self.invokeCommand?(.updatedCameraPosition(position: .back))
                        }
                    }
                }
            }
            
            dispatch(.muteUnmuteCall(mute: !(call?.hasLocalAudio ?? true)))
            if isSpeakerEnabled {
                enableLoudSpeaker()
            } else {
                updateSpeakerInfo()
            }
            addChatRoomParticipantsChangedListener()
            requestPrivilegeChange(forChatRoom: chatRoom)
            requestAllowNonHostToAddParticipantsValueChange(forChatRoom: chatRoom)
        case .hangCall(let presenter, let sender):
            manageHangCall(presenter, sender)
        case .shareLink(let presenter, let sender):
            containerViewModel?.dispatch(.shareLink(presenter: presenter, sender: sender, completion: nil))
        case .inviteParticipants:
            inviteParticipants()
        case .onContextMenuTap(let presenter, let sender, let participant):
            router.showContextMenu(presenter: presenter,
                                   sender: sender,
                                   participant: participant,
                                   isMyselfModerator: isMyselfAModerator,
                                   meetingFloatingPanelModel: self)

        case .muteUnmuteCall(let muted):
            guard let call = self.call else { return }
            checkForAudioPermission(forCall: call) { granted in
                let microphoneMuted = granted ? muted : true
                self.callCoordinatorUseCase.muteUnmuteCall(call, muted: microphoneMuted)
                self.invokeCommand?(.microphoneMuted(muted: microphoneMuted))
            }
        case .turnCamera(let on):
            checkForVideoPermission {
                self.turnCamera(on: on) {
                    if on && self.isBackCameraSelected() {
                        self.invokeCommand?(.updatedCameraPosition(position: .back))
                    }
                }
            }
        case .switchCamera(let backCameraOn):
            switchCamera(backCameraOn: backCameraOn)
        case .enableLoudSpeaker:
            enableLoudSpeaker()
        case .disableLoudSpeaker:
            disableLoudSpeaker()
        case .makeModerator(let participant):
            guard let call = call else { return }
            participant.isModerator = true
            callUseCase.makePeerAModerator(inCall: call, peerId: participant.participantId)
            invokeCommand?(.reloadParticpantsList(participants: callParticipants))
        case .removeModeratorPrivilage(let participant):
            guard let call = call else { return }
            participant.isModerator = false
            callUseCase.removePeerAsModerator(inCall: call, peerId: participant.participantId)
            invokeCommand?(.reloadParticpantsList(participants: callParticipants))
        case .removeParticipant(let participant):
            guard let call = call, let index = callParticipants.firstIndex(of: participant) else { return }
            callParticipants.remove(at: index)
            callUseCase.removePeer(fromCall: call, peerId: participant.participantId)
            invokeCommand?(.reloadParticpantsList(participants: callParticipants))
        case .displayParticipantInMainView(let participant):
            containerViewModel?.dispatch(.displayParticipantInMainView(participant))
            invokeCommand?(.transitionToShortForm)
        case .didDisplayParticipantInMainView(let participant):
            callParticipants.forEach { $0.isSpeakerPinned = $0 == participant }
            invokeCommand?(.reloadParticpantsList(participants: callParticipants))
        case .didSwitchToGridView:
            callParticipants.forEach { $0.isSpeakerPinned = false }
            invokeCommand?(.reloadParticpantsList(participants: callParticipants))
        case .allowNonHostToAddParticipants(let enabled):
            updateAllowNonHostToAddParticipantsTask?.cancel()
            updateAllowNonHostToAddParticipantsTask = createAllowNonHostToAddParticipants(enabled: enabled, chatRoom: chatRoom)
        }
    }
    
    // MARK: - Private methods
    private func inviteParticipants() {
        let participantsAddingViewFactory = createParticipantsAddingViewFactory()
        
        guard participantsAddingViewFactory.hasVisibleContacts else {
            router.showNoAvailableContactsAlert(withParticipantsAddingViewFactory: participantsAddingViewFactory)
            return
        }
        
        let excludedHandles = recentlyAddedHandles
        recentlyAddedHandles = []
                        
        guard participantsAddingViewFactory.hasNonAddedVisibleContacts(withExcludedHandles: Set(excludedHandles)) else {
            router.showAllContactsAlreadyAddedAlert(withParticipantsAddingViewFactory: participantsAddingViewFactory)
            return
        }
                        
        router.inviteParticipants(
            withParticipantsAddingViewFactory: participantsAddingViewFactory,
            excludeParticpantsId: Set(excludedHandles)
        ) { [weak self] userHandles in
            guard let self = self, let call = self.call else { return }
            self.recentlyAddedHandles.append(contentsOf: userHandles)
            userHandles.forEach { self.callUseCase.addPeer(toCall: call, peerId: $0) }
        }
    }
    
    private func createParticipantsAddingViewFactory() -> ParticipantsAddingViewFactory {
        ParticipantsAddingViewFactory(
            accountUseCase: accountUseCase,
            chatRoomUseCase: chatRoomUseCase,
            chatRoom: chatRoom
        )
    }
    
    private func addChatRoomParticipantsChangedListener() {
        chatRoomUseCase
            .participantsUpdated(forChatRoom: chatRoom)
            .sink { [weak self] peerHandles in
                guard let self = self else { return }
                
                self.chatRoomParticipantsUpdatedTask?.cancel()
                self.chatRoomParticipantsUpdatedTask = Task {
                    await self.updateRecentlyAddedHandles(removing: peerHandles)
                }
            }
            .store(in: &subscriptions)
    }
    
    @MainActor
    func updateRecentlyAddedHandles(removing peerHandles: [HandleEntity]) {
        recentlyAddedHandles.removeAll(where: peerHandles.contains)
    }
    
    private func enableLoudSpeaker() {
        audioSessionUseCase.enableLoudSpeaker { [weak self] _ in
            self?.updateSpeakerInfo()
        }
    }
    
    private func disableLoudSpeaker() {
        audioSessionUseCase.disableLoudSpeaker { [weak self] _ in
            self?.updateSpeakerInfo()
        }
    }
    
    private func checkForVideoPermission(onSuccess completionBlock: @escaping () -> Void) {
        permissionHandler.requestVideoPermission { [weak self] granted in
            self?.videoPermissionGranted(granted, withCompletionBlock: completionBlock)
        }
    }
    
    private func videoPermissionGranted(_ granted: Bool, withCompletionBlock completionBlock: @escaping () -> Void) {
        if granted {
            completionBlock()
        } else {
            router.showVideoPermissionError()
        }
    }
    
    private func checkForAudioPermission(forCall call: CallEntity, completionBlock: @escaping (Bool) -> Void) {
        permissionHandler.requestAudioPermission { [weak self] granted in
            self?.audioPermissionGranted(granted, withCompletionBlock: completionBlock)
        }
    }
    
    private func audioPermissionGranted(_ granted: Bool, withCompletionBlock completionBlock: @escaping (Bool) -> Void) {
        completionBlock(granted)
        if !granted {
            router.showAudioPermissionError()
        }
    }
    
    private func currentCameraPosition() -> CameraPositionEntity {
        return captureDeviceUseCase.wideAngleCameraLocalizedName(postion: .front) == localVideoUseCase.videoDeviceSelected() ? .front : .back
    }
    
    private func sessionRouteChanged(routeChangedReason: AudioSessionRouteChangedReason) {
        guard let call = call else { return }
        MEGALogDebug("Meetings: session route changed with \(routeChangedReason) , current port \(audioSessionUseCase.currentSelectedAudioPort) and call \(call)")
        isSpeakerEnabled = audioSessionUseCase.isOutputFrom(port: .builtInSpeaker)
        updateSpeakerInfo()
    }
        
    private func updateSpeakerInfo() {
        let currentSelectedPort = audioSessionUseCase.currentSelectedAudioPort
        let isBluetoothAvailable = audioSessionUseCase.isBluetoothAudioRouteAvailable
        MEGALogDebug("Meetings: updating speaker info with selected port \(currentSelectedPort) bluetooth available \(isBluetoothAvailable)")
        self.isSpeakerEnabled = currentSelectedPort == .builtInSpeaker
        invokeCommand?(
            .updatedAudioPortSelection(audioPort: currentSelectedPort,
                                       bluetoothAudioRouteAvailable: isBluetoothAvailable)
        )
    }
    
    private func switchCamera(backCameraOn: Bool) {
        guard let selectCameraLocalizedString = captureDeviceUseCase.wideAngleCameraLocalizedName(postion: backCameraOn ? .back : .front),
              localVideoUseCase.videoDeviceSelected() != selectCameraLocalizedString else {
            return
        }
        localVideoUseCase.selectCamera(withLocalizedName: selectCameraLocalizedString) { [weak self] _ in
            guard let self = self else { return }
            let cameraPosition: CameraPositionEntity = backCameraOn ? .back : .front
            self.invokeCommand?(.updatedCameraPosition(position: cameraPosition))
        }
    }
    
    private func isBackCameraSelected() -> Bool {
        guard let selectCameraLocalizedString = captureDeviceUseCase.wideAngleCameraLocalizedName(postion: .back),
              localVideoUseCase.videoDeviceSelected() == selectCameraLocalizedString else {
            return false
        }
        
        return true
    }
    
    private func turnCamera(on: Bool, completion: (() -> Void)? = nil) {
        if on {
            localVideoUseCase.enableLocalVideo(for: chatRoom.chatId) { [weak self] result in
                guard let self = self else { return }
                switch result {
                case .success:
                    self.invokeCommand?(.cameraTurnedOn(on: on))
                case .failure:
                    MEGALogDebug("Error enabling local video")
                }
                completion?()
            }
        } else {
            localVideoUseCase.disableLocalVideo(for: chatRoom.chatId) { result in
                switch result {
                case .success:
                    self.invokeCommand?(.cameraTurnedOn(on: on))
                case .failure:
                    MEGALogDebug("Error disabling local video")
                }
                completion?()
            }
        }
    }
    
    private func populateParticipants() {
        guard let call = call else {
            MEGALogError("Failed to fetch call to populate participants")
            return
        }
        if let myself = CallParticipantEntity.myself(chatId: chatRoom.chatId) {
            myself.video = call.hasLocalVideo ? .on : .off
            callParticipants.append(myself)
        }
        let participants = call.clientSessions.compactMap({CallParticipantEntity(session: $0, chatId: chatRoom.chatId)})
        if !participants.isEmpty {
            callParticipants.append(contentsOf: participants)
        }
    }
    
    private func manageHangCall(_ presenter: UIViewController, _ sender: UIButton) {
        if let call = call {
            if let callId = megaHandleUseCase.base64Handle(forUserHandle: call.callId),
               let chatId = megaHandleUseCase.base64Handle(forUserHandle: call.chatId) {
                MEGALogDebug("Meeting: Floating panel - Hang call for call id \(callId) and chat id \(chatId)")
            } else {
                MEGALogDebug("Meeting: Floating panel - Hang call - cannot get the call id and chat id string")
            }
        } else {
            MEGALogDebug("Meeting: Hang call - no call found")
        }
        if (chatRoom.chatType == .group || chatRoom.chatType == .meeting) && chatRoom.ownPrivilege == .moderator && callParticipants.count > 1 {
            containerViewModel?.dispatch(.showHangOrEndCallDialog)
        } else {
            containerViewModel?.dispatch(.hangCall(presenter: presenter, sender: sender))
        }
    }
    
    private func requestPrivilegeChange(forChatRoom chatRoom: ChatRoomEntity) {
        chatRoomUseCase.userPrivilegeChanged(forChatRoom: chatRoom)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { error in
                MEGALogDebug("error fetching the changed privilege \(error)")
            }, receiveValue: { [weak self] handle in
                self?.participantPrivilegeChanged(forUserHandle: handle, chatRoom: chatRoom)
            })
            .store(in: &subscriptions)
    }
    
    private func requestAllowNonHostToAddParticipantsValueChange(forChatRoom chatRoom: ChatRoomEntity) {
        chatRoomUseCase
            .allowNonHostToAddParticipantsValueChanged(forChatRoom: chatRoom)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { error in
                MEGALogDebug("error fetching allow host to add participants with error \(error)")
            }, receiveValue: { [weak self] _ in
                guard let self = self,
                      let chatRoom = self.chatRoomUseCase.chatRoom(forChatId: self.chatRoom.chatId) else {
                    return
                }
                
                self.chatRoom = chatRoom
                self.configView()
            })
            .store(in: &subscriptions)
    }
    
    private func participantPrivilegeChanged(forUserHandle handle: HandleEntity, chatRoom: ChatRoomEntity) {
        callParticipants.filter({ $0.participantId == handle }).forEach { participant in
            participant.isModerator = chatRoomUseCase.peerPrivilege(forUserHandle: participant.participantId, chatRoom: chatRoom) == .moderator
        }
        invokeCommand?(.reloadParticpantsList(participants: callParticipants))
    }
    
    private func createAllowNonHostToAddParticipants(enabled: Bool, chatRoom: ChatRoomEntity) -> Task<Void, Never> {
        Task { [weak self] in
            guard let self = self else { return }
            
            do {
                let allowNonHostToAddParticipantsEnabled = try await self.chatRoomUseCase.allowNonHostToAddParticipants(enabled, forChatRoom: chatRoom)
                if let chatRoom = self.chatRoomUseCase.chatRoom(forChatId: self.chatRoom.chatId) {
                    self.chatRoom = chatRoom
                }
                try Task.checkCancellation()
                if allowNonHostToAddParticipantsEnabled != enabled {
                    await self.updateAllowNonHostToAddParticipants(enabled: allowNonHostToAddParticipantsEnabled)
                }
            } catch {
                MEGALogDebug("Error allowing Non Host To Add Participants enabled \(enabled) with \(error)")
            }
        }
    }
    
    @MainActor
    private func updateAllowNonHostToAddParticipants(enabled: Bool) {
        invokeCommand?(.updateAllowNonHostToAddParticipants(enabled: enabled))
    }
}

extension MeetingFloatingPanelViewModel: CallCallbacksUseCaseProtocol {
    func participantJoined(participant: CallParticipantEntity) {
        callParticipants.append(participant)
        invokeCommand?(.reloadParticpantsList(participants: callParticipants))
    }
    
    func participantLeft(participant: CallParticipantEntity) {
        if call == nil {
            containerViewModel?.dispatch(.dismissCall(completion: nil))
        } else if let index = callParticipants.firstIndex(of: participant) {
            callParticipants.remove(at: index)
            invokeCommand?(.reloadParticpantsList(participants: callParticipants))
        }
    }
    
    func updateParticipant(_ participant: CallParticipantEntity) {
        if let index = callParticipants.firstIndex(of: participant) {
            callParticipants[index] = participant
            invokeCommand?(.reloadParticpantsList(participants: callParticipants))
        }
    }
        
    func ownPrivilegeChanged(to privilege: ChatRoomPrivilegeEntity, in chatRoom: ChatRoomEntity) {
        self.chatRoom = chatRoom
        guard let participant = callParticipants.first else { return }
        participant.isModerator = privilege == .moderator
        configView()
        invokeCommand?(.reloadParticpantsList(participants: callParticipants))
    }
    
    func configView() {
        invokeCommand?(.configView(canInviteParticipants: canInviteParticipants,
                                   isOneToOneMeeting: chatRoom.chatType == .oneToOne,
                                   isVideoEnabled: isVideoEnabled ?? false,
                                   cameraPosition: (isVideoEnabled ?? false) ? (isBackCameraSelected() ? .back : .front) : nil,
                                   allowNonHostToAddParticipantsEnabled: chatRoom.isOpenInviteEnabled,
                                   isMyselfAModerator: isMyselfAModerator))
    }
    
    func localAvFlagsUpdated(video: Bool, audio: Bool) {
        invokeCommand?(.microphoneMuted(muted: !audio))
    }
}
