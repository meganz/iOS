import ChatRepo
import Combine
import MEGADomain
import MEGAL10n
import MEGAPermissions
import MEGAPresentation

enum MeetingFloatingPanelAction: ActionType {
    case onViewReady
    case onViewAppear
    case shareLink(presenter: UIViewController, sender: UIButton)
    case inviteParticipants
    case onContextMenuTap(presenter: UIViewController, sender: UIButton, participant: CallParticipantEntity)
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
    case muteParticipant(CallParticipantEntity)
}

final class MeetingFloatingPanelViewModel: ViewModelType {
    enum Command: CommandType, Equatable {
        case configView(canInviteParticipants: Bool,
                        isOneToOneCall: Bool,
                        isMeeting: Bool,
                        allowNonHostToAddParticipantsEnabled: Bool,
                        isMyselfAModerator: Bool)
        case microphoneMuted(muted: Bool)
        case cameraTurnedOn(on: Bool)
        case reloadParticipantsList(participants: [CallParticipantEntity])
        case transitionToShortForm
        case transitionToLongForm
        case updateAllowNonHostToAddParticipants(enabled: Bool)
        case reloadViewData(participantsListView: ParticipantsListView)
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
    private let callUseCase: any CallUseCaseProtocol
    private let callUpdateUseCase: any CallUpdateUseCaseProtocol
    private let accountUseCase: any AccountUseCaseProtocol
    private var chatRoomUseCase: any ChatRoomUseCaseProtocol
    private let chatUseCase: any ChatUseCaseProtocol
    private weak var containerViewModel: MeetingContainerViewModel?
    private var callParticipants = [CallParticipantEntity]()
    private var callParticipantsNotInCall = [CallParticipantEntity]()
    private var callParticipantsInWaitingRoom = [CallParticipantEntity]()
    private var updateAllowNonHostToAddParticipantsTask: Task<Void, Never>?
    private var onCallUpdateTask: Task<Void, Never>?
    private let presentUpgradeFlow: (AccountDetailsEntity) -> Void
    // store state of the fact that user dismissed upsell banner
    // shown to non-organizer host when there's more than max number of meeting participant
    // if organiser-user is free-tier user
    private var dismissedFreeUserLimitBanner: Bool = false
    
    // creates a config for the tableview's header view that contains UI controls such as:
    // * title of the tab with the number of users in the tab
    // * Admit all/mute all buttons
    // * can also contain a warning banner showing upgrade information (free-tier limitations)
    private var headerConfigFactory: any MeetingFloatingPanelHeaderConfigFactoryProtocol
    // we show upgrade warnings only if .chatMonetisation FF is enabled
    private let featureFlagProvider: any FeatureFlagProviderProtocol
    
    private var isMyselfAModerator: Bool {
        chatRoom.ownPrivilege == .moderator
    }
    
    // mobile clients dis-allow inviting new participants into 1-on-1 calls
    private var canInviteParticipants: Bool {
        (isMyselfAModerator || chatRoom.isOpenInviteEnabled) &&
        isNotOneToOne &&
        !accountUseCase.isGuest
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
    private var limitsChangedSubscription: AnyCancellable?
    private var limitations: CallLimitations?
    
    init(router: some MeetingFloatingPanelRouting,
         containerViewModel: MeetingContainerViewModel,
         chatRoom: ChatRoomEntity,
         callUseCase: some CallUseCaseProtocol,
         callUpdateUseCase: some CallUpdateUseCaseProtocol,
         accountUseCase: some AccountUseCaseProtocol,
         chatRoomUseCase: some ChatRoomUseCaseProtocol,
         chatUseCase: some ChatUseCaseProtocol,
         selectWaitingRoomList: Bool,
         headerConfigFactory: some MeetingFloatingPanelHeaderConfigFactoryProtocol,
         featureFlags: some FeatureFlagProviderProtocol,
         presentUpgradeFlow: @escaping (AccountDetailsEntity) -> Void
    ) {
        self.router = router
        self.containerViewModel = containerViewModel
        self.chatRoom = chatRoom
        self.callUseCase = callUseCase
        self.callUpdateUseCase = callUpdateUseCase
        self.accountUseCase = accountUseCase
        self.chatRoomUseCase = chatRoomUseCase
        self.chatUseCase = chatUseCase
        self.selectWaitingRoomList = selectWaitingRoomList
        self.selectedParticipantsListTab = selectWaitingRoomList ? .waitingRoom : .inCall
        self.headerConfigFactory = headerConfigFactory
        self.featureFlagProvider = featureFlags
        self.presentUpgradeFlow = presentUpgradeFlow
    }
    
    deinit {
        callUseCase.stopListeningForCall()
        chatRoomParticipantsUpdatedTask?.cancel()
        onCallUpdateTask?.cancel()
    }
    
    func dispatch(_ action: MeetingFloatingPanelAction) {
        switch action {
        case .onViewReady:
            onViewReady()
            monitorOnCallUpdate()
        case .onViewAppear:
            if selectWaitingRoomList {
                selectWaitingRoomList = false
                invokeCommand?(.transitionToLongForm)
            }
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
        case .muteParticipant(let participant):
            muteParticipant(participant: participant)
        }
    }
    
    private func onViewReady() {
        // this is some sane default as we do not have access to the actual default value
        // call entity is optional so we can't easily create this limitations object in the initializer
        limitations = .init(
            initialLimit: call?.callLimits.maxUsers ?? 100,
            chatRoom: chatRoom,
            callUseCase: CallUseCase(repository: CallRepository.newRepo),
            chatRoomUseCase: chatRoomUseCase
        )
        
        limitsChangedSubscription = limitations?
            .limitsChangedPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in
                self?.reloadParticipantsIfNeeded()
            }
        
        callUseCase.startListeningForCallInChat(chatRoom.chatId, callbacksDelegate: self)
        configView()
        
        addChatRoomParticipantsChangedListener()
        requestPrivilegeChange(forChatRoom: chatRoom)
        requestAllowNonHostToAddParticipantsValueChange(forChatRoom: chatRoom)
        prepareParticipantsTableViewData()
        subscribeToSeeWaitingRoomListNotification()
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
        
        let config = ContactPickerConfig(
            mode: .inviteParticipants,
            excludedParticipantIds: Set(excludedHandles),
            canInviteParticipants: canInviteParticipants,
            callLimitations: limitations,
            participantLimitAchieved: {[weak self] selectedCount in
                guard let self, let limitations else { return false }
                return limitations.contactPickerLimitChecker(
                    callParticipantCount: callParticipants.count,
                    selectedCount: selectedCount,
                    allowsNonHostToInvite: canInviteParticipants
                )
            }
        )
                       
        router.inviteParticipants(
            withParticipantsAddingViewFactory: participantsAddingViewFactory,
            contactPickerConfig: config
        ) { [weak self] userHandles in
            guard let self, let call else { return }
            recentlyAddedHandles.append(contentsOf: userHandles)
            if chatRoom.isWaitingRoomEnabled {
                userHandles.forEach {
                    self.invitedUserIdsToBypassWaitingRoom.insert($0)
                }
                callUseCase.allowUsersJoinCall(call, users: userHandles)
            }
            userHandles.forEach { self.callUseCase.addPeer(toCall: call, peerId: $0) }
        }
    }
    
    private func createParticipantsAddingViewFactory() -> ParticipantsAddingViewFactory {
        ParticipantsAddingViewFactory(
            accountUseCase: accountUseCase,
            chatRoomUseCase: chatRoomUseCase,
            chatRoom: chatRoom,
            featureFlagProvider: DIContainer.featureFlagProvider
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
                
                guard let call, let chatRoom = chatRoomUseCase.chatRoom(forChatId: call.chatId) else { return }
                self.chatRoom = chatRoom
                populateParticipantsNotInCall()
            }
            .store(in: &subscriptions)
    }
    
    @MainActor
    func updateRecentlyAddedHandles(removing peerHandles: [HandleEntity]) {
        recentlyAddedHandles.removeAll(where: peerHandles.contains)
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
            muteAllParticipants()
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
        reloadParticipantsIfNeeded()
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
        participants.forEach { participant in
            participant.absentParticipantState = .calling
            callUseCase.callAbsentParticipant(inChat: participant.chatId, userId: participant.participantId, timeout: 40)
        }
        reloadParticipantsIfNeeded()
        DispatchQueue.main.asyncAfter(deadline: .now() + 40.0) { [weak self] in
            guard let self else { return }
            participants.forEach { participant in
                participant.absentParticipantState = .noResponse
                self.calledUserIdsToBypassWaitingRoom.remove(participant.participantId)
            }
            reloadParticipantsIfNeeded()
        }
    }
    
    private func muteAllParticipants() {
        muteParticipant(participant: nil)
        reloadParticipantsIfNeeded()
    }
    
    private func muteParticipant(participant: CallParticipantEntity?) {
        Task { @MainActor in
            do {
                try await callUseCase.muteUser(inChat: chatRoom, clientId: participant?.clientId ?? .invalid)
                router.showMuteSuccess(for: participant)
            } catch {
                router.showMuteError(for: participant)
            }
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
                CallParticipantEntity(userHandle: $0, chatRoom: chatRoom, privilege: chatRoomUseCase.peerPrivilege(forUserHandle: $0, chatRoom: chatRoom))
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
                            userHandle: participantId,
                            chatRoom: chatRoom,
                            privilege: chatRoomUseCase.peerPrivilege(forUserHandle: participantId, chatRoom: chatRoom)
                        )
                    )
                }
            }
        }
    }
    
    // MARK: - On Call Update
    
    func monitorOnCallUpdate() {
        let callUpdates = callUpdateUseCase.monitorOnCallUpdate()
        onCallUpdateTask = Task { [weak self] in
            do {
                for try await call in callUpdates {
                    self?.onCallUpdate(call)
                }
            } catch {
                MEGALogError("Error monitoring call updates \(error)")
            }
        }
    }
    
    private func onCallUpdate(_ call: CallEntity) {
        switch call.changeType {
        case .callRaiseHand:
            reloadRaiseHandParticipantsList(call)
        default:
            break
        }
    }
    
    private func cancelMonitorOnCallUpdate() {
        onCallUpdateTask?.cancel()
        onCallUpdateTask = nil
    }
    
    // MARK: - Raise hand

    private func reloadRaiseHandParticipantsList(_ call: CallEntity) {
        for participant in callParticipants {
            participant.raisedHand = call.raiseHandsList.contains(participant.participantId)
        }
        reloadParticipantsIfNeeded()
    }
    
    // MARK: - Load data
    
    private func loadParticipantsInCall() {
        Task {
            await loadDataForTab(.inCall)
        }
    }
    
    private func loadParticipantsInWaitingRoom() {
        Task {
            await loadDataForTab(.waitingRoom)
        }
    }
    
    private func loadParticipantsNotInCall() {
        Task {
            await loadDataForTab(.notInCall)
        }
    }
    
    @MainActor private func loadDataForTab(_ tab: ParticipantsListTab) async {
        invokeCommand?(.reloadViewData(participantsListView: participantListViewData(for: tab)))
    }
    
    // configuration that specifies if there should be a waitingRoom tab present:
    // * chat room configured with wait room
    // * user is moderator
    // and if yes, then if
    // users in the wait list should have admit (✓) button enabled
    func waitingRoomConfig(for tab: ParticipantsListTab) -> WaitingRoomConfig? {
        guard
            isMyselfAModerator,
            chatRoom.isWaitingRoomEnabled
        else { return nil }
        
        return .init(
            allowIndividualWaitlistAdmittance: !hasReachedInCallFreeUserParticipantLimit
        )
    }
    
    var hasReachedInCallFreeUserParticipantLimit: Bool {
        guard let limitations else { return false }
        return limitations.hasReachedInCallFreeUserParticipantLimit(callParticipantCount: callParticipants.count)
    }
    
    var hasReachedInCallPlusWaitingRoomFreeUserParticipantLimit: Bool {
        guard let limitations else { return false }
        return limitations.hasReachedInCallPlusWaitingRoomFreeUserParticipantLimit(
            callParticipantCount: callParticipants.count,
            callParticipantsInWaitingRoom: callParticipantsInWaitingRoom.count
        )
    }
    
    // user has dismissed the upgrade banner with cross button so we save that fact for the
    // duration of the view controller life time and reload data to hide the banner
    func dismissFreeUserLimitBanner() {
        dismissedFreeUserLimitBanner = true
        reloadParticipantsIfNeeded()
    }
    
    var isNotOneToOne: Bool {
        chatRoom.chatType != .oneToOne
    }
    
    private func hostControls(for tab: ParticipantsListTab) -> [HostControlsSectionRow] {
        var hostControls: [HostControlsSectionRow] = if isNotOneToOne {
            [.listSelector]
        } else {
            []
        }
        
        if tab == .inCall && isMyselfAModerator && isNotOneToOne {
            hostControls.append(.allowNonHostToInvite)
        }
        
        return hostControls
    }
    
    private func inviteSectionRow(for tab: ParticipantsListTab) -> [InviteSectionRow] {
        if tab == .inCall && canInviteParticipants {
            [.invite]
        } else {
            []
        }
    }
    
    private var shouldDisableMuteAllButtonInInCallTab: Bool {
        let unmutedUsers = callParticipants.filter({ $0.audio == .on })
        
        // if there's nobody to mute, no need to enable mute button
        if unmutedUsers.isEmpty {
            return true
        }
        
        return currentUserIsOnlyUser(outOf: unmutedUsers)
    }
    
    private func currentUserIsOnlyUser(outOf users: [CallParticipantEntity]) -> Bool {
        guard users.count == 1 else { return false }
        
        return users.first?.participantId == accountUseCase.currentUserHandle
    }
    
    private var shouldHideCallAllIconInNotInCallTab: Bool {
        
        let someParticipantsThatAreNotCalledIn = callParticipantsNotInCall.filter({ $0.absentParticipantState != .calling }).isNotEmpty
        let triedCallingAllButNotResponse = callParticipantsNotInCall.allSatisfy { $0.absentParticipantState == .noResponse }
        
        return (
            someParticipantsThatAreNotCalledIn ||
            triedCallingAllButNotResponse
        )
    }
    
    private func participantListViewData(for tab: ParticipantsListTab) -> ParticipantsListView {
        let sections: [FloatingPanelTableViewSection] = [.hostControls, .invite, .participants]
        
        let participants = switch tab {
        case .inCall:
            featureFlagProvider.isFeatureFlagEnabled(for: .raiseToSpeak) ?
            callParticipants.sortByRaiseHand(call: call) : callParticipants
        case .notInCall:
            callParticipantsNotInCall
        case .waitingRoom:
            callParticipantsInWaitingRoom
        }
    
        return ParticipantsListView(
            headerConfig: headerConfigFactory.headerConfig(
                tab: tab,
                freeTierInCallParticipantLimitReached: hasReachedInCallFreeUserParticipantLimit,
                totalInCallAndWaitingRoomAboveFreeTierLimit: hasReachedInCallPlusWaitingRoomFreeUserParticipantLimit,
                participantsCount: participants.count,
                isMyselfAModerator: isMyselfAModerator,
                hasDismissedBanner: dismissedFreeUserLimitBanner,
                shouldHideCallAllIcon: shouldHideCallAllIconInNotInCallTab,
                shouldDisableMuteAllButton: shouldDisableMuteAllButtonInInCallTab,
                presentUpgradeFlow: { [weak self]  in
                    guard let self, let details = accountUseCase.currentAccountDetails else { return }
                    presentUpgradeFlow(details)
                },
                dismissFreeUserLimitBanner: dismissFreeUserLimitBanner,
                actionButtonTappedHandler: { [weak self] in
                    self?.dispatch(.onHeaderActionTap)
                }
            ),
            sections: sections,
            hostControlsRows: hostControls(for: tab),
            inviteSectionRow: inviteSectionRow(for: tab),
            tabs: tabsForParticipantList(),
            selectedTab: tab,
            participants: participants,
            waitingRoomConfig: waitingRoomConfig(for: tab),
            currentUserHandle: accountUseCase.currentUserHandle,
            isMyselfModerator: isMyselfAModerator
        )
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
            loadParticipantsInCall()
        case .notInCall:
            loadParticipantsNotInCall()
        case .waitingRoom:
            loadParticipantsInWaitingRoom()
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
        let myself = CallParticipantEntity.myself(
            handle: accountUseCase.currentUserHandle ?? .invalid,
            userName: chatUseCase.myFullName(),
            chatRoom: chatRoom, 
            raisedHand: call.raiseHandsList.contains(accountUseCase.currentUserHandle ?? .invalid)
        )
        myself.video = call.hasLocalVideo ? .on : .off
        myself.audio = call.hasLocalAudio ? .on : .off
        callParticipants.append(myself)
        
        let participants = call.clientSessions.compactMap({
            CallParticipantEntity(
                session: $0,
                chatRoom: chatRoom,
                privilege: chatRoomUseCase.peerPrivilege(forUserHandle: $0.peerId, chatRoom: chatRoom), 
                raisedHand: call.raiseHandsList.contains($0.peerId)
            )
        })
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
            CallParticipantEntity(userHandle: $0, chatRoom: chatRoom, privilege: chatRoomUseCase.peerPrivilege(forUserHandle: $0, chatRoom: chatRoom))
        }
    }
    
    private func populateParticipantsNotInCall() {
        callParticipantsNotInCall = chatRoom.peers.compactMap {
            CallParticipantEntity(userHandle: $0.handle, chatRoom: chatRoom, privilege: chatRoomUseCase.peerPrivilege(forUserHandle: $0.handle, chatRoom: chatRoom))
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
                                   allowNonHostToAddParticipantsEnabled: chatRoom.isOpenInviteEnabled,
                                   isMyselfAModerator: isMyselfAModerator))
    }
    
    func localAvFlagsUpdated(video: Bool, audio: Bool) {
        invokeCommand?(.microphoneMuted(muted: !audio))
        invokeCommand?(.cameraTurnedOn(on: video))
    }
    
    func waitingRoomUsersAllow(with handles: [HandleEntity]) {
        guard let call else { return }
        for userId in handles where invitedUserIdsToBypassWaitingRoom.contains(userId) {
            callUseCase.addPeer(toCall: call, peerId: userId)
            invitedUserIdsToBypassWaitingRoom.remove(userId)
        }
    }
}
