
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
    static let maxParticipantsCountForHighResolution = 6
}

final class MeetingParticipantsLayoutViewModel: NSObject, ViewModelType {
    enum Command: CommandType, Equatable {
        case configView(title: String, subtitle: String, isUserAGuest: Bool)
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

    private let callsUseCase: CallsUseCaseProtocol
    private let captureDeviceUseCase: CaptureDeviceUseCaseProtocol
    private let localVideoUseCase: CallsLocalVideoUseCaseProtocol
    private let remoteVideoUseCase: CallsRemoteVideoUseCaseProtocol
    private let chatRoomUseCase: ChatRoomUseCaseProtocol
    private let userUseCase: UserUseCaseProtocol

    // MARK: - Internal properties
    var invokeCommand: ((Command) -> Void)?
    
    init(router: MeetingParticipantsLayoutRouting, containerViewModel: MeetingContainerViewModel, callsUseCase: CallsUseCaseProtocol, captureDeviceUseCase: CaptureDeviceUseCaseProtocol, localVideoUseCase: CallsLocalVideoUseCaseProtocol, remoteVideoUseCase: CallsRemoteVideoUseCaseProtocol, chatRoomUseCase: ChatRoomUseCaseProtocol, userUseCase: UserUseCaseProtocol, chatRoom: ChatRoomEntity, call: CallEntity, initialVideoCall: Bool = false) {
        
        self.router = router
        self.containerViewModel = containerViewModel
        self.callsUseCase = callsUseCase
        self.captureDeviceUseCase = captureDeviceUseCase
        self.localVideoUseCase = localVideoUseCase
        self.remoteVideoUseCase = remoteVideoUseCase
        self.chatRoomUseCase = chatRoomUseCase
        self.userUseCase = userUseCase
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
            let participantsWithHighResolutionNoSpeaker = callParticipants.filter { $0.videoResolution == .high && $0.video == .on && $0.speakerVideoDataDelegate == nil }.map { $0.clientId }
            switchVideoResolutionHighToLow(for: participantsWithHighResolutionNoSpeaker, in: chatRoom.chatId)
        } else {
            layoutMode = .grid
            switchVideoResolutionBasedOnParticipantsCount()
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
    
    private func enableRemoteVideo(for participant: CallParticipantEntity) {
        switch layoutMode {
        case .grid:
            if callParticipants.count <= CallViewModelConstant.maxParticipantsCountForHighResolution {
                if participant.videoResolution == .low {
                    switchVideoResolutionLowToHigh(for: [participant.clientId], in: chatRoom.chatId)
                } else {
                    MEGALogDebug("Enable remote video grid view high resolution")
                    remoteVideoUseCase.enableRemoteVideo(for: participant)
                }
            } else {
                if participant.videoResolution == .low {
                    MEGALogDebug("Enable remote video grid view low resolution")
                    remoteVideoUseCase.enableRemoteVideo(for: participant)
                } else {
                    switchVideoResolutionHighToLow(for: [participant.clientId], in: chatRoom.chatId)
                }
            }
        case .speaker:
            if participant.speakerVideoDataDelegate == nil {
                if participant.videoResolution == .low {
                    MEGALogDebug("Enable remote video speaker view low resolution for no speaker")
                    remoteVideoUseCase.enableRemoteVideo(for: participant)
                } else {
                    switchVideoResolutionHighToLow(for: [participant.clientId], in: chatRoom.chatId)
                }
            } else {
                if participant.videoResolution == .high {
                    MEGALogDebug("Enable remote video speaker view high resolution for speaker")
                    remoteVideoUseCase.enableRemoteVideo(for: participant)
                } else {
                    switchVideoResolutionLowToHigh(for: [participant.clientId], in: chatRoom.chatId)
                }
            }
        }
    }
    
    private func disableRemoteVideo(for participant: CallParticipantEntity) {
        MEGALogDebug("Disable remote video")
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
            if chatRoom.isMeeting {
                invokeCommand?(
                    .configView(title: chatRoom.title ?? "",
                                subtitle: "",
                                isUserAGuest: userUseCase.isGuestAccount)
                )
                initTimerIfNeeded(with: Int(call.duration))
            } else {
                invokeCommand?(
                    .configView(title: chatRoom.title ?? "",
                                subtitle: initialSubtitle(),
                                isUserAGuest: userUseCase.isGuestAccount)
                )
            }
            callsUseCase.startListeningForCallInChat(chatRoom.chatId, callbacksDelegate: self)
            remoteVideoUseCase.addRemoteVideoListener(self)
            if callParticipants.isEmpty && !call.clientSessions.isEmpty {
                callsUseCase.createActiveSessions()
            }
            localAvFlagsUpdated(video: initialVideoCall, audio: true)
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
    
    private func switchVideoResolutionHighToLow(for clientIds: [MEGAHandle], in chatId: MEGAHandle) {
        if clientIds.count == 0 {
            return
        }
        remoteVideoUseCase.stopHighResolutionVideo(for: chatRoom.chatId, clientIds: clientIds) {  [weak self] result in
            switch result {
            case .success:
                self?.remoteVideoUseCase.requestLowResolutionVideos(for: chatId, clientIds: clientIds) { result in
                    switch result {
                    case .success:
                        MEGALogDebug("Success to request low resolution video")
                    case .failure(_):
                        MEGALogError("Fail to request low resolution video")
                    }
                }
            case .failure(_):
                MEGALogError("Fail to stop high resolution video")
            }
        }
    }
    
    private func switchVideoResolutionLowToHigh(for clientIds: [MEGAHandle], in chatId: MEGAHandle) {
        if clientIds.count == 0 {
            return
        }
        remoteVideoUseCase.stopLowResolutionVideo(for: chatRoom.chatId, clientIds: clientIds) { [weak self] result in
            switch result {
            case .success:
                clientIds.forEach { clientId in
                    self?.remoteVideoUseCase.requestHighResolutionVideo(for: chatId, clientId: clientId) { result in
                        switch result {
                        case .success:
                            MEGALogDebug("Success to request high resolution video")
                        case .failure(_):
                            MEGALogError("Fail to request high resolution video")
                        }
                    }
                }
            case .failure(_):
                MEGALogError("Fail to stop low resolution video")
            }
        }
    }
    
    private func switchVideoResolutionBasedOnParticipantsCount() {
        if callParticipants.count <= CallViewModelConstant.maxParticipantsCountForHighResolution {
            let participantsWithLowResolution = callParticipants.filter { $0.videoResolution == .low && $0.video == .on }.map { $0.clientId }
            switchVideoResolutionLowToHigh(for: participantsWithLowResolution, in: chatRoom.chatId)
        } else {
            let participantsWithHighResolution = callParticipants.filter { $0.videoResolution == .high && $0.video == .on }.map { $0.clientId }
            switchVideoResolutionHighToLow(for: participantsWithHighResolution, in: chatRoom.chatId)
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
                self?.enableRemoteVideo(for: attendee)
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
                remoteVideoUseCase.disableRemoteVideo(for: callParticipants[index])
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
            MEGALogError("Error getting participant updated")
            return
        }
        if participantUpdated.video == .off && attendee.video == .on {
            participantUpdated.video = .on
            enableRemoteVideo(for: participantUpdated)
        } else if participantUpdated.video == .on && attendee.video == .off {
            participantUpdated.video = .off
            disableRemoteVideo(for: participantUpdated)
        }

        participantUpdated.audio = attendee.audio
        updateParticipant(participantUpdated)
    }
    
    func remoteVideoResolutionChanged(for attendee: CallParticipantEntity, with resolution: CallParticipantVideoResolution) {
        guard let participantUpdated = callParticipants.filter({$0 == attendee}).first else {
            MEGALogError("Error getting participant updated with video resolution")
            return
        }
        if participantUpdated.videoResolution != resolution && participantUpdated.video == .on {
            MEGALogDebug("remoteVideoResolutionChanged")
            disableRemoteVideo(for: participantUpdated)
            participantUpdated.videoResolution = resolution
            enableRemoteVideo(for: participantUpdated)
        }
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
                if layoutMode == .speaker {
                    if currentSpeaker.video == .on && currentSpeaker.videoResolution == .high {
                        switchVideoResolutionHighToLow(for: [currentSpeaker.clientId], in: chatRoom.chatId)
                    }
                    if participantWithAudio.video == .on && participantWithAudio.videoResolution == .low {
                        switchVideoResolutionLowToHigh(for: [participantWithAudio.clientId], in: chatRoom.chatId)
                    }
                }
            }
        } else {
            speakerParticipant = participantWithAudio
            invokeCommand?(.updateSpeakerViewFor(speakerParticipant))
            if layoutMode == .speaker && participantWithAudio.video == .on && participantWithAudio.videoResolution == .low {
                switchVideoResolutionLowToHigh(for: [participantWithAudio.clientId], in: chatRoom.chatId)
            }
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
        switchVideoResolutionBasedOnParticipantsCount()
    }
    
    func participantRemoved(with handle: MEGAHandle) {
        participantName(for: handle) { [weak self] displayName in
            self?.invokeCommand?(.participantRemoved(displayName))
        }
        switchVideoResolutionBasedOnParticipantsCount()
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
