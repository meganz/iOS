import ChatRepo
import Combine
import Foundation
import MEGAAnalyticsiOS
import MEGADomain
import MEGAL10n
import MEGAPermissions
import MEGAPresentation
import MEGARepo
import MEGASDKRepo
import MEGASwiftUI

enum ChatViewMode {
    case chats
    case meetings
}

enum ChatViewType {
    case regular
    case archived
}

@MainActor
final class ChatRoomsListViewModel: ObservableObject {
    let router: any ChatRoomsListRouting
    private let chatUseCase: any ChatUseCaseProtocol
    private let chatRoomUseCase: any ChatRoomUseCaseProtocol
    private let networkMonitorUseCase: any NetworkMonitorUseCaseProtocol
    private let accountUseCase: any AccountUseCaseProtocol
    private let scheduledMeetingUseCase: any ScheduledMeetingUseCaseProtocol
    private let userAttributeUseCase: any UserAttributeUseCaseProtocol
    private let permissionHandler: any DevicePermissionsHandling
    private let permissionAlertRouter: any PermissionAlertRouting
    private let chatListItemCacheUseCase: any ChatListItemCacheUseCaseProtocol
    private let retryPendingConnectionsUseCase: any RetryPendingConnectionsUseCaseProtocol
    private let tracker: any AnalyticsTracking
    private let chatViewType: ChatViewType
    private var networkMonitorTask: Task<Void, Never>?
    
    lazy var contextMenuManager = ContextMenuManager(
        chatMenuDelegate: self,
        meetingContextMenuDelegate: self,
        createContextMenuUseCase: CreateContextMenuUseCase(repo: CreateContextMenuRepository.newRepo)
    )
    private var myAvatarManager: MyAvatarManager?
    
    lazy private var globalDNDNotificationControl = GlobalDNDNotificationControl(delegate: self)
    lazy private var chatNotificationControl = ChatNotificationControl(delegate: self)
    
    var isChatRoomEmpty: Bool {
        switch chatViewMode {
        case .chats:
            return displayChatRooms?.isEmpty ?? true
        case .meetings:
            return displayFutureMeetings?.isEmpty ?? true && displayPastMeetings?.isEmpty ?? true
        }
    }
    
    var shouldShowSearchBar: Bool {
        return isSearchActive || searchText.isNotEmpty || !isChatRoomEmpty
    }
    
    @Published var chatViewMode: ChatViewMode
    @Published var chatStatus: ChatStatusEntity?
    @Published var title: String = Strings.Localizable.Chat.title
    @Published var myAvatarBarButton: UIBarButtonItem?
    @Published var isConnectedToNetwork: Bool
    @Published var isFirstMeetingsLoad: Bool
    
    @Published var displayChatRooms: [ChatRoomViewModel]?
    @Published var displayPastMeetings: [ChatRoomViewModel]?
    @Published var displayFutureMeetings: [FutureMeetingSection]?
    
    var contactsOnMegaViewState: ChatRoomsTopRowViewState {
        ChatRoomsTopRowViewState.contactsOnMega(action: {[weak self] in self?.goToInviteContact() })
    }
    
    @Published var activeCallViewModel: ActiveCallViewModel?
    @Published var searchText: String {
        didSet {
            searchTask = Task { @MainActor in
                if chatViewMode == .meetings {
                    filterMeetings()
                } else {
                    filterChats()
                }
            }
        }
    }
    
    private var loadingTask: Task<Void, any Error>?
    private var searchTask: Task<Void, Never>?
    private var meetingTipTask: Task<Void, Never>?
    
    @Published var isSearchActive: Bool
    
    private var chatRooms: [ChatRoomViewModel]?
    
    private var pastMeetings: [ChatRoomViewModel]?
    private var futureMeetings: [FutureMeetingSection]?
    private var subscriptions = Set<AnyCancellable>()
    private var isViewOnScreen = false
    
    @Published private var currentTip: ScheduledMeetingOnboardingTip = .initial
    @Published private var meetingListFrame: CGRect = .zero
    @Published var isMeetingListScrolling: Bool = false
    @Published var createMeetingTipOffsetX: CGFloat = 0
    @Published var startMeetingTipOffsetY: CGFloat?
    @Published var startMeetingTipArrowDirection: TipView.TipArrowDirection = .up
    @Published var recurringMeetingTipOffsetY: CGFloat?
    @Published var recurringMeetingTipArrowDirection: TipView.TipArrowDirection = .up
    
    @Published private(set) var shouldDisplayUnreadBadgeForChats = false
    @Published private(set) var shouldDisplayUnreadBadgeForMeetings = false
    
    var presentingCreateMeetingTip: Bool {
        chatViewMode == .meetings && isConnectedToNetwork && currentTip == .createMeeting
    }
    
    var presentingRecurringMeetingTip: Bool {
        chatViewMode == .meetings  && !isMeetingListScrolling && recurringMeetingTipOffsetY != nil &&
        (currentTip == .recurringMeeting || currentTip == .recurringOrStartMeeting)
    }
    
    var presentingStartMeetingTip: Bool {
        chatViewMode == .meetings  && !isMeetingListScrolling && startMeetingTipOffsetY != nil &&
        (currentTip == .startMeeting || (currentTip == .recurringOrStartMeeting && !presentingRecurringMeetingTip))
    }
    
    var refreshContextMenuBarButton: (@MainActor () -> Void)?
    
    private let emptyViewStateFactory = ChatRoomsEmptyViewStateFactory()
    
    let urlOpener: (URL) -> Void
    
    init(
        router: some ChatRoomsListRouting,
        chatUseCase: any ChatUseCaseProtocol,
        chatRoomUseCase: any ChatRoomUseCaseProtocol,
        networkMonitorUseCase: any NetworkMonitorUseCaseProtocol,
        accountUseCase: any AccountUseCaseProtocol,
        scheduledMeetingUseCase: any ScheduledMeetingUseCaseProtocol,
        userAttributeUseCase: any UserAttributeUseCaseProtocol,
        chatType: ChatViewType = .regular,
        chatViewMode: ChatViewMode = .chats,
        permissionHandler: some DevicePermissionsHandling,
        permissionAlertRouter: some PermissionAlertRouting,
        chatListItemCacheUseCase: some ChatListItemCacheUseCaseProtocol,
        retryPendingConnectionsUseCase: some RetryPendingConnectionsUseCaseProtocol,
        tracker: some AnalyticsTracking = DIContainer.tracker,
        urlOpener: @escaping (URL) -> Void
    ) {
        self.router = router
        self.chatUseCase = chatUseCase
        self.chatRoomUseCase = chatRoomUseCase
        self.networkMonitorUseCase = networkMonitorUseCase
        self.scheduledMeetingUseCase = scheduledMeetingUseCase
        self.accountUseCase = accountUseCase
        self.userAttributeUseCase = userAttributeUseCase
        self.chatViewType = chatType
        self.chatViewMode = chatViewMode
        self.isConnectedToNetwork = networkMonitorUseCase.isConnected()
        self.searchText = ""
        self.permissionHandler = permissionHandler
        self.permissionAlertRouter = permissionAlertRouter
        self.chatListItemCacheUseCase = chatListItemCacheUseCase
        self.retryPendingConnectionsUseCase = retryPendingConnectionsUseCase
        self.tracker = tracker
        self.isSearchActive = false
        self.isFirstMeetingsLoad = true
        self.urlOpener = urlOpener
        
        configureTitle()
    }
    
    deinit {
        networkMonitorTask?.cancel()
        networkMonitorTask = nil
    }
    
    var hasContacts: Bool {
        // we filter only visible to not show removed contacts
        accountUseCase
            .contacts()
            .contains { $0.visibility == .visible }
    }
    
    var isSearching: Bool {
        isSearchActive || searchText.isNotEmpty
    }
    
    func emptyViewState() -> ChatRoomsEmptyViewState? {
        guard isChatRoomEmpty else {
            return nil
        }
        
        return if isSearching {
            emptyViewStateFactory.searchEmptyViewState()
        } else {
            emptyViewStateFactory.emptyChatRoomsViewState(
                hasArchivedChats: hasArchivedChats,
                hasContacts: hasContacts,
                chatViewMode: chatViewMode,
                contactsOnMega: contactsOnMegaViewState,
                archivedChats: archiveChatsViewState,
                actions: emptyViewActions,
                bottomButtonMenus: chatViewMode == .meetings && isConnectedToNetwork ? [startMeetingMenu(), joinMeetingMenu(), scheduleMeetingMenu()] : []
            )
        }
    }
    
    func startMeeting() {
        tracker.trackAnalyticsEvent(with: StartMeetingNowPressedEvent())
        router.presentCreateMeeting()
    }
    
    func scheduleMeeting() {
        tracker.trackAnalyticsEvent(with: ScheduleMeetingPressedEvent())
        router.presentScheduleMeeting()
    }
    
    func joinMeeting() {
        tracker.trackAnalyticsEvent(with: JoinMeetingPressedEvent())
        router.presentEnterMeeting()
    }
    
    var emptyViewActions: ChatRoomsEmptyViewStateFactory.ChatEmptyViewActions {
        .init(
            startMeeting: startMeeting,
            scheduleMeeting: scheduleMeeting,
            inviteFriend: goToInviteContact,
            newChat: addChatButtonTapped,
            linkTappedAction: linkTappedAction
        )
    }
    
    private func trackInviteFriend() {
        tracker.trackAnalyticsEvent(with: InviteFriendsPressedEvent())
    }
    
    func trackNewMeetingsAddMenu() {
        tracker.trackAnalyticsEvent(with: MeetingsAddMenuEvent())
    }
    
    func trackScreenAppearance() {
        tracker.trackAnalyticsEvent(with: ChatScreenEvent())
    }
    
    func linkTappedAction() {
        guard let link = URL(string: "https://mega.io/chatandmeetings") else {
            return
        }
        urlOpener(link)
        tracker.trackAnalyticsEvent(with: InviteFriendsLearnMorePressedEvent())
    }
    
    func askForNotificationsPermissionsIfNeeded() async {
        let shouldAsk = await permissionHandler.shouldAskForNotificationPermission()
        if shouldAsk {
            permissionAlertRouter
                .presentModalNotificationsPermissionPrompt()
        }
    }
    
    @MainActor 
    func loadChatRoomsIfNeeded() {
        isViewOnScreen = true
        retryPendingConnectionsUseCase.retryPendingConnections()
        chatUseCase.retryPendingConnections()
        
        if chatUseCase.chatConnectionStatus() == .online {
            fetchChats()
        }
        
        let isConnectedToNetwork = networkMonitorUseCase.isConnected()
        if self.isConnectedToNetwork != isConnectedToNetwork {
            self.isConnectedToNetwork = isConnectedToNetwork
        }
        
        updateActiveCall(chatUseCase.activeCall())
        
        listenToChatListUpdate()
        monitorChatConnectionStatusUpdate()
        listenToChatStatusUpdate()
        monitorNetworkChanges()
        monitorActiveCallChanges()
        fetchScheduledMeetingTipRecord()
    }
    
    func cancelLoading() {
        isViewOnScreen = false
        subscriptions.forEach { $0.cancel() }
        subscriptions = []
        
        cancelLoadingTask()
        cancelSearchTask()
        cancelMeetingTipTask()
    }
    
    func contextMenuConfiguration() -> CMConfigEntity {
        CMConfigEntity(
            menuType: .menu(type: .chat),
            isDoNotDisturbEnabled: globalDNDNotificationControl.isGlobalDNDEnabled,
            timeRemainingToDeactiveDND: globalDNDNotificationControl.timeRemainingToDeactiveDND ?? "",
            chatStatus: chatUseCase.chatStatus(),
            isArchivedChatsVisible: hasArchivedChats
        )
    }
    
    func selectChatMode(_ mode: ChatViewMode) {
        guard mode != chatViewMode else { return }
        chatViewMode = mode
        switch mode {
        case .chats: tracker.trackAnalyticsEvent(with: ChatsTabEvent())
        case .meetings: tracker.trackAnalyticsEvent(with: MeetingsTabEvent())
        }
        fetchChats()
    }
    
    func addChatButtonTapped() {
        tracker.trackAnalyticsEvent(with: ChatRoomsStartConversationMenuEvent())
        router.presentStartConversation()
    }
    
    func changeChatStatus(to status: ChatStatusEntity) {
        guard status != chatStatus else {
            return
        }
        chatUseCase.changeChatStatus(to: status)
    }
    
    var archivedChatsCount: UInt {
        chatUseCase.archivedChatListCount()
    }
    
    var hasArchivedChats: Bool {
        archivedChatsCount > 0
    }
    
    var archiveChatsViewState: ChatRoomsTopRowViewState {
        ChatRoomsTopRowViewState.archivedChatsViewState(
            count: archivedChatsCount,
            action: { [weak self] in
                self?.router.showArchivedChatRooms()
            }
        )
    }
    
    func noNetworkEmptyViewState() -> ChatRoomsEmptyViewState? {
        if isConnectedToNetwork {
            return nil
        }
        
        return emptyViewStateFactory.noNetworkEmptyViewState(
            hasArchivedChats: hasArchivedChats,
            chatViewMode: chatViewMode,
            contactsOnMega: contactsOnMegaViewState,
            archivedChats: archiveChatsViewState
        )
    }
    
    func updateMeetingListFrame(_ meetingListframeInGlobal: CGRect) {
        meetingListFrame = meetingListframeInGlobal
        let trailingPadding = UIDevice.current.iPad ? 91.0 : 88.0
        createMeetingTipOffsetX = meetingListFrame.width / 2 - trailingPadding
    }
    
    func updateTipOffsetY(for meeting: FutureMeetingRoomViewModel, meetingframeInGlobal: CGRect?) {
        guard currentTip != .showedAll else { return }
        
        if isFirstScheduledMeeting(meeting) {
            if let meetingframeInGlobal = meetingframeInGlobal {
                let offsetY = meetingframeInGlobal.midY - meetingListFrame.minY
                if offsetY < meetingListFrame.midY {
                    startMeetingTipOffsetY = offsetY
                    startMeetingTipArrowDirection = .up
                } else {
                    startMeetingTipOffsetY = meetingframeInGlobal.midY - meetingListFrame.maxY
                    startMeetingTipArrowDirection = .down
                }
            } else {
                startMeetingTipOffsetY = nil
            }
        }
        
        if meeting.isFirstRecurringAndHost {
            if let meetingframeInGlobal = meetingframeInGlobal {
                let offsetY = meetingframeInGlobal.midY - meetingListFrame.minY
                if offsetY < meetingListFrame.midY {
                    recurringMeetingTipOffsetY = offsetY
                    recurringMeetingTipArrowDirection = .up
                } else {
                    recurringMeetingTipOffsetY = meetingframeInGlobal.midY - meetingListFrame.maxY
                    recurringMeetingTipArrowDirection = .down
                }
            } else {
                recurringMeetingTipOffsetY = nil
            }
        }
    }
    
    func makeCreateMeetingTip() -> Tip {
        Tip(title: Strings.Localizable.Meetings.ScheduleMeeting.CreateMeetingTip.title,
            message: Strings.Localizable.Meetings.ScheduleMeeting.CreateMeetingTip.message,
            buttonTitle: Strings.Localizable.Meetings.ScheduleMeeting.TipView.gotIt) { [weak self] in
            guard let self else { return }
            currentTip = .recurringOrStartMeeting
            saveOnboardingTipRecord()
        }
    }
    
    func makeStartMeetingTip() -> Tip {
        Tip(title: Strings.Localizable.Meetings.ScheduleMeeting.StartMeetingTip.title,
            message: Strings.Localizable.Meetings.ScheduleMeeting.StartMeetingTip.message,
            boldMessage: Strings.Localizable.Meetings.ScheduleMeeting.StartMeetingTip.startMeeting,
            buttonTitle: Strings.Localizable.Meetings.ScheduleMeeting.TipView.gotIt) { [weak self] in
            guard let self else { return }
            if currentTip == .recurringOrStartMeeting {
                currentTip = .recurringMeeting
            } else {
                currentTip = .showedAll
            }
            saveOnboardingTipRecord()
        }
    }
    
    func makeRecurringMeetingTip() -> Tip {
        Tip(title: Strings.Localizable.Meetings.ScheduleMeeting.RecurringMeetingTip.title,
            message: Strings.Localizable.Meetings.ScheduleMeeting.RecurringMeetingTip.message,
            boldMessage: Strings.Localizable.Meetings.ScheduleMeeting.RecurringMeetingTip.occurrences,
            buttonTitle: Strings.Localizable.Meetings.ScheduleMeeting.TipView.gotIt) { [weak self] in
            guard let self else { return }
            if currentTip == .recurringOrStartMeeting {
                currentTip = .startMeeting
            } else {
                currentTip = .showedAll
            }
            saveOnboardingTipRecord()
        }
    }
    
    // MARK: - Private
    
    private func fetchChats() {
        cancelLoadingTask()
        loadingTask = Task {
            
            updateUnreadBadgeForChatsAndMeetings()
            
            if chatViewMode == .meetings {
                try await fetchMeetings()
            } else {
                await fetchNonMeetingChats()
            }
        }
    }
    
    private func updateUnreadBadgeForChatsAndMeetings() {
        let chats = chatUseCase.fetchNonMeetings() ?? []
        shouldDisplayUnreadBadgeForChats = chats.contains { $0.unreadCount != 0 }
        let meetings = chatUseCase.fetchMeetings() ?? []
        shouldDisplayUnreadBadgeForMeetings = meetings.contains { $0.unreadCount != 0 }
    }
    
    private func cancelLoadingTask() {
        loadingTask?.cancel()
        loadingTask = nil
    }
    
    private func cancelSearchTask() {
        searchTask?.cancel()
        searchTask = nil
    }
    
    private func cancelMeetingTipTask() {
        meetingTipTask?.cancel()
        meetingTipTask = nil
    }
    
    private func fetchNonMeetingChats() async {
        guard isViewOnScreen else { return }
        
        let chatListItems = chatUseCase.fetchNonMeetings() ?? []
        var newChatRooms = [ChatRoomViewModel]()
        for chatListItem in chatListItems {
            let newChatRoom = await constructChatRoomViewModel(forChatListItem: chatListItem)
            newChatRooms.append(newChatRoom)
        }
        chatRooms = newChatRooms
        
        filterChats()
    }
    
    private func fetchMeetings() async throws {
        guard isViewOnScreen else {
            MEGALogDebug("Unable to fetch chat list items")
            return
        }
        
        try await fetchFutureScheduledMeetings()
    }
    
    /// There are some sync calls: `scheduledMeetings` of `scheduledMeetingUseCase`, map and filter operations.
    /// Making this function nonisolated means it is not main actor isolated, hence avoid blocking main.
    private nonisolated func fetchFutureScheduledMeetings() async throws {
        let scheduledMeetings = scheduledMeetingUseCase.scheduledMeetings()
        let futureScheduledMeetings = scheduledMeetings.filter {
            if $0.parentScheduledId != .invalid {
                return false
            }
            if $0.rules.frequency == .invalid {
                return $0.endDate >= Date()
            } else {
                if let until = $0.rules.until {
                    return until >= Date()
                } else {
                    return true
                }
            }
        }
        
        let upcomingOccurrences = try await scheduledMeetingUseCase.upcomingOccurrences(forScheduledMeetings: futureScheduledMeetings)
        let futureScheduledMeetingsWithOccurrences = filterScheduledMeetingsWithOccurrences(futureScheduledMeetings: futureScheduledMeetings, upcomingOccurrences: upcomingOccurrences)
        
        let futureScheduledMeetingsChatIds = futureScheduledMeetingsWithOccurrences.map(\.chatId)
        await createPastMeetings(with: futureScheduledMeetingsChatIds)
        
        await populateFutureMeetings(from: futureScheduledMeetingsWithOccurrences, withUpcomingOccurrences: upcomingOccurrences)
        await filterMeetings()
    }
    
    private nonisolated func filterScheduledMeetingsWithOccurrences(futureScheduledMeetings: [ScheduledMeetingEntity], upcomingOccurrences: [ChatIdEntity: ScheduledMeetingOccurrenceEntity]) -> [ScheduledMeetingEntity] {
        return futureScheduledMeetings.filter { meeting in
            let hasUpcomingOccurrences = upcomingOccurrences.keys.contains(meeting.scheduledId)
            return meeting.rules.frequency == .invalid || hasUpcomingOccurrences || (!hasUpcomingOccurrences && meeting.endDate >= Date())
        }
    }
    
    private func createPastMeetings(with futureScheduledMeetingsChatIds: [ChatIdEntity]) async {
        let chatListItems = chatUseCase.fetchMeetings() ?? []
        let pastChatListItems: [ChatListItemEntity] = chatListItems.compactMap { chatListItem in
            guard futureScheduledMeetingsChatIds.notContains(where: { $0 == chatListItem.chatId }) else {
                return nil
            }
            return chatListItem
        }
        
        var newChatRooms = [ChatRoomViewModel]()
        for chatListItem in pastChatListItems {
            let newChatRoom = await constructChatRoomViewModel(forChatListItem: chatListItem)
            newChatRooms.append(newChatRoom)
        }
        
        pastMeetings = newChatRooms
    }
    
    private func filterChats() {
        guard !Task.isCancelled else { return }
        
        if searchText.isNotEmpty {
            displayChatRooms = chatRooms?.filter { $0.contains(searchText: searchText)}
        } else {
            displayChatRooms = chatRooms
        }
    }
    
    private func filterMeetings() {
        guard !Task.isCancelled else { return }
        
        if searchText.isNotEmpty {
            displayPastMeetings = pastMeetings?.filter { $0.contains(searchText: searchText)}
            displayFutureMeetings = futureMeetings?.compactMap { $0.filter(withSearchText: searchText) }
        } else {
            displayPastMeetings = pastMeetings
            displayFutureMeetings = futureMeetings
        }
    }
    
    private func populateFutureMeetings(
        from meetings: [ScheduledMeetingEntity],
        withUpcomingOccurrences upcomingOccurrences: [ChatIdEntity: ScheduledMeetingOccurrenceEntity]
    ) async {
        var filteredFutureMeetings = [FutureMeetingSection]()
        for meeting in meetings {
            filteredFutureMeetings = await merge(
                scheduledMeeting: meeting,
                intoFutureMeetingSections: filteredFutureMeetings,
                withUpcomingOccurrences: upcomingOccurrences
            )
        }
        populate(futureMeetingSection: filteredFutureMeetings)
    }
    
    private func merge(
        scheduledMeeting: ScheduledMeetingEntity,
        intoFutureMeetingSections futureMeetingSections: [FutureMeetingSection],
        withUpcomingOccurrences upcomingOccurrences: [ChatIdEntity: ScheduledMeetingOccurrenceEntity]
    ) async -> [FutureMeetingSection] {
        let nextOccurrence = upcomingOccurrences[scheduledMeeting.scheduledId]
        let date = startDate(for: scheduledMeeting, nextOccurrence: nextOccurrence)
        let key = formatedDateString(date)
        let futureMeetingViewModel = await constructFutureMeetingViewModel(for: scheduledMeeting, nextOccurrence: nextOccurrence)
        return merge(
            futureMeetingViewModel: futureMeetingViewModel,
            intoFutureMeetingSections: futureMeetingSections,
            matchingKey: key,
            forDate: date
        )
    }
    
    private func merge(
        futureMeetingViewModel: FutureMeetingRoomViewModel,
        intoFutureMeetingSections futureMeetingSections: [FutureMeetingSection],
        matchingKey key: String,
        forDate date: Date
    ) -> [FutureMeetingSection] {
        var result = futureMeetingSections
        
        if let index = result.firstIndex(where: { $0.title == key }) {
            var futureMeetingSection = result[index]
            futureMeetingSection.insert(futureMeetingViewModel)
            result[index] = futureMeetingSection
        } else {
            result.append(FutureMeetingSection(title: key, date: date, items: [futureMeetingViewModel]))
        }
        
        return result
    }
    
    private func populate(futureMeetingSection: [FutureMeetingSection]) {
        futureMeetings = futureMeetingSection.sorted(by: <)
        updateFirstRecurringMeetingAndHost()
        filterMeetings()
        setFirstMeetingsLoad()
    }
    
    private func setFirstMeetingsLoad() {
        if isFirstMeetingsLoad {
            isFirstMeetingsLoad.toggle()
        }
    }
    
    private func startDate(for meeting: ScheduledMeetingEntity, nextOccurrence: ScheduledMeetingOccurrenceEntity?) -> Date {
        let date: Date
        if let nextOccurrence {
            date = nextOccurrence.startDate
        } else {
            date = meeting.startDate
        }
        
        return date
    }
    
    private func formatedDateString(_ date: Date) -> String {
        if Calendar.current.isDateInToday(date) {
            return Strings.Localizable.today
        } else {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "EEEE, d MMM"
            return dateFormatter.string(from: date)
        }
    }
    
    private func constructChatRoomViewModel(forChatListItem chatListItem: ChatListItemEntity) async -> ChatRoomViewModel {
        let chatRoomUseCase = ChatRoomUseCase(chatRoomRepo: ChatRoomRepository.newRepo)
        let chatRoomUserUseCase = ChatRoomUserUseCase(
            chatRoomRepo: ChatRoomUserRepository.newRepo,
            userStoreRepo: UserStoreRepository(store: MEGAStore.shareInstance())
        )
        let megaHandleUseCase = MEGAHandleUseCase(repo: MEGAHandleRepository.newRepo)
        let userImageUseCase = UserImageUseCase(
            userImageRepo: UserImageRepository(sdk: .shared),
            userStoreRepo: UserStoreRepository(store: MEGAStore.shareInstance()),
            thumbnailRepo: ThumbnailRepository.newRepo,
            fileSystemRepo: FileSystemRepository.newRepo
        )
        let chatListItemDescription = await chatListItemCacheUseCase.description(for: chatListItem)
        let chatListItemAvatar = await chatListItemCacheUseCase.avatar(for: chatListItem)
        
        return ChatRoomViewModel(
            chatListItem: chatListItem,
            router: router,
            chatRoomUseCase: chatRoomUseCase,
            chatRoomUserUseCase: chatRoomUserUseCase,
            userImageUseCase: userImageUseCase,
            chatUseCase: chatUseCase,
            accountUseCase: accountUseCase,
            megaHandleUseCase: megaHandleUseCase,
            callManager: CallKitCallManager.shared,
            callUseCase: CallUseCase(repository: CallRepository.newRepo),
            audioSessionUseCase: AudioSessionUseCase(audioSessionRepository: AudioSessionRepository(audioSession: AVAudioSession())),
            scheduledMeetingUseCase: scheduledMeetingUseCase,
            chatNotificationControl: chatNotificationControl,
            permissionRouter: permissionAlertRouter,
            chatListItemCacheUseCase: chatListItemCacheUseCase,
            chatListItemDescription: chatListItemDescription,
            chatListItemAvatar: chatListItemAvatar
        )
    }
    
    private func constructFutureMeetingViewModel(
        for scheduledMeetingEntity: ScheduledMeetingEntity,
        nextOccurrence: ScheduledMeetingOccurrenceEntity?
    ) async -> FutureMeetingRoomViewModel {
        let chatRoomUseCase = ChatRoomUseCase(chatRoomRepo: ChatRoomRepository.newRepo)
        let chatRoomUserUseCase = ChatRoomUserUseCase(
            chatRoomRepo: ChatRoomUserRepository.newRepo,
            userStoreRepo: UserStoreRepository(store: MEGAStore.shareInstance())
        )
        let megaHandleUseCase = MEGAHandleUseCase(repo: MEGAHandleRepository.newRepo)
        let userImageUseCase = UserImageUseCase(
            userImageRepo: UserImageRepository(sdk: .shared),
            userStoreRepo: UserStoreRepository(store: MEGAStore.shareInstance()),
            thumbnailRepo: ThumbnailRepository.newRepo,
            fileSystemRepo: FileSystemRepository.newRepo
        )
        
        let chatListItemAvatar = await chatListItemCacheUseCase.avatar(for: scheduledMeetingEntity)
        
        return FutureMeetingRoomViewModel(
            scheduledMeeting: scheduledMeetingEntity,
            nextOccurrence: nextOccurrence,
            router: router,
            chatRoomUseCase: chatRoomUseCase,
            chatRoomUserUseCase: chatRoomUserUseCase,
            userImageUseCase: userImageUseCase,
            chatUseCase: chatUseCase,
            accountUseCase: accountUseCase,
            callUseCase: CallUseCase(repository: CallRepository.newRepo),
            audioSessionUseCase: AudioSessionUseCase(audioSessionRepository: AudioSessionRepository(audioSession: AVAudioSession())),
            scheduledMeetingUseCase: scheduledMeetingUseCase,
            megaHandleUseCase: megaHandleUseCase,
            callManager: CallKitCallManager.shared,
            permissionAlertRouter: permissionAlertRouter,
            chatNotificationControl: chatNotificationControl,
            chatListItemCacheUseCase: chatListItemCacheUseCase,
            chatListItemAvatar: chatListItemAvatar
        )
    }
    
    private func configureTitle() {
        switch chatViewType {
        case .regular:
            title = Strings.Localizable.Chat.title
        case .archived:
            title = Strings.Localizable.archivedChats
        }
    }
    
    private func startMeetingMenu() -> MenuButtonModel.Menu {
        .init(
            name: Strings.Localizable.Meetings.StartConversation.ContextMenu.startMeeting,
            image: .startMeeting,
            action: startMeeting
        )
    }
    
    private func joinMeetingMenu() -> MenuButtonModel.Menu {
        .init(
            name: Strings.Localizable.Meetings.StartConversation.ContextMenu.joinMeeting,
            image: .joinAMeeting,
            action: joinMeeting
        )
    }
    
    private func scheduleMeetingMenu() -> MenuButtonModel.Menu {
        .init(
            name: Strings.Localizable.Meetings.StartConversation.ContextMenu.scheduleMeeting,
            image: .scheduleMeeting,
            action: scheduleMeeting
        )
    }
    
    private func listenToChatStatusUpdate() {
        chatUseCase
            .monitorChatStatusChange()
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { error in
                MEGALogDebug("error fetching the changed status \(error)")
            }, receiveValue: { [weak self] statusForUser in
                guard let self, let myHandle = self.accountUseCase.currentUserHandle, statusForUser.0 == myHandle else { return }
                chatStatus = statusForUser.1
            })
            .store(in: &subscriptions)
    }
    
    private func listenToChatListUpdate() {
        chatUseCase
            .monitorChatListItemUpdate()
            .sink { @Sendable [weak self] chatListItems in
                Task { @MainActor in
                    self?.onChatListItemsUpdate(chatListItems)
                }
            }
            .store(in: &subscriptions)
    }
    
    @MainActor
    private func monitorNetworkChanges() {
        let connectionSequence = networkMonitorUseCase.connectionSequence
        
        networkMonitorTask?.cancel()
        networkMonitorTask = Task { [weak self] in
            for await isConnected in connectionSequence {
                self?.isConnectedToNetwork = isConnected
            }
        }
    }
    
    private func monitorActiveCallChanges() {
        chatUseCase
            .monitorChatCallStatusUpdate()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] call in
                self?.updateActiveCall(call)
            }
            .store(in: &subscriptions)
    }
    
    private func monitorChatConnectionStatusUpdate() {
        chatUseCase
            .monitorChatConnectionStatusUpdate(forChatId: .invalid)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] connectionStatus in
                if connectionStatus == .online {
                    self?.fetchChats()
                }
            }
            .store(in: &subscriptions)
    }
    
    private func updateActiveCall(_ call: CallEntity?) {
        if let call, call.status == .inProgress {
            activeCallViewModel = ActiveCallViewModel(
                call: call,
                router: router,
                activeCallUseCase: ActiveCallUseCase(callRepository: CallRepository.newRepo),
                chatRoomUseCase: chatRoomUseCase
            )
        } else {
            activeCallViewModel = nil
        }
    }
    
    private func goToInviteContact() {
        trackInviteFriend()
        router.showInviteContactScreen()
    }
    
    private func onChatListItemsUpdate(_ chatListItems: [ChatListItemEntity]) {
        let chatRooms = chatListItems.compactMap { chatRoomUseCase.chatRoom(forChatId: $0.chatId) }
        if (chatViewMode == .chats &&
            chatRooms.contains(where: { $0.chatType == .oneToOne || $0.chatType == .group })) ||
            (chatViewMode == .meetings &&
             chatRooms.contains(where: { $0.chatType == .meeting })) {
            fetchChats()
        } else if chatListItems.contains(where: {$0.unreadCount != 0 }) {
            updateUnreadBadgeForChatsAndMeetings()
        }
        if chatListItems.contains(where: { $0.changeType == .archived }) {
            refreshContextMenu()
        }
    }
    
    private func refreshContextMenu() {
        Task { @MainActor in refreshContextMenuBarButton?() }
    }
    
    private func fetchScheduledMeetingTipRecord() {
        meetingTipTask = Task { @MainActor in
            defer { cancelMeetingTipTask() }
            
            do {
                if let onboardingRecord = try await userAttributeUseCase.onboardingRecord() {
                    currentTip = onboardingRecord.currentTip
                } else {
                    currentTip = .createMeeting
                }
            } catch {
                MEGALogError("[Chat] when to load saved scheduled meeting onboarding record \(error.localizedDescription)")
            }
        }
    }
    
    private func saveOnboardingTipRecord() {
        Task { @MainActor in
            do {
                let record = ScheduledMeetingOnboardingRecord(currentTip: currentTip.toScheduledMeetingOnboardingTipType())
                try await userAttributeUseCase.saveScheduledMeetingOnBoardingRecord(key: ScheduledMeetingOnboardingKeysEntity.key, record: record)
            } catch {
                MEGALogError("[Chat] Unable to save scheduled meeting onboarding record. \(error.localizedDescription)")
            }
        }
    }
    
    private func isFirstScheduledMeeting(_ meeting: FutureMeetingRoomViewModel) -> Bool {
        guard let firstMeetingId = displayFutureMeetings?.first?.items.first?.scheduledMeeting.scheduledId else { return false }
        return firstMeetingId == meeting.scheduledMeeting.scheduledId
    }
    
    private func updateFirstRecurringMeetingAndHost() {
        guard let futureMeetings = futureMeetings, currentTip != .showedAll else { return }
        let allFutureMeetings = futureMeetings.flatMap {$0.items }
        let firstRecurringMeetingAndHost = allFutureMeetings.first { $0.isRecurring && $0.scheduledMeeting.organizerUserId == accountUseCase.currentUserHandle }
        firstRecurringMeetingAndHost?.isFirstRecurringAndHost = true
    }
}

// MARK: - ChatMenuDelegate
extension ChatRoomsListViewModel: ChatMenuDelegate {
    
    nonisolated func chatStatusMenu(didSelect action: ChatStatusEntity) {
        tracker.trackAnalyticsEvent(with: ChatRoomStatusMenuItemEvent())
        Task { @MainActor in
            changeChatStatus(to: action)
        }
    }
    
    nonisolated func chatDoNotDisturbMenu(didSelect option: DNDTurnOnOption) {
        tracker.trackAnalyticsEvent(with: ChatRoomDNDMenuItemEvent())
        Task { @MainActor in
            globalDNDNotificationControl.turnOnDND(dndTurnOnOption: option) { [weak self] in
                self?.refreshContextMenu()
            }
        }
    }
    
    nonisolated func chatDisableDoNotDisturb() {
        Task { @MainActor in
            guard globalDNDNotificationControl.isGlobalDNDEnabled else {
                return
            }
            
            globalDNDNotificationControl.turnOffDND { [weak self] in
                self?.refreshContextMenu()
            }
        }
    }
    
    nonisolated func archivedChatsTapped() {
        tracker.trackAnalyticsEvent(with: ArchivedChatsMenuItemEvent())
        Task { @MainActor in
            router.showArchivedChatRooms()
        }
    }
}

// MARK: - MeetingContextMenuDelegate
extension ChatRoomsListViewModel: MeetingContextMenuDelegate {
    nonisolated func meetingContextMenu(didSelect action: MeetingActionEntity) {
        Task { @MainActor in
            if shouldCancelActionIfCallInProgress(action) {
                router.presentMeetingAlreadyExists()
                return
            }
            
            switch action {
            case .startMeeting:
                startMeeting()
            case .joinMeeting:
                joinMeeting()
            case .scheduleMeeting:
                scheduleMeeting()
            }
        }
    }
    
    private func shouldCancelActionIfCallInProgress(_ action: MeetingActionEntity) -> Bool {
        // It is not allowed to start o join with link another meeting if an active call is in progress
        chatUseCase.existsActiveCall() && [.startMeeting, .joinMeeting].contains(action)
    }
}

// MARK: - MyAvatarPresenterProtocol
extension ChatRoomsListViewModel: MyAvatarPresenterProtocol {
    func setupMyAvatar(barButton: UIBarButtonItem) {
        myAvatarBarButton = barButton
        refreshMyAvatar()
    }
    
    func configureMyAvatarManager() {
        guard let navController = router.navigationController else { return }
        myAvatarManager = MyAvatarManager(navigationController: navController, delegate: self)
        myAvatarManager?.setup()
    }
    
    func refreshMyAvatar() {
        myAvatarManager?.refreshMyAvatar()
    }
}

// MARK: - PushNotificationControlProtocol
extension ChatRoomsListViewModel: PushNotificationControlProtocol {
    func presentAlertController(_ alert: UIAlertController) {
        router.present(alert: alert, animated: true)
    }
    
    func reloadDataIfNeeded() {
        switch chatViewMode {
        case .chats:
            chatRooms?.forEach { $0.pushNotificationSettingsChanged() }
        case .meetings:
            pastMeetings?.forEach { $0.pushNotificationSettingsChanged() }
            futureMeetings?.forEach { $0.items.forEach { $0.pushNotificationSettingsChanged() } }
        }
    }
    
    func pushNotificationSettingsLoaded() {
        refreshContextMenu()
    }
}
