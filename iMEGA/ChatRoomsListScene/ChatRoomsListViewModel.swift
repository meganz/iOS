import ChatRepo
import Combine
import Foundation
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

final class ChatRoomsListViewModel: ObservableObject {
    let router: any ChatRoomsListRouting
    private let chatUseCase: any ChatUseCaseProtocol
    private let chatRoomUseCase: any ChatRoomUseCaseProtocol
    private let contactsUseCase: any ContactsUseCaseProtocol
    private let networkMonitorUseCase: any NetworkMonitorUseCaseProtocol
    private let accountUseCase: any AccountUseCaseProtocol
    private let scheduledMeetingUseCase: any ScheduledMeetingUseCaseProtocol
    private let userAttributeUseCase: any UserAttributeUseCaseProtocol
    private let permissionHandler: any DevicePermissionsHandling
    private let permissionAlertRouter: any PermissionAlertRouting
    private let featureFlagProvider: any FeatureFlagProviderProtocol
    private let notificationCenter: NotificationCenter
    private let chatViewType: ChatViewType
    
    lazy var contextMenuManager = ContextMenuManager(chatMenuDelegate: self,
                                                     meetingContextMenuDelegate: self,
                                                     createContextMenuUseCase: CreateContextMenuUseCase(repo: CreateContextMenuRepository.newRepo))
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
        return isSearchActive || !isChatRoomEmpty
    }
    
    @Published var chatViewMode: ChatViewMode
    @Published var chatStatus: ChatStatusEntity?
    @Published var title: String = Strings.Localizable.Chat.title
    @Published var myAvatarBarButton: UIBarButtonItem?
    @Published var isConnectedToNetwork: Bool
    @Published var isFirstMeetingsLoad: Bool
    @Published var bottomViewHeight: CGFloat = 0
    
    @Published var displayChatRooms: [ChatRoomViewModel]?
    @Published var displayPastMeetings: [ChatRoomViewModel]?
    @Published var displayFutureMeetings: [FutureMeetingSection]?
    
    @Published var contactsOnMegaViewState: ChatRoomsTopRowViewState?
    
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
    
    private var loadingTask: Task<Void, Never>?
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

    init(router: some ChatRoomsListRouting,
         chatUseCase: any ChatUseCaseProtocol,
         chatRoomUseCase: any ChatRoomUseCaseProtocol,
         contactsUseCase: any ContactsUseCaseProtocol,
         networkMonitorUseCase: any NetworkMonitorUseCaseProtocol,
         accountUseCase: any AccountUseCaseProtocol,
         scheduledMeetingUseCase: any ScheduledMeetingUseCaseProtocol,
         userAttributeUseCase: any UserAttributeUseCaseProtocol,
         notificationCenter: NotificationCenter = NotificationCenter.default,
         chatType: ChatViewType = .regular,
         chatViewMode: ChatViewMode = .chats,
         permissionHandler: some DevicePermissionsHandling,
         permissionAlertRouter: some PermissionAlertRouting,
         featureFlagProvider: some FeatureFlagProviderProtocol = DIContainer.featureFlagProvider
    ) {
        self.router = router
        self.chatUseCase = chatUseCase
        self.contactsUseCase = contactsUseCase
        self.chatRoomUseCase = chatRoomUseCase
        self.networkMonitorUseCase = networkMonitorUseCase
        self.scheduledMeetingUseCase = scheduledMeetingUseCase
        self.accountUseCase = accountUseCase
        self.userAttributeUseCase = userAttributeUseCase
        self.notificationCenter = notificationCenter
        self.chatViewType = chatType
        self.chatViewMode = chatViewMode
        self.isConnectedToNetwork = networkMonitorUseCase.isConnected()
        self.searchText = ""
        self.permissionHandler = permissionHandler
        self.permissionAlertRouter = permissionAlertRouter
        self.featureFlagProvider = featureFlagProvider
        self.isSearchActive = false
        self.isFirstMeetingsLoad = true
        
        configureTitle()
    }
    
    @MainActor
    func askForNotificationsPermissionsIfNeeded() async {
        let shouldAsk = await permissionHandler.shouldAskForNotificationPermission()
        if shouldAsk {
            permissionAlertRouter
                .presentModalNotificationsPermissionPrompt()
        }
    }
    
    func loadChatRoomsIfNeeded() {
        isViewOnScreen = true
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
        createTaskToUpdateContactsOnMegaViewStateIfRequired()
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
        CMConfigEntity(menuType: .menu(type: .chat),
                       isDoNotDisturbEnabled: globalDNDNotificationControl.isGlobalDNDEnabled,
                       timeRemainingToDeactiveDND: globalDNDNotificationControl.timeRemainingToDeactiveDND ?? "",
                       chatStatus: chatUseCase.chatStatus(),
                       isArchivedChatsVisible: chatUseCase.archivedChatListCount() > 0)
    }
    
    func selectChatMode(_ mode: ChatViewMode) {
        guard mode != chatViewMode else { return }
        chatViewMode = mode
        
        fetchChats()
        createTaskToUpdateContactsOnMegaViewStateIfRequired()
    }
    
    func addChatButtonTapped() {
        router.presentStartConversation()
    }
    
    func changeChatStatus(to status: ChatStatusEntity) {
        guard status != chatStatus else {
            return
        }
        chatUseCase.changeChatStatus(to: status)
    }
    
    func archiveChatsViewState() -> ChatRoomsTopRowViewState? {
        guard chatUseCase.archivedChatListCount() > 0 else { return nil }
        
        return ChatRoomsTopRowViewState(
            image: Asset.Images.Chat.archiveChat.image,
            description: Strings.Localizable.archivedChats,
            rightDetail: "\(chatUseCase.archivedChatListCount())") { [weak self] in
                self?.router.showArchivedChatRooms()
            }
    }
    
    func searchEmptyViewState() -> ChatRoomsEmptyViewState {
        ChatRoomsEmptyViewState(
            contactsOnMega: nil,
            archivedChats: nil,
            centerImageAsset: Asset.Images.EmptyStates.searchEmptyState,
            centerTitle: Strings.Localizable.noResults,
            centerDescription: nil,
            bottomButtonTitle: nil,
            bottomButtonAction: nil,
            bottomButtonMenus: nil
        )
    }
    
    func noNetworkEmptyViewState() -> ChatRoomsEmptyViewState {
        ChatRoomsEmptyViewState(
            contactsOnMega: chatViewMode == .chats ? contactsOnMegaViewState : nil,
            archivedChats: archiveChatsViewState(),
            centerImageAsset: Asset.Images.EmptyStates.noInternetEmptyState,
            centerTitle: chatViewMode == .chats ? Strings.Localizable.Chat.Chats.EmptyState.title : Strings.Localizable.Chat.Meetings.EmptyState.title,
            centerDescription: chatViewMode == .chats ? Strings.Localizable.Chat.Chats.EmptyState.description : Strings.Localizable.Chat.Meetings.EmptyState.description,
            bottomButtonTitle: nil,
            bottomButtonAction: nil,
            bottomButtonMenus: nil
        )
    }
    
    func emptyChatRoomsViewState() -> ChatRoomsEmptyViewState {
        ChatRoomsEmptyViewState(
            contactsOnMega: chatViewMode == .chats ? contactsOnMegaViewState : nil,
            archivedChats: archiveChatsViewState(),
            centerImageAsset: chatViewMode == .chats ? Asset.Images.EmptyStates.chatEmptyState : Asset.Images.EmptyStates.meetingEmptyState,
            centerTitle: chatViewMode == .chats ? Strings.Localizable.Chat.Chats.EmptyState.title : Strings.Localizable.Chat.Meetings.EmptyState.title,
            centerDescription: chatViewMode == .chats ? Strings.Localizable.Chat.Chats.EmptyState.description : Strings.Localizable.Chat.Meetings.EmptyState.description,
            bottomButtonTitle: chatViewMode == .chats ? Strings.Localizable.Chat.Chats.EmptyState.Button.title : Strings.Localizable.Chat.Meetings.EmptyState.Button.title,
            bottomButtonAction: { [weak self] in
                guard let self else { return }
                if self.chatViewMode == .chats {
                    self.addChatButtonTapped()
                }
            },
            bottomButtonMenus: chatViewMode == .meetings && isConnectedToNetwork ? [startMeetingMenu(), joinMeetingMenu(), scheduleMeetingMenu()] : nil
        )
    }
    
    @MainActor
    func updateMeetingListFrame(_ meetingListframeInGlobal: CGRect) {
        meetingListFrame = meetingListframeInGlobal
        let trailingPadding = UIDevice.current.iPad ? 91.0 : 88.0
        createMeetingTipOffsetX = meetingListFrame.width / 2 - trailingPadding
    }
    
    @MainActor
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
        loadingTask = Task {
            defer { cancelLoadingTask() }
            
            if chatViewMode == .meetings {
                await fetchMeetings()
            } else {
                await fetchNonMeetingChats()
            }
        }
    }
    
    private func createTaskToUpdateContactsOnMegaViewStateIfRequired() {
        if chatViewMode == .chats {
            Task {
                await updateContactsOnMegaViewStateIfRequired()
            }
        }
    }
    
    private func updateContactsOnMegaViewStateIfRequired() async {
        let description = descriptionForContactsOnMegaViewState()
        if contactsOnMegaViewState?.description != description {
            await createContactsOnMegaViewState(withDescription: description)
        }
    }
    
    private func descriptionForContactsOnMegaViewState() -> String {
        let description: String
        description = Strings.Localizable.inviteContactNow
        
        return description
    }
    
    @MainActor
    private func createContactsOnMegaViewState(withDescription description: String) {
        contactsOnMegaViewState = ChatRoomsTopRowViewState(
            image: Asset.Images.Chat.inviteToChat.image,
            description: description) { [weak self] in
                self?.topRowViewTapped()
            }
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
        chatRooms = chatListItems.map(constructChatRoomViewModel)
        
        await filterChats()
    }
    
    private func fetchMeetings() async {
        guard isViewOnScreen else {
            MEGALogDebug("Unable to fetch chat list items")
            return
        }
        
        fetchFutureScheduledMeetings()
    }
    
    private func fetchFutureScheduledMeetings() {
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
        
        Task {
            let upcomingOccurrences = try await scheduledMeetingUseCase.upcomingOccurrences(forScheduledMeetings: futureScheduledMeetings)
            let futureScheduledMeetingsWithOccurrences = filterScheduledMeetingsWithOccurrences(futureScheduledMeetings: futureScheduledMeetings, upcomingOccurrences: upcomingOccurrences)
            
            let futureScheduledMeetingsChatIds = futureScheduledMeetingsWithOccurrences.map(\.chatId)
            createPastMeetings(with: futureScheduledMeetingsChatIds)
            
            await populateFutureMeetings(from: futureScheduledMeetingsWithOccurrences, withUpcomingOccurrences: upcomingOccurrences)
            await filterMeetings()
        }
    }
    
    private func filterScheduledMeetingsWithOccurrences(futureScheduledMeetings: [ScheduledMeetingEntity], upcomingOccurrences: [ChatIdEntity: ScheduledMeetingOccurrenceEntity]) -> [ScheduledMeetingEntity] {
        return futureScheduledMeetings.filter { meeting in
            let hasUpcomingOccurrences = upcomingOccurrences.keys.contains(meeting.scheduledId)
            return meeting.rules.frequency == .invalid || hasUpcomingOccurrences || (!hasUpcomingOccurrences && meeting.endDate >= Date())
        }
    }
    
    private func createPastMeetings(with futureScheduledMeetingsChatIds: [ChatIdEntity]) {
        let chatListItems = chatUseCase.fetchMeetings() ?? []

        pastMeetings = chatListItems.compactMap { chatListItem in
            guard futureScheduledMeetingsChatIds.notContains(where: { $0 == chatListItem.chatId }) else {
                return nil
            }
            
            return constructChatRoomViewModel(forChatListItem: chatListItem)
        }
    }
    
    @MainActor
    private func filterChats() {
        guard !Task.isCancelled else { return }
        
        if searchText.isNotEmpty {
            displayChatRooms = chatRooms?.filter { $0.contains(searchText: searchText)}
        } else {
            displayChatRooms = chatRooms
        }
    }
    
    @MainActor
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
    
    @MainActor
    private func populateFutureMeetings(
        from meetings: [ScheduledMeetingEntity],
        withUpcomingOccurrences upcomingOccurrences: [ChatIdEntity: ScheduledMeetingOccurrenceEntity]
    ) {
        let filteredFutureMeetings = meetings.reduce([FutureMeetingSection]()) { futureMeetingSections, meeting in
            merge(
                scheduledMeeting: meeting,
                intoFutureMeetingSections: futureMeetingSections,
                withUpcomingOccurrences: upcomingOccurrences
            )
        }
        
       populate(futureMeetingSection: filteredFutureMeetings)
    }
    
    private func merge(
        scheduledMeeting: ScheduledMeetingEntity,
        intoFutureMeetingSections futureMeetingSections: [FutureMeetingSection],
        withUpcomingOccurrences upcomingOccurrences: [ChatIdEntity: ScheduledMeetingOccurrenceEntity]
    ) -> [FutureMeetingSection] {
        let nextOccurrence = upcomingOccurrences[scheduledMeeting.scheduledId]
        let date = startDate(for: scheduledMeeting, nextOccurrence: nextOccurrence)
        let key = formatedDateString(date)
        let futureMeetingViewModel = constructFutureMeetingViewModel(for: scheduledMeeting, nextOccurrence: nextOccurrence)
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
    
    @MainActor
    private func populate(futureMeetingSection: [FutureMeetingSection]) {
        futureMeetings = futureMeetingSection.sorted(by: <)
        updateFirstRecurringMeetingAndHost()
        filterMeetings()
        setFirstMeetingsLoad()
    }
    
    @MainActor
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
    
    private func constructChatRoomViewModel(forChatListItem chatListItem: ChatListItemEntity) -> ChatRoomViewModel {
        let chatRoomUseCase = ChatRoomUseCase(chatRoomRepo: ChatRoomRepository.sharedRepo)
        let chatRoomUserUseCase = ChatRoomUserUseCase(chatRoomRepo: ChatRoomUserRepository.newRepo,
                                                      userStoreRepo: UserStoreRepository(store: MEGAStore.shareInstance()))
        let megaHandleUseCase = MEGAHandleUseCase(repo: MEGAHandleRepository.newRepo)
        let userImageUseCase = UserImageUseCase(
            userImageRepo: UserImageRepository(sdk: .shared),
            userStoreRepo: UserStoreRepository(store: MEGAStore.shareInstance()),
            thumbnailRepo: ThumbnailRepository.newRepo,
            fileSystemRepo: FileSystemRepository.newRepo
        )
        
        return ChatRoomViewModel(
            chatListItem: chatListItem,
            router: router,
            chatRoomUseCase: chatRoomUseCase,
            chatRoomUserUseCase: chatRoomUserUseCase,
            userImageUseCase: userImageUseCase,
            chatUseCase: chatUseCase,
            accountUseCase: accountUseCase,
            megaHandleUseCase: megaHandleUseCase,
            callUseCase: CallUseCase(repository: CallRepository(chatSdk: .shared, callActionManager: CallActionManager.shared)),
            audioSessionUseCase: AudioSessionUseCase(audioSessionRepository: AudioSessionRepository(audioSession: AVAudioSession(), callActionManager: CallActionManager.shared)), scheduledMeetingUseCase: scheduledMeetingUseCase,
            chatNotificationControl: chatNotificationControl, permissionHandler: permissionHandler
        )
    }
    
    private func constructFutureMeetingViewModel(
        for scheduledMeetingEntity: ScheduledMeetingEntity,
        nextOccurrence: ScheduledMeetingOccurrenceEntity?
    ) -> FutureMeetingRoomViewModel {
        let chatRoomUseCase = ChatRoomUseCase(chatRoomRepo: ChatRoomRepository.sharedRepo)
        let chatRoomUserUseCase = ChatRoomUserUseCase(chatRoomRepo: ChatRoomUserRepository.newRepo,
                                                      userStoreRepo: UserStoreRepository(store: MEGAStore.shareInstance()))
        let megaHandleUseCase = MEGAHandleUseCase(repo: MEGAHandleRepository.newRepo)
        let userImageUseCase = UserImageUseCase(
            userImageRepo: UserImageRepository(sdk: .shared),
            userStoreRepo: UserStoreRepository(store: MEGAStore.shareInstance()),
            thumbnailRepo: ThumbnailRepository.newRepo,
            fileSystemRepo: FileSystemRepository.newRepo
        )
        
        return FutureMeetingRoomViewModel(
            scheduledMeeting: scheduledMeetingEntity,
            nextOccurrence: nextOccurrence,
            router: router,
            chatRoomUseCase: chatRoomUseCase,
            chatRoomUserUseCase: chatRoomUserUseCase,
            userImageUseCase: userImageUseCase,
            chatUseCase: chatUseCase,
            accountUseCase: accountUseCase,
            callUseCase: CallUseCase(repository: CallRepository(chatSdk: .shared, callActionManager: CallActionManager.shared)),
            audioSessionUseCase: AudioSessionUseCase(audioSessionRepository: AudioSessionRepository(audioSession: AVAudioSession(), callActionManager: CallActionManager.shared)),
            scheduledMeetingUseCase: scheduledMeetingUseCase,
            megaHandleUseCase: megaHandleUseCase,
            permissionAlertRouter: permissionAlertRouter,
            chatNotificationControl: chatNotificationControl
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
    
    private func startMeetingMenu() -> ChatRoomsEmptyBottomButtonMenu {
        ChatRoomsEmptyBottomButtonMenu(
            name: Strings.Localizable.Meetings.StartConversation.ContextMenu.startMeeting,
            image: Asset.Images.Meetings.startMeeting
        ) { [weak self] in
            guard let self else { return }
            self.router.presentCreateMeeting()
        }
    }
    
    private func joinMeetingMenu() -> ChatRoomsEmptyBottomButtonMenu {
        ChatRoomsEmptyBottomButtonMenu(
            name: Strings.Localizable.Meetings.StartConversation.ContextMenu.joinMeeting,
            image: Asset.Images.Meetings.joinAMeeting
        ) { [weak self] in
            guard let self else { return }
            self.router.presentEnterMeeting()
        }
    }
    
    private func scheduleMeetingMenu() -> ChatRoomsEmptyBottomButtonMenu {
        ChatRoomsEmptyBottomButtonMenu(
            name: Strings.Localizable.Meetings.StartConversation.ContextMenu.scheduleMeeting,
            image: Asset.Images.Meetings.scheduleMeeting
        ) { [weak self] in
            guard let self else { return }
            self.router.presentScheduleMeeting()
        }
    }
    
    private func listenToChatStatusUpdate() {
        chatUseCase
            .monitorChatStatusChange()
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { error in
                MEGALogDebug("error fetching the changed status \(error)")
            }, receiveValue: { [weak self] statusForUser in
                guard let self, let myHandle = self.accountUseCase.currentUserHandle, statusForUser.0 == myHandle else { return }
                self.chatStatus = statusForUser.1
            })
            .store(in: &subscriptions)
    }
    
    private func listenToChatListUpdate() {
        chatUseCase
            .monitorChatListItemUpdate()
            .sink { [weak self] chatListItems in
                self?.onChatListItemsUpdate(chatListItems)
            }
            .store(in: &subscriptions)
    }
    
    private func monitorNetworkChanges() {
        networkMonitorUseCase.networkPathChanged { [weak self] isConnectedToNetwork in
            guard let self else { return }
            self.isConnectedToNetwork = isConnectedToNetwork
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
                activeCallUseCase: ActiveCallUseCase(callRepository: CallRepository(chatSdk: .shared, callActionManager: CallActionManager.shared)),
                chatRoomUseCase: chatRoomUseCase
            )
        } else {
            activeCallViewModel = nil
        }
    }
    
    private func topRowViewTapped() {
        router.showInviteContactScreen()
    }
    
    private func onChatListItemsUpdate(_ chatListItems: [ChatListItemEntity]) {
        let chatRooms = chatListItems.compactMap { chatRoomUseCase.chatRoom(forChatId: $0.chatId) }
        if (chatViewMode == .chats
            && chatRooms.contains(where: { $0.chatType == .oneToOne || $0.chatType == .group }))
            || (chatViewMode == .meetings
                && chatRooms.contains(where: { $0.chatType == .meeting })) {
            DispatchQueue.main.async {
                self.fetchChats()
            }
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
    
    func chatStatusMenu(didSelect action: ChatStatusEntity) {
        changeChatStatus(to: action)
    }
    
    func chatDoNotDisturbMenu(didSelect option: DNDTurnOnOption) {
        globalDNDNotificationControl.turnOnDND(dndTurnOnOption: option) { [weak self] in
            self?.refreshContextMenu()
        }
    }
    
    func chatDisableDoNotDisturb() {
        guard globalDNDNotificationControl.isGlobalDNDEnabled else {
            return
        }
        
        globalDNDNotificationControl.turnOffDND { [weak self] in
            self?.refreshContextMenu()
        }
    }
    
    func archivedChatsTapped() {
        router.showArchivedChatRooms()
    }
}

// MARK: - MeetingContextMenuDelegate
extension ChatRoomsListViewModel: MeetingContextMenuDelegate {
    func meetingContextMenu(didSelect action: MeetingActionEntity) {
        if chatUseCase.existsActiveCall() {
            router.presentMeetingAlreadyExists()
            return
        }
        
        switch action {
        case .startMeeting:
            router.presentCreateMeeting()
        case .joinMeeting:
            router.presentEnterMeeting()
        case .scheduleMeeting:
            router.presentScheduleMeeting()
        }
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
