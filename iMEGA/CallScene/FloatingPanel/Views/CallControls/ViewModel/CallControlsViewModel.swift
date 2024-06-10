import MEGADomain
import MEGAPermissions
import MEGAPresentation

final class CallControlsViewModel: CallControlsViewModelProtocol {
    private let router: any MeetingFloatingPanelRouting

    private var chatRoom: ChatRoomEntity

    private let callUseCase: any CallUseCaseProtocol
    private let captureDeviceUseCase: any CaptureDeviceUseCaseProtocol
    private let localVideoUseCase: any CallLocalVideoUseCaseProtocol
    private let audioSessionUseCase: any AudioSessionUseCaseProtocol
    private weak var containerViewModel: MeetingContainerViewModel?

    private let permissionHandler: any DevicePermissionsHandling
    private let callManager: any CallManagerProtocol
    private let callKitManager: any CallKitManagerProtocol
    private let featureFlagProvider: any FeatureFlagProviderProtocol

    private let notificationCenter: NotificationCenter
    private let audioRouteChangeNotificationName: Notification.Name

    @Published var micEnabled: Bool = false
    @Published var cameraEnabled: Bool = false
    @Published var speakerEnabled: Bool = false
    @Published var routeViewVisible: Bool = false
    
    init(router: any MeetingFloatingPanelRouting,
         chatRoom: ChatRoomEntity,
         callUseCase: any CallUseCaseProtocol,
         captureDeviceUseCase: any CaptureDeviceUseCaseProtocol,
         localVideoUseCase: any CallLocalVideoUseCaseProtocol,
         containerViewModel: MeetingContainerViewModel? = nil,
         audioSessionUseCase: any AudioSessionUseCaseProtocol,
         permissionHandler: any DevicePermissionsHandling,
         callManager: any CallManagerProtocol,
         callKitManager: some CallKitManagerProtocol,
         notificationCenter: NotificationCenter,
         audioRouteChangeNotificationName: Notification.Name,
         featureFlagProvider: any FeatureFlagProviderProtocol
    ) {
        self.router = router
        self.chatRoom = chatRoom
        self.callUseCase = callUseCase
        self.captureDeviceUseCase = captureDeviceUseCase
        self.localVideoUseCase = localVideoUseCase
        self.containerViewModel = containerViewModel
        self.permissionHandler = permissionHandler
        self.audioSessionUseCase = audioSessionUseCase
        self.callManager = callManager
        self.callKitManager = callKitManager
        self.notificationCenter = notificationCenter
        self.audioRouteChangeNotificationName = audioRouteChangeNotificationName
        self.featureFlagProvider = featureFlagProvider
        
        guard let call = callUseCase.call(for: chatRoom.chatId) else {
            MEGALogError("Error initialising call actions, call does not exists")
            return
        }
        
        micEnabled = call.hasLocalAudio
        cameraEnabled = call.hasLocalVideo
        
        registerForAudioRouteChanges()
        checkRouteViewAvailability()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Public
    
    @MainActor func endCallTapped() {
        manageEndCall()
    }
    
    func toggleCameraTapped() async {
        await toggleCamera()
    }
    
    func toggleMicTapped() async {
        await toggleMic()
    }
    
    func toggleSpeakerTapped() {
        toggleSpeaker()
    }
    
    func switchCameraTapped() async {
        await switchCamera()
    }
    
    // MARK: - Private
    private func toggleSpeaker() {
        if speakerEnabled {
            audioSessionUseCase.disableLoudSpeaker()
        } else {
            audioSessionUseCase.enableLoudSpeaker()
        }
    }
    
    private func updateSpeakerIcon() {
        let currentSelectedPort = audioSessionUseCase.currentSelectedAudioPort
        let isBluetoothAvailable = audioSessionUseCase.isBluetoothAudioRouteAvailable
        MEGALogDebug("[Calls Controls] updating speaker info with selected port \(currentSelectedPort) bluetooth available \(isBluetoothAvailable)")
        speakerEnabled = switch currentSelectedPort {
        case .unknown, .builtInReceiver, .other:
            false
        case .builtInSpeaker, .headphones:
            true
        }
    }
    
    private func manageEndCall() {
        guard let call = callUseCase.call(for: chatRoom.chatId) else {
            MEGALogError("Error hanging call, call does not exists")
            return
        }
        if (chatRoom.chatType == .group || chatRoom.chatType == .meeting) && chatRoom.ownPrivilege == .moderator && call.numberOfParticipants > 1, let containerViewModel {
            router.showHangOrEndCallDialog(containerViewModel: containerViewModel)
        } else {
            if featureFlagProvider.isFeatureFlagEnabled(for: .callKitRefactor) {
                callManager.endCall(in: chatRoom, endForAll: false)
            } else {
                containerViewModel?.dispatch(.hangCall(presenter: nil, sender: nil))
            }
        }
    }
    
    @MainActor private func toggleMic() async {
        guard let call = callUseCase.call(for: chatRoom.chatId) else {
            MEGALogError("Error muting or unmuting call, call does not exists")
            return
        }
        if await permissionHandler.requestPermission(for: .audio) {
            if featureFlagProvider.isFeatureFlagEnabled(for: .callKitRefactor) {
                callManager.muteCall(in: chatRoom, muted: micEnabled)
            } else {
                callKitManager.muteUnmuteCall(call, muted: micEnabled)
            }
            micEnabled.toggle()
        } else {
            router.showAudioPermissionError()
        }
    }
    
    @MainActor private func toggleCamera() async {
        if await permissionHandler.requestPermission(for: .video) {
            do {
                if cameraEnabled {
                    try await localVideoUseCase.disableLocalVideo(for: chatRoom.chatId)
                } else {
                    try await localVideoUseCase.enableLocalVideo(for: chatRoom.chatId)
                }
                cameraEnabled.toggle()
            } catch {
                MEGALogDebug("Error enabling or disabling local video")
            }
        } else {
            router.showVideoPermissionError()
        }
    }
    
    @MainActor private func switchCamera() async {
        guard cameraEnabled else { return }
        guard let selectCameraLocalizedString = captureDeviceUseCase.wideAngleCameraLocalizedName(position: isBackCameraSelected() ? .front : .back) else {
            MEGALogError("[cma] Error getting camera localised name")
            return
        }
        do {
            try await localVideoUseCase.selectCamera(withLocalizedName: selectCameraLocalizedString)
        } catch {
            MEGALogError("Error selecting camera: \(error.localizedDescription)")
        }
    }
    
    private func isBackCameraSelected() -> Bool {
        guard let selectCameraLocalizedString = captureDeviceUseCase.wideAngleCameraLocalizedName(position: .back),
              localVideoUseCase.videoDeviceSelected() == selectCameraLocalizedString else {
            return false
        }
        
        return true
    }
    
    private func registerForAudioRouteChanges() {
        notificationCenter.addObserver(
            self,
            selector: #selector(audioRouteChanged(_:)),
            name: audioRouteChangeNotificationName,
            object: nil
        )
    }
    
    @objc private func audioRouteChanged(_ notification: Notification) {
        checkRouteViewAvailability()
        updateSpeakerIcon()
    }
    
    private func checkRouteViewAvailability() {
        routeViewVisible = audioSessionUseCase.isBluetoothAudioRouteAvailable
    }
}
