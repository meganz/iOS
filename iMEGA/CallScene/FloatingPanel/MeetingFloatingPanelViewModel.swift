import Combine
import MEGADomain
import MEGAPermissions
import MEGAPresentation

enum MeetingFloatingPanelAction: ActionType {
    case onViewReady
    case onViewAppear
    case hangCall(presenter: UIViewController, sender: UIButton)
    case shareLink(presenter: UIViewController, sender: UIButton)
    case inviteParticipants
    case onContextMenuTap(presenter: UIViewController, sender: UIButton, participant: CallParticipantEntity)
    case muteUnmuteCall(mute: Bool)
    case turnCamera(on: Bool)
    case switchCamera(backCameraOn: Bool)
    case enableLoudSpeaker
    case disableLoudSpeaker
    case makeModerator(participant: CallParticipantEntity)
    case removeModeratorPrivilege(forParticipant: CallParticipantEntity)
    case removeParticipant(participant: CallParticipantEntity)
    case displayParticipantInMainView(_ participant: CallParticipantEntity)
    case didDisplayParticipantInMainView(_ participant: CallParticipantEntity)
    case didSwitchToGridView
    case allowNonHostToAddParticipants(enabled: Bool)
    case selectParticipantsList(selectedTab: ParticipantsListTab)
    case onAdmitParticipantTap(participant: CallParticipantEntity)
    case onDenyParticipantTap(participant: CallParticipantEntity)
    case onHeaderActionTap
    case seeMoreParticipantsInWaitingRoomTapped
    case panelTransitionIsLongForm(Bool)
    case callAbsentParticipant(CallParticipantEntity)
}

final class MeetingFloatingPanelViewModel: ViewModelType {
    enum Command: CommandType, Equatable {
        case configView(canInviteParticipants: Bool,
                        isOneToOneCall: Bool,
                        isMeeting: Bool,
                        isVideoEnabled: Bool,
                        cameraPosition: CameraPositionEntity?,
                        allowNonHostToAddParticipantsEnabled: Bool,
                        isMyselfAModerator: Bool)
        case enabledLoudSpeaker(enabled: Bool)
        case microphoneMuted(muted: Bool)
        case updatedCameraPosition(position: CameraPositionEntity)
        case cameraTurnedOn(on: Bool)
        case reloadParticipantsList(participants: [CallParticipantEntity])
        case updatedAudioPortSelection(audioPort: AudioPort, bluetoothAudioRouteAvailable: Bool)
        case transitionToShortForm
        case transitionToLongForm
        case updateAllowNonHostToAddParticipants(enabled: Bool)
        case reloadViewData(participantsListView: ParticipantsListView)
        case hideCallAllIcon(Bool)
    }
    
    private let router: any MeetingFloatingPanelRouting
    private var chatRoom: ChatRoomEntity
    private var recentlyAddedHandles = [HandleEntity]()
    private var invitedUserIdsToBypassWaitingRoom = Set<HandleEntity>()
    private var calledUserIdsToBypassWaitingRoom = Set<HandleEntity>()
    private var chatRoomParticipantsUpdatedTask: Task<Void, Never>?
    private var subscriptions = Set<AnyCancellable>()
    private var call: CallEntity? {
        return callUseCase.call(for: chatRoom.chatId)
    }
    private let callCoordinatorUseCase: any CallCoordinatorUseCaseProtocol
    private let callUseCase: any CallUseCaseProtocol
    private let audioSessionUseCase: any AudioSessionUseCaseProtocol
    private let permissionHandler: any DevicePermissionsHandling
    private let captureDeviceUseCase: any CaptureDeviceUseCaseProtocol
    private let localVideoUseCase: any CallLocalVideoUseCaseProtocol
    private let accountUseCase: any AccountUseCaseProtocol
    private var chatRoomUseCase: any ChatRoomUseCaseProtocol
    private let megaHandleUseCase: any MEGAHandleUseCaseProtocol
    private weak var containerViewModel: MeetingContainerViewModel?
    private var callParticipants = [CallParticipantEntity]()
    private var callParticipantsNotInCall = [CallParticipantEntity]()
    private var callParticipantsInWaitingRoom = [CallParticipantEntity]()
    private var updateAllowNonHostToAddParticipantsTask: Task<Void, Never>?
    private var isSpeakerEnabled: Bool {
        didSet {
            containerViewModel?.dispatch(.speakerEnabled(isSpeakerEnabled))
        }
    }
    
    private var isVideoEnabled: Bool? {
        call?.hasLocalVideo
    }
    
    private var isMyselfAModerator: Bool {
        chatRoom.ownPrivilege == .moderator
    }
    
    private var canInviteParticipants: Bool {
        (isMyselfAModerator || chatRoom.isOpenInviteEnabled) && !accountUseCase.isGuest
    }
    
    private var selectedParticipantsListTab: ParticipantsListTab {
        didSet {
            isWaitingRoomListVisible = panelIsLongForm && selectedParticipantsListTab == .waitingRoom
        }
    }
    
    @PreferenceWrapper(key: .isCallUIVisible, defaultValue: false, useCase: PreferenceUseCase.default)
    var isCallUIVisible: Bool
    @PreferenceWrapper(key: .isWaitingRoomListVisible, defaultValue: false, useCase: PreferenceUseCase.default)
    var isWaitingRoomListVisible: Bool
    
    private var selectWaitingRoomList: Bool
    private var panelIsLongForm = false {
        didSet {
            isWaitingRoomListVisible = panelIsLongForm && selectedParticipantsListTab == .waitingRoom
        }
    }

    var invokeCommand: ((Command) -> Void)?

    init(router: some MeetingFloatingPanelRouting,
         containerViewModel: MeetingContainerViewModel,
         chatRoom: ChatRoomEntity,
         isSpeakerEnabled: Bool,
         callCoordinatorUseCase: some CallCoordinatorUseCaseProtocol,
         callUseCase: some CallUseCaseProtocol,
         audioSessionUseCase: some AudioSessionUseCaseProtocol,
         permissionHandler: some DevicePermissionsHandling,
         captureDeviceUseCase: some CaptureDeviceUseCaseProtocol,
         localVideoUseCase: some CallLocalVideoUseCaseProtocol,
         accountUseCase: some AccountUseCaseProtocol,
         chatRoomUseCase: some ChatRoomUseCaseProtocol,
         megaHandleUseCase: some MEGAHandleUseCaseProtocol,
         selectWaitingRoomList: Bool
    ) {
        self.router = router
        self.containerViewModel = containerViewModel
        self.chatRoom = chatRoom
        self.callCoordinatorUseCase = callCoordinatorUseCase
        self.callUseCase = callUseCase
        self.audioSessionUseCase = audioSessionUseCase
        self.permissionHandler = permissionHandler
        self.captureDeviceUseCase = captureDeviceUseCase
        self.localVideoUseCase = localVideoUseCase
        self.isSpeakerEnabled = isSpeakerEnabled
        self.accountUseCase = accountUseCase
        self.chatRoomUseCase = chatRoomUseCase
        self.megaHandleUseCase = megaHandleUseCase
        self.selectWaitingRoomList = selectWaitingRoomList
        self.selectedParticipantsListTab = selectWaitingRoomList ? .waitingRoom : .inCall
    }
    
    deinit {
        callUseCase.stopListeningForCall()
        chatRoomParticipantsUpdatedTask?.cancel()
    }
    
    func dispatch(_ action: MeetingFloatingPanelAction) {
        switch action {
        case .onViewReady:
            audioSessionUseCase.routeChanged { [weak self] routeChangedReason, previousAudioPort in
                guard let self else { return }
                if previousAudioPort == nil,
                   self.chatRoom.chatType == .meeting,
                   self.audioSessionUseCase.currentSelectedAudioPort == .builtInReceiver {
                    self.enableLoudSpeaker()
                } else {
                    self.sessionRouteChanged(routeChangedReason: routeChangedReason)
                }
            }
            callUseCase.startListeningForCallInChat(chatRoom.chatId, callbacksDelegate: self)
            configView()
            if let call = call, call.hasLocalVideo {
                checkForVideoPermission {
                    self.turnCamera(on: true) {
                        if self.isBackCameraSelected() {
                            self.invokeCommand?(.updatedCameraPosition(position: .back))
                        }
                    }
                }
            }
            
            dispatch(.muteUnmuteCall(mute: !(call?.hasLocalAudio ?? true)))
            if isSpeakerEnabled {
                enableLoudSpeaker()
            } else {
                updateSpeakerInfo()
            }
            addChatRoomParticipantsChangedListener()
            requestPrivilegeChange(forChatRoom: chatRoom)
            requestAllowNonHostToAddParticipantsValueChange(forChatRoom: chatRoom)
            prepareParticipantsTableViewData()
            subscribeToSeeWaitingRoomListNotification()
        case .onViewAppear:
            if selectWaitingRoomList {
                selectWaitingRoomList = false
                invokeCommand?(.transitionToLongForm)
            }
        case .hangCall(let presenter, let sender):
            manageHangCall(presenter, sender)
        case .shareLink(let presenter, let sender):
            containerViewModel?.dispatch(.shareLink(presenter: presenter, sender: sender, completion: nil))
        case .inviteParticipants:
            inviteParticipants()
        case .onContextMenuTap(let presenter, let sender, let participant):
            router.showContextMenu(presenter: presenter,
                                   sender: sender,
                                   participant: participant,
                                   isMyselfModerator: isMyselfAModerator,
                                   meetingFloatingPanelModel: self)

        case .muteUnmuteCall(let muted):
            guard let call = self.call else { return }
            checkForAudioPermission { granted in
                let microphoneMuted = granted ? muted : true
                self.callCoordinatorUseCase.muteUnmuteCall(call, muted: microphoneMuted)
                self.invokeCommand?(.microphoneMuted(muted: microphoneMuted))
            }
        case .turnCamera(let on):
            checkForVideoPermission {
                self.turnCamera(on: on) {
                    if on && self.isBackCameraSelected() {
                        self.invokeCommand?(.updatedCameraPosition(position: .back))
                    }
                }
            }
        case .switchCamera(let backCameraOn):
            switchCamera(backCameraOn: backCameraOn)
        case .enableLoudSpeaker:
            enableLoudSpeaker()
        case .disableLoudSpeaker:
            disableLoudSpeaker()
        case .makeModerator(let participant):
            guard let call = call else { return }
            participant.isModerator = true
            callUseCase.makePeerAModerator(inCall: call, peerId: participant.participantId)
            invokeCommand?(.reloadParticipantsList(participants: callParticipants))
        case .removeModeratorPrivilege(let participant):
            guard let call = call else { return }
            participant.isModerator = false
            callUseCase.removePeerAsModerator(inCall: call, peerId: participant.participantId)
            invokeCommand?(.reloadParticipantsList(participants: callParticipants))
        case .removeParticipant(let participant):
            guard let call = call, let index = callParticipants.firstIndex(of: participant) else { return }
            callParticipants.remove(at: index)
            callUseCase.removePeer(fromCall: call, peerId: participant.participantId)
            invokeCommand?(.reloadParticipantsList(participants: callParticipants))
        case .displayParticipantInMainView(let participant):
            containerViewModel?.dispatch(.displayParticipantInMainView(participant))
            invokeCommand?(.transitionToShortForm)
        case .didDisplayParticipantInMainView(let participant):
            callParticipants.forEach { $0.isSpeakerPinned = $0 == participant }
            invokeCommand?(.reloadParticipantsList(participants: callParticipants))
        case .didSwitchToGridView:
            callParticipants.forEach { $0.isSpeakerPinned = false }
            invokeCommand?(.reloadParticipantsList(participants: callParticipants))
        case .allowNonHostToAddParticipants(let enabled):
            updateAllowNonHostToAddParticipantsTask?.cancel()
            updateAllowNonHostToAddParticipantsTask = createAllowNonHostToAddParticipants(enabled: enabled, chatRoom: chatRoom)
        case .selectParticipantsList(let selectedTab):
            selectParticipantsListTab(selectedTab)
        case .onAdmitParticipantTap(let participant):
            admitParticipant(participant)
        case .onDenyParticipantTap(let participant):
            denyParticipant(participant)
        case .onHeaderActionTap:
            headerTapped()
        case .seeMoreParticipantsInWaitingRoomTapped:
            guard let call else { return }
            router.showWaitingRoomParticipantsList(for: call)
        case .panelTransitionIsLongForm(let isLongForm):
            panelIsLongForm = isLongForm
        case .callAbsentParticipant(let participant):
            callAbsentParticipants([participant])
        }
    }
    
    // MARK: - Private methods
    private func inviteParticipants() {
        let participantsAddingViewFactory = createParticipantsAddingViewFactory()
        
        guard participantsAddingViewFactory.hasVisibleContacts else {
            router.showNoAvailableContactsAlert(withParticipantsAddingViewFactory: participantsAddingViewFactory)
            return
        }
        
        let excludedHandles = recentlyAddedHandles
        recentlyAddedHandles = []
                        
        guard participantsAddingViewFactory.hasNonAddedVisibleContacts(withExcludedHandles: Set(excludedHandles)) else {
            router.showAllContactsAlreadyAddedAlert(withParticipantsAddingViewFactory: participantsAddingViewFactory)
            return
        }
                        
        router.inviteParticipants(
            withParticipantsAddingViewFactory: participantsAddingViewFactory,
            excludeParticipantsId: Set(excludedHandles)
        ) { [weak self] userHandles in
            guard let self, let call else { return }
            recentlyAddedHandles.append(contentsOf: userHandles)
            if chatRoom.isWaitingRoomEnabled {
                userHandles.forEach { 
                    self.invitedUserIdsToBypassWaitingRoom.insert($0)
                }
                callUseCase.allowUsersJoinCall(call, users: userHandles)
            } else {
                userHandles.forEach { self.callUseCase.addPeer(toCall: call, peerId: $0) }
            }
        }
    }
    
    private func createParticipantsAddingViewFactory() -> ParticipantsAddingViewFactory {
        ParticipantsAddingViewFactory(
            accountUseCase: accountUseCase,
            chatRoomUseCase: chatRoomUseCase,
            chatRoom: chatRoom
        )
    }
    
    private func addChatRoomParticipantsChangedListener() {
        chatRoomUseCase
            .participantsUpdated(forChatRoom: chatRoom)
            .sink { [weak self] peerHandles in
                guard let self else { return }
                
                chatRoomParticipantsUpdatedTask?.cancel()
                chatRoomParticipantsUpdatedTask = Task {
                    await self.updateRecentlyAddedHandles(removing: peerHandles)
                }
            }
            .store(in: &subscriptions)
    }
    
    @MainActor
    func updateRecentlyAddedHandles(removing peerHandles: [HandleEntity]) {
        recentlyAddedHandles.removeAll(where: peerHandles.contains)
    }
    
    private func enableLoudSpeaker() {
        audioSessionUseCase.enableLoudSpeaker { [weak self] _ in
            self?.updateSpeakerInfo()
        }
    }
    
    private func disableLoudSpeaker() {
        audioSessionUseCase.disableLoudSpeaker { [weak self] _ in
            self?.updateSpeakerInfo()
        }
    }
    
    private func checkForVideoPermission(onSuccess completionBlock: @escaping () -> Void) {
        permissionHandler.requestVideoPermission { [weak self] granted in
            self?.videoPermissionGranted(granted, withCompletionBlock: completionBlock)
        }
    }
    
    private func videoPermissionGranted(_ granted: Bool, withCompletionBlock completionBlock: @escaping () -> Void) {
        if granted {
            completionBlock()
        } else {
            router.showVideoPermissionError()
        }
    }
    
    private func checkForAudioPermission(_ completionBlock: @escaping (Bool) -> Void) {
        permissionHandler.requestAudioPermission { [weak self] granted in
            self?.audioPermissionGranted(granted, withCompletionBlock: completionBlock)
        }
    }
    
    private func audioPermissionGranted(_ granted: Bool, withCompletionBlock completionBlock: @escaping (Bool) -> Void) {
        completionBlock(granted)
        if !granted {
            router.showAudioPermissionError()
        }
    }
    
    private func sessionRouteChanged(routeChangedReason: AudioSessionRouteChangedReason) {
        guard let call = call else { return }
        MEGALogDebug("Meetings: session route changed with \(routeChangedReason) , current port \(audioSessionUseCase.currentSelectedAudioPort) and call \(call)")
        isSpeakerEnabled = audioSessionUseCase.isOutputFrom(port: .builtInSpeaker)
        updateSpeakerInfo()
    }
        
    private func updateSpeakerInfo() {
        let currentSelectedPort = audioSessionUseCase.currentSelectedAudioPort
        let isBluetoothAvailable = audioSessionUseCase.isBluetoothAudioRouteAvailable
        MEGALogDebug("Meetings: updating speaker info with selected port \(currentSelectedPort) bluetooth available \(isBluetoothAvailable)")
        self.isSpeakerEnabled = currentSelectedPort == .builtInSpeaker
        invokeCommand?(
            .updatedAudioPortSelection(audioPort: currentSelectedPort,
                                       bluetoothAudioRouteAvailable: isBluetoothAvailable)
        )
    }
    
    private func switchCamera(backCameraOn: Bool) {
        guard let selectCameraLocalizedString = captureDeviceUseCase.wideAngleCameraLocalizedName(position: backCameraOn ? .back : .front),
              localVideoUseCase.videoDeviceSelected() != selectCameraLocalizedString else {
            return
        }
        localVideoUseCase.selectCamera(withLocalizedName: selectCameraLocalizedString) { [weak self] _ in
            guard let self else { return }
            let cameraPosition: CameraPositionEntity = backCameraOn ? .back : .front
            self.invokeCommand?(.updatedCameraPosition(position: cameraPosition))
        }
    }
    
    private func isBackCameraSelected() -> Bool {
        guard let selectCameraLocalizedString = captureDeviceUseCase.wideAngleCameraLocalizedName(position: .back),
              localVideoUseCase.videoDeviceSelected() == selectCameraLocalizedString else {
            return false
        }
        
        return true
    }
    
    private func turnCamera(on: Bool, completion: (() -> Void)? = nil) {
        if on {
            localVideoUseCase.enableLocalVideo(for: chatRoom.chatId) { [weak self] result in
                guard let self else { return }
                switch result {
                case .success:
                    self.invokeCommand?(.cameraTurnedOn(on: on))
                case .failure:
                    MEGALogDebug("Error enabling local video")
                }
                completion?()
            }
        } else {
            localVideoUseCase.disableLocalVideo(for: chatRoom.chatId) { result in
                switch result {
                case .success:
                    self.invokeCommand?(.cameraTurnedOn(on: on))
                case .failure:
                    MEGALogDebug("Error disabling local video")
                }
                completion?()
            }
        }
    }
    
    private func manageHangCall(_ presenter: UIViewController, _ sender: UIButton) {
        if let call = call {
            if let callId = megaHandleUseCase.base64Handle(forUserHandle: call.callId),
               let chatId = megaHandleUseCase.base64Handle(forUserHandle: call.chatId) {
                MEGALogDebug("Meeting: Floating panel - Hang call for call id \(callId) and chat id \(chatId)")
            } else {
                MEGALogDebug("Meeting: Floating panel - Hang call - cannot get the call id and chat id string")
            }
        } else {
            MEGALogDebug("Meeting: Hang call - no call found")
        }
        if (chatRoom.chatType == .group || chatRoom.chatType == .meeting) && chatRoom.ownPrivilege == .moderator && callParticipants.count > 1 {
            containerViewModel?.dispatch(.showHangOrEndCallDialog)
        } else {
            containerViewModel?.dispatch(.hangCall(presenter: presenter, sender: sender))
        }
    }
    
    private func requestPrivilegeChange(forChatRoom chatRoom: ChatRoomEntity) {
        chatRoomUseCase.userPrivilegeChanged(forChatRoom: chatRoom)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { error in
                MEGALogDebug("error fetching the changed privilege \(error)")
            }, receiveValue: { [weak self] handle in
                self?.participantPrivilegeChanged(forUserHandle: handle, chatRoom: chatRoom)
            })
            .store(in: &subscriptions)
    }
    
    private func requestAllowNonHostToAddParticipantsValueChange(forChatRoom chatRoom: ChatRoomEntity) {
        chatRoomUseCase
            .allowNonHostToAddParticipantsValueChanged(forChatRoom: chatRoom)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { error in
                MEGALogDebug("error fetching allow host to add participants with error \(error)")
            }, receiveValue: { [weak self] _ in
                guard let self = self,
                      let chatRoom = self.chatRoomUseCase.chatRoom(forChatId: self.chatRoom.chatId) else {
                    return
                }
                
                self.chatRoom = chatRoom
                self.configView()
            })
            .store(in: &subscriptions)
    }
    
    private func participantPrivilegeChanged(forUserHandle handle: HandleEntity, chatRoom: ChatRoomEntity) {
        callParticipants.filter({ $0.participantId == handle }).forEach { participant in
            participant.isModerator = chatRoomUseCase.peerPrivilege(forUserHandle: participant.participantId, chatRoom: chatRoom) == .moderator
        }
        invokeCommand?(.reloadParticipantsList(participants: callParticipants))
    }
    
    private func createAllowNonHostToAddParticipants(enabled: Bool, chatRoom: ChatRoomEntity) -> Task<Void, Never> {
        Task { [weak self] in
            guard let self else { return }
            
            do {
                let allowNonHostToAddParticipantsEnabled = try await self.chatRoomUseCase.allowNonHostToAddParticipants(enabled, forChatRoom: chatRoom)
                if let chatRoom = self.chatRoomUseCase.chatRoom(forChatId: self.chatRoom.chatId) {
                    self.chatRoom = chatRoom
                }
                try Task.checkCancellation()
                if allowNonHostToAddParticipantsEnabled != enabled {
                    await self.updateAllowNonHostToAddParticipants(enabled: allowNonHostToAddParticipantsEnabled)
                }
            } catch {
                MEGALogDebug("Error allowing Non Host To Add Participants enabled \(enabled) with \(error)")
            }
        }
    }
    
    @MainActor
    private func updateAllowNonHostToAddParticipants(enabled: Bool) {
        invokeCommand?(.updateAllowNonHostToAddParticipants(enabled: enabled))
    }
    
    private func selectParticipantsListTab(_ selectedTab: ParticipantsListTab) {
        selectedParticipantsListTab = selectedTab
        switch selectedTab {
        case .inCall:
            loadParticipantsInCall()
        case .notInCall:
            loadParticipantsNotInCall()
        case .waitingRoom:
            loadParticipantsInWaitingRoom()
        }
    }
    
    private func subscribeToSeeWaitingRoomListNotification() {
        NotificationCenter
            .default
            .publisher(for: .seeWaitingRoomListEvent)
            .sink { [weak self] _ in
                guard let self else { return }
                selectParticipantsListTab(.waitingRoom)
                invokeCommand?(.transitionToLongForm)
            }
            .store(in: &subscriptions)
    }
    
    // MARK: - Waiting room
    
    private func headerTapped() {
        switch selectedParticipantsListTab {
        case .inCall:
            break
        case .notInCall:
            callAbsentParticipants(callParticipantsNotInCall)
        case .waitingRoom:
            admitAllParticipants()
        }
    }
    
    private func admitAllParticipants() {
        guard let call else { return }
        let waitingRoomParticipantHandles = callParticipantsInWaitingRoom.compactMap { $0.participantId }
        callUseCase.allowUsersJoinCall(call, users: waitingRoomParticipantHandles)
    }
    
    private func allowToJoinAbsentParticipantsIfNeeded(_ participants: [CallParticipantEntity]) {
        if chatRoom.chatType == .meeting && chatRoom.isWaitingRoomEnabled {
            guard let call else { return }
            participants.forEach {
                calledUserIdsToBypassWaitingRoom.insert($0.participantId)
            }
            callUseCase.allowUsersJoinCall(call, users: participants.map { $0.participantId })
        }
    }
    
    private func callAbsentParticipants(_ participants: [CallParticipantEntity]) {
        allowToJoinAbsentParticipantsIfNeeded(participants)
        invokeCommand?(.hideCallAllIcon(participants.count == 1))
        participants.forEach { participant in
            participant.absentParticipantState = .calling
            callUseCase.callAbsentParticipant(inChat: participant.chatId, userId: participant.participantId, timeout: 40)
        }
        reloadParticipantsIfNeeded()
        DispatchQueue.main.asyncAfter(deadline: .now() + 40.0) { [weak self] in
            participants.forEach { participant in
                participant.absentParticipantState = .noResponse
                self?.calledUserIdsToBypassWaitingRoom.remove(participant.participantId)
            }
            guard let self else { return }
            invokeCommand?(.hideCallAllIcon(true))
            reloadParticipantsIfNeeded()
        }
    }

    private func admitParticipant(_ participant: CallParticipantEntity) {
        guard let call else { return }
        callUseCase.allowUsersJoinCall(call, users: [participant.participantId])
    }
    
    private func denyParticipant(_ participant: CallParticipantEntity) {
        router.showConfirmDenyAction(for: participant.name ?? "", isCallUIVisible: isCallUIVisible) { [weak self] in
            guard let self, let call = call else { return }
            callUseCase.kickUsersFromCall(call, users: [participant.participantId])
        } cancelDenyAction: { }
    }
    
    private func configureWaitingRoomListener(forCall call: CallEntity) {
        callUseCase.callWaitingRoomUsersUpdate(forCall: call)
            .debounce(for: 1, scheduler: DispatchQueue.main)
            .sink { [weak self] call in
                self?.manageWaitingRoom(for: call)
            }
            .store(in: &subscriptions)
    }
    
    private func manageWaitingRoom(for call: CallEntity) {
        populateParticipantsInWaitingRoom(forCall: call)
        updateParticipantsNotInCallWithWaitingRoom(change: call.changeType ?? .noChanges, waitingRoomList: call.waitingRoomHandleList)
        
        containerViewModel?.dispatch(.participantJoinedWaitingRoom)
        
        if callParticipantsInWaitingRoom.isNotEmpty {
            selectParticipantsListTab(.waitingRoom)
        } else if selectedParticipantsListTab == .notInCall && calledUserIdsToBypassWaitingRoom.isNotEmpty {
            guard let waitingRoomUserHandles = call.waitingRoom?.userIds else { return }
            waitingRoomUserHandles.forEach { calledUserIdsToBypassWaitingRoom.remove($0) }
        } else {
            selectParticipantsListTab(.inCall)
        }
    }
    
    private func updateParticipantsNotInCallWithWaitingRoom(change: CallEntity.ChangeType, waitingRoomList: [HandleEntity]) {
        if change == .waitingRoomUsersEntered {
            let participantsJoinedWaitingRoom = waitingRoomList.compactMap {
                CallParticipantEntity(chatId: chatRoom.chatId, userHandle: $0)
            }
            participantsJoinedWaitingRoom.forEach { participant in
                callParticipantsNotInCall.remove(object: participant)
            }
        } else if change == .waitingRoomUsersLeave {
            guard let call else { return }
            waitingRoomList.forEach { participantId in
                if call.participants.notContains(participantId) {
                    callParticipantsNotInCall.append(
                        CallParticipantEntity(
                            chatId: call.chatId,
                            userHandle: participantId,
                            peerPrivilege: chatRoomUseCase.peerPrivilege(forUserHandle: participantId, chatRoom: chatRoom)
                        )
                    )
                }
            }
        }
    }
    
    // MARK: - Load data

    private func loadParticipantsInCall() {
        let sections: [FloatingPanelTableViewSection] = [.hostControls, .invite, .participants]
        
        var hostControls: [HostControlsSectionRow] = []
        if chatRoom.chatType != .oneToOne {
            hostControls.append(.listSelector)
        }
        if isMyselfAModerator && chatRoom.chatType != .oneToOne {
            hostControls.append(.allowNonHostToInvite)
        }
        
        var invite: [InviteSectionRow] = []
        if (isMyselfAModerator || chatRoom.isOpenInviteEnabled) && chatRoom.chatType != .oneToOne {
            invite.append(.invite)
        }
        
        let participantsListView = ParticipantsListView(
            sections: sections,
            hostControlsRows: hostControls,
            inviteSectionRow: invite,
            tabs: tabsForParticipantList(),
            selectedTab: .inCall,
            participants: callParticipants,
            existsWaitingRoom: chatRoom.isWaitingRoomEnabled && isMyselfAModerator)
        
        invokeCommand?(.reloadViewData(participantsListView: participantsListView))
    }
    
    private func loadParticipantsInWaitingRoom() {
        let sections: [FloatingPanelTableViewSection] = [.hostControls, .invite, .participants]
        
        var hostControls: [HostControlsSectionRow] = []
        if chatRoom.chatType != .oneToOne {
            hostControls.append(.listSelector)
        }
        
        let participantsListView = ParticipantsListView(
            sections: sections,
            hostControlsRows: hostControls,
            inviteSectionRow: [],
            tabs: tabsForParticipantList(),
            selectedTab: .waitingRoom,
            participants: callParticipantsInWaitingRoom,
            existsWaitingRoom: chatRoom.isWaitingRoomEnabled && isMyselfAModerator)
        
        invokeCommand?(.reloadViewData(participantsListView: participantsListView))
    }
    
    private func loadParticipantsNotInCall() {
        let sections: [FloatingPanelTableViewSection] = [.hostControls, .invite, .participants]
        
        var hostControls: [HostControlsSectionRow] = []
        if chatRoom.chatType != .oneToOne {
            hostControls.append(.listSelector)
        }
        
        let participantsListView = ParticipantsListView(
            sections: sections,
            hostControlsRows: hostControls,
            inviteSectionRow: [],
            tabs: tabsForParticipantList(),
            selectedTab: .notInCall,
            participants: callParticipantsNotInCall,
            existsWaitingRoom: chatRoom.isWaitingRoomEnabled && isMyselfAModerator)
        
        invokeCommand?(.reloadViewData(participantsListView: participantsListView))
    }
    
    private func tabsForParticipantList() -> [ParticipantsListTab] {
        if chatRoom.isWaitingRoomEnabled && isMyselfAModerator {
            if callParticipantsInWaitingRoom.isNotEmpty {
                return [.waitingRoom, .inCall, .notInCall]
            } else {
                return [.inCall, .notInCall, .waitingRoom]
            }
        } else {
            return [.inCall, .notInCall]
        }
    }
    
    private func reloadParticipantsIfNeeded() {
        switch selectedParticipantsListTab {
        case .inCall:
            invokeCommand?(.reloadParticipantsList(participants: callParticipants))
        case .notInCall:
            invokeCommand?(.reloadParticipantsList(participants: callParticipantsNotInCall))
        case .waitingRoom:
            invokeCommand?(.reloadParticipantsList(participants: callParticipantsInWaitingRoom))
        }
    }
    
    private func prepareParticipantsTableViewData() {
        populateParticipantsInCall()
        if let call = call, chatRoom.isWaitingRoomEnabled && isMyselfAModerator {
            configureWaitingRoomListener(forCall: call)
            populateParticipantsInWaitingRoom(forCall: call)
            if callParticipantsInWaitingRoom.isNotEmpty {
                selectParticipantsListTab(.waitingRoom)
            }
        }
        populateParticipantsNotInCall()
        if selectWaitingRoomList {
            loadParticipantsInWaitingRoom()
        } else {
            loadParticipantsInCall()
        }
    }
    
    private func populateParticipantsInCall() {
        guard let call = call else {
            MEGALogError("Failed to fetch call to populate participants")
            return
        }
        if let myself = CallParticipantEntity.myself(chatId: chatRoom.chatId) {
            myself.video = call.hasLocalVideo ? .on : .off
            callParticipants.append(myself)
        }
        let participants = call.clientSessions.compactMap({CallParticipantEntity(session: $0, chatId: chatRoom.chatId)})
        if !participants.isEmpty {
            callParticipants.append(contentsOf: participants)
        }
    }
    
    private func populateParticipantsInWaitingRoom(forCall call: CallEntity) {
        guard call.changeType != .waitingRoomUsersAllow,
              let waitingRoomUserHandles = call.waitingRoom?.userIds else { return }
        
        let waitingRoomNonModeratorUserHandles = waitingRoomUserHandles.filter { chatRoomUseCase.peerPrivilege(forUserHandle: $0, chatRoom: chatRoom).isUserInWaitingRoom }
        
        let callParticipantsInWaitingRoomUserHandles = callParticipantsInWaitingRoom.map { $0.participantId }

        guard waitingRoomNonModeratorUserHandles != callParticipantsInWaitingRoomUserHandles else { return }
        
        callParticipantsInWaitingRoom = waitingRoomNonModeratorUserHandles.compactMap {
            CallParticipantEntity(chatId: chatRoom.chatId, userHandle: $0)
        }
    }
    
    private func populateParticipantsNotInCall() {
        callParticipantsNotInCall = chatRoom.peers.compactMap {
            CallParticipantEntity(chatId: chatRoom.chatId, userHandle: $0.handle, peerPrivilege: $0.privilege)
        }
        
        callParticipants.forEach { callPartipant in
            callParticipantsNotInCall.remove(object: callPartipant)
        }
        
        callParticipantsInWaitingRoom.forEach { callParticipantInWaitingRoom in
            callParticipantsNotInCall.remove(object: callParticipantInWaitingRoom)
        }
    }
}

extension MeetingFloatingPanelViewModel: CallCallbacksUseCaseProtocol {
    func participantJoined(participant: CallParticipantEntity) {
        callParticipantsNotInCall.remove(object: participant)
        callParticipants.append(participant)
        reloadParticipantsIfNeeded()
    }
    
    func participantLeft(participant: CallParticipantEntity) {
        if call == nil {
            containerViewModel?.dispatch(.dismissCall(completion: nil))
        } else if let index = callParticipants.firstIndex(of: participant) {
            callParticipants.remove(at: index)
            participant.clientId = .invalid
            callParticipantsNotInCall.append(participant)
            reloadParticipantsIfNeeded()
        }
    }
    
    func updateParticipant(_ participant: CallParticipantEntity) {
        if let index = callParticipants.firstIndex(of: participant) {
            callParticipants[index] = participant
            reloadParticipantsIfNeeded()
        }
    }
        
    func ownPrivilegeChanged(to privilege: ChatRoomPrivilegeEntity, in chatRoom: ChatRoomEntity) {
        self.chatRoom = chatRoom
        guard let participant = callParticipants.first else { return }
        participant.isModerator = privilege == .moderator
        configView()
        reloadParticipantsIfNeeded()
    }
    
    func configView() {
        invokeCommand?(.configView(canInviteParticipants: canInviteParticipants,
                                   isOneToOneCall: chatRoom.chatType == .oneToOne,
                                   isMeeting: chatRoom.chatType == .meeting,
                                   isVideoEnabled: isVideoEnabled ?? false,
                                   cameraPosition: (isVideoEnabled ?? false) ? (isBackCameraSelected() ? .back : .front) : nil,
                                   allowNonHostToAddParticipantsEnabled: chatRoom.isOpenInviteEnabled,
                                   isMyselfAModerator: isMyselfAModerator))
    }
    
    func localAvFlagsUpdated(video: Bool, audio: Bool) {
        invokeCommand?(.microphoneMuted(muted: !audio))
    }
    
    func waitingRoomUsersAllow(with handles: [HandleEntity]) {
        guard let call else { return }
        for userId in handles where invitedUserIdsToBypassWaitingRoom.contains(userId) {
            callUseCase.addPeer(toCall: call, peerId: userId)
            invitedUserIdsToBypassWaitingRoom.remove(userId)
        }
    }
}
