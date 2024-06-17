import Combine
import CombineSchedulers
import MEGADomain
import MEGAL10n
import MEGAPermissions
import MEGAPresentation

final class CallControlsViewModel: CallControlsViewModelProtocol {
    
    private let router: any MeetingFloatingPanelRouting
    private let scheduler: AnySchedulerOf<DispatchQueue>
    private let menuPresenter: ([ActionSheetAction]) -> Void
    private var chatRoom: ChatRoomEntity
    
    private let callUseCase: any CallUseCaseProtocol
    private let captureDeviceUseCase: any CaptureDeviceUseCaseProtocol
    private let localVideoUseCase: any CallLocalVideoUseCaseProtocol
    private let audioSessionUseCase: any AudioSessionUseCaseProtocol
    private weak var containerViewModel: MeetingContainerViewModel?
    
    private let permissionHandler: any DevicePermissionsHandling
    private let callManager: any CallManagerProtocol
    private let featureFlagProvider: any FeatureFlagProviderProtocol
    private let accountUseCase: any AccountUseCaseProtocol
    private let notificationCenter: NotificationCenter
    private let audioRouteChangeNotificationName: Notification.Name
    private let layoutUpdateChannel: ParticipantLayoutUpdateChannel
    
    private var subscriptions = Set<AnyCancellable>()

    @Published var micEnabled: Bool = false
    @Published var cameraEnabled: Bool = false
    @Published var speakerEnabled: Bool = false
    @Published var routeViewVisible: Bool = false
    
    init(
        router: some MeetingFloatingPanelRouting,
        scheduler: AnySchedulerOf<DispatchQueue>,
        menuPresenter: @escaping ([ActionSheetAction]) -> Void,
        chatRoom: ChatRoomEntity,
        callUseCase: some CallUseCaseProtocol,
        captureDeviceUseCase: some CaptureDeviceUseCaseProtocol,
        localVideoUseCase: some CallLocalVideoUseCaseProtocol,
        containerViewModel: MeetingContainerViewModel? = nil,
        audioSessionUseCase: some AudioSessionUseCaseProtocol,
        permissionHandler: some DevicePermissionsHandling,
        callManager: some CallManagerProtocol,
        notificationCenter: NotificationCenter,
        audioRouteChangeNotificationName: Notification.Name,
        featureFlagProvider: some FeatureFlagProviderProtocol,
        accountUseCase: some AccountUseCaseProtocol,
        layoutUpdateChannel: ParticipantLayoutUpdateChannel
    ) {
        self.router = router
        self.scheduler = scheduler
        self.menuPresenter = menuPresenter
        self.chatRoom = chatRoom
        self.callUseCase = callUseCase
        self.captureDeviceUseCase = captureDeviceUseCase
        self.localVideoUseCase = localVideoUseCase
        self.containerViewModel = containerViewModel
        self.permissionHandler = permissionHandler
        self.audioSessionUseCase = audioSessionUseCase
        self.callManager = callManager
        self.notificationCenter = notificationCenter
        self.audioRouteChangeNotificationName = audioRouteChangeNotificationName
        self.featureFlagProvider = featureFlagProvider
        self.accountUseCase = accountUseCase
        self.layoutUpdateChannel = layoutUpdateChannel
        
        guard let call = callUseCase.call(for: chatRoom.chatId) else {
            MEGALogError("Error initialising call actions, call does not exists")
            return
        }
        
        micEnabled = call.hasLocalAudio
        cameraEnabled = call.hasLocalVideo
        
        registerForAudioRouteChanges()
        checkRouteViewAvailability()
        listenToCallUpdates()
    }
    
    // MARK: - Public
    
    @MainActor func endCallTapped() async {
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
    
    private var isNotOneToOneCall: Bool {
        chatRoom.chatType != .oneToOne
    }
    
    // we do not show raise hand functionality in one-to-one calls
    var showMoreButton: Bool {
        featureFlagProvider.isFeatureFlagEnabled(for: .raiseToSpeak) && isNotOneToOneCall
    }
    
    private func switchLayout(
        gallery: Bool,
        enabled: Bool
    ) -> ActionSheetAction {
        .init(
            title: gallery ? Strings.Localizable.Chat.Call.ContextMenu.switchToMainView : Strings.Localizable.Chat.Call.ContextMenu.switchToGrid,
            detail: nil,
            image: gallery ? UIImage(resource: .speakerView) : UIImage(resource: .galleryView),
            enabled: layoutSwitchingEnabled,
            syncIconAndTextColor: true,
            style: .default,
            actionHandler: toggleLayoutAction
        )
    }
    
    private var layoutSwitchingEnabled: Bool {
        layoutUpdateChannel.layoutSwitchingEnabled?() ?? false
    }
    
    private var currentLayout: ParticipantsLayoutMode {
        layoutUpdateChannel.getCurrentLayout?() ?? .grid
    }
    
    private func toggleLayoutAction() {
        var layout = currentLayout
        layout.toggle()
        layoutUpdateChannel.updateLayout?(layout)
    }
    
    private func raiseOrLowerHand(raised: Bool) -> ActionSheetAction {
        .init(
            title: raised ? Strings.Localizable.Chat.Call.ContextMenu.lowerHand : Strings.Localizable.Chat.Call.ContextMenu.raiseHand,
            detail: nil,
            image: UIImage(resource: .callRaiseHand),
            syncIconAndTextColor: true,
            style: .default,
            actionHandler: { [weak self] in
                self?.signalHandAction(!raised)
            }
        )
    }
    
    private func signalHandAction(_ raise: Bool) {
        guard
            let call = callUseCase.call(for: chatRoom.chatId)
        else { return }
        
        Task {
            MEGALogDebug("[CallControls] \(raise ? "raising" : "lowering") hand begin")
            do {
                if raise {
                    try await self.callUseCase.raiseHand(forCall: call)
                } else {
                    try await self.callUseCase.lowerHand(forCall: call)
                }
                MEGALogDebug("[CallControls] \(raise ? "raised" : "lowered") hand successfully")
            } catch {
                MEGALogDebug("[CallControls] \(raise ? "raising" : "lowering") hand failed \(error)")
            }
        }
    }
    
    private var localUserHandIsRaiseCurrently: Bool {
        guard
            let call = callUseCase.call(for: chatRoom.chatId),
            let userId = accountUseCase.currentUserHandle
        else { return false }
        let raised = Set(call.raiseHandsList).contains(userId)
        MEGALogDebug("[CallControls] local user has raised hand: \(raised)")
        return raised
    }
    
    private var moreMenuActions: [ActionSheetAction] {
        [
            switchLayout(gallery: currentLayout == .grid, enabled: layoutSwitchingEnabled),
            raiseOrLowerHand(raised: localUserHandIsRaiseCurrently)
        ]
    }
    
    @MainActor
    func moreButtonTapped() async {
        menuPresenter(moreMenuActions)
    }
    
    private func manageEndCall() {
        guard let call = callUseCase.call(for: chatRoom.chatId) else {
            MEGALogError("Error hanging call, call does not exists")
            return
        }
        if (chatRoom.chatType == .group || chatRoom.chatType == .meeting) && chatRoom.ownPrivilege == .moderator && call.numberOfParticipants > 1, let containerViewModel {
            router.showHangOrEndCallDialog(containerViewModel: containerViewModel)
        } else {
            callManager.endCall(in: chatRoom, endForAll: false)
        }
    }
    
    @MainActor private func toggleMic() async {
        if await permissionHandler.requestPermission(for: .audio) {
            callManager.muteCall(in: chatRoom, muted: micEnabled)
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
    
    private func listenToCallUpdates() {
        callUseCase.onCallUpdate()
            .receive(on: scheduler)
            .sink { [weak self] call in
                self?.onCallUpdate(call)
            }
            .store(in: &subscriptions)
    }
    
    private func onCallUpdate(_ call: CallEntity) {
        switch call.changeType {
        case .localAVFlags:
            micEnabled = call.hasLocalAudio
        default:
            break
        }
    }
}
