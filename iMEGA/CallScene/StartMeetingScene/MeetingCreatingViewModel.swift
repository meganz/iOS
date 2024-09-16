import Combine
import MEGAAnalyticsiOS
import MEGADomain
import MEGAL10n
import MEGAPermissions
import MEGAPresentation

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
    case loadAvatarImage
}

@objc
enum MeetingConfigurationType: Int {
    case start
    case guestJoin
    case join
}

@MainActor
final class MeetingCreatingViewModel: ViewModelType {
    enum Command: CommandType, Equatable {
        case configView(title: String, type: MeetingConfigurationType, isMicrophoneEnabled: Bool)
        case updateMeetingName(String)
        case updateAvatarImage(UIImage)
        case updateVideoButton(enabled: Bool)
        case updateMicrophoneButton(enabled: Bool)
        case updateCameraPosition(position: CameraPositionEntity)
        case loadingStartMeeting
        case loadingEndMeeting
        case localVideoFrame(width: Int, height: Int, buffer: Data!)
        case updatedAudioPortSelection(audioPort: AudioPort, bluetoothAudioRouteAvailable: Bool)
    }
    
    // MARK: - Private properties
    private let router: any MeetingCreatingViewRouting
    private var meetingName = ""
    private var firstName = ""
    private var lastName = ""

    private let type: MeetingConfigurationType
    private let link: String?
    
    private let meetingUseCase: any MeetingCreatingUseCaseProtocol
    private let audioSessionUseCase: any AudioSessionUseCaseProtocol
    private let localVideoUseCase: any CallLocalVideoUseCaseProtocol
    private let captureDeviceUseCase: any CaptureDeviceUseCaseProtocol
    private let permissionHandler: any DevicePermissionsHandling
    private let userImageUseCase: any UserImageUseCaseProtocol
    private let accountUseCase: any AccountUseCaseProtocol
    private let megaHandleUseCase: any MEGAHandleUseCaseProtocol
    private let callUseCase: any CallUseCaseProtocol
    private let callManager: any CallManagerProtocol

    private let tracker: any AnalyticsTracking
    private let featureFlagProvider: any FeatureFlagProviderProtocol

    private var isVideoEnabled = false
    private var isSpeakerEnabled = true
    private var isMicrophoneEnabled = false
    private var isSpeakRequestEnabled = false
    private var isWaitingRoomEnabled = false
    private var doesAllowNonHostToAddParticipants = true
    private var userHandle: UInt64
    
    private var chatId: UInt64?
    
    var appDidBecomeActiveSubscription: AnyCancellable?
    var appWillResignActiveSubscription: AnyCancellable?

    // MARK: - Internal properties
    var invokeCommand: ((Command) -> Void)?
    
    private var defaultMeetingName: String {
        Strings.Localizable.Meetings.CreateMeeting.defaultMeetingName(meetingUseCase.username())
    }
    
    // MARK: - Init
    init(
        router: some MeetingCreatingViewRouting,
        type: MeetingConfigurationType,
        meetingUseCase: some MeetingCreatingUseCaseProtocol,
        audioSessionUseCase: some AudioSessionUseCaseProtocol,
        localVideoUseCase: some CallLocalVideoUseCaseProtocol,
        captureDeviceUseCase: some CaptureDeviceUseCaseProtocol,
        permissionHandler: some DevicePermissionsHandling,
        userImageUseCase: some UserImageUseCaseProtocol,
        accountUseCase: some AccountUseCaseProtocol,
        megaHandleUseCase: some MEGAHandleUseCaseProtocol,
        callUseCase: some CallUseCaseProtocol,
        callManager: some CallManagerProtocol,
        tracker: some AnalyticsTracking = DIContainer.tracker,
        featureFlagProvider: some FeatureFlagProviderProtocol,
        link: String?,
        userHandle: UInt64
    ) {
        self.router = router
        self.type = type
        self.meetingUseCase = meetingUseCase
        self.audioSessionUseCase = audioSessionUseCase
        self.localVideoUseCase = localVideoUseCase
        self.captureDeviceUseCase = captureDeviceUseCase
        self.permissionHandler = permissionHandler
        self.userImageUseCase = userImageUseCase
        self.accountUseCase = accountUseCase
        self.megaHandleUseCase = megaHandleUseCase
        self.callUseCase = callUseCase
        self.callManager = callManager
        self.tracker = tracker
        self.featureFlagProvider = featureFlagProvider
        self.link = link
        self.userHandle = userHandle
        
        appDidBecomeActiveSubscription = NotificationCenter.default
            .publisher(for: UIApplication.didBecomeActiveNotification)
            .sink { [weak self] _ in
                guard let self else { return }
                self.audioSessionUseCase.configureCallAudioSession()
                self.addRouteChangedListener()
                self.enableLoudSpeaker(enabled: self.isSpeakerEnabled)
            }
        
        appWillResignActiveSubscription = NotificationCenter.default
            .publisher(for: UIApplication.willResignActiveNotification)
            .sink { [weak self] _ in
                self?.removeRouteChangedListener()
            }
    }
    
    // MARK: - Dispatch action
    func dispatch(_ action: MeetingCreatingViewAction) {
        switch action {
        case .onViewReady:
            audioSessionUseCase.configureCallAudioSession()
            addRouteChangedListener()
            if audioSessionUseCase.isBluetoothAudioRouteAvailable {
                isSpeakerEnabled = audioSessionUseCase.isOutputFrom(port: .builtInSpeaker)
                updateSpeakerInfo()
            } else {
                enableLoudSpeaker(enabled: isSpeakerEnabled)
            }
            permissionHandler.requestAudioPermission()
            selectFrontCameraIfNeeded()
            switch type {
            case .join, .guestJoin:
                guard let link else { return }
                checkChatLink(link: link)
            case .start:
                meetingName = defaultMeetingName
                invokeCommand?(
                    .configView(
                        title: meetingName,
                        type: type,
                        isMicrophoneEnabled: isMicrophoneEnabled
                    )
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
                    self.localVideoUseCase.openVideoDevice { _ in
                        self.localVideoUseCase.addLocalVideo(for: MEGAInvalidHandle, callbacksDelegate: self)
                    }
                } else {
                    self.localVideoUseCase.releaseVideoDevice { _ in
                        self.localVideoUseCase.removeLocalVideo(for: MEGAInvalidHandle, callbacksDelegate: self)
                    }
                }
                self.invokeCommand?(.updateVideoButton(enabled: self.isVideoEnabled))
            }
        case .didTapSpeakerButton:
            isSpeakerEnabled = !isSpeakerEnabled
            enableLoudSpeaker(enabled: isSpeakerEnabled)
        case .didTapStartMeetingButton:
            switch type {
            case .start:
                startChatCall()
            case .join:
                guard let chatId else { return }
                joinChatAndStartCall(chatId: chatId)
            case .guestJoin:
                guard let chatId else { return }
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
        case .loadAvatarImage:
            guard let myHandle = accountUseCase.currentUserHandle,
                  let base64Handle = megaHandleUseCase.base64Handle(forUserHandle: myHandle),
                  let avatarBackgroundHexColor = MEGASdk.avatarColor(forBase64UserHandle: base64Handle) else {
                return
            }
            
            let avatarHandler = UserAvatarHandler(
                userImageUseCase: userImageUseCase,
                initials: meetingUseCase.username().initialForAvatar(),
                avatarBackgroundColor: UIColor.colorFromHexString(avatarBackgroundHexColor) ?? UIColor.black000000
            )
            
            Task { @MainActor in
                let image = await avatarHandler.avatar(for: base64Handle)
                invokeCommand?(.updateAvatarImage(image))
            }
        }
    }
    
    private func addRouteChangedListener() {
        audioSessionUseCase.routeChanged { [weak self] routeChangedReason, _ in
            guard let self else { return }
            self.sessionRouteChanged(routeChangedReason: routeChangedReason)
        }
    }
    
    private func removeRouteChangedListener() {
        audioSessionUseCase.routeChanged()
    }
    
    private func enableLoudSpeaker(enabled: Bool) {
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
    
    private func createEphemeralAccountAndJoinChat(chatId: UInt64) {
        guard let link else { return }
        tracker.trackAnalyticsEvent(with: ScheduledMeetingJoinGuestButtonEvent())
        meetingUseCase.createEphemeralAccountAndJoinChat(firstName: firstName, lastName: lastName, link: link) { [weak self] in
            guard let self else { return }
            switch $0 {
            case .success:
                Task { @MainActor [weak self] in
                    guard let self else { return }
                    joinChatAndStartCall(chatId: chatId)
                    NotificationCenter.default.post(name: .accountDidLogin, object: nil)
                }
            case .failure:
                Task { @MainActor [weak self] in
                    guard let self else { return }
                    dismiss()
                }
            }
        } karereInitCompletion: { }
    }
    
    private func joinChatAndStartCall(chatId: UInt64) {
        meetingUseCase.joinChat(forChatId: chatId, userHandle: userHandle) { [weak self] in
            guard let self else { return }
            switch $0 {
            case .success(let chatRoom):
                startCall(inChatRoom: chatRoom)
            case .failure:
                self.dismiss()
            }
        }
    }
    
    private func startChatCall() {
        if meetingName.isEmpty || meetingName.trimmingCharacters(in: .whitespaces).isEmpty {
            dispatch(.updateMeetingName(defaultMeetingName))
        }
        
        let startCallData = CreateMeetingNowEntity(
            meetingName: meetingName,
            speakRequest: isSpeakRequestEnabled,
            waitingRoom: isWaitingRoomEnabled,
            allowNonHostToAddParticipants: doesAllowNonHostToAddParticipants)
        
        Task { @MainActor in
            do {
                let chatRoom = try await meetingUseCase.createMeeting(startCallData)
                startCall(inChatRoom: chatRoom)
            } catch {
                self.dismiss()
            }
        }
    }
    
    private func startCall(inChatRoom chatRoom: ChatRoomEntity) {
        dismiss { [weak self] in
            guard let self else { return }
            callManager.startCall(
                with: CallActionSync(
                    chatRoom: chatRoom,
                    audioEnabled: !self.isMicrophoneEnabled,
                    videoEnabled: self.isVideoEnabled,
                    isJoiningActiveCall: true
                )
            )
        }
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
    
    private func checkChatLink(link: String) {
        invokeCommand?(.loadingStartMeeting)
        
        meetingUseCase.checkChatLink(link: link) { [weak self] in
            guard let self else { return }
            self.invokeCommand?(.loadingEndMeeting)

            switch $0 {
            case .success(let chatRoom):
                self.invokeCommand?(
                    .configView(
                        title: chatRoom.title ?? "",
                        type: self.type,
                        isMicrophoneEnabled: self.isMicrophoneEnabled)
                )
                self.chatId = chatRoom.chatId
            case .failure:
                self.dismiss()
            }
        }
    }
    
    private func dismiss(completion: (() -> Void)? = nil) {
        disableLocalVideoIfNeeded()
        router.dismiss(completion: completion)
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
    
    private func switchCamera() {
        guard let selectCameraLocalizedString = captureDeviceUseCase.wideAngleCameraLocalizedName(position: isBackCameraSelected() ? .front : .back),
              localVideoUseCase.videoDeviceSelected() != selectCameraLocalizedString else {
            return
        }
        localVideoUseCase.selectCamera(withLocalizedName: selectCameraLocalizedString) { _ in }
    }
    
    private func disableLocalVideoIfNeeded() {
        if isVideoEnabled {
            localVideoUseCase.removeLocalVideo(for: MEGAInvalidHandle, callbacksDelegate: self)
        }
    }
    
    private func updateSpeakerInfo() {
        let currentSelectedPort = audioSessionUseCase.currentSelectedAudioPort
        let isBluetoothAvailable = audioSessionUseCase.isBluetoothAudioRouteAvailable
        isSpeakerEnabled = audioSessionUseCase.isOutputFrom(port: .builtInSpeaker)
        MEGALogDebug("Create meeting: updating speaker info with selected port \(currentSelectedPort) bluetooth available \(isBluetoothAvailable)")
        invokeCommand?(
            .updatedAudioPortSelection(audioPort: currentSelectedPort,
                                       bluetoothAudioRouteAvailable: isBluetoothAvailable)
        )
    }
    
    private func sessionRouteChanged(routeChangedReason: AudioSessionRouteChangedReason) {
        MEGALogDebug("Create meeting: session route changed with \(routeChangedReason) , current port \(audioSessionUseCase.currentSelectedAudioPort)")
        updateSpeakerInfo()
    }
}

extension MeetingCreatingViewModel: CallLocalVideoCallbacksUseCaseProtocol {
    func localVideoFrameData(width: Int, height: Int, buffer: Data) {
        invokeCommand?(.localVideoFrame(width: width, height: height, buffer: buffer))
    }
    
    func localVideoChangedCameraPosition() {
        invokeCommand?(.updateCameraPosition(position: isBackCameraSelected() ? .back : .front))
    }
}
