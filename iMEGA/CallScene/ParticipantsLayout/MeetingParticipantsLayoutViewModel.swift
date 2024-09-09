import Combine
import CombineSchedulers
import Foundation
import MEGADomain
import MEGAFoundation
import MEGAL10n
import MEGAPresentation
import MEGASwift
import MEGASwiftUI

enum CallViewAction: ActionType {
    case onViewLoaded
    case onViewReady
    case tapOnView(onParticipantsView: Bool)
    case tapOnLayoutModeButton
    case tapOnOptionsMenuButton(presenter: UIViewController, sender: UIBarButtonItem)
    case tapOnBackButton
    case showRenameChatAlert
    case switchCamera
    case shareLinkTapped(sender: NSObject)
    case setNewTitle(String)
    case discardChangeTitle
    case renameTitleDidChange(String)
    case tapParticipantToPinAsSpeaker(CallParticipantEntity)
    case fetchAvatar(participant: CallParticipantEntity)
    case fetchSpeakerAvatar
    case participantIsVisible(_ participant: CallParticipantEntity, index: Int)
    case indexVisibleParticipants([Int])
    case pinParticipantAsSpeaker(CallParticipantEntity)
    case addParticipant(withHandle: HandleEntity)
    case removeParticipant(withHandle: HandleEntity)
    case startCallEndCountDownTimer
    case endCallEndCountDownTimer
    case didEndDisplayLastPeerLeftStatusMessage
    case showNavigation
    case orientationOrModeChange(isIPhoneLandscape: Bool, isSpeakerMode: Bool)
    case onOrientationChanged
    case copyLinkTapped
    case inviteParticipantsTapped
}

enum ParticipantsLayoutMode {
    case grid
    case speaker
    
    mutating func toggle() {
        if self == .grid {
            self = .speaker
        } else {
            self = .grid
        }
    }
}

enum DeviceOrientation {
    case landscape
    case portrait
}

private enum CallViewModelConstant {
    static let callEndCountDownTimerDuration: TimeInterval = 120
}

final class MeetingParticipantsLayoutViewModel: NSObject, ViewModelType {
    enum Command: CommandType, Equatable {
        case configView(title: String, subtitle: String, isUserAGuest: Bool, isOneToOne: Bool)
        case configLocalUserView(position: CameraPositionEntity)
        case switchMenusVisibility
        case switchMenusVisibilityToShownIfNeeded
        case switchLayoutMode(layout: ParticipantsLayoutMode, participantsCount: Int)
        case disableSwitchLayoutModeButton(disable: Bool)
        case switchLocalVideo(Bool)
        case updateName(String)
        case updateDuration(String)
        case updatePageControl(Int)
        case updateParticipants([CallParticipantEntity])
        case reloadParticipantAt(Int, [CallParticipantEntity])
        case updateParticipantMicAt(Int, CallParticipantEntity)
        case updateParticipantAudioLevelAt(Int, CallParticipantEntity)
        case updateParticipantRaisedHandAt(Int, CallParticipantEntity)
        case updateSpeakerViewFor(CallParticipantEntity)
        case localVideoFrame(Int, Int, Data)
        case participantsStatusChanged(addedParticipantCount: Int,
                                       removedParticipantCount: Int,
                                       addedParticipantNames: [String],
                                       removedParticipantNames: [String],
                                       isOnlyMyselfRemainingInTheCall: Bool)
        case reconnecting
        case reconnected
        case updateCameraPositionTo(position: CameraPositionEntity)
        case updatedCameraPosition
        case showRenameAlert(title: String, isMeeting: Bool)
        case enableRenameButton(Bool)
        case showNoOneElseHereMessage
        case showWaitingForOthersMessage
        case hideEmptyRoomMessage
        case updateHasLocalAudio(Bool)
        case updateLocalRaisedHandHidden(Bool)
        case shouldHideSpeakerView(Bool)
        case ownPrivilegeChangedToModerator
        case showBadNetworkQuality
        case hideBadNetworkQuality
        case updateAvatar(UIImage, CallParticipantEntity)
        case updateSpeakerAvatar(UIImage)
        case updateSpeakerMic(audioEnabled: Bool, audioDetected: Bool)
        case updateMyAvatar(UIImage)
        case updateCallEndDurationRemainingString(String)
        case removeCallEndDurationView
        case configureSpeakerView(
            isSpeakerMode: Bool,
            leadingAndTrailingConstraint: CGFloat,
            topConstraint: CGFloat,
            bottomConstraint: CGFloat
        )
        case hideRecording(Bool)
        case showCallWillEnd(String)
        case updateCallWillEnd(String)
        case hideCallWillEnd
        case enableSwitchCameraButton
        case updateSnackBar(SnackBar?)
        case showEmptyCallShareOptionsView(canInviteParticipants: Bool)
        case removeEmptyCallShareOptionsView
        case updateBarButtons
    }
    
    private var chatRoom: ChatRoomEntity
    private var call: CallEntity
    
    private var timer: Timer?
    private var callWillEndTimer: Timer?
    private var callWillEndCountDown: Double = 0
    
    private(set) var callParticipants = [CallParticipantEntity]() {
        didSet {
            requestAvatarChanges(forParticipants: callParticipants + [myself], chatId: call.chatId)
        }
    }
    private var indexOfVisibleParticipants = [Int]()
    private var hasParticipantJoinedBefore = false
    private(set) var speakerParticipant: CallParticipantEntity? {
        willSet {
            speakerParticipant?.speakerVideoDataDelegate = nil
        }
        didSet {
            guard let speakerParticipant else { return }
            didSetSpeakerParticipant(speakerParticipant)
        }
    }
    
    private(set) var isSpeakerParticipantPinned: Bool = false
    internal var layoutMode: ParticipantsLayoutMode = .grid {
        didSet {
            if layoutMode == .grid {
                isSpeakerParticipantPinned = false
                callParticipants.forEach { $0.isSpeakerPinned = false }
                containerViewModel?.dispatch(.didSwitchToGridView)
                speakerParticipant = nil
            } else if speakerParticipant == nil {
                callParticipants.first?.isSpeakerPinned = true
                isSpeakerParticipantPinned = true
                speakerParticipant = callParticipants.first
            }
        }
    }
    private var localVideoEnabled: Bool = false
    private var reconnecting: Bool = false
    private var switchingCamera: Bool = false
    private var hasScreenSharingParticipant: Bool = false
    private var hasBeenInProgress: Bool = false
    private weak var containerViewModel: MeetingContainerViewModel?
    
    private let chatUseCase: any ChatUseCaseProtocol
    private let callUseCase: any CallUseCaseProtocol
    private let captureDeviceUseCase: any CaptureDeviceUseCaseProtocol
    private let localVideoUseCase: any CallLocalVideoUseCaseProtocol
    private let remoteVideoUseCase: any CallRemoteVideoUseCaseProtocol
    private let chatRoomUseCase: any ChatRoomUseCaseProtocol
    private let chatRoomUserUseCase: any ChatRoomUserUseCaseProtocol
    private let accountUseCase: any AccountUseCaseProtocol
    private var userImageUseCase: any UserImageUseCaseProtocol
    private let analyticsEventUseCase: any AnalyticsEventUseCaseProtocol
    private let megaHandleUseCase: any MEGAHandleUseCaseProtocol
    private let callUpdateUseCase: any CallUpdateUseCaseProtocol
    private let sessionUpdateUseCase: any SessionUpdateUseCaseProtocol
    private let chatRoomUpdateUseCase: any ChatRoomUpdateUseCaseProtocol
    
    private let callManager: any CallManagerProtocol
    private let featureFlagProvider: any FeatureFlagProviderProtocol
    
    @PreferenceWrapper(key: .callsSoundNotification, defaultValue: true)
    private var callsSoundNotificationPreference: Bool
    
    private var avatarChangeSubscription: AnyCancellable?
    private var avatarRefetchTasks: [Task<Void, Never>]?
    
    private var callEndCountDownSubscription: AnyCancellable?
    private lazy var dateComponentsFormatter: DateComponentsFormatter = {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.minute, .second]
        formatter.zeroFormattingBehavior = .pad
        formatter.unitsStyle = .positional
        return formatter
    }()
    
    private var meetingParticipantStatusPipelineSubscription: AnyCancellable?
    private let meetingParticipantStatusPipeline = MeetingParticipantStatusPipeline(
        collectionDuration: 1.0,
        resetCollectionDurationUpToCount: 2
    )
    
    private let tonePlayer = TonePlayer()
    var namesFetchingTask: Task<Void, Never>?
    
    private var reconnecting1on1Subscription: AnyCancellable?
    
    private var currentRaiseHandHandles: [HandleEntity] = []
    private let debouncer = Debouncer(delay: 0.5)

    // MARK: - Internal properties
    var invokeCommand: ((Command) -> Void)?
    private var layoutUpdateChannel: ParticipantLayoutUpdateChannel
    let cameraSwitcher: any CameraSwitching
    let scheduler: AnySchedulerOf<DispatchQueue>
        
    init(
        containerViewModel: MeetingContainerViewModel,
        scheduler: AnySchedulerOf<DispatchQueue>,
        chatUseCase: some ChatUseCaseProtocol,
        callUseCase: some CallUseCaseProtocol,
        captureDeviceUseCase: some CaptureDeviceUseCaseProtocol,
        localVideoUseCase: some CallLocalVideoUseCaseProtocol,
        remoteVideoUseCase: some CallRemoteVideoUseCaseProtocol,
        chatRoomUseCase: some ChatRoomUseCaseProtocol,
        chatRoomUserUseCase: some ChatRoomUserUseCaseProtocol,
        accountUseCase: some AccountUseCaseProtocol,
        userImageUseCase: some UserImageUseCaseProtocol,
        analyticsEventUseCase: some AnalyticsEventUseCaseProtocol,
        megaHandleUseCase: some MEGAHandleUseCaseProtocol,
        callUpdateUseCase: some CallUpdateUseCaseProtocol,
        sessionUpdateUseCase: some SessionUpdateUseCaseProtocol,
        chatRoomUpdateUseCase: some ChatRoomUpdateUseCaseProtocol,
        callManager: some CallManagerProtocol,
        featureFlagProvider: some FeatureFlagProviderProtocol = DIContainer.featureFlagProvider,
        chatRoom: ChatRoomEntity,
        call: CallEntity,
        preferenceUseCase: some PreferenceUseCaseProtocol = PreferenceUseCase.default,
        layoutUpdateChannel: ParticipantLayoutUpdateChannel,
        cameraSwitcher: some CameraSwitching
    ) {
        self.chatUseCase = chatUseCase
        self.scheduler = scheduler
        self.containerViewModel = containerViewModel
        self.callUseCase = callUseCase
        self.captureDeviceUseCase = captureDeviceUseCase
        self.localVideoUseCase = localVideoUseCase
        self.remoteVideoUseCase = remoteVideoUseCase
        self.chatRoomUseCase = chatRoomUseCase
        self.chatRoomUserUseCase = chatRoomUserUseCase
        self.accountUseCase = accountUseCase
        self.userImageUseCase = userImageUseCase
        self.analyticsEventUseCase = analyticsEventUseCase
        self.megaHandleUseCase = megaHandleUseCase
        self.callUpdateUseCase = callUpdateUseCase
        self.sessionUpdateUseCase = sessionUpdateUseCase
        self.chatRoomUpdateUseCase = chatRoomUpdateUseCase
        self.callManager = callManager
        self.featureFlagProvider = featureFlagProvider
        self.chatRoom = chatRoom
        self.call = call
        self.layoutUpdateChannel = layoutUpdateChannel
        self.cameraSwitcher = cameraSwitcher
        self.cameraEnabled = call.hasLocalVideo
        super.init()
        self.$callsSoundNotificationPreference.useCase = preferenceUseCase
        
        self.layoutUpdateChannel.getCurrentLayout = { [weak self] in
            guard let self else { return .grid }
            return layoutMode
        }
        
        self.layoutUpdateChannel.layoutSwitchingEnabled = { [weak self] in
            guard let self else { return false }
            return !hasScreenSharingParticipant
        }
        
        self.layoutUpdateChannel.updateLayout = { [weak self] in
            guard let self else { return  }
            updateLayout(to: $0)
        }
    }
    
    deinit {
        cancelReconnecting1on1Subscription()
        avatarRefetchTasks?.forEach { $0.cancel() }
        callWillEndTimer?.invalidate()
    }
    
    private func initTimerIfNeeded(with duration: Int) {
        if timer == nil {
            let callDurationInfo = CallDurationInfo(initDuration: duration, baseDate: Date())
            let timer = Timer(timeInterval: 1, repeats: true, block: { [weak self] _ in
                let duration = Int(Date().timeIntervalSince1970) - Int(callDurationInfo.baseDate.timeIntervalSince1970) + callDurationInfo.initDuration
                self?.invokeCommand?(.updateDuration(TimeInterval(duration).timeString))
            })
            RunLoop.main.add(timer, forMode: .common)
            self.timer = timer
        }
    }
    
    private func switchLayout() {
        MEGALogDebug("Switch meetings layout from \(layoutMode == .grid ? "grid" : "speaker") to \(layoutMode == .grid ? "speaker" : "grid")")
        callParticipants.forEach { $0.videoDataDelegate = nil }
        if layoutMode == .grid {
            updateLayout(to: .speaker)
        } else {
            updateLayout(to: .grid)
        }
    }
    
    private func updateLayout(to layout: ParticipantsLayoutMode) {
        self.layoutMode = layout
        
        invokeCommand?(.switchLayoutMode(layout: layoutMode, participantsCount: callParticipants.count))
    }
    
    private func reloadParticipant(_ participant: CallParticipantEntity) {
        guard let index = index(for: participant) else { return }
        invokeCommand?(.reloadParticipantAt(index, callParticipants))
    }
    
    private func updateParticipantMic(_ participant: CallParticipantEntity) {
        guard let index = index(for: participant) else { return }
        invokeCommand?(.updateParticipantMicAt(index, participant))
    }
    
    private func updateParticipantAudioLevel(_ participant: CallParticipantEntity) {
        guard let index = index(for: participant) else { return }
        invokeCommand?(.updateParticipantAudioLevelAt(index, participant))
    }
    
    /// This method returns the index for a participant inside the callParticipants
    /// Participants has participantId and clientId as unique identifiers inside a call. When participants share screen, a fake participant is duplicated with property isScreenShareCell = true, to differentiate the participant from the share screen stream. For that reason we need to check isScreenShareCell for getting correct index.
    private func index(for participant: CallParticipantEntity) -> Int? {
        callParticipants.firstIndex(where: {$0 == participant && $0.isScreenShareCell == participant.isScreenShareCell})
    }
    
    /// Participant changes are received with a new full CallParticipantEntity object. This method find same participant in the callParticipants array in order to update it.
    /// isScreenShareCell must be false, as those fake participants are duplicated from the original one just to stream the share screen video, but never updated.
    private func participantToUpdate(from participant: CallParticipantEntity) -> CallParticipantEntity? {
        guard let participantToUpdate = callParticipants.first(where: {$0 == participant && !$0.isScreenShareCell}) else {
            MEGALogError("Error getting participant updated")
            return nil
        }
        return participantToUpdate
    }
    
    private func updateSpeakerMicIfNeeded(_ participant: CallParticipantEntity) {
        guard isParticipantCurrentSpeakerParticipant(participant) else {
            return
        }
        invokeCommand?(.updateSpeakerMic(audioEnabled: participant.audio == .on, audioDetected: participant.audioDetected))
    }
    
    private func reloadSpeakerIfNeeded(_ participant: CallParticipantEntity) {
        guard isParticipantCurrentSpeakerParticipant(participant) else {
            return
        }
        speakerParticipant = participant
    }
    
    private func isParticipantCurrentSpeakerParticipant(_ participant: CallParticipantEntity) -> Bool {
        speakerParticipant == participant &&
        speakerParticipant?.isScreenShareCell == participant.isScreenShareCell
    }
    
    private func requestRemoteScreenShareVideo(for participant: CallParticipantEntity) {
        guard participant.hasScreenShare else { return }
        if participant.isVideoHiRes && !participant.isReceivingHiResVideo {
            remoteVideoUseCase.requestHighResolutionVideo(for: chatRoom.chatId, clientId: participant.clientId, completion: nil)
        }
        if participant.isVideoLowRes && !participant.isReceivingLowResVideo {
            remoteVideoUseCase.requestLowResolutionVideos(for: chatRoom.chatId, clientId: participant.clientId, completion: nil)
        }
        if participant.hasCamera && participant.isLowResCamera && participant.canReceiveVideoLowRes && !participant.canReceiveVideoHiRes && !participant.isReceivingHiResVideo {
            remoteVideoUseCase.requestHighResolutionVideo(for: chatRoom.chatId, clientId: participant.clientId, completion: nil)
        }
        if participant.hasCamera && participant.isHiResCamera && participant.canReceiveVideoHiRes && !participant.canReceiveVideoLowRes && !participant.isReceivingLowResVideo {
            remoteVideoUseCase.requestLowResolutionVideos(for: chatRoom.chatId, clientId: participant.clientId, completion: nil)
        }
    }
    
    private func enableRemoteVideo(for participant: CallParticipantEntity) {
        guard !participant.hasScreenShare else {
            enableRemoteScreenShareVideo(for: participant)
            return
        }
        let canEnableHiResVideo = participant.isVideoHiRes && participant.canReceiveVideoHiRes
        let canEnableLowResVideo = participant.isVideoLowRes && participant.canReceiveVideoLowRes
        switch layoutMode {
        case .grid:
            if remoteVideoUseCase.isReceivingBothHighAndLowResVideo(for: participant) {
                stopRemoteVideo(for: participant, isHiRes: false)
            } else if canEnableHiResVideo {
                remoteVideoUseCase.enableRemoteVideo(for: participant, isHiRes: true)
            } else if canEnableLowResVideo {
                switchVideoResolutionLowToHigh(for: participant, in: chatRoom.chatId)
            } else if participant.isVideoHiRes {
                remoteVideoUseCase.requestHighResolutionVideo(for: chatRoom.chatId, clientId: participant.clientId, completion: nil)
            }
        case .speaker:
            if participant.speakerVideoDataDelegate == nil {
                if remoteVideoUseCase.isReceivingBothHighAndLowResVideo(for: participant) {
                    stopRemoteVideo(for: participant, isHiRes: true)
                } else if canEnableLowResVideo {
                    remoteVideoUseCase.enableRemoteVideo(for: participant, isHiRes: false)
                } else if canEnableHiResVideo && remoteVideoUseCase.isOnlyReceivingHighResVideo(for: participant) {
                    switchVideoResolutionHighToLow(for: participant, in: chatRoom.chatId)
                } else if participant.isVideoLowRes {
                    remoteVideoUseCase.requestLowResolutionVideos(for: chatRoom.chatId, clientId: participant.clientId, completion: nil)
                }
            } else {
                if remoteVideoUseCase.isReceivingBothHighAndLowResVideo(for: participant) {
                    stopRemoteVideo(for: participant, isHiRes: false)
                } else if canEnableHiResVideo {
                    remoteVideoUseCase.enableRemoteVideo(for: participant, isHiRes: true)
                } else if canEnableLowResVideo && remoteVideoUseCase.isOnlyReceivingLowResVideo(for: participant) {
                    switchVideoResolutionLowToHigh(for: participant, in: chatRoom.chatId)
                } else if participant.isVideoHiRes {
                    remoteVideoUseCase.requestHighResolutionVideo(for: chatRoom.chatId, clientId: participant.clientId, completion: nil)
                }
            }
        }
    }
    
    private func enableRemoteScreenShareVideo(for participant: CallParticipantEntity) {
        let canEnableHiResVideo = participant.isVideoHiRes && participant.canReceiveVideoHiRes
        let canEnableLowResVideo = participant.isVideoLowRes && participant.canReceiveVideoLowRes
        let isNotReceivingBothBothHighAndLowResVideo = remoteVideoUseCase.isNotReceivingBothBothHighAndLowResVideo(for: participant)
        if participant.hasCamera {
            if canEnableHiResVideo && !participant.isReceivingHiResVideo {
                remoteVideoUseCase.enableRemoteVideo(for: participant, isHiRes: true)
            }
            if canEnableLowResVideo && !participant.isReceivingLowResVideo {
                remoteVideoUseCase.enableRemoteVideo(for: participant, isHiRes: false)
            }
        } else {
            if participant == speakerParticipant && canEnableHiResVideo && isNotReceivingBothBothHighAndLowResVideo {
                remoteVideoUseCase.enableRemoteVideo(for: participant, isHiRes: true)
            } else if participant != speakerParticipant && canEnableLowResVideo && isNotReceivingBothBothHighAndLowResVideo {
                remoteVideoUseCase.enableRemoteVideo(for: participant, isHiRes: false)
            } else if participant == speakerParticipant && canEnableHiResVideo && remoteVideoUseCase.isOnlyReceivingLowResVideo(for: participant) {
                switchVideoResolutionLowToHigh(for: participant, in: chatRoom.chatId)
            } else if participant == speakerParticipant && remoteVideoUseCase.isReceivingBothHighAndLowResVideo(for: participant) {
                stopRemoteVideo(for: participant, isHiRes: false)
            } else if participant != speakerParticipant && remoteVideoUseCase.isReceivingBothHighAndLowResVideo(for: participant) {
                stopRemoteVideo(for: participant, isHiRes: true)
            }
        }
    }
    
    private func disableRemoteVideo(for participant: CallParticipantEntity, isHiRes: Bool) {
        remoteVideoUseCase.disableRemoteVideo(for: participant, isHiRes: isHiRes)
    }
    
    private func stopRemoteVideo(for participant: CallParticipantEntity, isHiRes: Bool) {
        if isHiRes {
            remoteVideoUseCase.stopHighResolutionVideo(for: chatRoom.chatId, clientId: participant.clientId) { [weak self] result in
                guard let self, case .success = result else { return }
                onStopVideoReceiving(for: participant.clientId, isHiRes: true)
            }
        } else {
            remoteVideoUseCase.stopLowResolutionVideo(for: chatRoom.chatId, clientId: participant.clientId) { [weak self] result in
                guard let self, case .success = result else { return }
                onStopVideoReceiving(for: participant.clientId, isHiRes: false)
            }
        }
    }
    
    private func onStopVideoReceiving(for clientId: HandleEntity, isHiRes: Bool) {
        for callParticipant in callParticipants where callParticipant.clientId == clientId {
            if isHiRes {
                callParticipant.isReceivingHiResVideo = false
            } else {
                callParticipant.isReceivingLowResVideo = false
            }
        }
    }
    
    private func fetchAvatar(for participant: CallParticipantEntity, name: String, completion: @escaping ((UIImage) -> Void)) {
        guard let base64Handle = megaHandleUseCase.base64Handle(forUserHandle: participant.participantId),
              let avatarBackgroundHexColor = MEGASdk.avatarColor(forBase64UserHandle: base64Handle) else {
            return
        }
        
        let avatarHandler = UserAvatarHandler(
            userImageUseCase: userImageUseCase,
            initials: name.initialForAvatar(),
            avatarBackgroundColor: UIColor.colorFromHexString(avatarBackgroundHexColor) ?? UIColor.black000000
        )
        
        Task { @MainActor in
            let image = await avatarHandler.avatar(for: base64Handle)
            completion(image)
        }
    }
    
    private func participantName(for userHandle: HandleEntity, completion: @escaping (String?) -> Void) {
        Task { @MainActor in
            let name = try? await chatRoomUserUseCase.userDisplayName(forPeerId: userHandle, in: chatRoom)
            completion(name)
        }
    }
    
    private func isBackCameraSelected() -> Bool {
        guard let selectCameraLocalizedString = captureDeviceUseCase.wideAngleCameraLocalizedName(position: .back),
              localVideoUseCase.videoDeviceSelected() == selectCameraLocalizedString else {
            return false
        }
        
        return true
    }
    
    private func initialSubtitle() -> String {
        if call.isRinging || call.status == .joining {
            return Strings.Localizable.connecting
        } else {
            return Strings.Localizable.calling
        }
    }
    
    private func isActiveCall() -> Bool {
        callParticipants.isEmpty && !call.clientSessions.isEmpty
    }
    
    private func addMeetingParticipantStatusPipelineSubscription() {
        meetingParticipantStatusPipelineSubscription?.cancel()
        meetingParticipantStatusPipelineSubscription = meetingParticipantStatusPipeline
            .statusPublisher
            .sink { [weak self] handlerCollectionType in
                guard let self else { return }
                
                if self.callsSoundNotificationPreference {
                    if handlerCollectionType.removedHandlers.isEmpty == false {
                        self.tonePlayer.play(tone: .participantLeft)
                    } else if handlerCollectionType.addedHandlers.isEmpty == false {
                        self.tonePlayer.play(tone: .participantJoined)
                    }
                }
                
                self.namesFetchingTask?.cancel()
                self.namesFetchingTask = Task { [weak self, chatRoomUserUseCase = self.chatRoomUserUseCase, chatRoom = self.chatRoom] in
                    guard let self else { return }
                    
                    let addedParticipantHandlersSubset = self.handlersSubsetToFetch(forHandlers: handlerCollectionType.addedHandlers)
                    let removedParticipantHandlersSubset = self.handlersSubsetToFetch(forHandlers: handlerCollectionType.removedHandlers)
                    
                    do {
                        async let addedParticipantNamesAsyncTask = chatRoomUserUseCase.userDisplayNames(
                            forPeerIds: addedParticipantHandlersSubset,
                            in: chatRoom)
                        
                        async let removedParticipantNamesAsyncTask = chatRoomUserUseCase.userDisplayNames(
                            forPeerIds: removedParticipantHandlersSubset,
                            in: chatRoom)
                        
                        let participantNamesResult = try await [addedParticipantNamesAsyncTask, removedParticipantNamesAsyncTask]
                        
                        handle(
                            addedParticipantCount: handlerCollectionType.addedHandlers.count,
                            removedParticipantCount: handlerCollectionType.removedHandlers.count,
                            addedParticipantNames: participantNamesResult[0],
                            removedParticipantNames: participantNamesResult[1]
                        )
                    } catch {
                        MEGALogError("Failed to load participants name \(error)")
                    }
                }
            }
    }
    
    private var myself: CallParticipantEntity {
        .myself(
            handle: accountUseCase.currentUserHandle ?? .invalid,
            userName: chatUseCase.myFullName(),
            chatRoom: chatRoom,
            raisedHand: call.raiseHandsList.contains(accountUseCase.currentUserHandle ?? .invalid)
        )
    }
    
    // MARK: - Dispatch action
    func dispatch(_ action: CallViewAction) {
        switch action {
        case .onViewLoaded:
            onViewLoaded()
        case .onViewReady:
            fetchAvatar(for: myself, name: myself.name ?? "Unknown") { [weak self] image in
                self?.invokeCommand?(.updateMyAvatar(image))
            }
            
            requestAvatarChanges(forParticipants: callParticipants + [myself], chatId: call.chatId)
            invokeCommand?(.configLocalUserView(position: isBackCameraSelected() ? .back : .front))
            invokeCommand?(.updateLocalRaisedHandHidden(call.raiseHandsList.notContains(chatUseCase.myUserHandle())))
            showCallWillEndNotificationIfNeeded()
        case .tapOnView(let onParticipantsView):
            if onParticipantsView && layoutMode == .speaker && !callParticipants.isEmpty {
                return
            }
            invokeCommand?(.switchMenusVisibility)
            containerViewModel?.dispatch(.changeMenuVisibility)
        case .tapOnLayoutModeButton:
            switchLayout()
        case .tapOnOptionsMenuButton(let presenter, let sender):
            containerViewModel?.dispatch(.showOptionsMenu(presenter: presenter, sender: sender, isMyselfModerator: chatRoom.ownPrivilege == .moderator))
        case .tapOnBackButton:
            timer?.invalidate()
            callWillEndTimer?.invalidate()
            remoteVideoUseCase.disableAllRemoteVideos()
            containerViewModel?.dispatch(.tapOnBackButton)
        case .showRenameChatAlert:
            invokeCommand?(.showRenameAlert(title: chatRoom.title ?? "", isMeeting: chatRoom.chatType == .meeting))
        case .setNewTitle(let newTitle):
            chatRoomUseCase.renameChatRoom(chatRoom, title: newTitle) { [weak self] result in
                switch result {
                case .success(let title):
                    self?.invokeCommand?(.updateName(title))
                case .failure:
                    MEGALogError("Could not change the chat title")
                }
                self?.containerViewModel?.dispatch(.changeMenuVisibility)
            }
        case .discardChangeTitle:
            containerViewModel?.dispatch(.changeMenuVisibility)
        case .renameTitleDidChange(let newTitle):
            invokeCommand?(.enableRenameButton(chatRoom.title != newTitle && !newTitle.isEmpty))
        case .tapParticipantToPinAsSpeaker(let participant):
            tappedParticipant(participant)
        case .fetchAvatar(let participant):
            participantName(for: participant.participantId) { [weak self] name in
                guard let name = name else { return }
                self?.fetchAvatar(for: participant, name: name) { [weak self] image in
                    self?.invokeCommand?(.updateAvatar(image, participant))
                }
            }
        case .fetchSpeakerAvatar:
            guard let speakerParticipant = speakerParticipant else { return }
            participantName(for: speakerParticipant.participantId) { [weak self] name in
                guard let name = name else { return }
                self?.fetchAvatar(for: speakerParticipant, name: name) { image in
                    self?.invokeCommand?(.updateSpeakerAvatar(image))
                }
            }
        case .participantIsVisible(let participant, let index):
            if participant.video == .on {
                requestRemoteScreenShareVideo(for: participant)
                enableRemoteVideo(for: participant)
            } else {
                stopVideoForParticipant(participant)
            }
            indexOfVisibleParticipants.append(index)
        case .indexVisibleParticipants(let visibleIndex):
            updateVisibleParticipants(for: visibleIndex)
        case .pinParticipantAsSpeaker(let participant):
            pinParticipantAsSpeaker(participant)
        case .addParticipant(let handle):
            meetingParticipantStatusPipeline.addParticipant(withHandle: handle)
        case .removeParticipant(let handle):
            meetingParticipantStatusPipeline.removeParticipant(withHandle: handle)
        case .startCallEndCountDownTimer:
            invokeCommand?(.hideEmptyRoomMessage)
            startCallEndCountDownTimer()
        case .endCallEndCountDownTimer:
            endCallEndCountDownTimer()
            showEmptyCallMessageIfNeeded()
        case .didEndDisplayLastPeerLeftStatusMessage:
            if chatRoom.chatType == .group || chatRoom.chatType == .meeting {
                containerViewModel?.dispatch(.showEndCallDialogIfNeeded)
            }
        case .showNavigation:
            invokeCommand?(.switchMenusVisibility)
        case .orientationOrModeChange(let isIPhoneLandscape, let isSpeakerMode):
            if isIPhoneLandscape && isSpeakerMode {
                invokeCommand?(
                    .configureSpeakerView(
                        isSpeakerMode: isSpeakerMode,
                        leadingAndTrailingConstraint: 180,
                        topConstraint: 0,
                        bottomConstraint: 0
                    )
                )
            } else if !isIPhoneLandscape && isSpeakerMode {
                invokeCommand?(
                    .configureSpeakerView(
                        isSpeakerMode: isSpeakerMode,
                        leadingAndTrailingConstraint: 0,
                        topConstraint: 160,
                        bottomConstraint: 200
                    )
                )
            } else {
                invokeCommand?(
                    .configureSpeakerView(
                        isSpeakerMode: isSpeakerMode,
                        leadingAndTrailingConstraint: 0,
                        topConstraint: 0,
                        bottomConstraint: 0
                    )
                )
            }
        case .onOrientationChanged:
            updateLayoutModeAccordingScreenSharingParticipant()
        case .switchCamera:
            Task {
                await cameraSwitcher.switchCamera()
            }
        case .shareLinkTapped(let sender):
            containerViewModel?.dispatch(.shareLinkTapped(sender))
        case .copyLinkTapped:
            containerViewModel?.dispatch(.copyLinkTapped)
        case .inviteParticipantsTapped:
            containerViewModel?.dispatch(.inviteParticipantsTapped)
        }
    }
    
    var cameraAndShareButtonsInNavBar: Bool {
        moreButtonVisibleInCallControls(
            isOneToOne: isOneToOne
        )
    }
    
    var showRightNavBarItems: Bool {
        !isOneToOne
    }
    
    var floatingPanelShown: Bool {
        containerViewModel?.floatingPanelShown ?? false
    }
    
    var cameraEnabled: Bool {
        didSet {
            invokeCommand?(.enableSwitchCameraButton)
        }
    }
    
    /// Keeps sync between nav bar share link button visibility and empty call share options view. If one is visible the other one must be hidden.
    var shareLinkBarButtonHidden: Bool = false
    
    // MARK: - Private
    
    private var isOneToOne: Bool {
        chatRoom.chatType == .oneToOne
    }
    
    private func didSetSpeakerParticipant(_ speakerParticipant: CallParticipantEntity) {
        invokeCommand?(.updateSpeakerViewFor(speakerParticipant))
        containerViewModel?.dispatch(.didDisplayParticipantInMainView(speakerParticipant))
    }
    
    private func showEmptyCallMessageIfNeeded() {
        if call.numberOfParticipants == 1,
           call.participants.first == accountUseCase.currentUserHandle {
            invokeCommand?(hasParticipantJoinedBefore ? .showNoOneElseHereMessage : .showWaitingForOthersMessage)
        }
    }
    
    private func startCallEndCountDownTimer() {
        let callEndCountDownTimerStartDate = Date()
        if let timeRemainingString = self.dateComponentsFormatter.string(from: CallViewModelConstant.callEndCountDownTimerDuration) {
            invokeCommand?(.updateCallEndDurationRemainingString(timeRemainingString))
        }
        
        callEndCountDownSubscription = Timer
            .publish(every: 1.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] date in
                guard let self else { return }
                
                let timeElapsed = date.timeIntervalSince(callEndCountDownTimerStartDate)
                let timeRemaining = round(CallViewModelConstant.callEndCountDownTimerDuration - timeElapsed)
                
                if timeRemaining > 0 {
                    if let timeRemainingString = self.dateComponentsFormatter.string(from: timeRemaining) {
                        self.invokeCommand?(.updateCallEndDurationRemainingString(timeRemainingString))
                    }
                } else {
                    self.analyticsEventUseCase.sendAnalyticsEvent(.meetings(.endCallWhenEmptyCallTimeout))
                    self.tonePlayer.play(tone: .callEnded)
                    self.endCallEndCountDownTimer()
                    
                    // when ending call, CallKit decativation will interupt playing of tone.
                    // Adding a delay of 0.7 seconds so there is enough time to play the tone
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
                        self.containerViewModel?.dispatch(.removeEndCallAlertAndEndCall)
                    }
                }
            }
    }
    
    private func endCallEndCountDownTimer() {
        invokeCommand?(.removeCallEndDurationView)
        callEndCountDownSubscription?.cancel()
        callEndCountDownSubscription = nil
    }
    
    private func handlersSubsetToFetch(forHandlers handlers: [HandleEntity]) -> [HandleEntity] {
        var handlersSubset = [HandleEntity]()
        if handlers.count > 2 {
            handlersSubset.append(handlers[0])
        } else if handlers.count == 2 {
            handlersSubset = Array(handlers.prefix(2))
        } else if handlers.count == 1 {
            handlersSubset.append(contentsOf: handlers)
        }
        
        return handlersSubset
    }
    
    @MainActor
    private func handle(addedParticipantCount: Int, removedParticipantCount: Int, addedParticipantNames: [String], removedParticipantNames: [String]) {
        guard let call = callUseCase.call(for: chatRoom.chatId) else { return }
        let isOnlyMyselfRemainingInTheCall = call.numberOfParticipants == 1 && call.participants.first == accountUseCase.currentUserHandle
        
        self.invokeCommand?(
            .participantsStatusChanged(addedParticipantCount: addedParticipantCount,
                                       removedParticipantCount: removedParticipantCount,
                                       addedParticipantNames: addedParticipantNames,
                                       removedParticipantNames: removedParticipantNames,
                                       isOnlyMyselfRemainingInTheCall: isOnlyMyselfRemainingInTheCall)
        )
    }
    
    private func updateVisibleParticipants(for visibleIndex: [Int]) {
        indexOfVisibleParticipants.forEach {
            if !visibleIndex.contains($0),
               let participant = callParticipants[safe: $0] {
                if participant.video == .on &&
                    participant.speakerVideoDataDelegate == nil &&
                    !participant.isScreenShareCell &&
                    !remoteVideoUseCase.isNotReceivingBothBothHighAndLowResVideo(for: participant) {
                    stopVideoForParticipant(participant)
                }
            }
        }
        indexOfVisibleParticipants = visibleIndex
    }
    
    private func stopVideoForParticipant(_ participant: CallParticipantEntity) {
        if participant.isReceivingLowResVideo {
            stopRemoteVideo(for: participant, isHiRes: false)
        }
        if participant.isReceivingHiResVideo {
            stopRemoteVideo(for: participant, isHiRes: true)
        }
    }
    
    func tappedParticipant(_ participant: CallParticipantEntity) {
        if speakerParticipant == participant && participant.hasScreenShare {
            containerViewModel?.dispatch(.showScreenShareWarning)
        } else if !isSpeakerParticipantPinned || (isSpeakerParticipantPinned && speakerParticipant != participant) {
            updateScreenShareAndCameraVideoForNewSpeaker(participant)
            assignSpeakerParticipant(participant)
        } else {
            participant.isSpeakerPinned = false
            isSpeakerParticipantPinned = false
            speakerParticipant = nil
            reloadParticipantWithChanges(participant)
        }
    }
    
    private func updateScreenShareAndCameraVideoForNewSpeaker(_ newSpeakerParticipant: CallParticipantEntity) {
        // Update screen share and camera video for old speaker
        if let currentSpeaker = speakerParticipant,
           currentSpeaker != newSpeakerParticipant,
           currentSpeaker.video == .on {
            if currentSpeaker.hasScreenShare {
                configScreenShareForNonSpeaker(currentSpeaker)
            } else {
                configCameraVideoForNonSpeaker(currentSpeaker)
            }
        }
        // Update screen share and camera video for new speaker
        if newSpeakerParticipant.video == .on {
            if newSpeakerParticipant.hasScreenShare {
                configScreenShareVideoForSpeaker(newSpeakerParticipant)
            } else {
                configCameraVideoForSpeaker(newSpeakerParticipant)
            }
        }
    }
    
    private func configScreenShareVideoForSpeaker(_ participant: CallParticipantEntity) {
        guard participant.hasScreenShare else { return }
        if !participant.hasCamera && remoteVideoUseCase.isOnlyReceivingLowResVideo(for: participant) {
            switchVideoResolutionLowToHigh(for: participant, in: chatRoom.chatId)
        } else if participant.hasCamera && !remoteVideoUseCase.isReceivingBothHighAndLowResVideo(for: participant) {
            requestRemoteScreenShareVideo(for: participant)
        }
    }
    
    private func configCameraVideoForSpeaker(_ participant: CallParticipantEntity) {
        guard !participant.hasScreenShare && participant.hasCamera else { return }
        if remoteVideoUseCase.isReceivingBothHighAndLowResVideo(for: participant) {
            stopRemoteVideo(for: participant, isHiRes: false)
        } else if remoteVideoUseCase.isOnlyReceivingLowResVideo(for: participant) {
            switchVideoResolutionLowToHigh(for: participant, in: chatRoom.chatId)
        } else if remoteVideoUseCase.isNotReceivingBothBothHighAndLowResVideo(for: participant) {
            enableRemoteVideo(for: participant)
        }
    }
    
    private func configScreenShareForNonSpeaker(_ participant: CallParticipantEntity) {
        guard participant.hasScreenShare else { return }
        if participant.hasCamera {
            if !remoteVideoUseCase.isReceivingBothHighAndLowResVideo(for: participant) {
                requestRemoteScreenShareVideo(for: participant)
            }
        } else {
            if remoteVideoUseCase.isReceivingBothHighAndLowResVideo(for: participant) {
                stopRemoteVideo(for: participant, isHiRes: true)
            } else if remoteVideoUseCase.isNotReceivingBothBothHighAndLowResVideo(for: participant) {
                requestRemoteScreenShareVideo(for: participant)
            }
        }
    }
    
    private func configCameraVideoForNonSpeaker(_ participant: CallParticipantEntity) {
        guard !participant.hasScreenShare && participant.hasCamera else { return }
        if remoteVideoUseCase.isReceivingBothHighAndLowResVideo(for: participant) {
            stopRemoteVideo(for: participant, isHiRes: true)
        } else if remoteVideoUseCase.isNotReceivingBothBothHighAndLowResVideo(for: participant) {
            enableRemoteVideo(for: participant)
        } else if remoteVideoUseCase.isOnlyReceivingHighResVideo(for: participant) {
            switchVideoResolutionHighToLow(for: participant, in: chatRoom.chatId)
        }
    }
    
    private func assignSpeakerParticipant(_ participant: CallParticipantEntity) {
        guard let newSpeakerParticipant = participantToUpdate(from: participant) else { return }
        isSpeakerParticipantPinned = true
        speakerParticipant?.isSpeakerPinned = false
        newSpeakerParticipant.isSpeakerPinned = true
        if speakerParticipant != newSpeakerParticipant {
            if let speakerParticipant {
                speakerParticipant.speakerVideoDataDelegate = nil
                reloadParticipant(speakerParticipant)
            }
            speakerParticipant = newSpeakerParticipant
            if newSpeakerParticipant.hasScreenShare && callParticipants.first != newSpeakerParticipant {
                moveScreenShareParticipantToMainView(participant)
            }
        } else {
            didSetSpeakerParticipant(newSpeakerParticipant)
        }
        reloadParticipant(newSpeakerParticipant)
        configScreenShareAndCameraFeedParticipants()
    }
    
    private func moveScreenShareParticipantToMainView(_ participant: CallParticipantEntity) {
        guard participant.hasScreenShare,
              let index = callParticipants.firstIndex(where: {$0 == participant && !$0.isScreenShareCell}) else { return }
        callParticipants.move(at: index, to: 0)
    }
    
    private func pinParticipantAsSpeaker(_ participant: CallParticipantEntity) {
        if layoutMode == .grid {
            switchLayout()
        }
        
        guard let participantIndex = callParticipants.firstIndex(of: participant) else {
            assert(true, "participant not found")
            MEGALogError("Participant not found \(participant) in the list")
            return
        }
        
        tappedParticipant(callParticipants[participantIndex])
    }
    
    private func switchVideoResolutionHighToLow(for participant: CallParticipantEntity, in chatId: HandleEntity) {
        let clientId = participant.clientId
        remoteVideoUseCase.stopHighResolutionVideo(for: chatId, clientId: clientId) { [weak self] result in
            guard let self, case .success = result else { return }
            onStopVideoReceiving(for: clientId, isHiRes: true)
            if participant.isVideoLowRes && participant.canReceiveVideoLowRes {
                remoteVideoUseCase.enableRemoteVideo(for: participant, isHiRes: false)
            } else {
                remoteVideoUseCase.requestLowResolutionVideos(for: chatRoom.chatId, clientId: clientId, completion: nil)
            }
        }
    }
    
    private func switchVideoResolutionLowToHigh(for participant: CallParticipantEntity, in chatId: HandleEntity) {
        let clientId = participant.clientId
        remoteVideoUseCase.stopLowResolutionVideo(for: chatId, clientId: clientId) { [weak self] result in
            guard let self, case .success = result else { return }
            onStopVideoReceiving(for: clientId, isHiRes: false)
            if participant.isVideoHiRes && participant.canReceiveVideoHiRes {
                remoteVideoUseCase.enableRemoteVideo(for: participant, isHiRes: true)
            } else {
                remoteVideoUseCase.requestHighResolutionVideo(for: chatRoom.chatId, clientId: clientId, completion: nil)
            }
        }
    }
    
    private func cancelReconnecting1on1Subscription() {
        reconnecting1on1Subscription?.cancel()
        reconnecting1on1Subscription = nil
    }
    
    private func waitForRecoverable1on1Call() {
        
        reconnecting1on1Subscription = Just(Void.self)
            .delay(for: .seconds(10), scheduler: RunLoop.main)
            .sink { [weak self] _ in
                guard let self else { return }
                self.tonePlayer.play(tone: .callEnded)
                self.reconnecting1on1Subscription = nil
                self.callTerminated(self.call)
                self.containerViewModel?.dispatch(.dismissCall(completion: nil))
            }
    }
    
    private func requestAvatarChanges(forParticipants participants: [CallParticipantEntity], chatId: HandleEntity) {
        avatarChangeSubscription?.cancel()
        avatarRefetchTasks?.forEach { $0.cancel() }
        
        avatarChangeSubscription = userImageUseCase
            .requestAvatarChangeNotification(forUserHandles: participants.map(\.participantId))
            .sink { error in
                MEGALogError("error fetching the changed avatar \(error)")
            } receiveValue: { [weak self] handles in
                guard let self else { return }
                self.avatarRefetchTasks = handles.map {
                    self.createRefetchAvatarTask(forHandle: $0, chatId: chatId)
                }
            }
    }
    
    private func createRefetchAvatarTask(forHandle handle: HandleEntity, chatId: HandleEntity) -> Task<Void, Never> {
        Task { [weak self] in
            guard let self, let chatRoom = self.chatRoomUseCase.chatRoom(forChatId: chatId) else { return }
            
            do {
                guard let name = try await self.chatRoomUserUseCase.userDisplayNames(forPeerIds: [handle], in: chatRoom).first else {
                    MEGALogError("Unable to find the name for handle \(handle)")
                    return
                }
                
                guard let base64Handle = self.megaHandleUseCase.base64Handle(forUserHandle: handle) else { return }
                
                userImageUseCase.clearAvatarCache(base64Handle: base64Handle)
                
                if let avatarBackgroundHexColor = MEGASdk.avatarColor(forBase64UserHandle: base64Handle) {
                    let avatarHandler = UserAvatarHandler(
                        userImageUseCase: userImageUseCase,
                        initials: name.initialForAvatar(),
                        avatarBackgroundColor: UIColor.colorFromHexString(avatarBackgroundHexColor) ?? UIColor.black000000
                    )
                    let image = await avatarHandler.avatar(for: base64Handle)
                    updateAvatar(handle: handle, image: image)
                }
            } catch {
                MEGALogDebug("Failed to fetch avatar for \(handle) with \(error)")
            }
        }
    }
    
    @MainActor
    private func updateAvatar(handle: HandleEntity, image: UIImage) {
        
        if handle == myself.participantId {
            invokeCommand?(.updateMyAvatar(image))
        } else {
            if let participant = callParticipants.first(where: { $0.participantId == handle && !$0.isScreenShareCell }) {
                invokeCommand?(.updateAvatar(image, participant))
            }
        }
    }
    
    private func updateLayoutModeAccordingScreenSharingParticipant() {
        let previousLayoutMode = layoutMode
        let newHasScreenSharingParticipant = callParticipants.contains { $0.hasScreenShare }
        let shouldChangeToThumbnailView = hasScreenSharingParticipant && !newHasScreenSharingParticipant
        hasScreenSharingParticipant = newHasScreenSharingParticipant
        
        if hasScreenSharingParticipant {
            layoutMode = .speaker
        } else if shouldChangeToThumbnailView {
            layoutMode = .grid
        }
        let shouldUpdateLayout = previousLayoutMode != layoutMode
        if shouldUpdateLayout {
            invokeCommand?(.switchLayoutMode(layout: layoutMode, participantsCount: callParticipants.count))
        }
        invokeCommand?(.disableSwitchLayoutModeButton(disable: hasScreenSharingParticipant))
    }
    
    private func configScreenShareAndCameraFeedParticipants() {
        var newParticipants = [CallParticipantEntity]()
        let cameraParticipants = callParticipants.filter { !$0.isScreenShareCell}
        let screenShareParticipants = callParticipants.filter { $0.isScreenShareCell}
        for callParticipant in cameraParticipants {
            if let firstParticipant = cameraParticipants.first, callParticipant == firstParticipant {
                if callParticipant.hasScreenShare,
                   let speakerParticipant,
                   callParticipant != speakerParticipant &&
                    !speakerParticipant.hasScreenShare {
                    if let screenShareParticipant = firstCallParticipant(callParticipant, in: screenShareParticipants) {
                        newParticipants.append(screenShareParticipant)
                    } else {
                        let screenShareParticipant = CallParticipantEntity.createScreenShareParticipant(callParticipant)
                        newParticipants.append(screenShareParticipant)
                    }
                }
                newParticipants.append(callParticipant)
            } else if callParticipant.hasScreenShare {
                if let screenShareParticipant = firstCallParticipant(callParticipant, in: screenShareParticipants) {
                    newParticipants.append(screenShareParticipant)
                } else {
                    let screenShareParticipant = CallParticipantEntity.createScreenShareParticipant(callParticipant)
                    newParticipants.append(screenShareParticipant)
                }
                newParticipants.append(callParticipant)
            } else {
                newParticipants.append(callParticipant)
            }
        }
        callParticipants = newParticipants
        invokeCommand?(.updateParticipants(callParticipants))
        updateLayoutModeAccordingScreenSharingParticipant()
    }
    
    private func firstCallParticipant(
        _ participant: CallParticipantEntity,
        in callParticipants: [CallParticipantEntity],
        shouldCheckScreenShareCell: Bool = false
    ) -> CallParticipantEntity? {
        if shouldCheckScreenShareCell {
            return callParticipants.first(where: {$0 == participant && $0.isScreenShareCell == participant.isScreenShareCell})
        } else {
            return callParticipants.first(where: {$0 == participant})
        }
    }
    
    private func updateActiveSpeakIndicator(for participant: CallParticipantEntity) {
        if isSpeakerParticipantPinned && speakerParticipant == participant {
            participant.isSpeakerPinned = true
            invokeCommand?(.updateSpeakerMic(audioEnabled: participant.audio == .on, audioDetected: participant.audioDetected))
        }
        guard let participantToUpdate = participantToUpdate(from: participant) else {
            return
        }
        participantToUpdate.audioDetected = participant.audioDetected
        updateParticipantAudioLevel(participant)
    }
    
    private func onViewLoaded() {
        if let updatedCall = callUseCase.call(for: chatRoom.chatId) {
            call = updatedCall
        }
        if chatRoom.chatType == .meeting {
            invokeCommand?(
                .configView(title: chatRoom.title ?? "",
                            subtitle: "",
                            isUserAGuest: accountUseCase.isGuest,
                            isOneToOne: false)
            )
            initTimerIfNeeded(with: Int(call.duration))
        } else {
            invokeCommand?(
                .configView(title: chatRoom.title ?? "",
                            subtitle: initialSubtitle(),
                            isUserAGuest: accountUseCase.isGuest,
                            isOneToOne: isOneToOne)
            )
        }
        
        monitorOnCallUpdate()
        monitorOnSessionUpdate()
        monitorOnChatRoomUpdate()
        
        remoteVideoUseCase.addRemoteVideoListener(self)
        if isActiveCall() {
            call.clientSessions.forEach {
                let participant = participantForSession($0)
                participantJoined(participant: participant)
            }
        } else {
            if (chatRoom.chatType == .meeting || chatRoom.chatType == .group) && (call.numberOfParticipants == 0 || call.numberOfParticipants == 1 && call.status == .inProgress) {
                invokeCommand?(.showWaitingForOthersMessage)
                showEmptyCallShareOptionsViewIfNeeded()
            }
        }
        localAvFlagsUpdated(video: call.hasLocalVideo, audio: call.hasLocalAudio)
        if !isOneToOne {
            addMeetingParticipantStatusPipelineSubscription()
        }
        hasBeenInProgress = call.status == .inProgress
        invokeCommand?(.updateBarButtons)
    }
    
    private func participantForSession(_ session: ChatSessionEntity) -> CallParticipantEntity {
        CallParticipantEntity(
            session: session,
            chatRoom: chatRoom,
            privilege: chatRoomUseCase.peerPrivilege(forUserHandle: session.peerId, chatRoom: chatRoom),
            raisedHand: call.raiseHandsList.contains(session.peerId)
        )
    }
    
    // MARK: Raise hand
    
    private func callRaiseHandChanged(for call: CallEntity) {
        let updater = RaiseHandUpdater(
            snackBarFactory: RaiseHandSnackBarFactory(
                viewRaisedHandsHandler: viewRaisedHands,
                lowerHandHandler: lowerRaisedHand
            ),
            updateLocalRaiseHand: {[weak self] hidden in
                self?.invokeCommand?(.updateLocalRaisedHandHidden(hidden))
            },
            stateUpdater: {[weak self]  index, change in
                guard let self else { return }
                callParticipants[index].raisedHand = change.raisedHand
                invokeCommand?(.updateParticipantRaisedHandAt(index, callParticipants[index]))
            },
            snackBarUpdater: {[weak self] snackBar in
                self?.invokeCommand?(.updateSnackBar(snackBar))
            }
        )
        
        updater.update(
            callParticipants: callParticipants,
            raiseHandListBefore: currentRaiseHandHandles,
            raiseHandListAfter: call.raiseHandsList,
            localUserHandle: chatUseCase.myUserHandle()
        )
        
        currentRaiseHandHandles = call.raiseHandsList
    }
    
    private func viewRaisedHands() {
        showParticipantList()
    }
    
    private func showParticipantList() {
        // we show menus if needed (navbar, drawer etc)
        invokeCommand?(.switchMenusVisibilityToShownIfNeeded)
        // and then transition to long form of navbar to show list of participants,
        // we also switch to "in-call" tab in the floating drawer
        containerViewModel?.dispatch(.transitionToLongForm)
    }
    
    private func lowerRaisedHand() {
        Task {
            do {
                try await self.callUseCase.lowerHand(forCall: call)
            } catch {
                MEGALogError("[RaiseHand] lowering hand failed \(error)")
            }
        }
    }
    
    // MARK: Call end/destroyed
    
    /// Call will end alert is shown for moderators and countdown for all participants.
    /// Both can not be shown at same time, so countdown is presented for moderators when they choose one action in the alert.
    /// For non moderators, countdown is showed directly.
    private func manageCallWillEnd(for call: CallEntity) {
        let timeToEndCall = Date(timeIntervalSince1970: TimeInterval(call.callWillEndTimestamp)).timeIntervalSinceNow
        showCallWillEndNotification(timeToEndCall: timeToEndCall)
    }
    
    private func showCallWillEndNotification(timeToEndCall: Double) {
        callWillEndCountDown = timeToEndCall
        
        invokeCommand?(.showCallWillEnd(timeToEndCall.timeString))
        startCallWillEndTimer()
    }
    
    private func startCallWillEndTimer() {
        callWillEndTimer?.invalidate()
        callWillEndTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true, block: { [weak self] _ in
            guard let self else { return }
            callWillEndCountDown -= 1
            guard callWillEndCountDown >= 0 else { return }
            invokeCommand?(.updateCallWillEnd(TimeInterval(callWillEndCountDown).timeString))
        })
    }
    
    private func showCallWillEndNotificationIfNeeded() {
        if call.callWillEndTimestamp > 0 {
            let timeToEndCall = Date(timeIntervalSince1970: TimeInterval(call.callWillEndTimestamp)).timeIntervalSinceNow
            showCallWillEndNotification(timeToEndCall: timeToEndCall)
        }
    }
    
    // MARK: Invite participants
    
    private func showEmptyCallShareOptionsViewIfNeeded() {
        if !isOneToOne && call.numberOfParticipants <= 1 && !hasParticipantJoinedBefore {
            shareLinkBarButtonHidden = true
            invokeCommand?(.showEmptyCallShareOptionsView(canInviteParticipants: canInviteParticipants))
        }
    }
    
    private var canInviteParticipants: Bool {
        (chatRoom.ownPrivilege == .moderator || chatRoom.isOpenInviteEnabled) &&
        chatRoom.chatType != .oneToOne &&
        !accountUseCase.isGuest
    }
    
    private func removeEmptyCallShareOptionsViewIfNeeded() {
        if !isOneToOne && !hasParticipantJoinedBefore {
            shareLinkBarButtonHidden = false
            invokeCommand?(.removeEmptyCallShareOptionsView)
            invokeCommand?(.updateBarButtons)
        }
    }
}

struct CallDurationInfo {
    let initDuration: Int
    let baseDate: Date
}

// MARK: - On Call Update

extension MeetingParticipantsLayoutViewModel {
    func monitorOnCallUpdate() {
        let callUpdates = callUpdateUseCase.monitorOnCallUpdate()
        Task { [weak self] in
            for await call in callUpdates {
                self?.onCallUpdate(call)
            }
        }
    }

    private func onCallUpdate(_ call: CallEntity) {
        self.call = call
        switch call.changeType {
        case .callWillEnd:
            manageCallWillEnd(for: call)
        case .localAVFlags:
            cameraEnabled = call.hasLocalVideo
            if call.auxHandle != .invalid {
                mutedByClient(handle: call.auxHandle)
            }
            localAvFlagsUpdated(video: call.hasLocalVideo, audio: call.hasLocalAudio)
        case .networkQuality:
            networkQualityChanged(call.networkQuality)
        case .outgoingRingingStop:
            outgoingRingingStopReceived(call)
        case .status:
            switch call.status {
            case .connecting:
                connecting()
            case .inProgress:
                inProgress()
            case .terminatingUserParticipation, .destroyed:
                callTerminated(call)
            default:
                break
            }
        case .callComposition:
            guard call.peeridCallCompositionChange != accountUseCase.currentUserHandle && call.status == .inProgress else {
                return
            }
            switch call.callCompositionChange {
            case .peerRemoved:
                participantRemoved(with: call.peeridCallCompositionChange)
            case .peerAdded:
                participantAdded(with: call.peeridCallCompositionChange)
            default:
                break
            }
        case .callRaiseHand:
            debouncer.start { @MainActor [weak self] in
                self?.callRaiseHandChanged(for: call)
            }
        default:
            break
        }
    }
    
    private func callTerminated(_ call: CallEntity) {
        timer?.invalidate()
        callWillEndTimer?.invalidate()
        if reconnecting {
            tonePlayer.play(tone: .callEnded)
            containerViewModel?.dispatch(.dismissCall(completion: {
                SVProgressHUD.showError(withStatus: Strings.Localizable.Meetings.Reconnecting.failed)
            }))
        }
    }
    
    private func participantAdded(with handle: HandleEntity) {
        meetingParticipantStatusPipeline.addParticipant(withHandle: handle)
        containerViewModel?.dispatch(.participantAdded)
    }
    
    private func participantRemoved(with handle: HandleEntity) {
        meetingParticipantStatusPipeline.removeParticipant(withHandle: handle)
        containerViewModel?.dispatch(.participantRemoved)
    }
    
    private func connecting() {
        guard hasBeenInProgress else { return }
        if !reconnecting {
            reconnecting = true
            tonePlayer.play(tone: .reconnecting)
            invokeCommand?(.reconnecting)
            invokeCommand?(.hideEmptyRoomMessage)
        }
    }
    
    private func inProgress() {
        hasBeenInProgress = true
        if reconnecting {
            invokeCommand?(.reconnected)
            reconnecting = false
            if callParticipants.isEmpty {
                invokeCommand?(.showNoOneElseHereMessage)
            }
        }
    }
    
    private func localAvFlagsUpdated(video: Bool, audio: Bool) {
        if localVideoEnabled != video {
            if localVideoEnabled {
                localVideoUseCase.removeLocalVideo(for: chatRoom.chatId, callbacksDelegate: self)
            } else {
                localVideoUseCase.addLocalVideo(for: chatRoom.chatId, callbacksDelegate: self)
            }
            localVideoEnabled = video
            invokeCommand?(.switchLocalVideo(localVideoEnabled))
        }
        invokeCommand?(.updateHasLocalAudio(audio))
    }
    
    private func networkQualityChanged(_ quality: NetworkQuality) {
        switch quality {
        case .bad:
            invokeCommand?(.showBadNetworkQuality)
        case .good:
            invokeCommand?(.hideBadNetworkQuality)
        }
    }
    
    private func outgoingRingingStopReceived(_ call: CallEntity) {
        if isOneToOne && call.numberOfParticipants == 1 {
            callManager.endCall(in: chatRoom, endForAll: false)
            self.tonePlayer.play(tone: .callEnded)
        }
    }
    
    private func mutedByClient(handle: HandleEntity) {
        guard let participant = callParticipants.first(where: { $0.clientId == handle }), let name = participant.name else {
            return
        }
        containerViewModel?.dispatch(.showMutedBy(name))
    }
}

// MARK: - On Chat Room Update

extension MeetingParticipantsLayoutViewModel {
    func monitorOnChatRoomUpdate() {
        let chatRoomUpdates = chatRoomUpdateUseCase.monitorOnChatRoomUpdate()
        Task { [weak self] in
            for await chatRoom in chatRoomUpdates {
                self?.onChatRoomUpdate(chatRoom)
            }
        }
    }
    
    private func onChatRoomUpdate(_ chatRoom: ChatRoomEntity) {
        self.chatRoom = chatRoom
        switch chatRoom.changeType {
        case .ownPrivilege:
            ownPrivilegeUpdated()
        case .title:
            chatTitleUpdated()
        default:
            break
        }
    }
    
    private func ownPrivilegeUpdated() {
        if chatRoom.ownPrivilege == .moderator {
            invokeCommand?(.ownPrivilegeChangedToModerator)
        }
    }
    
    private func chatTitleUpdated() {
        guard let title = chatRoom.title else { return }
        invokeCommand?(.updateName(title))
    }
}

// MARK: - Session Update

extension MeetingParticipantsLayoutViewModel {
    func monitorOnSessionUpdate() {
        let sessionUpdates = sessionUpdateUseCase.monitorOnSessionUpdate()
        Task { [weak self] in
            for await session in sessionUpdates {
                self?.onSessionUpdate(session)
            }
        }
    }
    
    private func onSessionUpdate(_ session: ChatSessionEntity) {
        let participant = participantForSession(session)
        switch session.changeType {
        case .status:
            switch session.statusType {
            case .inProgress:
                participantJoined(participant: participant)
            case .destroyed:
                participantLeft(participant: participant)
            default:
                break
            }
        case .remoteAvFlags:
            updateParticipant(participant)
        case .audioLevel:
            audioLevel(for: participant)
        case .onHiRes:
            highResolutionChanged(for: participant)
        case .onLowRes:
            lowResolutionChanged(for: participant)
        case .onRecording:
            invokeCommand?(.hideRecording(!session.onRecording))
        default:
            break
        }
    }

    func participantJoined(participant: CallParticipantEntity) {
        removeEmptyCallShareOptionsViewIfNeeded()
        self.hasParticipantJoinedBefore = true
        if isOneToOne && reconnecting1on1Subscription != nil {
            cancelReconnecting1on1Subscription()
        }
        initTimerIfNeeded(with: Int(call.duration))
        if participant.hasScreenShare {
            callParticipants.insert(participant, at: 0)
        } else {
            callParticipants.append(participant)
        }
        configScreenShareAndCameraFeedParticipants()
        participantName(for: participant.participantId) { [weak self] in
            guard let self,
                  let call = callUseCase.call(for: chatRoom.chatId)
            else {
                MEGALogDebug("Error getting call when participant joined")
                return
            }
            participant.name = $0
            participant.raisedHand = call.raiseHandsList.contains(participant.participantId)
            reloadParticipantWithChanges(participant)
            invokeCommand?(.updateParticipants(callParticipants))
            if callParticipants.count == 1 && layoutMode == .speaker {
                invokeCommand?(.shouldHideSpeakerView(false))
                speakerParticipant = participant
            }
            if speakerParticipant == participant {
                invokeCommand?(.updateSpeakerViewFor(participant))
            }
            if layoutMode == .grid {
                invokeCommand?(.updatePageControl(callParticipants.count))
            }
            invokeCommand?(.hideEmptyRoomMessage)
            if participant.isRecording {
                invokeCommand?(.hideRecording(!participant.isRecording))
            }
        }
    }
    
    func participantLeft(participant: CallParticipantEntity) {
        if callUseCase.call(for: call.chatId) == nil {
            callTerminated(call)
        } else if callParticipants.contains(where: { $0 == participant }) {
            if isOneToOne && participant.sessionRecoverable {
                waitForRecoverable1on1Call()
            }
            callParticipants.removeAll { $0 == participant}
            updateLayoutModeAccordingScreenSharingParticipant()
            invokeCommand?(.updateParticipants(callParticipants))
            stopVideoForParticipant(participant)
            
            if callParticipants.isEmpty {
                if chatRoom.chatType == .meeting && !reconnecting && call.status == .inProgress {
                    invokeCommand?(.showNoOneElseHereMessage)
                }
                if layoutMode == .speaker {
                    invokeCommand?(.shouldHideSpeakerView(true))
                }
            }
            
            if layoutMode == .grid {
                invokeCommand?(.updatePageControl(callParticipants.count))
            }
            
            guard let currentSpeaker = speakerParticipant, currentSpeaker == participant else {
                return
            }
            isSpeakerParticipantPinned = false
            speakerParticipant = callParticipants.first
        } else {
            MEGALogError("Error removing participant from call")
        }
    }
    
    func updateParticipant(_ participant: CallParticipantEntity) {
        guard let participantToUpdate = participantToUpdate(from: participant) else {
            return
        }
        
        if participant.audio != participantToUpdate.audio {
            participantToUpdate.audio = participant.audio
            updateParticipantMic(participant)
            updateSpeakerMicIfNeeded(participantToUpdate)
        }
        
        if participant.video != participantToUpdate.video ||
            participantToUpdate.hasScreenShare != participant.hasScreenShare ||
            participant.hasCamera != participantToUpdate.hasCamera {
            reloadParticipantWithChanges(participant)
        }
    }
    
    private func reloadParticipantWithChanges(_ participant: CallParticipantEntity) {
        guard let participantToUpdate = participantToUpdate(from: participant) else {
            return
        }
        
        let onStartScreenShare = !participantToUpdate.hasScreenShare && participant.hasScreenShare
        let onStopScreenShare = participantToUpdate.hasScreenShare && !participant.hasScreenShare
        
        for callParticipant in callParticipants where callParticipant == participant {
            callParticipant.video = participant.video
            callParticipant.audio = participant.audio
            callParticipant.isVideoLowRes = participant.isVideoLowRes
            callParticipant.isVideoHiRes = participant.isVideoHiRes
            callParticipant.hasCamera = participant.hasCamera
            callParticipant.isLowResCamera = participant.isLowResCamera
            callParticipant.isHiResCamera = participant.isHiResCamera
            callParticipant.hasScreenShare = participant.hasScreenShare
            callParticipant.isLowResScreenShare = participant.isLowResScreenShare
            callParticipant.isHiResScreenShare = participant.isHiResScreenShare
            callParticipant.audioDetected = participant.audioDetected
            callParticipant.raisedHand = participantToUpdate.raisedHand
        }
        
        if onStartScreenShare {
            updateScreenShareAndCameraVideoForNewSpeaker(participantToUpdate)
            assignSpeakerParticipant(participantToUpdate)
        } else if onStopScreenShare {
            updateSpeakerOnStopScreenShare(of: participantToUpdate)
        }
        
        configScreenShareAndCameraFeedParticipants()
        reloadParticipant(participant)
        reloadSpeakerIfNeeded(participantToUpdate)
    }
    
    private func updateSpeakerOnStopScreenShare(of participant: CallParticipantEntity) {
        guard let speakerParticipant,
              speakerParticipant == participant,
              let nextScreenShareParticipant = callParticipants.first(where: {$0.hasScreenShare && !$0.isScreenShareCell}) else { return }
        configScreenShareVideoForSpeaker(nextScreenShareParticipant)
        configCameraVideoForNonSpeaker(participant)
        assignSpeakerParticipant(nextScreenShareParticipant)
    }
    
    func highResolutionChanged(for participant: CallParticipantEntity) {
        guard let participantUpdated = callParticipants.first(where: {$0 == participant}) else {
            MEGALogError("Error getting participant updated with video high resolution")
            return
        }
        
        for callParticipant in callParticipants where callParticipant == participant {
            callParticipant.canReceiveVideoHiRes = participant.canReceiveVideoHiRes
        }
        
        if participantUpdated.canReceiveVideoHiRes {
            enableRemoteVideo(for: participantUpdated)
        } else {
            disableRemoteVideo(for: participantUpdated, isHiRes: true)
        }
    }
    
    func lowResolutionChanged(for participant: CallParticipantEntity) {
        guard let participantUpdated = callParticipants.first(where: {$0 == participant}) else {
            MEGALogError("Error getting participant updated with video low resolution")
            return
        }
        
        for callParticipant in callParticipants where callParticipant == participant {
            callParticipant.canReceiveVideoLowRes = participant.canReceiveVideoLowRes
        }
        
        if participantUpdated.canReceiveVideoLowRes {
            enableRemoteVideo(for: participantUpdated)
        } else {
            disableRemoteVideo(for: participantUpdated, isHiRes: false)
        }
    }
    
    func audioLevel(for participant: CallParticipantEntity) {
        updateActiveSpeakIndicator(for: participant)
        
        if isSpeakerParticipantPinned || layoutMode == .grid {
            return
        }
        guard let participantWithAudio = participantToUpdate(from: participant) else {
            MEGALogError("Error getting participant with audio")
            return
        }
        
        participantWithAudio.audioDetected = participant.audioDetected
        if let currentSpeaker = speakerParticipant {
            if currentSpeaker != participantWithAudio {
                speakerParticipant = participantWithAudio
                if currentSpeaker.video == .on && currentSpeaker.isVideoHiRes && currentSpeaker.canReceiveVideoHiRes {
                    switchVideoResolutionHighToLow(for: currentSpeaker, in: chatRoom.chatId)
                }
                if participantWithAudio.video == .on && participantWithAudio.isVideoLowRes && participantWithAudio.canReceiveVideoLowRes {
                    switchVideoResolutionLowToHigh(for: participantWithAudio, in: chatRoom.chatId)
                }
            } else {
                invokeCommand?(.updateSpeakerViewFor(currentSpeaker))
            }
        } else {
            speakerParticipant = participantWithAudio
            if participantWithAudio.video == .on && participantWithAudio.canReceiveVideoLowRes {
                switchVideoResolutionLowToHigh(for: participantWithAudio, in: chatRoom.chatId)
            }
        }
    }
}

// MARK: - CallLocalVideoCallbacksUseCaseProtocol

extension MeetingParticipantsLayoutViewModel: CallLocalVideoCallbacksUseCaseProtocol {
    func localVideoFrameData(width: Int, height: Int, buffer: Data) {
        invokeCommand?(.localVideoFrame(width, height, buffer))
        
        if switchingCamera {
            switchingCamera = false
            invokeCommand?(.updatedCameraPosition)
        }
    }
    
    func localVideoChangedCameraPosition() {
        switchingCamera = true
        invokeCommand?(.updateCameraPositionTo(position: isBackCameraSelected() ? .back : .front))
    }
}

// MARK: - CallRemoteVideoListenerUseCaseProtocol

extension MeetingParticipantsLayoutViewModel: CallRemoteVideoListenerUseCaseProtocol {
    func remoteVideoFrameData(clientId: HandleEntity, width: Int, height: Int, buffer: Data, isHiRes: Bool) {
        for participant in callParticipants where participant.clientId == clientId {
            if participant.videoDataDelegate == nil {
                guard let index = index(for: participant) else { return }
                invokeCommand?(.reloadParticipantAt(index, callParticipants))
            }
            participant.remoteVideoFrame(width: width, height: height, buffer: buffer, isHiRes: isHiRes)
        }
    }
}

/// This function is shared logic and it controls the UI layout
/// It's related to Raise hand feature (which is available only for not 1:1 calls)  [MEET-2491]
/// When feature is active, CallControls has more button (instead of Switch Camera button)
/// For this reason, switch camera button has to go to the nav bar (together with share meeting link button)
/// Rename meeting [change it's title] button is NOT shown in call UI when Raise Hand feature is active.
/// Logic to decide this layout was refactored into the function below, so that it's always in sync, in all the places, it's taken into account.
func moreButtonVisibleInCallControls(
    isOneToOne: Bool
) -> Bool {
    !isOneToOne
}
