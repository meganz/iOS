
enum MeetingCreatingViewAction: ActionType {
    case onViewReady
    case didTapMicroPhoneButton
    case didTapVideoButton
    case didTapSpeakerButton
    case didTapSwitchCameraButton
    case didTapCloseButton
    case didTapStartMeetingButton
    case updateMeetingName(String)
    case updateFirstName(String)
    case updateLastName(String)
    case loadAvatarImage(CGSize)
}

@objc
enum MeetingConfigurationType: Int {
    case start
    case guestJoin
    case join
}

final class MeetingCreatingViewModel: ViewModelType {
    enum Command: CommandType, Equatable {
        case configView(title: String, subtitle: String, type: MeetingConfigurationType, isMicrophoneEnabled: Bool)
        case updateMeetingName(String)
        case updateAvatarImage(UIImage)
        case updateVideoButton(enabled: Bool)
        case updateMicrophoneButton(enabled: Bool)
        case updateCameraPosition(position: CameraPosition)
        case loadingStartMeeting
        case loadingEndMeeting
        case localVideoFrame(width: Int, height: Int, buffer: Data!)
        case enabledLoudSpeaker(enabled: Bool)
        case updatedAudioPortSelection(audioPort: AudioPort,bluetoothAudioRouteAvailable: Bool)
    }
    
    // MARK: - Private properties
    private let router: MeetingCreatingViewRouting
    private var meetingName = ""
    private var firstName = ""
    private var lastName = ""

    private let type: MeetingConfigurationType
    private let link: String?
    
    private let meetingUseCase: MeetingCreatingUseCaseProtocol
    private let audioSessionUseCase: AudioSessionUseCaseProtocol
    private let callsUseCase: CallsUseCaseProtocol
    private let localVideoUseCase: CallsLocalVideoUseCaseProtocol
    private let captureDeviceUseCase: CaptureDeviceUseCaseProtocol
    private let devicePermissionUseCase: DevicePermissionCheckingProtocol
    private let chatRoomUseCase: ChatRoomUseCaseProtocol
    private let userImageUseCase: UserImageUseCaseProtocol
    private let userUseCase: UserUseCaseProtocol

    private var isVideoEnabled = false
    private var isSpeakerEnabled = true
    private var isMicrophoneEnabled = false
    private var userHandle: UInt64
    
    private var chatId: UInt64?
    // MARK: - Internal properties
    var invokeCommand: ((Command) -> Void)?
    
    private var defaultMeetingName: String {
        return String(format: NSLocalizedString("%@ Meeting", comment: "Meeting Title"), meetingUseCase.getUsername())
    }
    
    // MARK: - Init
    init(router: MeetingCreatingViewRouting,
         type: MeetingConfigurationType,
         meetingUseCase: MeetingCreatingUseCaseProtocol,
         audioSessionUseCase: AudioSessionUseCaseProtocol,
         callsUseCase: CallsUseCaseProtocol,
         localVideoUseCase: CallsLocalVideoUseCaseProtocol,
         captureDeviceUseCase: CaptureDeviceUseCaseProtocol,
         devicePermissionUseCase: DevicePermissionCheckingProtocol,
         chatRoomUseCase: ChatRoomUseCaseProtocol,
         userImageUseCase: UserImageUseCaseProtocol,
         userUseCase: UserUseCaseProtocol,
         link: String?,
         userHandle: UInt64) {
        self.router = router
        self.type = type
        self.meetingUseCase = meetingUseCase
        self.link = link
        self.callsUseCase = callsUseCase
        self.audioSessionUseCase = audioSessionUseCase
        self.localVideoUseCase = localVideoUseCase
        self.captureDeviceUseCase = captureDeviceUseCase
        self.devicePermissionUseCase = devicePermissionUseCase
        self.chatRoomUseCase = chatRoomUseCase
        self.userImageUseCase = userImageUseCase
        self.userUseCase = userUseCase
        self.userHandle = userHandle
    }
    
    // MARK: - Dispatch action
    func dispatch(_ action: MeetingCreatingViewAction) {
        switch action {
        case .onViewReady:
            audioSessionUseCase.configureAudioSession()
            audioSessionUseCase.routeChanged { [weak self] routeChangedReason in
                guard let self = self else { return }
                self.sessionRouteChanged(routeChangedReason: routeChangedReason)
            }
            if audioSessionUseCase.isBluetoothAudioRouteAvailable {
                isSpeakerEnabled = audioSessionUseCase.isOutputFrom(port: .builtInSpeaker)
                updateSpeakerInfo()
            } else {
                enableLoudSpeaker(enabled: isSpeakerEnabled)
            }
            devicePermissionUseCase.getAudioAuthorizationStatus{ _ in  }
            selectFrontCameraIfNeeded()
            switch type {
            case .join, .guestJoin:
                guard let link = link else {
                    return
                }
                checkChatLink(link: link)
            case .start:
                meetingName = defaultMeetingName
                invokeCommand?(
                    .configView(title: meetingName,
                                subtitle: "",
                                type: type,
                                isMicrophoneEnabled: isMicrophoneEnabled)
                )
            }

        case .didTapMicroPhoneButton:
            checkForAudioPermission {
                self.isMicrophoneEnabled = !self.isMicrophoneEnabled
                self.invokeCommand?(.updateMicrophoneButton(enabled: self.isMicrophoneEnabled))
            }
        case .didTapVideoButton:
            checkForVideoPermission {
                self.isVideoEnabled = !self.isVideoEnabled
                if self.isVideoEnabled {
                    self.localVideoUseCase.openVideoDevice { result in
                        self.localVideoUseCase.addLocalVideo(for: 123, callbacksDelegate: self)
                    }
                } else {
                    self.localVideoUseCase.releaseVideoDevice { result in
                        self.localVideoUseCase.removeLocalVideo(for: 123, callbacksDelegate: self)
                    }
                }
                self.invokeCommand?(.updateVideoButton(enabled: self.isVideoEnabled))
            }
        case .didTapSpeakerButton:
            isSpeakerEnabled = !isSpeakerEnabled
            enableLoudSpeaker(enabled: isSpeakerEnabled)
        case .didTapStartMeetingButton:
            disableLocalVideoIfNeeded()
            switch type {
            case .start:
                startChatCall()
            case .join:
                guard let chatId = chatId else {
                    return
                }
                joinChatCall(chatId: chatId)
            case .guestJoin:
                guard let chatId = chatId else {
                    return
                }
                createEphemeralAccountAndJoinChat(chatId: chatId)
            }
            invokeCommand?(.loadingStartMeeting)
        case .didTapCloseButton:
            localVideoUseCase.releaseVideoDevice { _ in
                self.dismiss()
            }
        case .updateMeetingName(let name):
            meetingName = name
            invokeCommand?(.updateMeetingName(meetingName))    
        case .didTapSwitchCameraButton:
            switchCamera()
        case .updateFirstName(let name):
            firstName = name
        case .updateLastName(let name):
            lastName = name
        case .loadAvatarImage(let size):
            guard let myHandle = userUseCase.myHandle else {
                return
            }
            
            userImageUseCase.fetchUserAvatar(withUserHandle: myHandle,
                                             name: meetingUseCase.getUsername(),
                                             size: size) { [weak self] result in
                guard let self = self else { return }
                switch result {
                    case .success(let image):
                        self.invokeCommand?(.updateAvatarImage(image))
                    default:
                        break
                }
            }
        }
    }
    
    private func enableLoudSpeaker(enabled: Bool) {
        if enabled {
            audioSessionUseCase.enableLoudSpeaker { [weak self] result in
                switch result {
                case .success(_):
                    self?.invokeCommand?(.enabledLoudSpeaker(enabled: true))
                    MEGALogDebug("Create Meeting: Loud speaker enabled")
                case .failure(_):
                    MEGALogDebug("Create Meeting: Failed to enable loud speaker")
                }
            }
        } else {
            audioSessionUseCase.disableLoudSpeaker { [weak self] result in
                switch result {
                case .success(_):
                    self?.invokeCommand?(.enabledLoudSpeaker(enabled: false))
                    MEGALogDebug("Create Meeting: Loud speaker disabled")
                case .failure(_):
                    MEGALogDebug("Create Meeting: Failed to disable loud speaker")
                }
            }
        }
    }
    
    private func createEphemeralAccountAndJoinChat(chatId: UInt64) {
        guard let link = link else {
            return
        }
        
        self.meetingUseCase.createEphemeralAccountAndJoinChat(firstName: self.firstName, lastName: self.lastName, link: link) { [weak self] in
            guard let self = self else { return }
            switch $0 {
            case .success(_):
                self.joinChatCall(chatId: chatId)
                
            case .failure(_):
                self.dismiss()
            }
        }
    }
    
    private func joinChatCall(chatId: UInt64) {
        meetingUseCase.joinChatCall(forChatId: chatId, enableVideo: isVideoEnabled, enableAudio: isMicrophoneEnabled, userHandle: userHandle) { [weak self] in
            guard let self = self else { return }
            switch $0 {
            case .success(let chatRoom):
                guard let call = self.meetingUseCase.getCall(forChatId: chatRoom.chatId) else {
                    MEGALogError("Can not join meeting, not call found for chat")
                    self.dismiss()
                    return
                }
                self.router.dismiss()
                self.router.goToMeetingRoom(chatRoom: chatRoom, call: call, isVideoEnabled: self.isVideoEnabled, isSpeakerEnabled: self.isSpeakerEnabled)
            case .failure(_):
                self.dismiss()
            }
        }
    }
    
    private func startChatCall() {
        if meetingName.isEmpty || meetingName.trimmingCharacters(in: .whitespaces).isEmpty {
            dispatch(.updateMeetingName(defaultMeetingName))
        }
        
        meetingUseCase.startChatCall(meetingName: meetingName, enableVideo: isVideoEnabled, enableAudio: isMicrophoneEnabled) { [weak self] in
            guard let self = self else { return }
            switch $0 {
            case .success(let chatRoom):
                guard let call = self.meetingUseCase.getCall(forChatId: chatRoom.chatId) else {
                    MEGALogError("Can not start meeting, not call found for chat")
                    self.dismiss()
                    return
                }
                
                // Making sure the chatlink is created when meeting is created so that the other participant can share.
                self.meetingUseCase.createChatLink(forChatId: chatRoom.chatId)
                self.dismiss()
                self.router.goToMeetingRoom(chatRoom: chatRoom, call: call, isVideoEnabled: self.isVideoEnabled, isSpeakerEnabled: self.isSpeakerEnabled)
            case .failure(_):
                self.dismiss()
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
            DispatchQueue.main.async {
                if granted {
                    completionBlock()
                } else {
                    router.showAudioPermissionError()
                }
            }
        }
    }
    
    private func checkChatLink(link: String) {
        invokeCommand?(.loadingStartMeeting)
        
        meetingUseCase.checkChatLink(link: link) { [weak self] in
            guard let self = self else { return }
            self.invokeCommand?(.loadingEndMeeting)

            switch $0 {
            case .success(let chatRoom):
                self.invokeCommand?(
                    .configView(
                        title: chatRoom.title ?? "",
                        subtitle: link,
                        type: self.type,
                        isMicrophoneEnabled: self.isMicrophoneEnabled)
                )
                self.chatId = chatRoom.chatId
            case .failure(_):
                self.dismiss()
            }
        }
    }
    
    private func dismiss() {
        disableLocalVideoIfNeeded()
        router.dismiss()
    }
    
    private func selectFrontCameraIfNeeded() {
        if isBackCameraSelected() {
            guard let selectCameraLocalizedString = captureDeviceUseCase.wideAngleCameraLocalizedName(postion: .front) else {
                return
            }
            localVideoUseCase.selectCamera(withLocalizedName: selectCameraLocalizedString)
        }
    }
    
    private func isBackCameraSelected() -> Bool {
        guard let selectCameraLocalizedString = captureDeviceUseCase.wideAngleCameraLocalizedName(postion: .back),
              localVideoUseCase.videoDeviceSelected() == selectCameraLocalizedString else {
            return false
        }
        
        return true
    }
    
    private func switchCamera() {
        guard let selectCameraLocalizedString = captureDeviceUseCase.wideAngleCameraLocalizedName(postion: isBackCameraSelected() ? .front : .back),
              localVideoUseCase.videoDeviceSelected() != selectCameraLocalizedString else {
            return
        }
        localVideoUseCase.selectCamera(withLocalizedName: selectCameraLocalizedString)
    }
    
    private func disableLocalVideoIfNeeded() {
        if isVideoEnabled {
            localVideoUseCase.removeLocalVideo(for: 123, callbacksDelegate: self)
        }
    }
    
    private func updateSpeakerInfo() {
        let currentSelectedPort = audioSessionUseCase.currentSelectedAudioPort
        let isBluetoothAvailable = audioSessionUseCase.isBluetoothAudioRouteAvailable
        MEGALogDebug("Create meeting: updating speaker info with selected port \(currentSelectedPort) bluetooth available \(isBluetoothAvailable)")
        invokeCommand?(
            .updatedAudioPortSelection(audioPort: currentSelectedPort,
                                       bluetoothAudioRouteAvailable: isBluetoothAvailable)
        )
    }
    
    private func sessionRouteChanged(routeChangedReason: AudioSessionRouteChangedReason) {
        MEGALogDebug("Create meeting: session route changed with \(routeChangedReason) , current port \(audioSessionUseCase.currentSelectedAudioPort)")
        isSpeakerEnabled = audioSessionUseCase.isOutputFrom(port: .builtInSpeaker)
        updateSpeakerInfo()
    }
}

extension MeetingCreatingViewModel: CallsLocalVideoCallbacksUseCaseProtocol {
    func localVideoFrameData(width: Int, height: Int, buffer: Data!) {
        invokeCommand?(.localVideoFrame(width: width, height: height, buffer: buffer))
    }
    
    func localVideoChangedCameraPosition() {
        invokeCommand?(.updateCameraPosition(position: isBackCameraSelected() ? .back : .front))
    }
}
