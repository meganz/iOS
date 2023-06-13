import MEGADomain
import Combine

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
    @Published var existsInProgressCallInChatRoom = false
    @Published var totalCallDuration: TimeInterval = 0
    private let permissionHandler: DevicePermissionsHandling
    
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
         permissionHandler: DevicePermissionsHandling,
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
        self.permissionHandler = permissionHandler
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
    
    private func constructContextMenuOptions() -> [ChatRoomContextMenuOption] {
        var options: [ChatRoomContextMenuOption] = []
        
        options.append(ChatRoomContextMenuOption(
            title: existsInProgressCallInChatRoom ? Strings.Localizable.Meetings.Scheduled.ContextMenu.joinMeeting : Strings.Localizable.Meetings.Scheduled.ContextMenu.startMeeting,
            imageName: existsInProgressCallInChatRoom ? Asset.Images.Meetings.Scheduled.ContextMenu.joinMeeting2.name : Asset.Images.Meetings.Scheduled.ContextMenu.startMeeting2.name,
            action: { [weak self] in
                self?.startOrJoinMeetingTapped()
            }))
        
        if scheduledMeeting.rules.frequency != .invalid {
            options.append(ChatRoomContextMenuOption(
                title: Strings.Localizable.Meetings.Scheduled.ContextMenu.occurrences,
                imageName: Asset.Images.Meetings.Scheduled.ContextMenu.occurrences.name,
                action: { [weak self] in
                    self?.showOccurrences()
                }))
        }
        
        let isDNDEnabled = chatNotificationControl.isChatDNDEnabled(chatId: scheduledMeeting.chatId)
        
        options += [
            ChatRoomContextMenuOption(
                title: isDNDEnabled ? Strings.Localizable.unmute : Strings.Localizable.mute,
                imageName: Asset.Images.Chat.mutedChat.name,
                action: { [weak self] in
                    guard let self else { return }
                    self.toggleDND()
                }),
            ChatRoomContextMenuOption(
                title: Strings.Localizable.info,
                imageName: Asset.Images.Generic.info.name,
                action: { [weak self] in
                    guard let self else { return }
                    self.showChatRoomInfo()
                }),
            ChatRoomContextMenuOption(
                title: Strings.Localizable.archiveChat,
                imageName: Asset.Images.Chat.ContextualMenu.archiveChatMenu.name,
                action: { [weak self] in
                    guard let self else { return }
                    self.archiveChat()
                })
        ]
        
        return options
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
    
    private func archiveChat() {
        guard let chatRoom = self.chatRoomUseCase.chatRoom(forChatId: self.scheduledMeeting.chatId) else { return }
        chatRoomUseCase.archive(true, chatRoom: chatRoom)
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
        permissionHandler.audioPermission(modal: true, incomingCall: false) {[weak self] granted in
            guard let self else { return }
            guard granted else {
                permissionHandler.alertAudioPermission(incomingCall: false)
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
                        self?.router.showCallError(Strings.Localizable.Error.noMoreParticipantsAreAllowedInThisGroupCall)
                    default:
                        self?.router.showCallError(Strings.Localizable.somethingWentWrong)
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
                    self?.router.showCallError(Strings.Localizable.Error.noMoreParticipantsAreAllowedInThisGroupCall)
                default:
                    self?.router.showCallError(Strings.Localizable.somethingWentWrong)
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
