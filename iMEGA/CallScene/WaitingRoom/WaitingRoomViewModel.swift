import Combine
import MEGADomain
import MEGAPermissions
import MEGAPresentation
import MEGASDKRepo

protocol WaitingRoomViewRouting: Routing {
    func dismiss()
    func showLeaveAlert(leaveAction: @escaping () -> Void)
    func showMeetingInfo()
    func showVideoPermissionError()
    func showAudioPermissionError()
}

final class WaitingRoomViewModel: ObservableObject {
    private let scheduledMeeting: ScheduledMeetingEntity
    private let router: any WaitingRoomViewRouting
    private let waitingRoomUseCase: any WaitingRoomUseCaseProtocol
    private let accountUseCase: any AccountUseCaseProtocol
    private let megaHandleUseCase: any MEGAHandleUseCaseProtocol
    private let userImageUseCase: any UserImageUseCaseProtocol
    private let localVideoUseCase: any CallLocalVideoUseCaseProtocol
    private let captureDeviceUseCase: any CaptureDeviceUseCaseProtocol
    private let audioSessionUseCase: any AudioSessionUseCaseProtocol
    private let permissionHandler: any DevicePermissionsHandling
    
    var meetingTitle: String { scheduledMeeting.title }
    
    enum WaitingRoomViewState {
        case guestJoin
        case guestJoining
        case waitForHostToLetIn
    }
    @Published var viewState: WaitingRoomViewState
    
    @Published private(set) var userAvatar: UIImage?
    @Published private(set) var videoImage: UIImage?
    @Published var orientation = UIDeviceOrientation.unknown
    @Published var isVideoEnabled = false
    @Published var isMicrophoneEnabled = false
    @Published var isSpeakerEnabled = true
    @Published var showAVRoutePickerView = false
    
    var isLandscape: Bool {
        orientation == .landscapeLeft || orientation == .landscapeRight || orientation == .portraitUpsideDown
    }
    
    private var subscriptions = Set<AnyCancellable>()
    
    private var appDidBecomeActiveSubscription: AnyCancellable?
    private var appWillResignActiveSubscription: AnyCancellable?
    
    init(scheduledMeeting: ScheduledMeetingEntity,
         router: some WaitingRoomViewRouting,
         waitingRoomUseCase: some WaitingRoomUseCaseProtocol,
         accountUseCase: some AccountUseCaseProtocol,
         megaHandleUseCase: some MEGAHandleUseCaseProtocol,
         userImageUseCase: some UserImageUseCaseProtocol,
         localVideoUseCase: some CallLocalVideoUseCaseProtocol,
         captureDeviceUseCase: some CaptureDeviceUseCaseProtocol,
         audioSessionUseCase: some AudioSessionUseCaseProtocol,
         permissionHandler: some DevicePermissionsHandling) {
        self.scheduledMeeting = scheduledMeeting
        self.router = router
        self.waitingRoomUseCase = waitingRoomUseCase
        self.accountUseCase = accountUseCase
        self.megaHandleUseCase = megaHandleUseCase
        self.userImageUseCase = userImageUseCase
        self.localVideoUseCase = localVideoUseCase
        self.captureDeviceUseCase = captureDeviceUseCase
        self.audioSessionUseCase = audioSessionUseCase
        self.permissionHandler = permissionHandler
        viewState = accountUseCase.isGuest ? .guestJoin : .waitForHostToLetIn
        initSubscriptions()
        fetchInitialValues()
    }
    
    // MARK: - Public
    
    func createMeetingDate() -> String {
        let startDate = scheduledMeeting.startDate
        let endDate = scheduledMeeting.endDate
        
        let timeFormatter = DateFormatter.fromTemplate("HH:mm")

        let weekDayString = DateFormatter.fromTemplate("E").localisedString(from: startDate)
        let startDateString = DateFormatter.fromTemplate("ddMMM").localisedString(from: startDate)
        let startTimeString = timeFormatter.localisedString(from: startDate)
        let endTimeString = timeFormatter.localisedString(from: endDate)
        
        return "\(weekDayString), \(startDateString) ·\(startTimeString)-\(endTimeString)"
    }
    
    func enableLocalVideo(enabled: Bool) {
        checkForVideoPermission {
            if enabled {
                self.localVideoUseCase.openVideoDevice { [weak self] _ in
                    guard let self else { return }
                    localVideoUseCase.addLocalVideo(for: MEGAInvalidHandle, callbacksDelegate: self)
                }
            } else {
                self.localVideoUseCase.releaseVideoDevice { [weak self]  _ in
                    guard let self else { return }
                    localVideoUseCase.removeLocalVideo(for: MEGAInvalidHandle, callbacksDelegate: self)
                }
            }
        }
    }
    
    func enableLocalMicrophone(enabled: Bool) {
        checkForAudioPermission {}
    }
    
    func enableLoudSpeaker(enabled: Bool) {
        if enabled {
            audioSessionUseCase.enableLoudSpeaker { [weak self] _ in
                self?.updateSpeakerInfo()
            }
        } else {
            audioSessionUseCase.disableLoudSpeaker { [weak self] _ in
                self?.updateSpeakerInfo()
            }
        }
    }
    
    func leaveButtonTapped() {
        router.showLeaveAlert { [weak self] in
            guard let self else { return }
            router.dismiss()
        }
    }
    
    func infoButtonTapped() {
        router.showMeetingInfo()
    }
    
    func tapJoinAction() {
        guard viewState == .guestJoin else { return }
        viewState = .guestJoining
        Task { @MainActor in
            // This wait is a temporal workaround for demo propose
            // It will be replace in the next ticket when the API is ready
            try await Task.sleep(nanoseconds: 2_000_000_000)
            viewState = .waitForHostToLetIn
        }
    }
    
    func calculateVideoSize(by screenHeight: CGFloat) -> CGSize {
        let videoAspectRatio = isLandscape ? 424.0 / 236.0 : 236.0 / 424.0
        let videoHeight = screenHeight - (isLandscape ? 66.0 : 332.0)
        let videoWidth = videoHeight * videoAspectRatio
        return CGSize(width: videoWidth, height: videoHeight)
    }
    
    func calculateBottomPanelHeight() -> CGFloat {
        switch viewState {
        case .guestJoin:
            return 142.0
        case .guestJoining:
            return isLandscape ? 38.0 : 100.0
        case .waitForHostToLetIn:
            return isLandscape ? 8.0 : 100.0
        }
    }
    
    // MARK: - Private
    
    private func initSubscriptions() {
        appDidBecomeActiveSubscription = NotificationCenter.default
            .publisher(for: UIApplication.didBecomeActiveNotification)
            .sink { [weak self] _ in
                guard let self else { return }
                audioSessionUseCase.configureCallAudioSession()
                addRouteChangedListener()
                enableLoudSpeaker(enabled: isSpeakerEnabled)
            }
        
        appWillResignActiveSubscription = NotificationCenter.default
            .publisher(for: UIApplication.willResignActiveNotification)
            .sink { [weak self] _ in
                self?.removeRouteChangedListener()
            }
    }
    
    private func fetchInitialValues() {
        audioSessionUseCase.configureCallAudioSession()
        if audioSessionUseCase.isBluetoothAudioRouteAvailable {
            isSpeakerEnabled = audioSessionUseCase.isOutputFrom(port: .builtInSpeaker)
            updateSpeakerInfo()
        } else {
            enableLoudSpeaker(enabled: isSpeakerEnabled)
        }
        permissionHandler.requestAudioPermission()
        selectFrontCameraIfNeeded()
        fetchUserAvatar()
    }
    
    private func updateSpeakerInfo() {
        let currentSelectedPort = audioSessionUseCase.currentSelectedAudioPort
        let isBluetoothAvailable = audioSessionUseCase.isBluetoothAudioRouteAvailable
        isSpeakerEnabled = audioSessionUseCase.isOutputFrom(port: .builtInSpeaker)
        // Need this debug for the next ticket
        MEGALogDebug("Waiting room: updating speaker info with selected port \(currentSelectedPort), bluetooth available \(isBluetoothAvailable), isSpeakerEnabled: \(isSpeakerEnabled)")
    }
    
    private func selectFrontCameraIfNeeded() {
        if isBackCameraSelected() {
            guard let selectCameraLocalizedString = captureDeviceUseCase.wideAngleCameraLocalizedName(position: .front) else {
                return
            }
            localVideoUseCase.selectCamera(withLocalizedName: selectCameraLocalizedString) { _ in }
        }
    }
    
    private func isBackCameraSelected() -> Bool {
        guard let selectCameraLocalizedString = captureDeviceUseCase.wideAngleCameraLocalizedName(position: .back),
              localVideoUseCase.videoDeviceSelected() == selectCameraLocalizedString else {
            return false
        }
        return true
    }
    
    private func addRouteChangedListener() {
        audioSessionUseCase.routeChanged { [weak self] routeChangedReason, _ in
            guard let self = self else { return }
            self.sessionRouteChanged(routeChangedReason: routeChangedReason)
        }
    }
    
    private func removeRouteChangedListener() {
        audioSessionUseCase.routeChanged()
    }
    
    private func sessionRouteChanged(routeChangedReason: AudioSessionRouteChangedReason) {
        updateSpeakerInfo()
    }
    
    private func checkForVideoPermission(onSuccess completionBlock: @escaping () -> Void) {
        permissionHandler.requestVideoPermission { [weak self] granted in
            if granted {
                completionBlock()
            } else {
                self?.router.showVideoPermissionError()
            }
        }
    }
    
    private func checkForAudioPermission(onSuccess completionBlock: @escaping () -> Void) {
        permissionHandler.requestAudioPermission { [weak self] granted in
            if granted {
                completionBlock()
            } else {
                self?.router.showAudioPermissionError()
            }
        }
    }
    
    private func fetchUserAvatar() {
        guard let myHandle = accountUseCase.currentUserHandle,
              let base64Handle = megaHandleUseCase.base64Handle(forUserHandle: myHandle),
              let avatarBackgroundHexColor = userImageUseCase.avatarColorHex(forBase64UserHandle: base64Handle) else {
            return
        }
        userImageUseCase.fetchUserAvatar(withUserHandle: myHandle,
                                         base64Handle: base64Handle,
                                         avatarBackgroundHexColor: avatarBackgroundHexColor,
                                         name: waitingRoomUseCase.userName()) { [weak self] result in
            guard let self else { return }
            switch result {
            case .success(let image):
                userAvatar = image
            default:
                break
            }
        }
    }
}

// MARK: - CallLocalVideoCallbacksUseCaseProtocol

extension WaitingRoomViewModel: CallLocalVideoCallbacksUseCaseProtocol {
    func localVideoFrameData(width: Int, height: Int, buffer: Data) {
        videoImage = UIImage.mnz_convert(toUIImage: buffer, withWidth: width, withHeight: height)
    }
    
    func localVideoChangedCameraPosition() {
    }
}
