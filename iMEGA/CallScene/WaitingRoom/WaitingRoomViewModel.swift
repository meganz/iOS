import Combine
import MEGAAnalyticsiOS
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
    func showHostDidNotRespondAlert(leaveAction: @escaping () -> Void)
    func openCallUI(for call: CallEntity, in chatRoom: ChatRoomEntity, isSpeakerEnabled: Bool)
}

final class WaitingRoomViewModel: ObservableObject {
    private let scheduledMeeting: ScheduledMeetingEntity
    private let router: any WaitingRoomViewRouting
    private let chatUseCase: any ChatUseCaseProtocol
    private let chatRoomUseCase: any ChatRoomUseCaseProtocol
    private let callUseCase: any CallUseCaseProtocol
    private let callManager: any CallManagerProtocol
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
    private let tracker: any AnalyticsTracking
    private let featureFlagProvider: any FeatureFlagProviderProtocol
    private let chatLink: String?
    private let requestUserHandle: HandleEntity
    
    var meetingTitle: String { scheduledMeeting.title }
    
    enum WaitingRoomViewState {
        case guestUserSetup
        case guestUserJoining
        case loggedInUserJoining
        case waitForHostToStart
        case waitForHostToLetIn
    }
    @Published private(set) var viewState: WaitingRoomViewState = .waitForHostToLetIn
    @Published private(set) var userAvatar: UIImage?
    @Published private(set) var videoImage: UIImage?
    @Published var isVideoEnabled = false
    @Published var isMicrophoneMuted = true
    @Published var isSpeakerEnabled = true
    @Published var speakerOnIcon: ImageResource = .callControlSpeakerEnabled
    @Published var isBluetoothAudioRouteAvailable = false
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
    var isJoining: Bool {
        viewState == .guestUserJoining || viewState == .loggedInUserJoining
    }
    
    private(set) var isLandscape: Bool = false
    
    private var call: CallEntity? { callUseCase.call(for: scheduledMeeting.chatId) }
    private var isMeetingStart: Bool { call != nil }
    private var isActiveWaitingRoom: Bool { chatUseCase.isActiveWaitingRoom(for: scheduledMeeting.chatId) }
    private var chatId: HandleEntity { scheduledMeeting.chatId }
    
    private var onCallUpdateSubscription: AnyCancellable?
    private var subscriptions = Set<AnyCancellable>()
    
    init(scheduledMeeting: ScheduledMeetingEntity,
         router: some WaitingRoomViewRouting,
         chatUseCase: some ChatUseCaseProtocol,
         chatRoomUseCase: some ChatRoomUseCaseProtocol,
         callUseCase: some CallUseCaseProtocol,
         callManager: some CallManagerProtocol,
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
         tracker: some AnalyticsTracking = DIContainer.tracker,
         featureFlagProvider: some FeatureFlagProviderProtocol,
         chatLink: String? = nil,
         requestUserHandle: HandleEntity = 0) {
        self.scheduledMeeting = scheduledMeeting
        self.router = router
        self.chatUseCase = chatUseCase
        self.chatRoomUseCase = chatRoomUseCase
        self.callUseCase = callUseCase
        self.callManager = callManager
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
        self.tracker = tracker
        self.featureFlagProvider = featureFlagProvider
        self.chatLink = chatLink
        self.requestUserHandle = requestUserHandle
        initializeState()
        initSubscriptions()
        fetchInitialValues()
    }
    
    deinit {
        callUseCase.stopListeningForCall()
    }
    
    // MARK: - Public
    
    func createMeetingDate(locale: Locale = .autoupdatingCurrent) -> String {
        let startDate = scheduledMeeting.startDate
        let endDate = scheduledMeeting.endDate
        
        let timeFormatter = DateFormatter.timeShort(locale: locale)
        
        let weekDayString = DateFormatter.fromTemplate("E", locale: locale).localisedString(from: startDate)
        let startDateString = DateFormatter.fromTemplate("ddMMM", locale: locale).localisedString(from: startDate)
        let startTimeString = timeFormatter.localisedString(from: startDate)
        let endTimeString = timeFormatter.localisedString(from: endDate)
        
        return "\(weekDayString), \(startDateString) ·\(startTimeString)-\(endTimeString)"
    }
    
    func enableLocalVideo(enabled: Bool) {
        checkForVideoPermission { [weak self] in
            guard let self else { return }
            if enabled {
                localVideoUseCase.openVideoDevice { [weak self] _ in
                    guard let self else { return }
                    localVideoUseCase.addLocalVideo(for: MEGAInvalidHandle, callbacksDelegate: self)
                }
                if isActiveWaitingRoom {
                    localVideoUseCase.enableLocalVideo(for: self.chatId) { [weak self] result in
                        guard let self else { return }
                        switch result {
                        case .success:
                            isVideoEnabled = true
                        case .failure:
                            MEGALogDebug("Error enabling local video")
                        }
                    }
                }
            } else {
                localVideoUseCase.releaseVideoDevice { [weak self]  _ in
                    guard let self else { return }
                    localVideoUseCase.removeLocalVideo(for: MEGAInvalidHandle, callbacksDelegate: self)
                }
                if isActiveWaitingRoom {
                    localVideoUseCase.disableLocalVideo(for: self.chatId) { [weak self] result in
                        guard let self else { return }
                        switch result {
                        case .success:
                            isVideoEnabled = false
                        case .failure:
                            MEGALogDebug("Error disabling local video")
                        }
                    }
                }
            }
        }
    }
    
    func muteLocalMicrophone(mute: Bool) {
        checkForAudioPermission { [weak self] in
            guard let self, let call else { return }
            guard let chatRoom = chatRoomUseCase.chatRoom(forChatId: call.chatId) else { return }
            callManager.muteCall(in: chatRoom, muted: mute)
        }
    }
    
    func enableLoudSpeaker(enabled: Bool) {
        if enabled {
            audioSessionUseCase.enableLoudSpeaker()
        } else {
            audioSessionUseCase.disableLoudSpeaker()
        }
    }
    
    func leaveButtonTapped() {
        router.showLeaveAlert { [weak self] in
            guard let self else { return }
            tracker.trackAnalyticsEvent(with: WaitingRoomLeaveButtonEvent())
            dismiss()
        }
    }
    
    func infoButtonTapped() {
        router.showMeetingInfo()
    }
    
    func tapJoinAction(firstName: String, lastName: String) {
        guard viewState == .guestUserSetup else { return }
        tracker.trackAnalyticsEvent(with: ScheduledMeetingJoinGuestButtonEvent())
        viewState = .guestUserJoining
        createEphemeralAccountAndJoinChat(firstName: firstName, lastName: lastName)
    }
    
    func calculateVideoSize() -> CGSize {
        let videoAspectRatio = isLandscape ? 424.0 / 236.0 : 236.0 / 424.0
        let verticalPadding = isLandscape ? 66.0 : 332.0
        let tmpHeight = screenSize.height - verticalPadding
        let videoHeight = tmpHeight > 0 ? tmpHeight : min(screenSize.height, screenSize.width)
        let videoWidth = videoHeight * videoAspectRatio
        return CGSize(width: videoWidth, height: videoHeight)
    }
    
    func calculateBottomPanelHeight() -> CGFloat {
        switch viewState {
        case .guestUserSetup:
            return 142.0
        case .guestUserJoining, .loggedInUserJoining:
            return isLandscape ? 38.0 : 100.0
        case .waitForHostToStart, .waitForHostToLetIn:
            return isLandscape ? 8.0 : 100.0
        }
    }
    
    // MARK: - Private
    
    private func initializeState() {
        if accountUseCase.isGuest {
            viewState = .guestUserSetup
        } else if isMeetingStart {
            viewState = .waitForHostToLetIn
            answerCall()
        } else {
            if let chatLink {
                viewState = .loggedInUserJoining
                checkChatLink(chatLink)
            } else {
                viewState = .waitForHostToStart
            }
        }
    }
    
    private func initSubscriptions() {
        onCallUpdateSubscription = callUseCase
            .onCallUpdate()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] call in
                guard let self,
                      call.chatId == chatId,
                      viewState != .guestUserSetup && !isJoining else { return }
                if call.changeType == .waitingRoomAllow || (call.changeType == .status && call.status == .inProgress) {
                    goToCallUI(for: call)
                } else if call.termCodeType == .kicked {
                    showHostDenyAlert()
                } else if call.termCodeType == .waitingRoomTimeout {
                    showHostDidNotRespondAlert()
                } else {
                    updateCallStatus()
                }
            }
        onCallUpdateSubscription?.store(in: &subscriptions)
        
        NotificationCenter.default
            .publisher(for: UIApplication.didBecomeActiveNotification)
            .sink { [weak self] _ in
                guard let self else { return }
                audioSessionUseCase.configureCallAudioSession()
            }
            .store(in: &subscriptions)
                
        audioSessionUseCase
            .onAudioSessionRouteChange()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let self else { return }
                updateSpeakerInfo()
            }
            .store(in: &subscriptions)
    }
    
    private func fetchInitialValues() {
        audioSessionUseCase.configureCallAudioSession()
        if audioSessionUseCase.isBluetoothAudioRouteAvailable {
            updateSpeakerInfo()
        } else {
            enableLoudSpeaker(enabled: isSpeakerEnabled)
        }
        permissionHandler.requestAudioPermission()
        selectFrontCameraIfNeeded()
        if !accountUseCase.isGuest {
            fetchUserAvatar()
        }
    }
    
    private func updateSpeakerInfo() {
        isBluetoothAudioRouteAvailable = audioSessionUseCase.isBluetoothAudioRouteAvailable
        switch audioSessionUseCase.currentSelectedAudioPort {
        case .builtInReceiver:
            isSpeakerEnabled = false
        case .headphones, .builtInSpeaker:
            isSpeakerEnabled = true
            speakerOnIcon = .callControlSpeakerEnabled
        default:
            isSpeakerEnabled = isBluetoothAudioRouteAvailable
            speakerOnIcon = isBluetoothAudioRouteAvailable ? .speakerOnBluetooth : .callControlSpeakerEnabled
        }
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
        let myHandle = chatUseCase.myUserHandle()
        guard let base64Handle = megaHandleUseCase.base64Handle(forUserHandle: myHandle),
              let avatarBackgroundHexColor = userImageUseCase.avatarColorHex(forBase64UserHandle: base64Handle) else {
            return
        }
        
        let avatarHandler = UserAvatarHandler(
            userImageUseCase: userImageUseCase,
            initials: waitingRoomUseCase.userName().initialForAvatar(),
            avatarBackgroundColor: UIColor.colorFromHexString(avatarBackgroundHexColor) ?? UIColor.black000000
        )
        
        Task { @MainActor in
            let image = await avatarHandler.avatar(for: base64Handle)
            userAvatar = image
        }
    }
    
    private func removeLocalVideo() {
        if isVideoEnabled {
            localVideoUseCase.removeLocalVideo(for: MEGAInvalidHandle, callbacksDelegate: self)
        }
    }
    
    private func dismiss() {
        removeLocalVideo()
        callUseCase.stopListeningForCall()
        router.dismiss { [weak self] in
            guard let self else { return }
            if accountUseCase.isGuest {
                authUseCase.logout()
            }
            dismissCall()
        }
    }
    
    private func showHostDenyAlert() {
        showRespondAlert(router.showHostDenyAlert)
    }
    
    private func showHostDidNotRespondAlert() {
        tracker.trackAnalyticsEvent(with: WaitingRoomTimeoutEvent())
        showRespondAlert(router.showHostDidNotRespondAlert)
    }

    private func showRespondAlert(_ block: (@escaping () -> Void) -> Void) {
        onCallUpdateSubscription?.cancel()
        callUseCase.stopListeningForCall()
        dismissCall()
        block { [weak self] in
            guard let self else { return }
            dismiss()
        }
    }

    // MARK: - Chat and call related methods
    
    private func updateCallStatus() {
        if isMeetingStart {
            if !isActiveWaitingRoom {
                answerCall()
            }
        } else {
            if isActiveWaitingRoom {
                dismissCall()
            }
            viewState = .waitForHostToStart
        }
    }
    
    private func answerCall() {
        guard let chatRoom = chatRoomUseCase.chatRoom(forChatId: chatId) else { return }
        let chatIdBase64Handle = megaHandleUseCase.base64Handle(forUserHandle: chatRoom.chatId) ?? "Unknown"
        callManager.startCall(in: chatRoom, chatIdBase64Handle: chatIdBase64Handle, hasVideo: isVideoEnabled, notRinging: false, isJoiningActiveCall: true)
        viewState = .waitForHostToLetIn
    }
    
    private func dismissCall() {
        guard let chatRoom = chatRoomUseCase.chatRoom(forChatId: chatId) else { return }
        callManager.endCall(in: chatRoom, endForAll: false)
    }
    
    private func createEphemeralAccountAndJoinChat(firstName: String, lastName: String) {
        guard let chatLink else { return }
        meetingUseCase.createEphemeralAccountAndJoinChat(firstName: firstName, lastName: lastName, link: chatLink) { [weak self] result in
            guard let self else { return }
            switch result {
            case .success:
                joinChatCall()
                NotificationCenter.default.post(name: .accountDidLogin, object: nil)
            case .failure:
                viewState = .guestUserSetup
            }
        } karereInitCompletion: { [weak self] in
            guard let self else { return }
            selectFrontCameraIfNeeded()
            if isVideoEnabled {
                enableLocalVideo(enabled: true)
            }
        }
    }
    
    private func checkChatLink(_ chatLink: String) {
        meetingUseCase.checkChatLink(link: chatLink) { [weak self] result in
            guard let self else { return }
            switch result {
            case .success(let chatRoom):
                if chatRoom.ownPrivilege == .removed || chatRoom.ownPrivilege == .readOnly {
                    joinChatCall()
                } else {
                    viewState = .waitForHostToStart
                }
            case .failure:
                dismiss()
            }
        }
    }
    
    private func joinChatCall() {
        Task { @MainActor in
            do {
                _ = try await waitingRoomUseCase.joinChat(forChatId: chatId, userHandle: requestUserHandle)
                if accountUseCase.isGuest {
                    fetchUserAvatar()
                }
                // There is a delay for a call to update its status after joining a meeting
                // We can't check whether the meeting is started or not immediately after joining a meeting
                // So the wait is used here to wait for the call's update
                // Note that if the call is updated faster than the wait, it will do the logic without the wait
                try await Task.sleep(nanoseconds: 500_000_000)
                updateCallStatus()
            } catch {
                dismiss()
            }
        }
    }
    
    private func goToCallUI(for call: CallEntity) {
        guard let chatRoom = chatRoomUseCase.chatRoom(forChatId: chatId) else { return }
        router.openCallUI(for: call, in: chatRoom, isSpeakerEnabled: isSpeakerEnabled)
        callManager.muteCall(in: chatRoom, muted: !isMicrophoneMuted)
        onCallUpdateSubscription?.cancel()
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
