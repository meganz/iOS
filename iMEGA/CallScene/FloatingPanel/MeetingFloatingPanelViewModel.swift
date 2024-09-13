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
    // this one is to show long form after user taps View on the Raise Hand snack bar
    case transitionToLongForm
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
    private var call: CallEntity? {
        return callUseCase.call(for: chatRoom.chatId)
    }
    private let callUseCase: any CallUseCaseProtocol
    private let callUpdateUseCase: any CallUpdateUseCaseProtocol
    private let sessionUpdateUseCase: any SessionUpdateUseCaseProtocol
    private let chatRoomUpdateUseCase: any ChatRoomUpdateUseCaseProtocol
    private let accountUseCase: any AccountUseCaseProtocol
    private var chatRoomUseCase: any ChatRoomUseCaseProtocol
    private let chatUseCase: any ChatUseCaseProtocol

    private weak var containerViewModel: MeetingContainerViewModel?
    private var callParticipants = [CallParticipantEntity]()
    private var callParticipantsNotInCall = [CallParticipantEntity]()
    private var callParticipantsInWaitingRoom = [CallParticipantEntity]()
    private var seeWaitingRoomListNotificationTask: Task<Void, Never>?
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
    private let notificationCenter: NotificationCenter
    
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
    var panelIsLongForm = false {
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
         sessionUpdateUseCase: some SessionUpdateUseCaseProtocol,
         chatRoomUpdateUseCase: some ChatRoomUpdateUseCaseProtocol,
         accountUseCase: some AccountUseCaseProtocol,
         chatRoomUseCase: some ChatRoomUseCaseProtocol,
         chatUseCase: some ChatUseCaseProtocol,
         selectWaitingRoomList: Bool,
         headerConfigFactory: some MeetingFloatingPanelHeaderConfigFactoryProtocol,
         featureFlags: some FeatureFlagProviderProtocol,
         notificationCenter: NotificationCenter,
         presentUpgradeFlow: @escaping (AccountDetailsEntity) -> Void
    ) {
        self.router = router
        self.containerViewModel = containerViewModel
        self.chatRoom = chatRoom
        self.callUseCase = callUseCase
        self.callUpdateUseCase = callUpdateUseCase
        self.sessionUpdateUseCase = sessionUpdateUseCase
        self.chatRoomUpdateUseCase = chatRoomUpdateUseCase
        self.accountUseCase = accountUseCase
        self.chatRoomUseCase = chatRoomUseCase
        self.chatUseCase = chatUseCase
        self.selectWaitingRoomList = selectWaitingRoomList
        self.selectedParticipantsListTab = selectWaitingRoomList ? .waitingRoom : .inCall
        self.headerConfigFactory = headerConfigFactory
        self.featureFlagProvider = featureFlags
        self.notificationCenter = notificationCenter
        self.presentUpgradeFlow = presentUpgradeFlow
    }
    
    func dispatch(_ action: MeetingFloatingPanelAction) {
        switch action {
        case .onViewReady:
            onViewReady()
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
            reloadCallParticipantsInCall()
        case .removeModeratorPrivilege(let participant):
            guard let call = call else { return }
            participant.isModerator = false
            callUseCase.removePeerAsModerator(inCall: call, peerId: participant.participantId)
            reloadCallParticipantsInCall()
        case .removeParticipant(let participant):
            guard let call = call, let index = callParticipants.firstIndex(of: participant) else { return }
            callParticipants.remove(at: index)
            callUseCase.removePeer(fromCall: call, peerId: participant.participantId)
            reloadCallParticipantsInCall()
        case .displayParticipantInMainView(let participant):
            containerViewModel?.dispatch(.displayParticipantInMainView(participant))
            invokeCommand?(.transitionToShortForm)
        case .didDisplayParticipantInMainView(let participant):
            callParticipants.forEach { $0.isSpeakerPinned = $0 == participant }
            reloadCallParticipantsInCall()
        case .didSwitchToGridView:
            callParticipants.forEach { $0.isSpeakerPinned = false }
            reloadCallParticipantsInCall()
        case .allowNonHostToAddParticipants(let enabled):
            Task {
                try await self.chatRoomUseCase.allowNonHostToAddParticipants(enabled, forChatRoom: chatRoom)
            }
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
            containerViewModel?.dispatch(.willTransitionToLongForm)
            panelIsLongForm = isLongForm
        case .callAbsentParticipant(let participant):
            callAbsentParticipants([participant])
        case .muteParticipant(let participant):
            muteParticipant(participant: participant)
        case .transitionToLongForm:
            invokeCommand?(.transitionToLongForm)
            selectParticipantsListTab(.inCall)
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
        
        configView()
        prepareParticipantsTableViewData()
        subscribeToSeeWaitingRoomListNotification()
        
        monitorOnCallUpdate()
        monitorOnSessionUpdate()
        monitorOnChatRoomUpdate()
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
            chatRoom: chatRoom
        )
    }
    
    func updateRecentlyAddedHandles(removing peerHandles: [HandleEntity]) {
        recentlyAddedHandles.removeAll(where: peerHandles.contains)
    }
    
    private func participantPrivilegeChanged(forUserHandle handle: HandleEntity, chatRoom: ChatRoomEntity) {
        callParticipants.filter({ $0.participantId == handle }).forEach { participant in
            participant.isModerator = chatRoomUseCase.peerPrivilege(forUserHandle: participant.participantId, chatRoom: chatRoom) == .moderator
        }
        reloadCallParticipantsInCall()
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
        seeWaitingRoomListNotificationTask = Task { [weak self, notificationCenter] in
            for await _ in notificationCenter.notifications(named: .seeWaitingRoomListEvent) {
                self?.selectParticipantsListTab(.waitingRoom)
                self?.invokeCommand?(.transitionToLongForm)
            }
        }
    }
    
    private func dismissCallUIAsLastParticipantLeaveAndCallNotExists() {
        containerViewModel?.dispatch(.dismissCall(completion: nil))
    }
    
    private func participant(with session: ChatSessionEntity) -> CallParticipantEntity {
        CallParticipantEntity(
            session: session,
            chatRoom: chatRoom,
            privilege: chatRoomUseCase.peerPrivilege(forUserHandle: session.peerId, chatRoom: chatRoom),
            raisedHand: callUseCase.isParticipantRaisedHand(session.peerId, forCallInChatId: chatRoom.chatId)
        )
    }
    
    private func configView() {
        invokeCommand?(.configView(canInviteParticipants: canInviteParticipants,
                                   isOneToOneCall: chatRoom.chatType == .oneToOne,
                                   isMeeting: chatRoom.chatType == .meeting,
                                   allowNonHostToAddParticipantsEnabled: chatRoom.isOpenInviteEnabled,
                                   isMyselfAModerator: isMyselfAModerator))
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
    
    private func manageWaitingRoom(for call: CallEntity) {
        guard isMyselfAModerator else { return }
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
        Task { [weak self] in
            for await call in callUpdates {
                self?.onCallUpdate(call)
            }
        }
    }
    
    private func onCallUpdate(_ call: CallEntity) {
        switch call.changeType {
        case .callRaiseHand:
            reloadRaiseHandParticipantsList(call)
        case .localAVFlags:
            localAvFlagsUpdated(call: call)
        case .waitingRoomUsersAllow:
            for userId in call.waitingRoomHandleList where invitedUserIdsToBypassWaitingRoom.contains(userId) {
                callUseCase.addPeer(toCall: call, peerId: userId)
                invitedUserIdsToBypassWaitingRoom.remove(userId)
            }
            manageWaitingRoom(for: call)
        case .waitingRoomDeny, .waitingRoomUsersEntered, .waitingRoomUsersLeave, .waitingRoomComposition:
            manageWaitingRoom(for: call)
        default:
            break
        }
    }
    
    // MARK: - Chat Room Update
    
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
            guard let participant = callParticipants.first else { return }
            participant.isModerator = chatRoom.ownPrivilege == .moderator
            configView()
            reloadParticipantsIfNeeded()
        case .openInvite:
            invokeCommand?(.updateAllowNonHostToAddParticipants(enabled: chatRoom.isOpenInviteEnabled))
        case .participants:
            updateRecentlyAddedHandles(removing: chatRoom.peers.map { $0.handle })
            populateParticipantsNotInCall()
            if chatRoom.userHandle != .invalid {
                participantPrivilegeChanged(forUserHandle: chatRoom.userHandle, chatRoom: chatRoom)
            }
        default:
            break
        }
    }
    
    // MARK: - Session Update
    
    func monitorOnSessionUpdate() {
        let sessionUpdates = sessionUpdateUseCase.monitorOnSessionUpdate()
        Task { [weak self] in
            for await (session, _) in sessionUpdates {
                self?.onSessionUpdate(session)
            }
        }
    }
    
    private func onSessionUpdate(_ session: ChatSessionEntity) {
        switch session.changeType {
        case .status:
            switch session.statusType {
            case .inProgress:
                let participant = participant(with: session)
                callParticipantsNotInCall.remove(object: participant)
                callParticipants.append(participant)
                reloadParticipantsIfNeeded()
            case .destroyed:
                let participant = participant(with: session)
                if call == nil {
                    dismissCallUIAsLastParticipantLeaveAndCallNotExists()
                } else if let index = callParticipants.firstIndex(of: participant) {
                    callParticipants.remove(at: index)
                    participant.clientId = .invalid
                    callParticipantsNotInCall.append(participant)
                    reloadParticipantsIfNeeded()
                }
            default:
                break
            }
        case .remoteAvFlags:
            let participant = participant(with: session)
            if let index = callParticipants.firstIndex(of: participant) {
                callParticipants[index] = participant
                reloadParticipantsIfNeeded()
            }
        default:
            break
        }
    }
    
    // MARK: Local av flags
    
    func localAvFlagsUpdated(call: CallEntity) {
        invokeCommand?(.microphoneMuted(muted: !call.hasLocalAudio))
        invokeCommand?(.cameraTurnedOn(on: call.hasLocalVideo))
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
            sortedCallParticipantsInCall()
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
    
    private func sortedCallParticipantsInCall() -> [CallParticipantEntity] {
        callParticipants.sortByRaiseHand(call: call)
    }
    
    /// Sort call participants by raise hand before updating UI
    private func reloadCallParticipantsInCall() {
        invokeCommand?(.reloadParticipantsList(participants: sortedCallParticipantsInCall()))
    }
}
