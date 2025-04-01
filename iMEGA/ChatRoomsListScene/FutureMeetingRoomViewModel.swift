import Combine
import MEGAAnalyticsiOS
import MEGAAppPresentation
import MEGADomain
import MEGAL10n

@MainActor
final class FutureMeetingRoomViewModel: ObservableObject, Identifiable {
    let scheduledMeeting: ScheduledMeetingEntity
    let nextOccurrence: ScheduledMeetingOccurrenceEntity?
    private let router: any ChatRoomsListRouting
    let chatRoomAvatarViewModel: ChatRoomAvatarViewModel?
    private let chatRoomUseCase: any ChatRoomUseCaseProtocol
    private let chatRoomUserUseCase: any ChatRoomUserUseCaseProtocol
    private let chatUseCase: any ChatUseCaseProtocol
    private var chatNotificationControl: ChatNotificationControl
    private let callUseCase: any CallUseCaseProtocol
    private let audioSessionUseCase: any AudioSessionUseCaseProtocol
    private let scheduledMeetingUseCase: any ScheduledMeetingUseCaseProtocol
    private let handleUseCase: any MEGAHandleUseCaseProtocol
    private let callController: any CallControllerProtocol
    private let callsManager: any CallsManagerProtocol
    private let permissionAlertRouter: any PermissionAlertRouting
    private let tracker: any AnalyticsTracking
    private let callInProgressTimeReporter: any CallInProgressTimeReporting
    private var callInProgressTimeMonitorTask: Task<Void, Never>? {
        willSet {
            callInProgressTimeMonitorTask?.cancel()
        }
    }
    private var searchString: String?
    private(set) var contextMenuOptions: [ChatRoomContextMenuOption]?
    private(set) var isMuted: Bool
    
    private var subscriptions = Set<AnyCancellable>()
    
    private var chatHasMessagesSubscription: AnyCancellable?
    var isFirstRecurringAndHost = false
    
    var title: String {
        scheduledMeeting.title
    }
    
    lazy var time: String = {
        return time(for: scheduledMeeting, nextOccurrence: nextOccurrence)
    }()

    var recurrence: String {
        switch scheduledMeeting.rules.frequency {
        case .invalid:
            return ""
        case .daily:
            return Strings.Localizable.Meetings.Scheduled.Recurring.daily
        case .weekly:
            return Strings.Localizable.Meetings.Scheduled.Recurring.weekly
        case .monthly:
            return Strings.Localizable.Meetings.Scheduled.Recurring.monthly
        }
    }
    
    var shouldShowUnreadCount = false
    private(set) var unreadCountString = ""
    var isRecurring: Bool
    var chatHasMessages = false
    
    var lastMessageTimestamp: String? {
        let chatListItem = chatUseCase.chatListItem(forChatId: scheduledMeeting.chatId)
        if let lastMessageDate = chatListItem?.lastMessageDate {
            if lastMessageDate.isToday(on: .autoupdatingCurrent) {
                return DateFormatter.fromTemplate("HH:mm").localisedString(from: lastMessageDate)
            } else if let difference = lastMessageDate.dayDistance(toFutureDate: Date(), on: .autoupdatingCurrent), difference < 7 {
                return DateFormatter.fromTemplate("EEE").localisedString(from: lastMessageDate)
            } else {
                return DateFormatter.fromTemplate("ddyyMM").localisedString(from: lastMessageDate)
            }
        }
        
        return nil
    }
        
    @Published var showDNDTurnOnOptions = false
    @Published var showCancelMeetingAlert = false
    @Published var existsInProgressCallInChatRoom = false
    @Published var totalCallDuration: TimeInterval = 0
    
    init(
        scheduledMeeting: ScheduledMeetingEntity,
        nextOccurrence: ScheduledMeetingOccurrenceEntity?,
        router: some ChatRoomsListRouting,
        chatRoomUseCase: some ChatRoomUseCaseProtocol,
        chatRoomUserUseCase: some ChatRoomUserUseCaseProtocol,
        userImageUseCase: some UserImageUseCaseProtocol,
        chatUseCase: some ChatUseCaseProtocol,
        accountUseCase: some AccountUseCaseProtocol,
        callUseCase: some CallUseCaseProtocol,
        audioSessionUseCase: some AudioSessionUseCaseProtocol,
        scheduledMeetingUseCase: some ScheduledMeetingUseCaseProtocol,
        megaHandleUseCase: some MEGAHandleUseCaseProtocol,
        callController: some CallControllerProtocol,
        callsManager: some CallsManagerProtocol,
        permissionAlertRouter: some PermissionAlertRouting,
        tracker: some AnalyticsTracking = DIContainer.tracker,
        chatNotificationControl: ChatNotificationControl,
        chatListItemCacheUseCase: some ChatListItemCacheUseCaseProtocol,
        chatListItemAvatar: ChatListItemAvatarEntity? = nil,
        callInProgressTimeReporter: some CallInProgressTimeReporting = CallInProgressTimeReporter()
    ) {
        
        self.scheduledMeeting = scheduledMeeting
        self.nextOccurrence = nextOccurrence
        self.router = router
        self.chatRoomUseCase = chatRoomUseCase
        self.chatRoomUserUseCase = chatRoomUserUseCase
        self.chatUseCase = chatUseCase
        self.callUseCase = callUseCase
        self.audioSessionUseCase = audioSessionUseCase
        self.scheduledMeetingUseCase = scheduledMeetingUseCase
        self.handleUseCase = megaHandleUseCase
        self.callController = callController
        self.callsManager = callsManager
        self.permissionAlertRouter = permissionAlertRouter
        self.chatNotificationControl = chatNotificationControl
        self.tracker = tracker
        self.isMuted = chatNotificationControl.isChatDNDEnabled(chatId: scheduledMeeting.chatId)
        self.isRecurring = scheduledMeeting.rules.frequency != .invalid
        self.callInProgressTimeReporter = callInProgressTimeReporter
        
        if let chatRoomEntity = chatRoomUseCase.chatRoom(forChatId: scheduledMeeting.chatId) {
            self.chatRoomAvatarViewModel = ChatRoomAvatarViewModel(
                title: scheduledMeeting.title,
                peerHandle: chatRoomEntity.peers.first?.handle ?? .invalid,
                chatRoom: chatRoomEntity,
                chatRoomUseCase: chatRoomUseCase,
                chatRoomUserUseCase: chatRoomUserUseCase,
                userImageUseCase: userImageUseCase,
                chatUseCase: chatUseCase,
                accountUseCase: accountUseCase,
                megaHandleUseCase: megaHandleUseCase,
                chatListItemCacheUseCase: chatListItemCacheUseCase,
                chatListItemAvatar: chatListItemAvatar
            )
            self.shouldShowUnreadCount = chatRoomEntity.unreadCount != 0
            if chatRoomEntity.unreadCount > 0 {
                self.unreadCountString = chatRoomEntity.unreadCount > 99 ? "99+" : "\(chatRoomEntity.unreadCount)"
            } else {
                self.unreadCountString = "\(-chatRoomEntity.unreadCount)+"
            }
            
        } else {
            self.chatRoomAvatarViewModel = nil
        }
        
        loadFutureMeetingSearchString()
        self.existsInProgressCallInChatRoom = chatUseCase.isCallInProgress(for: scheduledMeeting.chatId)
        if let call = callUseCase.call(for: scheduledMeeting.chatId) {
            self.startMonitoringCallInProgressTime(for: call)
        }
        monitorActiveCallChanges()
        self.contextMenuOptions = constructContextMenuOptions()
    }
    
    deinit {
        callInProgressTimeMonitorTask?.cancel()
    }
    
    func contains(searchText: String) -> Bool {
        searchString?.localizedCaseInsensitiveContains(searchText) ?? false
    }
    
    func dndTurnOnOptions() -> [DNDTurnOnOption] {
        ChatNotificationControl.dndTurnOnOptions()
    }
    
    func turnOnDNDOption(_ option: DNDTurnOnOption) {
        chatNotificationControl.turnOnDND(chatId: scheduledMeeting.chatId, option: option)
    }
    
    func pushNotificationSettingsChanged() {
        let newValue = chatNotificationControl.isChatDNDEnabled(chatId: scheduledMeeting.chatId)
        guard isMuted != newValue else { return }
        
        contextMenuOptions = constructContextMenuOptions()
        isMuted = newValue
        objectWillChange.send()
    }
    
    func showDetails() {
        router.showDetails(forChatId: scheduledMeeting.chatId)
    }
    
    func cancelMeetingAlertData() -> CancelMeetingAlertDataModel {
        return CancelMeetingAlertDataModel(
            title: Strings.Localizable.Meetings.Scheduled.CancelAlert.title(scheduledMeeting.title),
            message: chatHasMessages ? Strings.Localizable.Meetings.Scheduled.CancelAlert.Description.withMessages : Strings.Localizable.Meetings.Scheduled.CancelAlert.Description.withoutMessages,
            primaryButtonTitle: chatHasMessages ? Strings.Localizable.Meetings.Scheduled.CancelAlert.Option.Confirm.withMessages : Strings.Localizable.Meetings.Scheduled.CancelAlert.Option.Confirm.withoutMessages,
            primaryButtonAction: cancelScheduledMeeting,
            secondaryButtonTitle: Strings.Localizable.Meetings.Scheduled.CancelAlert.Option.dontCancel)
    }
    
    func startOrJoinCall() {
        guard let chatRoom = chatRoomUseCase.chatRoom(forChatId: scheduledMeeting.chatId) else {
            MEGALogError("Not able to fetch chat room for start or join call")
            return
        }
        
        if existsInProgressCallInChatRoom {
            joinCall(in: chatRoom)
        } else {
            startCall(in: chatRoom)
        }
    }
    
    // MARK: - Private methods.
    
    private func loadFutureMeetingSearchString() {
        Task { [weak self] in
            guard let self, let chatRoom = self.chatRoomUseCase.chatRoom(forChatId: self.scheduledMeeting.chatId) else {
                return
            }
            
            do {
                self.searchString = try await self.chatRoomUserUseCase.chatRoomUsersDescription(for: chatRoom)
            } catch {
                MEGALogDebug("Unable to populate search string for \(scheduledMeeting.chatId) with error \(error.localizedDescription)")
            }
        }
    }
    
    private func showChatRoomInfo() {
        router.showMeetingInfo(for: scheduledMeeting)
    }
    
    private func toggleDND() {
        if chatNotificationControl.isChatDNDEnabled(chatId: scheduledMeeting.chatId) {
            chatNotificationControl.turnOffDND(chatId: scheduledMeeting.chatId)
        } else {
            showDNDTurnOnOptions = true
        }
    }
    
    private func cancelMeeting() {
        guard let chatRoom = self.chatRoomUseCase.chatRoom(forChatId: self.scheduledMeeting.chatId) else { return }
        subscribeToMessagesLoaded(in: chatRoom)
        checkIfChatHasMessages(for: chatRoom)
    }
    
    private func checkIfChatHasMessages(for chatRoom: ChatRoomEntity) {
        let source = chatRoomUseCase.loadMessages(for: chatRoom, count: 10)
        if source == .none {
            chatHasMessages(chatRoom, false)
        }
    }
    
    private func subscribeToMessagesLoaded(in chatRoom: ChatRoomEntity) {
        chatHasMessagesSubscription = chatRoomUseCase.chatMessageLoaded(forChatRoom: chatRoom)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { error in
                MEGALogError("error fetching allow host to add participants with error \(error)")
            }, receiveValue: { [weak self] message in
                guard let self else { return }
                guard let message else {
                    checkIfChatHasMessages(for: chatRoom)
                    return
                }
                
                if !message.managementMessage {
                    chatHasMessages(chatRoom, true)
                }
            })
    }
    
    private func chatHasMessages(_ chatRoom: ChatRoomEntity, _ hasMessages: Bool) {
        cancelChatHasMessageSubscription()
        closeChat(chatRoom)
        chatHasMessages = hasMessages
        showCancelMeetingAlert = true
    }
    
    private func cancelChatHasMessageSubscription() {
        chatHasMessagesSubscription?.cancel()
        chatHasMessagesSubscription = nil
    }
    
    private func closeChat(_ chatRoom: ChatRoomEntity) {
        chatRoomUseCase.closeChatRoom(chatRoom)
    }
    
    func cancelScheduledMeeting() {
        Task {
            do {
                var scheduledMeeting = scheduledMeeting
                scheduledMeeting.cancelled = true
                _ = try await scheduledMeetingUseCase.updateScheduleMeeting(scheduledMeeting, updateChatTitle: false)
                if !chatHasMessages {
                    archiveChatRoom(afterCancelMeeting: true)
                } else {
                    router.showSuccessMessage(Strings.Localizable.Meetings.Scheduled.CancelAlert.Success.withMessages)
                }
            } catch {
                router.showErrorMessage(Strings.Localizable.somethingWentWrong)
                MEGALogError("Failed to cancel meeting")
            }
        }
    }
    
    private func archiveChatRoom(afterCancelMeeting: Bool) {
        Task {
            do {
                guard let chatRoom = self.chatRoomUseCase.chatRoom(forChatId: self.scheduledMeeting.chatId) else { return }
                try await Task.sleep(nanoseconds: 2_000_000_000) // This is a temporal workaround until API fixes that some management messages (like this one, cancelled meeting) don't unarchive chats MEET-2928
                _ = try await chatRoomUseCase.archive(true, chatRoom: chatRoom)
                if afterCancelMeeting {
                    router.showSuccessMessage(Strings.Localizable.Meetings.Scheduled.CancelAlert.Success.withoutMessages)
                }
            } catch {
                router.showErrorMessage(Strings.Localizable.somethingWentWrong)
                MEGALogError("Failed to archive chat")
            }
        }
    }
    
    private func monitorActiveCallChanges() {
        chatUseCase.monitorChatCallStatusUpdate()
            .sink { [weak self] call in
                guard let self, call.chatId == self.scheduledMeeting.chatId else { return }
                self.existsInProgressCallInChatRoom = call.status == .inProgress || call.status == .userNoPresent
                self.startMonitoringCallInProgressTime(for: call)
                self.contextMenuOptions = self.constructContextMenuOptions()
            }
            .store(in: &subscriptions)
    }
    
    func startOrJoinMeetingTapped() {
        permissionAlertRouter.audioPermission(modal: true, incomingCall: false) {[weak self] granted in
            guard let self else { return }
            guard granted else {
                permissionAlertRouter.alertAudioPermission(incomingCall: false)
                return
            }
            
            guard !chatUseCase.existsActiveCall() else {
                router.presentMeetingAlreadyExists()
                return
            }
            
            if chatRoomUseCase.shouldOpenWaitingRoom(forChatId: scheduledMeeting.chatId) {
                openWaitingRoom()
            } else {
                startOrJoinCall()
            }
        }
    }
    
    private func openWaitingRoom() {
        router.presentWaitingRoom(for: scheduledMeeting)
    }
    
    private func joinCall(in chatRoom: ChatRoomEntity) {
        guard let call = callUseCase.call(for: scheduledMeeting.chatId) else { return }
        if call.status == .userNoPresent {
            if let incomingCallUUID = callsManager.callUUID(forChatRoom: chatRoom) {
                callController.answerCall(in: chatRoom, withUUID: incomingCallUUID)
            } else {
                startCallJoiningActiveCall(true, notRinging: false, in: chatRoom)
            }
        } else {
            prepareAndShowCallUI(for: call, in: chatRoom)
        }
    }
    
    private func startCall(in chatRoom: ChatRoomEntity) {
        startCallJoiningActiveCall(false, notRinging: true, in: chatRoom)
    }
    
    private func startCallJoiningActiveCall(_ joining: Bool, notRinging: Bool, in chatRoom: ChatRoomEntity) {
        callController.startCall(
            with: CallActionSync(
                chatRoom: chatRoom,
                speakerEnabled: chatRoom.isMeeting,
                notRinging: notRinging,
                isJoiningActiveCall: joining
            )
        )
    }
        
    private func prepareAndShowCallUI(for call: CallEntity, in chatRoom: ChatRoomEntity) {
        audioSessionUseCase.enableLoudSpeaker()
        router.openCallView(for: call, in: chatRoom)
    }
    
    private func showOccurrences() {
        router.showMeetingOccurrences(for: scheduledMeeting)
    }
    
    private func time(for scheduledMeeting: ScheduledMeetingEntity, nextOccurrence: ScheduledMeetingOccurrenceEntity?) -> String {
        guard let nextOccurrence else {
            return time(forStartDate: scheduledMeeting.startDate, endDate: scheduledMeeting.endDate)
        }
        
        return time(forStartDate: nextOccurrence.startDate, endDate: nextOccurrence.endDate)
    }
    
    private func time(forStartDate startDate: Date, endDate: Date) -> String {
        let formatter = timeFormatter()
        let start = formatter.localisedString(from: startDate)
        let end = formatter.localisedString(from: endDate)
        return "\(start) - \(end)"
    }
    
    private func timeFormatter() -> DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = .none
        formatter.timeStyle = .short
        return formatter
    }
    
    private func startMonitoringCallInProgressTime(for call: CallEntity) {
        callInProgressTimeMonitorTask = Task { [weak self, callInProgressTimeReporter] in
            for await timeInterval in callInProgressTimeReporter.configureCallInProgress(for: call) {
                self?.totalCallDuration = timeInterval
            }
        }
    }
}

// Context menu extension
extension FutureMeetingRoomViewModel {
    private var startOrJoinMeetingContextMenuOption: ChatRoomContextMenuOption {
        ChatRoomContextMenuOption(
            title: existsInProgressCallInChatRoom ? Strings.Localizable.Meetings.Scheduled.ContextMenu.joinMeeting : Strings.Localizable.Meetings.Scheduled.ContextMenu.startMeeting,
            image: existsInProgressCallInChatRoom ? .joinMeeting2 : .startMeeting2
        ) { [weak self] in
            guard let self else { return }
            startOrJoinMeetingTapped()
        }
    }
    
    private var editContextMenuOption: ChatRoomContextMenuOption {
        ChatRoomContextMenuOption(
            title: Strings.Localizable.edit,
            image: .editMeeting
        ) {
            self.tracker.trackAnalyticsEvent(with: ScheduledMeetingEditMenuItemEvent())
            self.router.edit(scheduledMeeting: self.scheduledMeeting)
        }
    }
    
    private var occurrenceContextMenuOption: ChatRoomContextMenuOption {
        return ChatRoomContextMenuOption(
            title: Strings.Localizable.Meetings.Scheduled.ContextMenu.occurrences,
            image: .occurrences
        ) {
            self.showOccurrences()
        }
    }
    
    private var cancelContextMenuOption: ChatRoomContextMenuOption {
        return ChatRoomContextMenuOption(
            title: Strings.Localizable.Meetings.Scheduled.ContextMenu.cancel,
            image: .rubbishBin
        ) {
            self.tracker.trackAnalyticsEvent(with: ScheduledMeetingCancelMenuItemEvent())
            self.cancelMeeting()
        }
    }
    
    private var muteContextMenuOption: ChatRoomContextMenuOption {
        let isDNDEnabled = chatNotificationControl.isChatDNDEnabled(chatId: scheduledMeeting.chatId)
        return ChatRoomContextMenuOption(
            title: isDNDEnabled ? Strings.Localizable.unmute : Strings.Localizable.mute,
            image: .mutedChat
        ) { [weak self] in
            guard let self else { return }
            self.toggleDND()
        }
    }
    
    private var infoChatContextMenuOption: ChatRoomContextMenuOption {
        ChatRoomContextMenuOption(
            title: Strings.Localizable.info,
            image: .info
        ) { [weak self] in
            guard let self else { return }
            self.showChatRoomInfo()
        }
    }
    
    private var archiveChatContextMenuOption: ChatRoomContextMenuOption {
        ChatRoomContextMenuOption(
            title: Strings.Localizable.archiveChat,
            image: .archiveChatMenu
        ) { [weak self] in
            guard let self else { return }
            archiveChatRoom(afterCancelMeeting: false)
        }
    }
    
    private func constructContextMenuOptions() -> [ChatRoomContextMenuOption] {
        var options = [
            startOrJoinMeetingContextMenuOption,
            muteContextMenuOption,
            infoChatContextMenuOption,
            archiveChatContextMenuOption
        ]
        
        if scheduledMeeting.rules.frequency != .invalid {
            options.insert(occurrenceContextMenuOption, at: 1)
        }
        
        if chatRoomUseCase.chatRoom(forChatId: scheduledMeeting.chatId)?.ownPrivilege == .moderator {
            options.insert(editContextMenuOption, at: 1)
            options.append(cancelContextMenuOption)
        }
        
        return options
    }
}

extension FutureMeetingRoomViewModel: Equatable {
    nonisolated static func == (lhs: FutureMeetingRoomViewModel, rhs: FutureMeetingRoomViewModel) -> Bool {
        lhs.scheduledMeeting.scheduledId == rhs.scheduledMeeting.scheduledId
    }
}

extension FutureMeetingRoomViewModel: Comparable {
    nonisolated static func < (lhs: FutureMeetingRoomViewModel, rhs: FutureMeetingRoomViewModel) -> Bool {
        let lhsDate = lhs.nextOccurrence?.startDate ?? lhs.scheduledMeeting.startDate
        let rhsDate = rhs.nextOccurrence?.startDate ?? rhs.scheduledMeeting.startDate
        return lhsDate < rhsDate
    }
}
