
enum MeetingFloatingPanelAction: ActionType {
    case onViewReady
    case hangCall(presenter: UIViewController, sender: UIButton)
    case shareLink(presenter: UIViewController, sender: UIButton)
    case inviteParticipants(presenter: UIViewController)
    case onContextMenuTap(presenter: UIViewController, sender: UIButton, attendee: CallParticipantEntity)
    case muteUnmuteCall(mute: Bool)
    case turnCamera(on: Bool)
    case switchCamera(backCameraOn: Bool)
    case enableLoudSpeaker
    case disableLoudSpeaker
    case makeModerator(participant: CallParticipantEntity)
    case removeModerator(participant: CallParticipantEntity)
}

final class MeetingFloatingPanelViewModel: ViewModelType {
    enum Command: CommandType, Equatable {
        case configView(canInviteParticipants: Bool,
                        isOneToOneMeeting: Bool,
                        isVideoEnabled: Bool,
                        cameraPosition: CameraPosition?)
        case enabledLoudSpeaker(enabled: Bool)
        case microphoneMuted(muted: Bool)
        case updatedCameraPosition(position: CameraPosition)
        case cameraTurnedOn(on: Bool)
        case reloadParticpantsList(participants: [CallParticipantEntity])
        case updatedAudioPortSelection(audioPort: AudioPort,bluetoothAudioRouteAvailable: Bool)
    }
    
    private let router: MeetingFloatingPanelRouting
    private var chatRoom: ChatRoomEntity
    private var call: CallEntity? {
        return callsUseCase.call(for: chatRoom.chatId)
    }
    private let callManagerUseCase: CallManagerUseCaseProtocol
    private let callsUseCase: CallsUseCaseProtocol
    private let audioSessionUseCase: AudioSessionUseCaseProtocol
    private let devicePermissionUseCase: DevicePermissionCheckingProtocol
    private let captureDeviceUseCase: CaptureDeviceUseCaseProtocol
    private let localVideoUseCase: CallsLocalVideoUseCaseProtocol
    private let userUseCase: UserUseCaseProtocol
    private weak var containerViewModel: MeetingContainerViewModel?
    private var callParticipants = [CallParticipantEntity]()
    private var isSpeakerEnabled: Bool {
        didSet {
            containerViewModel?.dispatch(.speakerEnabled(isSpeakerEnabled))
        }
    }
    private var isVideoEnabled: Bool? {
        return call?.hasLocalVideo
    }
    private var isMyselfAModerator: Bool {
        return chatRoom.ownPrivilege == .moderator
    }
    var invokeCommand: ((Command) -> Void)?

    init(router: MeetingFloatingPanelRouting,
         containerViewModel: MeetingContainerViewModel,
         chatRoom: ChatRoomEntity,
         isSpeakerEnabled: Bool,
         callManagerUseCase: CallManagerUseCaseProtocol,
         callsUseCase: CallsUseCaseProtocol,
         audioSessionUseCase: AudioSessionUseCaseProtocol,
         devicePermissionUseCase: DevicePermissionCheckingProtocol,
         captureDeviceUseCase: CaptureDeviceUseCaseProtocol,
         localVideoUseCase: CallsLocalVideoUseCaseProtocol,
         userUseCase: UserUseCaseProtocol) {
        self.router = router
        self.containerViewModel = containerViewModel
        self.chatRoom = chatRoom
        self.callManagerUseCase = callManagerUseCase
        self.callsUseCase = callsUseCase
        self.audioSessionUseCase = audioSessionUseCase
        self.devicePermissionUseCase = devicePermissionUseCase
        self.captureDeviceUseCase = captureDeviceUseCase
        self.localVideoUseCase = localVideoUseCase
        self.isSpeakerEnabled = isSpeakerEnabled
        self.userUseCase = userUseCase
    }
    
    deinit {
        callsUseCase.stopListeningForCall()
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
            callsUseCase.startListeningForCallInChat(chatRoom.chatId, callbacksDelegate: self)
            invokeCommand?(.configView(canInviteParticipants: isMyselfAModerator && !userUseCase.isGuestAccount,
                                       isOneToOneMeeting: chatRoom.chatType == .oneToOne,
                                       isVideoEnabled: isVideoEnabled ?? false,
                                       cameraPosition: (isVideoEnabled ?? false) ? (isBackCameraSelected() ? .back : .front) : nil))
            invokeCommand?(.reloadParticpantsList(participants: callParticipants))
            if isVideoEnabled ?? false {
                checkForVideoPermission {
                    self.turnCamera(on: true)
                }
            }
            
            dispatch(.muteUnmuteCall(mute: !(call?.hasLocalAudio ?? true)))
            updateSpeakerInfo()
        case .hangCall(let presenter, let sender):
            if let call = call {
                if let callId = MEGASdk.base64Handle(forUserHandle: call.callId),
                   let chatId = MEGASdk.base64Handle(forUserHandle: call.chatId) {
                    MEGALogDebug("Meeting: Floating panel - Hang call for call id \(callId) and chat id \(chatId)")
                } else {
                    MEGALogDebug("Meeting: Floating panel - Hang call - cannot get the call id and chat id string")
                }
            } else {
                MEGALogDebug("Meeting: Hang call - no call found")
            }
            containerViewModel?.dispatch(.hangCall(presenter: presenter, sender: sender))
        case .shareLink(let presenter, let sender):
            containerViewModel?.dispatch(.shareLink(presenter: presenter, sender: sender, completion: nil))
        case .inviteParticipants(let presenter):
            let participantsIDs = callParticipants.map({ $0.participantId })
            router.inviteParticipants(presenter: presenter,
                                      excludeParticpants: participantsIDs) { [weak self] userHandles in
                guard let self = self, let call = self.call else { return }
                self.containerViewModel?.dispatch(.onAddingParticipant)
                userHandles.forEach { self.callsUseCase.addPeer(toCall: call, peerId: $0) }
            }
        case .onContextMenuTap(let presenter, let sender, let attendee):
            router.showContextMenu(presenter: presenter,
                                   sender: sender,
                                   attendee: attendee,
                                   isMyselfModerator: isMyselfAModerator,
                                   meetingFloatingPanelModel: self)

        case .muteUnmuteCall(let muted):
            guard let call = self.call else { return }
            checkForAudioPermission(forCall: call) { granted in
                let microphoneMuted = granted ? muted : true
                self.callManagerUseCase.muteUnmuteCall(call, muted: microphoneMuted)
                self.invokeCommand?(.microphoneMuted(muted: microphoneMuted))
            }
        case .turnCamera(let on):
            checkForVideoPermission {
                self.turnCamera(on: on)
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
            callsUseCase.makePeerAModerator(inCall: call, peerId: participant.participantId)
            invokeCommand?(.reloadParticpantsList(participants: callParticipants))
        case .removeModerator(let participant):
            guard let call = call else { return }
            participant.isModerator = false
            callsUseCase.removePeerAsModerator(inCall: call, peerId: participant.participantId)
            invokeCommand?(.reloadParticpantsList(participants: callParticipants))

        }
    }
    
    //MARK:- Private methods
    private func enableLoudSpeaker() {
        audioSessionUseCase.enableLoudSpeaker { [weak self] _ in
            self?.updateSpeakerInfo()
        }
    }
    
    private func disableLoudSpeaker() {
        audioSessionUseCase.disableLoudSpeaker { [weak self] result in
            self?.updateSpeakerInfo()
        }
    }
    
    private func checkForVideoPermission(onSuccess completionBlock: @escaping () -> Void) {
        devicePermissionUseCase.getVideoAuthorizationStatus { [self] granted in
            DispatchQueue.main.async {
                if granted {
                    completionBlock()
                } else {
                    router.showVideoPermissionError()
                }
            }
        }
    }
    
    private func checkForAudioPermission(forCall call: CallEntity, completionBlock: @escaping (Bool) -> Void) {
        devicePermissionUseCase.getAudioAuthorizationStatus { [self] granted in
            DispatchQueue.main.async {
                completionBlock(granted)
                if !granted {
                    router.showAudioPermissionError()
                }
            }
        }
    }
    
    private func currentCameraPosition() -> CameraPosition {
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
        localVideoUseCase.selectCamera(withLocalizedName: selectCameraLocalizedString)
        let cameraPosition: CameraPosition = backCameraOn ? .back : .front
        invokeCommand?(.updatedCameraPosition(position: cameraPosition))
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
                    completion?()
                case .failure(_):
                    MEGALogDebug("Error enabling local video")
                }
            }
        } else {
            localVideoUseCase.disableLocalVideo(for: chatRoom.chatId) { result in
                switch result {
                case .success:
                    self.invokeCommand?(.cameraTurnedOn(on: on))
                    completion?()
                case .failure(_):
                    MEGALogDebug("Error disabling local video")
                }
            }
        }
    }
    
    private func populateParticipants() {
        if let myself = CallParticipantEntity.myself(chatId: chatRoom.chatId) {
            callParticipants.append(myself)
        }
        
        guard let call = call else { return }
        let participants = call.clientSessions.compactMap({CallParticipantEntity(session: $0, chatId: chatRoom.chatId)})
        if !participants.isEmpty {
            callParticipants.append(contentsOf: participants)
        }
    }
}


extension MeetingFloatingPanelViewModel: CallsCallbacksUseCaseProtocol {
    func attendeeJoined(attendee: CallParticipantEntity) {
        callParticipants.append(attendee)
        invokeCommand?(.reloadParticpantsList(participants: callParticipants))
    }
    
    func attendeeLeft(attendee: CallParticipantEntity) {
        if call == nil {
            containerViewModel?.dispatch(.dismissCall(completion: nil))
        } else if let index = callParticipants.firstIndex(of: attendee) {
            callParticipants.remove(at: index)
            invokeCommand?(.reloadParticpantsList(participants: callParticipants))
        }
    }
    
    func updateAttendee(_ attendee: CallParticipantEntity) {
        if let index = callParticipants.firstIndex(of: attendee) {
            callParticipants[index] = attendee
            invokeCommand?(.reloadParticpantsList(participants: callParticipants))
        }
    }
    
    func callTerminated() { }
    
    func ownPrivilegeChanged(to privilege: ChatRoomEntity.Privilege, in chatRoom: ChatRoomEntity) {
        self.chatRoom = chatRoom
        guard let attendee = callParticipants.first else { return }
        attendee.isModerator = privilege == .moderator
        invokeCommand?(.configView(canInviteParticipants: isMyselfAModerator && !userUseCase.isGuestAccount,
                                   isOneToOneMeeting: chatRoom.chatType == .oneToOne,
                                   isVideoEnabled: isVideoEnabled ?? false,
                                   cameraPosition: (isVideoEnabled ?? false) ? (isBackCameraSelected() ? .back : .front) : nil))
        invokeCommand?(.reloadParticpantsList(participants: callParticipants))
    }
    
    func remoteVideoResolutionChanged(for attende: CallParticipantEntity, with resolution: CallParticipantVideoResolution) {    }
    func audioLevel(for attende: CallParticipantEntity) {   }
    func participantAdded(with handle: MEGAHandle) {    }
    func participantRemoved(with handle: MEGAHandle) {  }
    func connecting() {   }
    func inProgress() {    }
    func localAvFlagsUpdated(video: Bool, audio: Bool) {    }
    func chatTitleChanged(chatRoom: ChatRoomEntity) {   }
    func networkQuality() {    }
}
