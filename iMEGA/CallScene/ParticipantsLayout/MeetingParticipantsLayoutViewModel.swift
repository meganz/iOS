
protocol MeetingParticipantsLayoutRouting: Routing {
    func dismissAndShowPasscodeIfNeeded()
    func showRenameChatAlert()
}

enum CallViewAction: ActionType {
    case onViewReady
    case tapOnView
    case tapOnLayoutModeButton
    case tapOnOptionsMenuButton(presenter: UIViewController, sender: UIBarButtonItem)
    case tapOnBackButton
    case switchIphoneOrientation(_ orientation: DeviceOrientation)
    case showRenameChatAlert
    case setNewTitle(String)
    case discardChangeTitle
    case renameTitleDidChange(String)
}

enum CallLayoutMode {
    case grid
    case speaker
}

enum DeviceOrientation {
    case landscape
    case portrait
}

private enum CallViewModelConstant {
    static let maxParticipantsCountForHighResolution = 5
}

final class MeetingParticipantsLayoutViewModel: NSObject, ViewModelType {
    enum Command: CommandType, Equatable {
        case configView(title: String, subtitle: String, isVideoEnabled: Bool)
        case switchMenusVisibility
        case toggleLayoutButton
        case switchLayoutMode(layout: CallLayoutMode, participantsCount: Int)
        case switchLocalVideo
        case updateName(String)
        case updateDuration(String)
        case updatePageControl(Int)
        case insertParticipant([CallParticipantEntity])
        case deleteParticipantAt(Int, [CallParticipantEntity])
        case updateParticipantAt(Int, [CallParticipantEntity])
        case updateSpeakerViewFor(CallParticipantEntity?)
        case localVideoFrame(Int, Int, Data)
        case participantAdded(String)
        case participantRemoved(String)
        case reconnecting
        case reconnected
        case updatedCameraPosition(position: CameraPosition)
        case showRenameAlert(title: String)
        case enableRenameButton(Bool)
    }
    
    private let router: MeetingParticipantsLayoutRouting
    private var chatRoom: ChatRoomEntity
    private var call: CallEntity
    private var initialVideoCall: Bool
    private var timer: Timer?
    private var callDurationInfo: CallDurationInfo?
    private var callParticipants = [CallParticipantEntity]()
    private var speakerParticipant: CallParticipantEntity?
    internal var layoutMode: CallLayoutMode = .grid
    private var localVideoEnabled: Bool = false
    private weak var containerViewModel: MeetingContainerViewModel?

    private let callManagerUseCase: CallManagerUseCaseProtocol
    private let callsUseCase: CallsUseCaseProtocol
    private let captureDeviceUseCase: CaptureDeviceUseCaseProtocol
    private let localVideoUseCase: CallsLocalVideoUseCaseProtocol
    private let remoteVideoUseCase: CallsRemoteVideoUseCaseProtocol
    private let chatRoomUseCase: ChatRoomUseCaseProtocol

    // MARK: - Internal properties
    var invokeCommand: ((Command) -> Void)?
    
    init(router: MeetingParticipantsLayoutRouting, containerViewModel: MeetingContainerViewModel, callManager: CallManagerUseCaseProtocol, callsUseCase: CallsUseCaseProtocol, captureDeviceUseCase: CaptureDeviceUseCaseProtocol, localVideoUseCase: CallsLocalVideoUseCaseProtocol, remoteVideoUseCase: CallsRemoteVideoUseCaseProtocol, chatRoomUseCase: ChatRoomUseCaseProtocol, chatRoom: ChatRoomEntity, call: CallEntity, initialVideoCall: Bool = false) {
        
        self.router = router
        self.containerViewModel = containerViewModel
        self.callManagerUseCase = callManager
        self.callsUseCase = callsUseCase
        self.captureDeviceUseCase = captureDeviceUseCase
        self.localVideoUseCase = localVideoUseCase
        self.remoteVideoUseCase = remoteVideoUseCase
        self.chatRoomUseCase = chatRoomUseCase
        self.chatRoom = chatRoom
        self.call = call
        self.initialVideoCall = initialVideoCall

        super.init()
    }
    
    deinit {
        callsUseCase.stopListeningForCall()
    }
    
    private func initTimerIfNeeded(with duration: Int) {
        if timer == nil {
            let callDurationInfo = CallDurationInfo(initDuration: duration, baseDate: Date())
            let timer = Timer(timeInterval: 1, repeats: true, block: { [weak self] (timer) in
                let duration = Int(Date().timeIntervalSince1970) - Int(callDurationInfo.baseDate.timeIntervalSince1970) + callDurationInfo.initDuration
                self?.invokeCommand?(.updateDuration(NSString.mnz_string(fromTimeInterval: TimeInterval(duration))))
            })
            RunLoop.main.add(timer, forMode: .common)
            self.timer = timer
        }
    }
    
    private func forceGridLayout() {
        if layoutMode == .grid {
            return
        }
        layoutMode = .grid
        invokeCommand?(.switchLayoutMode(layout: layoutMode, participantsCount: callParticipants.count))
    }
    
    private func switchLayout() {
        if layoutMode == .grid {
            layoutMode = .speaker
        } else {
            layoutMode = .grid
        }
        invokeCommand?(.switchLayoutMode(layout: layoutMode, participantsCount: callParticipants.count))
        
        if speakerParticipant == nil {
            speakerParticipant = callParticipants.first
        }
        invokeCommand?(.updateSpeakerViewFor(speakerParticipant))
    }
    
    private func updateParticipant(_ participant: CallParticipantEntity) {
        guard let index = callParticipants.firstIndex(of: participant) else { return }
        invokeCommand?(.updateParticipantAt(index, callParticipants))
        
        guard let currentSpeaker = speakerParticipant, currentSpeaker == participant else {
            return
        }
        speakerParticipant = participant
        invokeCommand?(.updateSpeakerViewFor(currentSpeaker))
    }
    
    private func enableRemoteVideo(for participant: CallParticipantEntity, with resolution: CallParticipantVideoResolution) {
        switch resolution {
        case .low:
            if callParticipants.count < CallViewModelConstant.maxParticipantsCountForHighResolution {
                remoteVideoUseCase.requestHighResolutionVideo(for: chatRoom.chatId, clientId: participant.clientId) { [weak self] in
                    switch $0 {
                    case .success:
                        break
                    case .failure(_):
                        self?.remoteVideoUseCase.enableRemoteVideo(for: participant)
                    }
                }
            } else {
                remoteVideoUseCase.enableRemoteVideo(for: participant)
            }
        case .high:
            if callParticipants.count >= CallViewModelConstant.maxParticipantsCountForHighResolution {
                remoteVideoUseCase.requestLowResolutionVideos(for: chatRoom.chatId, clientIds: [participant.clientId]) { [weak self] in
                    switch $0 {
                    case .success:
                        break
                    case .failure(_):
                        self?.remoteVideoUseCase.enableRemoteVideo(for: participant)
                    }
                }
            } else {
                remoteVideoUseCase.enableRemoteVideo(for: participant)
            }
        }
    }
    
    private func disableRemoteVideo(for participant: CallParticipantEntity) {
        remoteVideoUseCase.disableRemoteVideo(for: participant)
    }
    
    private func participantName(for userHandle: MEGAHandle, completion: @escaping (String) -> Void) {
        chatRoomUseCase.userDisplayName(forPeerId: userHandle, chatId: chatRoom.chatId) { result in
            switch result {
            case .success(let displayName):
                completion(displayName)
            case .failure(_):
                break
            }
        }
    }
    
    private func isBackCameraSelected() -> Bool {
        guard let selectCameraLocalizedString = captureDeviceUseCase.wideAngleCameraLocalizedName(postion: .back),
              localVideoUseCase.videoDeviceSelected() == selectCameraLocalizedString else {
            return false
        }
        
        return true
    }
    
    internal func initialSubtitle() -> String {
        if call.isRinging || call.status == .joining {
            return NSLocalizedString("connecting", comment: "")
        } else {
            return NSLocalizedString("calling...", comment: "")
        }
    }
    
    // MARK: - Dispatch action
    func dispatch(_ action: CallViewAction) {
        switch action {
        case .onViewReady:
            invokeCommand?(.configView(title: chatRoom.title ?? "", subtitle: initialSubtitle(), isVideoEnabled: initialVideoCall))
            callsUseCase.startListeningForCallInChat(chatRoom.chatId, callbacksDelegate: self)
            remoteVideoUseCase.addRemoteVideoListener(self)
            if callParticipants.isEmpty && !call.clientSessions.isEmpty {
                callsUseCase.createActiveSessions()
            }
        case .tapOnView:
            invokeCommand?(.switchMenusVisibility)
            containerViewModel?.dispatch(.changeMenuVisibility)
        case .tapOnLayoutModeButton:
            switchLayout()
        case .tapOnOptionsMenuButton(let presenter, let sender):
            containerViewModel?.dispatch(.showOptionsMenu(presenter: presenter, sender: sender, isMyselfModerator: chatRoom.ownPrivilege == .moderator))
        case .tapOnBackButton:
            callsUseCase.stopListeningForCall()
            timer?.invalidate()
            remoteVideoUseCase.disableAllRemoteVideos()
            containerViewModel?.dispatch(.tapOnBackButton)
        case .switchIphoneOrientation(let orientation):
            switch orientation {
            case .landscape:
                forceGridLayout()
                invokeCommand?(.toggleLayoutButton)
            case .portrait:
                invokeCommand?(.toggleLayoutButton)
            }
        case .showRenameChatAlert:
            invokeCommand?(.showRenameAlert(title: chatRoom.title ?? ""))
        case .setNewTitle(let newTitle):
            chatRoomUseCase.renameChatRoom(chatId: chatRoom.chatId, title: newTitle) { [weak self] result in
                switch result {
                case .success(let title):
                    self?.invokeCommand?(.updateName(title))
                case .failure(_):
                    MEGALogDebug("Could not change the chat title")
                }
                self?.containerViewModel?.dispatch(.changeMenuVisibility)
            }
        case .discardChangeTitle:
            containerViewModel?.dispatch(.changeMenuVisibility)
        case .renameTitleDidChange(let newTitle):
            invokeCommand?(.enableRenameButton(chatRoom.title != newTitle && !newTitle.isEmpty))
        }
    }
}

struct CallDurationInfo {
    let initDuration: Int
    let baseDate: Date
}

extension MeetingParticipantsLayoutViewModel: CallsCallbacksUseCaseProtocol {
    func attendeeJoined(attendee: CallParticipantEntity) {
        initTimerIfNeeded(with: Int(call.duration))
        participantName(for: attendee.participantId) { [weak self] in
            attendee.name = $0
            if attendee.video == .on {
                self?.enableRemoteVideo(for: attendee, with: attendee.videoResolution)
            }
            self?.callParticipants.append(attendee)
            self?.invokeCommand?(.insertParticipant(self?.callParticipants ?? []))
            if self?.layoutMode == .grid {
                self?.invokeCommand?(.updatePageControl(self?.callParticipants.count ?? 0))
            }
        }
    }
    
    func attendeeLeft(attendee: CallParticipantEntity) {
        if let index = callParticipants.firstIndex(of: attendee) {
            if attendee.video == .on {
                remoteVideoUseCase.disableRemoteVideo(for: attendee)
            }
            callParticipants.remove(at: index)
            invokeCommand?(.deleteParticipantAt(index, callParticipants))
            
            if layoutMode == .grid {
                invokeCommand?(.updatePageControl(callParticipants.count))
            }
            
            guard let currentSpeaker = speakerParticipant, currentSpeaker == attendee else {
                return
            }
            speakerParticipant = callParticipants.first
            invokeCommand?(.updateSpeakerViewFor(speakerParticipant))
        } else {
            MEGALogError("Error removing participant from call")
        }
    }
    
    func updateAttendee(_ attendee: CallParticipantEntity) {
        guard let participantUpdated = callParticipants.filter({$0 == attendee}).first else {
            MEGALogError("Error getting participant with audio")
            return
        }
        if participantUpdated.video == .off && attendee.video == .on {
            participantUpdated.video = .on
            enableRemoteVideo(for: participantUpdated, with: participantUpdated.videoResolution)
        } else if participantUpdated.video == .on && attendee.video == .off {
            participantUpdated.video = .off
            disableRemoteVideo(for: participantUpdated)
        }

        participantUpdated.audio = attendee.audio
        updateParticipant(participantUpdated)
    }
    
    func remoteVideoReady(for attendee: CallParticipantEntity, with resolution: CallParticipantVideoResolution) {
        guard let participantUpdated = callParticipants.filter({$0 == attendee}).first else {
            MEGALogError("Error getting participant with audio")
            return
        }
        participantUpdated.videoResolution = resolution
        if participantUpdated.video == .off {
            return
        }
        
        enableRemoteVideo(for: participantUpdated, with: resolution)
    }
    
    func audioLevel(for attendee: CallParticipantEntity) {
        guard let participantWithAudio = callParticipants.filter({$0 == attendee}).first else {
            MEGALogError("Error getting participant with audio")
            return
        }
        if let currentSpeaker = speakerParticipant {
            if currentSpeaker != participantWithAudio {
                currentSpeaker.speakerVideoDataDelegate = nil
                speakerParticipant = participantWithAudio
                invokeCommand?(.updateSpeakerViewFor(speakerParticipant))
            }
        } else {
            speakerParticipant = participantWithAudio
            invokeCommand?(.updateSpeakerViewFor(speakerParticipant))
        }
    }
    
    func callTerminated() {
        callsUseCase.stopListeningForCall()
        timer?.invalidate()
        //Play hang out sound
        router.dismissAndShowPasscodeIfNeeded()
        //delete call flags?
    }
    
    func participantAdded(with handle: MEGAHandle) {
        participantName(for: handle) { [weak self] displayName in
            self?.invokeCommand?(.participantAdded(displayName))
        }
    }
    
    func participantRemoved(with handle: MEGAHandle) {
        participantName(for: handle) { [weak self] displayName in
            self?.invokeCommand?(.participantRemoved(displayName))
        }
    }
    
    func reconnecting() {
        invokeCommand?(.reconnecting)
    }
    
    func reconnected() {
        invokeCommand?(.reconnected)
    }
    
    func localAvFlagsUpdated(video: Bool, audio: Bool) {
        if localVideoEnabled != video {
            if localVideoEnabled {
                localVideoUseCase.removeLocalVideo(for: chatRoom.chatId, callbacksDelegate: self)
            } else {
                localVideoUseCase.addLocalVideo(for: chatRoom.chatId, callbacksDelegate: self)
            }
            localVideoEnabled = video
            invokeCommand?(.switchLocalVideo)
        }
    }
    
    func ownPrivilegeChanged(to privilege: ChatRoomEntity.Privilege, in chatRoom: ChatRoomEntity) { }
}

extension MeetingParticipantsLayoutViewModel: CallsLocalVideoCallbacksUseCaseProtocol {
    func localVideoFrameData(width: Int, height: Int, buffer: Data!) {
        invokeCommand?(.localVideoFrame(width, height, buffer))
    }
    
    func localVideoChangedCameraPosition() {
        invokeCommand?(.updatedCameraPosition(position: isBackCameraSelected() ? .back : .front))
    }
}

extension MeetingParticipantsLayoutViewModel: CallsRemoteVideoListenerUseCaseProtocol {
    func remoteVideoFrameData(clientId: MEGAHandle, width: Int, height: Int, buffer: Data!) {
        guard let participant = callParticipants.filter({ $0.clientId == clientId }).first else {
            MEGALogError("Error getting participant from remote video frame")
            return
        }
        
        participant.remoteVideoFrame(width: width, height: height, buffer: buffer)
    }
}
