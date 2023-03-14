import Combine
import Foundation
import MEGADomain
import MEGAPresentation

enum CallViewAction: ActionType {
    case onViewLoaded
    case onViewReady
    case tapOnView(onParticipantsView: Bool)
    case tapOnLayoutModeButton
    case tapOnOptionsMenuButton(presenter: UIViewController, sender: UIBarButtonItem)
    case tapOnBackButton
    case switchIphoneOrientation(_ orientation: DeviceOrientation)
    case showRenameChatAlert
    case setNewTitle(String)
    case discardChangeTitle
    case renameTitleDidChange(String)
    case tapParticipantToPinAsSpeaker(CallParticipantEntity, IndexPath)
    case fetchAvatar(participant: CallParticipantEntity)
    case fetchSpeakerAvatar
    case particpantIsVisible(_ participant: CallParticipantEntity, index: Int)
    case indexVisibleParticipants([Int])
    case pinParticipantAsSpeaker(CallParticipantEntity)
    case addParticipant(withHandle: HandleEntity)
    case removeParticipant(withHandle: HandleEntity)
    case startCallEndCountDownTimer
    case endCallEndCountDownTimer
    case didEndDisplayLastPeerLeftStatusMessage
}

enum ParticipantsLayoutMode {
    case grid
    case speaker
}

enum DeviceOrientation {
    case landscape
    case portrait
}

private enum CallViewModelConstant {
    static let maxParticipantsCountForHighResolution = 5
    static let callEndCountDownTimerDuration: TimeInterval = 120
}

final class MeetingParticipantsLayoutViewModel: NSObject, ViewModelType {
    enum Command: CommandType, Equatable {
        case configView(title: String, subtitle: String, isUserAGuest: Bool, isOneToOne: Bool)
        case configLocalUserView(position: CameraPositionEntity)
        case switchMenusVisibility
        case enableLayoutButton(Bool)
        case switchLayoutMode(layout: ParticipantsLayoutMode, participantsCount: Int)
        case switchLocalVideo(Bool)
        case updateName(String)
        case updateDuration(String)
        case updatePageControl(Int)
        case insertParticipant([CallParticipantEntity])
        case deleteParticipantAt(Int, [CallParticipantEntity])
        case reloadParticipantAt(Int, [CallParticipantEntity])
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
        case selectPinnedCellAt(IndexPath?)
        case shouldHideSpeakerView(Bool)
        case ownPrivilegeChangedToModerator
        case showBadNetworkQuality
        case hideBadNetworkQuality
        case updateAvatar(UIImage, CallParticipantEntity)
        case updateSpeakerAvatar(UIImage)
        case updateMyAvatar(UIImage)
        case updateCallEndDurationRemainingString(String)
        case removeCallEndDurationView
    }
    
    private let router: MeetingParticipantsLayoutRouting
    private var chatRoom: ChatRoomEntity
    private var call: CallEntity
    private var timer: Timer?
    private var callDurationInfo: CallDurationInfo?
    private var callParticipants = [CallParticipantEntity]() {
        didSet {
            if let myself = CallParticipantEntity.myself(chatId: call.chatId) {
                requestAvatarChanges(forParticipants: callParticipants + [myself], chatId: call.chatId)
            } else {
                requestAvatarChanges(forParticipants: callParticipants, chatId: call.chatId)
            }
        }
    }
    private var indexOfVisibleParticipants = [Int]()
    private var hasParticipantJoinedBefore = false
    private var speakerParticipant: CallParticipantEntity? {
        willSet {
            speakerParticipant?.speakerVideoDataDelegate = nil
            speakerParticipant?.isSpeakerPinned = false
        }
        didSet {
            guard let speaker = speakerParticipant else { return }
            speaker.isSpeakerPinned = true
            invokeCommand?(.updateSpeakerViewFor(speaker))
            containerViewModel?.dispatch(.didDisplayParticipantInMainView(speaker))
        }
    }
    private var isSpeakerParticipantPinned: Bool = false
    internal var layoutMode: ParticipantsLayoutMode = .grid {
        didSet {
            if layoutMode == .grid {
                isSpeakerParticipantPinned = false
                containerViewModel?.dispatch(.didSwitchToGridView)
                speakerParticipant = nil
            } else if speakerParticipant == nil {
                speakerParticipant = callParticipants.first
            }
        }
    }
    private var localVideoEnabled: Bool = false
    private var reconnecting: Bool = false
    private var switchingCamera: Bool = false
    private weak var containerViewModel: MeetingContainerViewModel?

    private let callUseCase: CallUseCaseProtocol
    private let captureDeviceUseCase: CaptureDeviceUseCaseProtocol
    private let localVideoUseCase: CallLocalVideoUseCaseProtocol
    private let remoteVideoUseCase: CallRemoteVideoUseCaseProtocol
    private let chatRoomUseCase: ChatRoomUseCaseProtocol
    private let chatRoomUserUseCase: ChatRoomUserUseCaseProtocol
    private let accountUseCase: AccountUseCaseProtocol
    private var userImageUseCase: UserImageUseCaseProtocol
    private let analyticsEventUseCase: AnalyticsEventUseCaseProtocol
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
        resetCollectionDurationUptoCount: 2
    )
    
    private let tonePlayer = TonePlayer()
    var namesFetchingTask: Task<Void, Never>?

    private var reconnecting1on1Subscription: AnyCancellable?

    // MARK: - Internal properties
    var invokeCommand: ((Command) -> Void)?
    
    init(router: MeetingParticipantsLayoutRouting,
         containerViewModel: MeetingContainerViewModel,
         callUseCase: CallUseCaseProtocol,
         captureDeviceUseCase: CaptureDeviceUseCaseProtocol,
         localVideoUseCase: CallLocalVideoUseCaseProtocol,
         remoteVideoUseCase: CallRemoteVideoUseCaseProtocol,
         chatRoomUseCase: ChatRoomUseCaseProtocol,
         chatRoomUserUseCase: ChatRoomUserUseCaseProtocol,
         accountUseCase: AccountUseCaseProtocol,
         userImageUseCase: UserImageUseCaseProtocol,
         analyticsEventUseCase: AnalyticsEventUseCaseProtocol,
         chatRoom: ChatRoomEntity,
         call: CallEntity,
         preferenceUseCase: PreferenceUseCaseProtocol = PreferenceUseCase.default) {
        
        self.router = router
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
        self.chatRoom = chatRoom
        self.call = call

        super.init()
        self.$callsSoundNotificationPreference.useCase = preferenceUseCase
    }
    
    deinit {
        cancelReconnecting1on1Subscription()
        callUseCase.stopListeningForCall()
        avatarRefetchTasks?.forEach { $0.cancel() }
    }
    
    private func initTimerIfNeeded(with duration: Int) {
        if timer == nil {
            let callDurationInfo = CallDurationInfo(initDuration: duration, baseDate: Date())
            let timer = Timer(timeInterval: 1, repeats: true, block: { [weak self] (timer) in
                let duration = Int(Date().timeIntervalSince1970) - Int(callDurationInfo.baseDate.timeIntervalSince1970) + callDurationInfo.initDuration
                self?.invokeCommand?(.updateDuration(TimeInterval(duration).timeString))
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
        MEGALogDebug("Switch meetings layout from \(layoutMode == .grid ? "grid" : "speaker") to \(layoutMode == .grid ? "speaker" : "grid")")
        callParticipants.forEach { $0.videoDataDelegate = nil }
        if layoutMode == .grid {
            layoutMode = .speaker
        } else {
            layoutMode = .grid
        }
        
        invokeCommand?(.switchLayoutMode(layout: layoutMode, participantsCount: callParticipants.count))
    }
    
    private func reloadParticipant(_ participant: CallParticipantEntity) {
        guard let index = callParticipants.firstIndex(of: participant) else { return }
        invokeCommand?(.reloadParticipantAt(index, callParticipants))
        
        guard let currentSpeaker = speakerParticipant, currentSpeaker == participant else {
            return
        }
        speakerParticipant = participant
    }
    
    private func enableRemoteVideo(for participant: CallParticipantEntity) {
        switch layoutMode {
        case .grid:
            if participant.isVideoHiRes && participant.canReceiveVideoHiRes {
                remoteVideoUseCase.enableRemoteVideo(for: participant)
            } else if participant.isVideoLowRes && participant.canReceiveVideoLowRes {
                switchVideoResolutionLowToHigh(for: participant.clientId, in: chatRoom.chatId)
            } else {
                remoteVideoUseCase.requestHighResolutionVideo(for: chatRoom.chatId, clientId: participant.clientId, completion: nil)
            }
        case .speaker:
            if participant.speakerVideoDataDelegate == nil {
                if participant.isVideoLowRes && participant.canReceiveVideoLowRes {
                    remoteVideoUseCase.enableRemoteVideo(for: participant)
                } else if participant.isVideoHiRes && participant.canReceiveVideoHiRes {
                    switchVideoResolutionHighToLow(for: participant.clientId, in: chatRoom.chatId)
                } else {
                    remoteVideoUseCase.requestLowResolutionVideos(for: chatRoom.chatId, clientId: participant.clientId, completion: nil)
                }
            } else {
                if participant.isVideoHiRes && participant.canReceiveVideoHiRes {
                    remoteVideoUseCase.enableRemoteVideo(for: participant)
                } else if participant.isVideoLowRes && participant.canReceiveVideoLowRes {
                    switchVideoResolutionLowToHigh(for: participant.clientId, in: chatRoom.chatId)
                } else {
                    remoteVideoUseCase.requestHighResolutionVideo(for: chatRoom.chatId, clientId: participant.clientId, completion: nil)
                }
            }
        }
    }
    
    private func disableRemoteVideo(for participant: CallParticipantEntity) {
        remoteVideoUseCase.disableRemoteVideo(for: participant)
    }
    
    private func fetchAvatar(for participant: CallParticipantEntity, name: String, completion: @escaping ((UIImage) -> Void)) {
        guard let base64Handle = MEGASdk.base64Handle(forUserHandle: participant.participantId),
              let avatarBackgroundHexColor = MEGASdk.avatarColor(forBase64UserHandle: base64Handle) else {
            return
        }
        
        userImageUseCase.fetchUserAvatar(withUserHandle: participant.participantId,
                                         base64Handle: base64Handle,
                                         avatarBackgroundHexColor: avatarBackgroundHexColor,
                                         name: name) { result in
            switch result {
            case .success(let image):
                completion(image)
            case .failure(_):
                MEGALogError("Error fetching avatar for participant \(MEGASdk.base64Handle(forUserHandle: participant.participantId) ?? "No name")")
            }
        }
    }
    
    private func participantName(for userHandle: HandleEntity, completion: @escaping (String?) -> Void) {
        Task { @MainActor in
            let name = try? await chatRoomUserUseCase.userDisplayName(forPeerId: userHandle, in: chatRoom)
            completion(name)
        }
    }
    
    private func isBackCameraSelected() -> Bool {
        guard let selectCameraLocalizedString = captureDeviceUseCase.wideAngleCameraLocalizedName(postion: .back),
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
                guard let self = self else { return }
                
                if self.callsSoundNotificationPreference {
                    if handlerCollectionType.removedHandlers.isEmpty == false {
                        self.tonePlayer.play(tone: .participantLeft)
                    } else if handlerCollectionType.addedHandlers.isEmpty == false {
                        self.tonePlayer.play(tone: .participantJoined)
                    }
                }
                
                self.namesFetchingTask?.cancel()
                self.namesFetchingTask = Task { [weak self,
                                                 chatRoomUserUseCase = self.chatRoomUserUseCase,
                                                 chatRoom = self.chatRoom] in
                    guard let self = self else { return }
                    
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
                        
                        await self.handle(addedParticipantCount: handlerCollectionType.addedHandlers.count,
                                          removedParticipantCount: handlerCollectionType.removedHandlers.count,
                                          addedParticipantNames: participantNamesResult[0],
                                          removedParticipantNames: participantNamesResult[1])
                    } catch {
                        MEGALogDebug("Failed to load participants name \(error)")
                    }
                }
            }
    }
    
    // MARK: - Dispatch action
    func dispatch(_ action: CallViewAction) {
        switch action {
        case .onViewLoaded:
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
                                isOneToOne: chatRoom.chatType == .oneToOne)
                )
            }
            callUseCase.startListeningForCallInChat(chatRoom.chatId, callbacksDelegate: self)
            remoteVideoUseCase.addRemoteVideoListener(self)
            if isActiveCall() {
                callUseCase.createActiveSessions()
            } else {
                if (chatRoom.chatType == .meeting || chatRoom.chatType == .group) && (call.numberOfParticipants == 0 || call.numberOfParticipants == 1 && call.status == .inProgress)  {
                    invokeCommand?(.showWaitingForOthersMessage)
                }
            }
            localAvFlagsUpdated(video: call.hasLocalVideo, audio: call.hasLocalAudio)
            if chatRoom.chatType != .oneToOne {
                addMeetingParticipantStatusPipelineSubscription()
            }
        case .onViewReady:
            if let myself = CallParticipantEntity.myself(chatId: call.chatId) {
                fetchAvatar(for: myself, name: myself.name ?? "Unknown") { [weak self] image in
                    self?.invokeCommand?(.updateMyAvatar(image))
                }
                
                requestAvatarChanges(forParticipants: callParticipants + [myself], chatId: call.chatId)
            }
            invokeCommand?(.configLocalUserView(position: isBackCameraSelected() ? .back : .front))
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
            callUseCase.stopListeningForCall()
            timer?.invalidate()
            remoteVideoUseCase.disableAllRemoteVideos()
            containerViewModel?.dispatch(.tapOnBackButton)
        case .switchIphoneOrientation(let orientation):
            switch orientation {
            case .landscape:
                forceGridLayout()
                invokeCommand?(.enableLayoutButton(false))
            case .portrait:
                invokeCommand?(.enableLayoutButton(true))
            }
        case .showRenameChatAlert:
            invokeCommand?(.showRenameAlert(title: chatRoom.title ?? "", isMeeting: chatRoom.chatType == .meeting))
        case .setNewTitle(let newTitle):
            chatRoomUseCase.renameChatRoom(chatRoom, title: newTitle) { [weak self] result in
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
        case .tapParticipantToPinAsSpeaker(let participant, let indexPath):
            tappedParticipant(participant, at: indexPath)
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
        case .particpantIsVisible(let participant, let index):
            if participant.video == .on {
                enableRemoteVideo(for: participant)
            } else {
                stopVideoForParticipant(participant)
            }
            indexOfVisibleParticipants.append(index)
        case .indexVisibleParticipants(let visibleIndex):
            updateVisibeParticipants(for: visibleIndex)
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
        }
    }
    
    private func showEmptyCallMessageIfNeeded() {
        if let call = callUseCase.call(for: chatRoom.chatId),
           call.numberOfParticipants == 1,
           call.participants.first == accountUseCase.currentUser?.handle {
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
                guard let self = self else { return }
                
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
        let isOnlyMyselfRemainingInTheCall = call.numberOfParticipants == 1 && call.participants.first == accountUseCase.currentUser?.handle
        
        self.invokeCommand?(
            .participantsStatusChanged(addedParticipantCount: addedParticipantCount,
                                       removedParticipantCount: removedParticipantCount,
                                       addedParticipantNames: addedParticipantNames,
                                       removedParticipantNames: removedParticipantNames,
                                       isOnlyMyselfRemainingInTheCall: isOnlyMyselfRemainingInTheCall)
        )
    }
    
    private func updateVisibeParticipants(for visibleIndex: [Int]) {
        indexOfVisibleParticipants.forEach {
            if !visibleIndex.contains($0),
               let participant = callParticipants[safe: $0] {
                if participant.video == .on && participant.speakerVideoDataDelegate == nil {
                    stopVideoForParticipant(participant)
                }
            }
        }
        indexOfVisibleParticipants = visibleIndex
    }
    
    private func stopVideoForParticipant(_ participant: CallParticipantEntity) {
        if participant.canReceiveVideoLowRes {
            remoteVideoUseCase.stopLowResolutionVideo(for: chatRoom.chatId, clientId: participant.clientId, completion: nil)
        } else if participant.canReceiveVideoHiRes {
            remoteVideoUseCase.stopHighResolutionVideo(for: chatRoom.chatId, clientId: participant.clientId, completion: nil)
        }
    }
    
    private func tappedParticipant(_ participant: CallParticipantEntity, at indexPath: IndexPath) {
        if !isSpeakerParticipantPinned || (isSpeakerParticipantPinned && speakerParticipant != participant) {
            if let currentSpeaker = speakerParticipant, currentSpeaker != participant {
                if currentSpeaker.video == .on && currentSpeaker.isVideoHiRes && currentSpeaker.canReceiveVideoHiRes {
                    switchVideoResolutionHighToLow(for: currentSpeaker.clientId, in: chatRoom.chatId)
                }
            }
            isSpeakerParticipantPinned = true
            speakerParticipant = participant
            if participant.video == .on && participant.isVideoLowRes && participant.canReceiveVideoLowRes {
                switchVideoResolutionLowToHigh(for: participant.clientId, in: chatRoom.chatId)
            }
            invokeCommand?(.selectPinnedCellAt(indexPath))
        } else {
            participant.isSpeakerPinned = false
            isSpeakerParticipantPinned = false
            invokeCommand?(.selectPinnedCellAt(nil))
        }
    }
    
    private func pinParticipantAsSpeaker(_ participant: CallParticipantEntity) {
        if layoutMode == .grid {
            switchLayout()
        }
        
        guard let participantIndex = callParticipants.firstIndex(of: participant) else {
            assert(true, "participant not found")
            MEGALogDebug("Participant not found \(participant) in the list")
            return
        }
                
        tappedParticipant(callParticipants[participantIndex], at: IndexPath(item: participantIndex, section: 0))
    }
    
    private func switchVideoResolutionHighToLow(for clientId: HandleEntity, in chatId: HandleEntity) {
        
        remoteVideoUseCase.stopHighResolutionVideo(for: chatRoom.chatId, clientId: clientId) {  [weak self] result in
            switch result {
            case .success:
                self?.remoteVideoUseCase.requestLowResolutionVideos(for: chatId, clientId: clientId, completion: nil)
            case .failure(_):
                break
            }
        }
    }
    
    private func switchVideoResolutionLowToHigh(for clientId: HandleEntity, in chatId: HandleEntity) {
        remoteVideoUseCase.stopLowResolutionVideo(for: chatRoom.chatId, clientId: clientId) { [weak self] result in
            switch result {
            case .success:
                self?.remoteVideoUseCase.requestHighResolutionVideo(for: chatId, clientId: clientId, completion: nil)
            case .failure(_):
                break
            }
        }
    }
    
    private func cancelReconnecting1on1Subscription() {
        reconnecting1on1Subscription?.cancel()
        reconnecting1on1Subscription = nil
    }
    
    private func waitForRecoverable1on1Call(participant: CallParticipantEntity) {
        
        reconnecting1on1Subscription = Just(Void.self)
            .delay(for: .seconds(10), scheduler: RunLoop.main)
            .sink() { [weak self] _ in
                guard let self = self else { return }
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
            .requestAvatarChangeNotification(forUserHandles:participants.map(\.participantId))
            .sink { error in
                MEGALogDebug("error fetching the changed avatar \(error)")
            } receiveValue: { [weak self] handles in
                guard let self = self else { return }
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
                    MEGALogDebug("Unable to find the name for handle \(handle)")
                    return
                }
                
                guard let base64Handle = MEGASdk.base64Handle(forUserHandle: handle) else { return }
                
                if let avatarBackgroundHexColor = MEGASdk.avatarColor(forBase64UserHandle: base64Handle) {
                    let image = try await self.userImageUseCase.createAvatar(withUserHandle: handle,
                                                                             base64Handle: base64Handle,
                                                                             avatarBackgroundHexColor: avatarBackgroundHexColor,
                                                                             backgroundGradientHexColor: nil,
                                                                             name: name)
                    await self.updateAvatar(handle: handle, image: image)
                }

                let avatar = try await self.userImageUseCase.downloadAvatar(withUserHandle: handle, base64Handle: base64Handle)
                await self.updateAvatar(handle: handle, image: avatar)
            } catch {
                MEGALogDebug("Failed to fetch avatar for \(handle) with \(error)")
            }
        }
    }
    
    @MainActor
    private func updateAvatar(handle: HandleEntity, image: UIImage) {
        guard let myself = CallParticipantEntity.myself(chatId: call.chatId) else {
            return
        }
        
        if handle == myself.participantId {
            invokeCommand?(.updateMyAvatar(image))
        } else {
            if let participant = callParticipants.first(where: { $0.participantId == handle }) {
                invokeCommand?(.updateAvatar(image, participant))
            }
        }
    }
}

struct CallDurationInfo {
    let initDuration: Int
    let baseDate: Date
}

extension MeetingParticipantsLayoutViewModel: CallCallbacksUseCaseProtocol {
    func participantJoined(participant: CallParticipantEntity) {
        self.hasParticipantJoinedBefore = true
        if chatRoom.chatType == .oneToOne && reconnecting1on1Subscription != nil {
            cancelReconnecting1on1Subscription()
        }
        initTimerIfNeeded(with: Int(call.duration))
        participantName(for: participant.participantId) { [weak self] in
            participant.name = $0
            self?.callParticipants.append(participant)
            self?.invokeCommand?(.insertParticipant(self?.callParticipants ?? []))
            if self?.callParticipants.count == 1 && self?.layoutMode == .speaker {
                self?.invokeCommand?(.shouldHideSpeakerView(false))
                self?.speakerParticipant = self?.callParticipants.first
            }
            if self?.layoutMode == .grid {
                self?.invokeCommand?(.updatePageControl(self?.callParticipants.count ?? 0))
            }
            self?.invokeCommand?(.hideEmptyRoomMessage)
        }
    }
    
    func participantLeft(participant: CallParticipantEntity) {
        if callUseCase.call(for: call.chatId) == nil {
            callTerminated(call)
        } else if let index = callParticipants.firstIndex(of: participant) {
            if chatRoom.chatType == .oneToOne && participant.sessionRecoverable {
                waitForRecoverable1on1Call(participant: participant)
            }
            callParticipants.remove(at: index)
            invokeCommand?(.deleteParticipantAt(index, callParticipants))
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
        guard let participantUpdated = callParticipants.first(where: {$0 == participant}) else {
            MEGALogError("Error getting participant updated")
            return
        }

        participantUpdated.video = participant.video
        participantUpdated.isVideoLowRes = participant.isVideoLowRes
        participantUpdated.isVideoHiRes = participant.isVideoHiRes
        participantUpdated.audio = participant.audio
        
        reloadParticipant(participantUpdated)
    }
    
    func highResolutionChanged(for participant: CallParticipantEntity) {
        guard let participantUpdated = callParticipants.first(where: {$0 == participant}) else {
            MEGALogError("Error getting participant updated with video high resolution")
            return
        }
        
        participantUpdated.canReceiveVideoHiRes = participant.canReceiveVideoHiRes
        
        if participantUpdated.canReceiveVideoHiRes {
            enableRemoteVideo(for: participantUpdated)
        } else {
            disableRemoteVideo(for: participantUpdated)
        }
    }
    
    func lowResolutionChanged(for participant: CallParticipantEntity) {
        guard let participantUpdated = callParticipants.first(where: {$0 == participant}) else {
            MEGALogError("Error getting participant updated with video low resolution")
            return
        }
        
        participantUpdated.canReceiveVideoLowRes = participant.canReceiveVideoLowRes

        if participantUpdated.canReceiveVideoLowRes {
            enableRemoteVideo(for: participantUpdated)
        } else {
            disableRemoteVideo(for: participantUpdated)
        }
    }
    
    func audioLevel(for participant: CallParticipantEntity) {
        if isSpeakerParticipantPinned || layoutMode == .grid {
            return
        }
        guard let participantWithAudio = callParticipants.first(where: {$0 == participant}) else {
            MEGALogError("Error getting participant with audio")
            return
        }
        if let currentSpeaker = speakerParticipant {
            if currentSpeaker != participantWithAudio {
                currentSpeaker.speakerVideoDataDelegate = nil
                speakerParticipant = participantWithAudio
                if currentSpeaker.video == .on && currentSpeaker.isVideoHiRes && currentSpeaker.canReceiveVideoHiRes {
                    switchVideoResolutionHighToLow(for: currentSpeaker.clientId, in: chatRoom.chatId)
                }
                if participantWithAudio.video == .on && participantWithAudio.isVideoLowRes && participantWithAudio.canReceiveVideoLowRes {
                    switchVideoResolutionLowToHigh(for: participantWithAudio.clientId, in: chatRoom.chatId)
                }
            }
        } else {
            speakerParticipant = participantWithAudio
            if participantWithAudio.video == .on && participantWithAudio.canReceiveVideoLowRes {
                switchVideoResolutionLowToHigh(for: participantWithAudio.clientId, in: chatRoom.chatId)
            }
        }
    }
    
    func callTerminated(_ call: CallEntity) {
        callUseCase.stopListeningForCall()
        timer?.invalidate()
        if (call.termCodeType == .tooManyParticipants) {
            containerViewModel?.dispatch(.dismissCall(completion: {
                SVProgressHUD.showError(withStatus: Strings.Localizable.Error.noMoreParticipantsAreAllowedInThisGroupCall)
            }))
        } else if reconnecting {
            tonePlayer.play(tone: .callEnded)
            containerViewModel?.dispatch(.dismissCall(completion: {
                SVProgressHUD.showError(withStatus: Strings.Localizable.Meetings.Reconnecting.failed)
            }))
        }
    }
    
    func participantAdded(with handle: HandleEntity) {
        dispatch(.addParticipant(withHandle: handle))
        containerViewModel?.dispatch(.participantAdded)
    }
    
    func participantRemoved(with handle: HandleEntity) {
        dispatch(.removeParticipant(withHandle: handle))
        containerViewModel?.dispatch(.participantRemoved)
    }
    
    func connecting() {
        if !reconnecting {
            reconnecting = true
            tonePlayer.play(tone: .reconnecting)
            invokeCommand?(.reconnecting)
            invokeCommand?(.hideEmptyRoomMessage)
        }
    }
    
    func inProgress() {
        if reconnecting {
            invokeCommand?(.reconnected)
            reconnecting = false
            if callParticipants.isEmpty {
                invokeCommand?(.showNoOneElseHereMessage)
            }
        }
    }
    
    func localAvFlagsUpdated(video: Bool, audio: Bool) {
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
    
    func ownPrivilegeChanged(to privilege: ChatRoomPrivilegeEntity, in chatRoom: ChatRoomEntity) {
        if self.chatRoom.ownPrivilege != chatRoom.ownPrivilege && privilege == .moderator {
            invokeCommand?(.ownPrivilegeChangedToModerator)
        }
        self.chatRoom = chatRoom
    }
    
    func chatTitleChanged(chatRoom: ChatRoomEntity) {
        self.chatRoom = chatRoom
        guard let title = chatRoom.title else { return }
        invokeCommand?(.updateName(title))
    }
    
    func networkQualityChanged(_ quality: NetworkQuality) {
        switch quality {
        case .bad:
            invokeCommand?(.showBadNetworkQuality)
        case .good:
            invokeCommand?(.hideBadNetworkQuality)
        }
    }
    
    func outgoingRingingStopReceived() {
        guard let call = callUseCase.call(for: chatRoom.chatId) else { return }
        self.call = call
        if chatRoom.chatType == .oneToOne && call.numberOfParticipants == 1 {
            callUseCase.hangCall(for: call.callId)
            self.tonePlayer.play(tone: .callEnded)
        }
    }
}

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

extension MeetingParticipantsLayoutViewModel: CallRemoteVideoListenerUseCaseProtocol {
    func remoteVideoFrameData(clientId: HandleEntity, width: Int, height: Int, buffer: Data) {
        guard let participant = callParticipants.first(where: { $0.clientId == clientId }) else {
            MEGALogError("Error getting participant from remote video frame")
            return
        }
        if participant.videoDataDelegate == nil {
            guard let index = callParticipants.firstIndex(of: participant) else { return }
            invokeCommand?(.reloadParticipantAt(index, callParticipants))
        }
        participant.remoteVideoFrame(width: width, height: height, buffer: buffer)
    }
}
