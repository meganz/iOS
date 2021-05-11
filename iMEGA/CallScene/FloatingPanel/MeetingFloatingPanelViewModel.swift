
enum MeetingFloatingPanelAction: ActionType {
    case onViewReady
    case hangCall(presenter: UIViewController)
    case shareLink(presenter: UIViewController, sender: UIButton)
    case inviteParticipants(presenter: UIViewController)
    case onContextMenuTap(presenter: UIViewController, sender: UIButton, attendee: CallParticipantEntity)
    case muteUnmuteCall(mute: Bool)
    case turnCamera(on: Bool)
    case switchCamera(backCameraOn: Bool)
    case enableLoudSpeaker
    case disableLoudSpeaker
    case changeModeratorTo(participant: CallParticipantEntity)
}

final class MeetingFloatingPanelViewModel: ViewModelType {
    enum Command: CommandType, Equatable {
        case configView(isUserAModerator: Bool,
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
    private let chatRoom: ChatRoomEntity
    private let call: CallEntity
    private let callManagerUseCase: CallManagerUseCaseProtocol
    private let callsUseCase: CallsUseCaseProtocol
    private let audioSessionUseCase: AudioSessionUseCaseProtocol
    private let devicePermissionUseCase: DevicePermissionCheckingProtocol
    private let captureDeviceUseCase: CaptureDeviceUseCaseProtocol
    private let chatRoomUseCase: ChatRoomUseCaseProtocol
    private let localVideoUseCase: CallsLocalVideoUseCaseProtocol
    private weak var containerViewModel: MeetingContainerViewModel?
    private var callParticipants = [CallParticipantEntity]()
    private var isSpeakerEnabled = false
    private var isVideoEnabled = false
    private var isMyselfAModerator: Bool {
        return chatRoom.ownPrivilege == .moderator
    }
    var invokeCommand: ((Command) -> Void)?

    init(router: MeetingFloatingPanelRouting,
         containerViewModel: MeetingContainerViewModel,
         chatRoom: ChatRoomEntity,
         call: CallEntity,
         callManagerUseCase: CallManagerUseCaseProtocol,
         callsUseCase: CallsUseCaseProtocol,
         audioSessionUseCase: AudioSessionUseCaseProtocol,
         devicePermissionUseCase: DevicePermissionCheckingProtocol,
         captureDeviceUseCase: CaptureDeviceUseCaseProtocol,
         chatRoomUseCase: ChatRoomUseCaseProtocol,
         localVideoUseCase: CallsLocalVideoUseCaseProtocol,
         isVideoEnabled: Bool) {
        self.router = router
        self.containerViewModel = containerViewModel
        self.chatRoom = chatRoom
        self.call = call
        self.callManagerUseCase = callManagerUseCase
        self.callsUseCase = callsUseCase
        self.audioSessionUseCase = audioSessionUseCase
        self.devicePermissionUseCase = devicePermissionUseCase
        self.captureDeviceUseCase = captureDeviceUseCase
        self.chatRoomUseCase = chatRoomUseCase
        self.localVideoUseCase = localVideoUseCase
        self.isVideoEnabled = isVideoEnabled
    }
    
    deinit {
        callsUseCase.stopListeningForCall()
    }
    
    func dispatch(_ action: MeetingFloatingPanelAction) {
        switch action {
        case .onViewReady:
            audioSessionUseCase.routeChanged { [weak self] routeChangedReason in
                guard let self = self else { return }
                self.sessionRouteChanged(routeChangedReason: routeChangedReason)
            }
            populateParticipants()
            callsUseCase.startListeningForCallInChat(chatRoom.chatId, callbacksDelegate: self)
            invokeCommand?(.configView(isUserAModerator: isMyselfAModerator,
                                       isOneToOneMeeting: !chatRoom.isGroup,
                                       isVideoEnabled: isVideoEnabled,
                                       cameraPosition: isVideoEnabled ? (isBackCameraSelected() ? .back : .front) : nil))
            invokeCommand?(.reloadParticpantsList(participants: callParticipants))
            if isVideoEnabled {
                checkForVideoPermission {
                    self.turnCamera(on: true)
                }
            }
        case .hangCall(let presenter):
            containerViewModel?.dispatch(.hangCall(presenter: presenter))
        case .shareLink(let presenter, let sender):
            chatRoomUseCase.fetchPublicLink(forChatRoom: chatRoom) { [weak self] result in
                switch result {
                case .success(let link):
                    self?.router.shareLink(presenter: presenter, sender: sender, link: link)
                case .failure(_):
                    MEGALogDebug("Could not get the chat link")
                }
            }
        case .inviteParticipants(let presenter):
            let participantsIDs = callParticipants.map({ $0.participantId })
            router.inviteParticipants(presenter: presenter,
                                      excludeParticpants: participantsIDs) { [weak self] userHandles in
                guard let self = self else { return }
                userHandles.forEach { self.callsUseCase.addPeer(toCall: self.call, peerId: $0) }
            }
        case .onContextMenuTap(let presenter, let sender, let attendee):
            router.showContextMenu(presenter: presenter,
                                   sender: sender,
                                   attendee: attendee,
                                   isMyselfModerator: isMyselfAModerator,
                                   meetingFloatingPanelModel: self)

        case .muteUnmuteCall(let muted):
            checkForAudioPermission {
                self.callManagerUseCase.muteUnmuteCall(callId: self.call.callId, chatId: self.chatRoom.chatId, muted: muted)
                self.invokeCommand?(.microphoneMuted(muted: muted))
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
        case .changeModeratorTo(let newModerator):
            newModerator.attendeeType = .moderator
            callsUseCase.makePeerAModerator(inCall: call, peerId: newModerator.participantId)
            invokeCommand?(.reloadParticpantsList(participants: callParticipants))
        }
    }
    
    //MARK:- Private methods
    
    private func enableLoudSpeaker() {
        audioSessionUseCase.enableLoudSpeaker { result in
            switch result {
            case .success(_):
                self.isSpeakerEnabled = true
            case .failure(_):
                break
            }
        }
    }
    
    private func disableLoudSpeaker() {
        audioSessionUseCase.disableLoudSpeaker { result in
            switch result {
            case .success(_):
                self.isSpeakerEnabled = false
            case .failure(_):
                break
            }
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
    
    private func checkForAudioPermission(onSuccess completionBlock: @escaping () -> Void) {
        devicePermissionUseCase.getAudioAuthorizationStatus { [self] granted in
            if granted {
                completionBlock()
            } else {
                router.showAudioPermissionError()
            }
        }
    }
    
    private func currentCameraPosition() -> CameraPosition {
        return captureDeviceUseCase.wideAngleCameraLocalizedName(postion: .front) == localVideoUseCase.videoDeviceSelected() ? .front : .back
    }
    
    private func sessionRouteChanged(routeChangedReason: AudioSessionRouteChangedReason) {
        switch routeChangedReason {
        case .override where audioSessionUseCase.isOutputFrom(port: .builtInReceiver) && isSpeakerEnabled,
             .categoryChange where (call.status == .reconnecting || call.status == .inProgress) && isSpeakerEnabled:
            invokeCommand?(.enabledLoudSpeaker(enabled: true))
            enableLoudSpeaker()
        default:
            break;
        }
        
        updateSpeakerInfo()
    }
    
    private func updateSpeakerInfo() {
        invokeCommand?(.updatedAudioPortSelection(audioPort: audioSessionUseCase.currentSelectedAudioPort,
                                                  bluetoothAudioRouteAvailable:  audioSessionUseCase.isBluetoothAudioRouteAvailable))
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
    
    private func turnCamera(on: Bool) {
        if on {
            localVideoUseCase.enableLocalVideo(for: chatRoom.chatId) { [weak self] result in
                guard let self = self else { return }
                switch result {
                case .success:
                    self.isVideoEnabled = on
                    self.invokeCommand?(.cameraTurnedOn(on: on))
                    self.invokeCommand?(.updatedCameraPosition(position: self.isBackCameraSelected() ? .back : .front))
                case .failure(_):
                    //TODO: show error local video HUD
                    MEGALogDebug("Error enabling local video")
                    break
                }
            }
        } else {
            localVideoUseCase.disableLocalVideo(for: chatRoom.chatId) { result in
                switch result {
                case .success:
                    self.isVideoEnabled = on
                    self.invokeCommand?(.cameraTurnedOn(on: on))
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
        if let index = callParticipants.firstIndex(of: attendee) {
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
    
    func callTerminated() {    }
    func remoteVideoReady(for attende: CallParticipantEntity, with resolution: CallParticipantVideoResolution) {    }
    func audioLevel(for attende: CallParticipantEntity) {   }
    func participantAdded(with handle: MEGAHandle) {    }
    func participantRemoved(with handle: MEGAHandle) {  }
    func reconnecting() {   }
    func reconnected() {    }
    func localAvFlagsUpdated(video: Bool, audio: Bool) {    }
}
