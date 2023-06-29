import Combine
import MEGADomain

final class FutureMeetingRoomViewModel: ObservableObject, Identifiable, CallInProgressTimeReporting {
    let scheduledMeeting: ScheduledMeetingEntity
    let nextOccurrence: ScheduledMeetingOccurrenceEntity?
    let chatRoomAvatarViewModel: ChatRoomAvatarViewModel?
    private let chatRoomUseCase: any ChatRoomUseCaseProtocol
    private let chatRoomUserUseCase: any ChatRoomUserUseCaseProtocol
    private let chatUseCase: any ChatUseCaseProtocol
    private var chatNotificationControl: ChatNotificationControl
    private let callUseCase: CallUseCaseProtocol
    private let audioSessionUseCase: any AudioSessionUseCaseProtocol
    private let scheduledMeetingUseCase: any ScheduledMeetingUseCaseProtocol
    private let megaHandleUseCase: any MEGAHandleUseCaseProtocol
    private var searchString: String?
    private(set) var contextMenuOptions: [ChatRoomContextMenuOption]?
    private(set) var isMuted: Bool
    private var subscriptions = Set<AnyCancellable>()
    
    var callDurationTotal: TimeInterval?
    var callDurationCapturedTime: TimeInterval?
    var timerSubscription: AnyCancellable?
    private var chatHasMessagesSubscription: AnyCancellable?
    
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
    var unreadCountString = ""
    var isRecurring: Bool
    var chatHasMeesages = false
    
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
    
    private let router: ChatRoomsListRouting
    
    @Published var showDNDTurnOnOptions = false
    @Published var showCancelMeetingAlert = false
    @Published var existsInProgressCallInChatRoom = false
    @Published var totalCallDuration: TimeInterval = 0
    private let permissionAlertRouter: any PermissionAlertRouting
    
    init(scheduledMeeting: ScheduledMeetingEntity,
         nextOccurrence: ScheduledMeetingOccurrenceEntity?,
         router: ChatRoomsListRouting,
         chatRoomUseCase: any ChatRoomUseCaseProtocol,
         chatRoomUserUseCase: any ChatRoomUserUseCaseProtocol,
         userImageUseCase: UserImageUseCaseProtocol,
         chatUseCase: any ChatUseCaseProtocol,
         accountUseCase: any AccountUseCaseProtocol,
         callUseCase: CallUseCaseProtocol,
         audioSessionUseCase: any AudioSessionUseCaseProtocol,
         scheduledMeetingUseCase: any ScheduledMeetingUseCaseProtocol,
         megaHandleUseCase: any MEGAHandleUseCaseProtocol,
         permissionAlertRouter: some PermissionAlertRouting,
         chatNotificationControl: ChatNotificationControl) {
        
        self.scheduledMeeting = scheduledMeeting
        self.nextOccurrence = nextOccurrence
        self.router = router
        self.chatRoomUseCase = chatRoomUseCase
        self.chatRoomUserUseCase = chatRoomUserUseCase
        self.chatUseCase = chatUseCase
        self.callUseCase = callUseCase
        self.audioSessionUseCase = audioSessionUseCase
        self.scheduledMeetingUseCase = scheduledMeetingUseCase
        self.megaHandleUseCase = megaHandleUseCase
        self.permissionAlertRouter = permissionAlertRouter
        self.chatNotificationControl = chatNotificationControl
        self.isMuted = chatNotificationControl.isChatDNDEnabled(chatId: scheduledMeeting.chatId)
        self.isRecurring = scheduledMeeting.rules.frequency != .invalid
        
        if let chatRoomEntity = chatRoomUseCase.chatRoom(forChatId: scheduledMeeting.chatId) {
            self.chatRoomAvatarViewModel = ChatRoomAvatarViewModel(
                title: scheduledMeeting.title,
                peerHandle: chatRoomEntity.peers.first?.handle ?? .invalid,
                chatRoomEntity: chatRoomEntity,
                chatRoomUseCase: chatRoomUseCase,
                chatRoomUserUseCase: chatRoomUserUseCase,
                userImageUseCase: userImageUseCase,
                chatUseCase: chatUseCase,
                accountUseCase: accountUseCase,
                megaHandleUseCase: megaHandleUseCase
            )
            self.shouldShowUnreadCount = chatRoomEntity.unreadCount != 0
            self.unreadCountString = chatRoomEntity.unreadCount > 0 ? "\(chatRoomEntity.unreadCount)" : "\(-chatRoomEntity.unreadCount)+"
        } else {
            self.chatRoomAvatarViewModel = nil
        }
        
        loadFutureMeetingSearchString()
        self.existsInProgressCallInChatRoom = chatUseCase.isCallInProgress(for: scheduledMeeting.chatId)
        if let call = callUseCase.call(for: scheduledMeeting.chatId) {
            configureCallInProgress(for: call)
        }
        monitorActiveCallChanges()
        self.contextMenuOptions = constructContextMenuOptions()
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
        guard let chatRoom = chatRoomUseCase.chatRoom(forChatId: scheduledMeeting.chatId) else { return }
        router.showDetails(forChatId: scheduledMeeting.chatId, unreadMessagesCount: chatRoom.unreadCount)
    }
    
    func cancelMeetingAlertData() -> CancelMeetingAlertDataModel {
        return CancelMeetingAlertDataModel(
            title: Strings.Localizable.Meetings.Scheduled.CancelAlert.title(scheduledMeeting.title),
            message: chatHasMeesages ? Strings.Localizable.Meetings.Scheduled.CancelAlert.Description.withMessages : Strings.Localizable.Meetings.Scheduled.CancelAlert.Description.withoutMessages,
            primaryButtonTitle: chatHasMeesages ? Strings.Localizable.Meetings.Scheduled.CancelAlert.Option.Confirm.withMessages : Strings.Localizable.Meetings.Scheduled.CancelAlert.Option.Confirm.withoutMessages,
            primaryButtonAction: cancelScheduledMeeting,
            secondaryButtonTitle: Strings.Localizable.Meetings.Scheduled.CancelAlert.Option.dontCancel)
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
        cancelChatHasMessageSuscription()
        closeChat(chatRoom)
        chatHasMeesages = hasMessages
        showCancelMeetingAlert = true
    }
    
    private func cancelChatHasMessageSuscription() {
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
                _ = try await scheduledMeetingUseCase.updateScheduleMeeting(scheduledMeeting)
                if !chatHasMeesages {
                    archiveChatRoom()
                } else {
                    router.showSuccessMessage(Strings.Localizable.Meetings.Scheduled.CancelAlert.Success.withMessages)
                }
            } catch {
                router.showErrorMessage(Strings.Localizable.somethingWentWrong)
                MEGALogError("Failed to cancel meeting")
            }
        }
    }
    
    private func archiveChatRoom() {
        Task {
            do {
                guard let chatRoom = self.chatRoomUseCase.chatRoom(forChatId: self.scheduledMeeting.chatId) else { return }
                _ = try await chatRoomUseCase.archive(true, chatRoom: chatRoom)
                router.showSuccessMessage(Strings.Localizable.Meetings.Scheduled.CancelAlert.Success.withoutMessages)
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
                self.configureCallInProgress(for: call)
                self.contextMenuOptions = self.constructContextMenuOptions()
            }
            .store(in: &subscriptions)
    }
    
    private func startOrJoinMeetingTapped() {
        permissionAlertRouter.audioPermission(modal: true, incomingCall: false) {[weak self] granted in
            guard let self else { return }
            guard granted else {
                permissionAlertRouter.alertAudioPermission(incomingCall: false)
                return
            }
            
            startOrJoinCall()
        }
    }
    
    func startOrJoinCall() {
        guard let chatRoom = chatRoomUseCase.chatRoom(forChatId: scheduledMeeting.chatId) else {
            MEGALogError("Not able to fetch chat room for start or join call")
            return
        }
        
        if existsInProgressCallInChatRoom {
            joinCall(in: chatRoom)
        } else {
            startMeetingCallNoRinging(in: chatRoom)
        }
    }
    
    private func joinCall(in chatRoom: ChatRoomEntity) {
        guard let call = callUseCase.call(for: scheduledMeeting.chatId) else { return }
        if call.status == .userNoPresent {
            callUseCase.startCall(for: scheduledMeeting.chatId, enableVideo: false, enableAudio: true) { [weak self] result in
                switch result {
                case .success:
                    self?.prepareAndShowCallUI(for: call, in: chatRoom)
                case .failure(let error):
                    switch error {
                    case .tooManyParticipants:
                        self?.router.showErrorMessage(Strings.Localizable.Error.noMoreParticipantsAreAllowedInThisGroupCall)
                    default:
                        self?.router.showErrorMessage(Strings.Localizable.somethingWentWrong)
                        MEGALogError("Not able to join scheduled meeting call")
                    }
                }
            }
        } else {
            prepareAndShowCallUI(for: call, in: chatRoom)
        }
    }
    
    private func startMeetingCallNoRinging(in chatRoom: ChatRoomEntity) {
        callUseCase.startCallNoRinging(for: scheduledMeeting, enableVideo: false, enableAudio: true) { [weak self] result in
            switch result {
            case .success(let call):
                self?.prepareAndShowCallUI(for: call, in: chatRoom)
            case .failure(let error):
                switch error {
                case .tooManyParticipants:
                    self?.router.showErrorMessage(Strings.Localizable.Error.noMoreParticipantsAreAllowedInThisGroupCall)
                default:
                    self?.router.showErrorMessage(Strings.Localizable.somethingWentWrong)
                    MEGALogError("Not able to start scheduled meeting call")
                }
            }
        }
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
}

// Context menu extension
extension FutureMeetingRoomViewModel {
    private var startOrJoinMeetingContextMenuOption: ChatRoomContextMenuOption {
        ChatRoomContextMenuOption(
            title: existsInProgressCallInChatRoom ? Strings.Localizable.Meetings.Scheduled.ContextMenu.joinMeeting : Strings.Localizable.Meetings.Scheduled.ContextMenu.startMeeting,
            imageName: existsInProgressCallInChatRoom ? Asset.Images.Meetings.Scheduled.ContextMenu.joinMeeting2.name : Asset.Images.Meetings.Scheduled.ContextMenu.startMeeting2.name
        ) { [weak self] in
            guard let self else { return }
            startOrJoinMeetingTapped()
        }
    }
    
    private var editContextMenuOption: ChatRoomContextMenuOption {
        ChatRoomContextMenuOption(
            title: Strings.Localizable.edit,
            imageName: Asset.Images.Meetings.editMeeting.name
        ) { [weak self] in
            guard let self else { return }
            router.edit(scheduledMeeting: scheduledMeeting)
        }
    }
    
    private var occurrenceContextMenuOption: ChatRoomContextMenuOption {
        return ChatRoomContextMenuOption(
            title: Strings.Localizable.Meetings.Scheduled.ContextMenu.occurrences,
            imageName: Asset.Images.Meetings.Scheduled.ContextMenu.occurrences.name
        ) { [weak self] in
            guard let self else { return }
            showOccurrences()
        }
    }
    
    private var cancelContextMenuOption: ChatRoomContextMenuOption {
        return ChatRoomContextMenuOption(
            title: Strings.Localizable.Meetings.Scheduled.ContextMenu.cancel,
            imageName: Asset.Images.NodeActions.rubbishBin.name
        ) { [weak self] in
            guard let self else { return }
            cancelMeeting()
        }
    }
    
    private var muteContextMenuOption: ChatRoomContextMenuOption {
        let isDNDEnabled = chatNotificationControl.isChatDNDEnabled(chatId: scheduledMeeting.chatId)
        return ChatRoomContextMenuOption(
            title: isDNDEnabled ? Strings.Localizable.unmute : Strings.Localizable.mute,
            imageName: Asset.Images.Chat.mutedChat.name
        ) { [weak self] in
            guard let self else { return }
            self.toggleDND()
        }
    }
    
    private var infoChatContextMenuOption: ChatRoomContextMenuOption {
        ChatRoomContextMenuOption(
            title: Strings.Localizable.info,
            imageName: Asset.Images.Generic.info.name
        ) { [weak self] in
            guard let self else { return }
            self.showChatRoomInfo()
        }
    }
    
    private var archiveChatContextMenuOption: ChatRoomContextMenuOption {
        ChatRoomContextMenuOption(
            title: Strings.Localizable.archiveChat,
            imageName: Asset.Images.Chat.ContextualMenu.archiveChatMenu.name
        ) { [weak self] in
            guard let self else { return }
            archiveChatRoom()
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
    static func == (lhs: FutureMeetingRoomViewModel, rhs: FutureMeetingRoomViewModel) -> Bool {
        lhs.scheduledMeeting.scheduledId == rhs.scheduledMeeting.scheduledId
    }
}

extension FutureMeetingRoomViewModel: Comparable {
    static func < (lhs: FutureMeetingRoomViewModel, rhs: FutureMeetingRoomViewModel) -> Bool {
        let lhsDate = lhs.nextOccurrence?.startDate ?? lhs.scheduledMeeting.startDate
        let rhsDate = rhs.nextOccurrence?.startDate ?? rhs.scheduledMeeting.startDate
        return lhsDate < rhsDate
    }
}
