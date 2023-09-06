import Combine
import MEGADomain
import MEGAL10n
import MEGAPermissions
import MEGAPresentation
import MEGASDKRepo

protocol WaitingRoomViewRouting: Routing {
    func dismiss(completion: (() -> Void)?)
    func showLeaveAlert(leaveAction: @escaping () -> Void)
    func showMeetingInfo()
    func showVideoPermissionError()
    func showAudioPermissionError()
    func showHostDenyAlert(leaveAction: @escaping () -> Void)
    func hostAllowToJoin()
}

final class WaitingRoomViewModel: ObservableObject {
    private let scheduledMeeting: ScheduledMeetingEntity
    private let router: any WaitingRoomViewRouting
    private let chatUseCase: any ChatUseCaseProtocol
    private let callUseCase: any CallUseCaseProtocol
    private let callCoordinatorUseCase: any CallCoordinatorUseCaseProtocol
    private let meetingUseCase: any MeetingCreatingUseCaseProtocol
    private let authUseCase: any AuthUseCaseProtocol
    private let waitingRoomUseCase: any WaitingRoomUseCaseProtocol
    private let accountUseCase: any AccountUseCaseProtocol
    private let megaHandleUseCase: any MEGAHandleUseCaseProtocol
    private let userImageUseCase: any UserImageUseCaseProtocol
    private let localVideoUseCase: any CallLocalVideoUseCaseProtocol
    private let captureDeviceUseCase: any CaptureDeviceUseCaseProtocol
    private let audioSessionUseCase: any AudioSessionUseCaseProtocol
    private let permissionHandler: any DevicePermissionsHandling
    private let chatLink: String?
    
    var meetingTitle: String { scheduledMeeting.title }
    
    enum WaitingRoomViewState {
        case guestJoin
        case guestJoining
        case waitForHostToStart
        case waitForHostToLetIn
    }
    @Published private(set) var viewState: WaitingRoomViewState = .waitForHostToLetIn
    
    @Published private(set) var userAvatar: UIImage?
    @Published private(set) var videoImage: UIImage?
    @Published var isVideoEnabled = false
    @Published var isMicrophoneEnabled = false
    @Published var isSpeakerEnabled = true
    @Published var screenSize: CGSize = .zero {
        didSet {
            guard screenSize != .zero else { return }
            isLandscape = screenSize.width > screenSize.height
        }
    }
    
    var showWaitingRoomMessage: Bool {
        viewState == .waitForHostToStart || viewState == .waitForHostToLetIn
    }
    var waitingRoomMessage: String {
        switch viewState {
        case .waitForHostToStart:
            return Strings.Localizable.Meetings.WaitingRoom.Message.waitForHostToStartTheMeeting
        case .waitForHostToLetIn:
            return Strings.Localizable.Meetings.WaitingRoom.Message.waitForHostToLetYouIn
        default:
            return ""
        }
    }
    
    private(set) var isLandscape: Bool = false
    
    private var call: CallEntity? {
        callUseCase.call(for: scheduledMeeting.chatId)
    }
    private var isMeetingStart: Bool {
        call != nil
    }
    private var isCallActive: Bool {
        chatUseCase.isCallActive(for: scheduledMeeting.chatId)
    }
    
    private var appDidBecomeActiveSubscription: AnyCancellable?
    private var appWillResignActiveSubscription: AnyCancellable?
    private var subscriptions = Set<AnyCancellable>()
    
    init(scheduledMeeting: ScheduledMeetingEntity,
         router: some WaitingRoomViewRouting,
         chatUseCase: some ChatUseCaseProtocol,
         callUseCase: some CallUseCaseProtocol,
         callCoordinatorUseCase: some CallCoordinatorUseCaseProtocol,
         meetingUseCase: some MeetingCreatingUseCaseProtocol,
         authUseCase: some AuthUseCaseProtocol,
         waitingRoomUseCase: some WaitingRoomUseCaseProtocol,
         accountUseCase: some AccountUseCaseProtocol,
         megaHandleUseCase: some MEGAHandleUseCaseProtocol,
         userImageUseCase: some UserImageUseCaseProtocol,
         localVideoUseCase: some CallLocalVideoUseCaseProtocol,
         captureDeviceUseCase: some CaptureDeviceUseCaseProtocol,
         audioSessionUseCase: some AudioSessionUseCaseProtocol,
         permissionHandler: some DevicePermissionsHandling,
         chatLink: String? = nil) {
        self.scheduledMeeting = scheduledMeeting
        self.router = router
        self.chatUseCase = chatUseCase
        self.callUseCase = callUseCase
        self.callCoordinatorUseCase = callCoordinatorUseCase
        self.meetingUseCase = meetingUseCase
        self.authUseCase = authUseCase
        self.waitingRoomUseCase = waitingRoomUseCase
        self.accountUseCase = accountUseCase
        self.megaHandleUseCase = megaHandleUseCase
        self.userImageUseCase = userImageUseCase
        self.localVideoUseCase = localVideoUseCase
        self.captureDeviceUseCase = captureDeviceUseCase
        self.audioSessionUseCase = audioSessionUseCase
        self.permissionHandler = permissionHandler
        self.chatLink = chatLink
        initializeState()
        initSubscriptions()
        fetchInitialValues()
    }
    
    deinit {
        callUseCase.stopListeningForCall()
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
            dismiss()
        }
    }
    
    func infoButtonTapped() {
        router.showMeetingInfo()
    }
    
    func tapJoinAction(firstName: String, lastName: String) {
        guard viewState == .guestJoin else { return }
        viewState = .guestJoining
        createEphemeralAccountAndJoinChat(firstName: firstName, lastName: lastName)
    }
    
    func calculateVideoSize() -> CGSize {
        let videoAspectRatio = isLandscape ? 424.0 / 236.0 : 236.0 / 424.0
        let videoHeight = screenSize.height - (isLandscape ? 66.0 : 332.0)
        let videoWidth = videoHeight * videoAspectRatio
        return CGSize(width: videoWidth, height: videoHeight)
    }
    
    func calculateBottomPanelHeight() -> CGFloat {
        switch viewState {
        case .guestJoin:
            return 142.0
        case .guestJoining:
            return isLandscape ? 38.0 : 100.0
        case .waitForHostToStart, .waitForHostToLetIn:
            return isLandscape ? 8.0 : 100.0
        }
    }
    
    // MARK: - Private
    
    private func initializeState() {
        if accountUseCase.isGuest {
            viewState = .guestJoin
        } else if isMeetingStart {
            viewState = .waitForHostToLetIn
            answerCall()
        } else {
            viewState = .waitForHostToStart
        }
    }
    
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
        
        chatUseCase
            .monitorChatCallStatusUpdate()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] call in
                guard let self,
                      viewState != .guestJoin && viewState != .guestJoining,
                      call.chatId == scheduledMeeting.chatId else { return }
                if isMeetingStart {
                    if !isCallActive {
                        answerCall()
                    }
                } else {
                    if isCallActive {
                        dismissCall()
                    }
                    viewState = .waitForHostToStart
                }
            }
            .store(in: &subscriptions)
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
        userImageUseCase.fetchUserAvatar(
            withUserHandle: myHandle,
            base64Handle: base64Handle,
            avatarBackgroundHexColor: avatarBackgroundHexColor,
            name: waitingRoomUseCase.userName()
        ) { [weak self] result in
            guard let self else { return }
            if case let .success(image) = result {
                userAvatar = image
            }
        }
    }
    
    private func disableLocalVideo() {
        if isVideoEnabled {
            localVideoUseCase.removeLocalVideo(for: MEGAInvalidHandle, callbacksDelegate: self)
        }
    }
    
    private func dismiss() {
        router.dismiss { [weak self] in
            guard let self else { return }
            if accountUseCase.isGuest {
                authUseCase.logout()
            }
            disableLocalVideo()
            callUseCase.stopListeningForCall()
            dismissCall()
        }
    }
    
    // MARK: - Chat and call related methods
    
    private func answerCall() {
        callUseCase.answerCall(for: scheduledMeeting.chatId) { [weak self] result in
            guard let self else { return }
            switch result {
            case .success:
                viewState = .waitForHostToLetIn
            case .failure:
                MEGALogDebug("Cannot answer call")
            }
        }
    }
    
    private func dismissCall() {
        guard let call else { return }
        callCoordinatorUseCase.removeCallRemovedHandler()
        callUseCase.hangCall(for: call.callId)
        callCoordinatorUseCase.endCall(call)
    }
    
    private func createEphemeralAccountAndJoinChat(firstName: String, lastName: String) {
        guard let chatLink else { return }
        meetingUseCase.createEphemeralAccountAndJoinChat(firstName: firstName, lastName: lastName, link: chatLink) { [weak self] result in
            guard let self else { return }
            if case .success = result {
                joinChatCall()
            }
        } karereInitCompletion: { [weak self] in
            guard let self else { return }
            if isVideoEnabled {
                enableLocalVideo(enabled: true)
            }
        }
    }
    
    private func joinChatCall() {
        meetingUseCase.joinChat(forChatId: scheduledMeeting.chatId,
                                userHandle: chatUseCase.myUserHandle()
        ) { [weak self] result in
            guard let self else { return }
            switch result {
            case .success:
                if isMeetingStart {
                    answerCall()
                } else {
                    viewState = .waitForHostToStart
                }
            case .failure:
                dismiss()
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
