import MEGADomain
import Combine

final class FutureMeetingRoomViewModel: ObservableObject, Identifiable {
    let scheduledMeeting: ScheduledMeetingEntity
    let chatRoomAvatarViewModel: ChatRoomAvatarViewModel?
    private let chatRoomUseCase: ChatRoomUseCaseProtocol
    private let chatUseCase: ChatUseCaseProtocol
    private var chatNotificationControl: ChatNotificationControl
    private let callUseCase: CallUseCaseProtocol
    private let audioSessionUseCase: AudioSessionUseCaseProtocol
    private let scheduledMeetingUseCase: ScheduledMeetingUseCaseProtocol
    private var searchString = ""
    private(set) var contextMenuOptions: [ChatRoomContextMenuOption]?
    private(set) var isMuted: Bool
    private var subscriptions = Set<AnyCancellable>()

    var title: String {
        scheduledMeeting.title
    }
    
    var time: String {
        let dateFormatter = DateFormatter.timeShort()
        let start = dateFormatter.localisedString(from: scheduledMeeting.startDate)
        let end = dateFormatter.localisedString(from: scheduledMeeting.endDate)
        return "\(start) - \(end)"
    }
    
    var shouldShowUnreadCount = false
    var unreadCountString = ""
    
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
    private var futureMeetingSearchStringTask: Task<Void, Never>?

    @Published var showDNDTurnOnOptions = false
    @Published var existsInProgressCallInChatRoom = false

    init(scheduledMeeting: ScheduledMeetingEntity,
         router: ChatRoomsListRouting,
         chatRoomUseCase: ChatRoomUseCaseProtocol,
         userImageUseCase: UserImageUseCaseProtocol,
         chatUseCase: ChatUseCaseProtocol,
         userUseCase: UserUseCaseProtocol,
         callUseCase: CallUseCaseProtocol,
         audioSessionUseCase: AudioSessionUseCaseProtocol,
         scheduledMeetingUseCase: ScheduledMeetingUseCaseProtocol,
         chatNotificationControl: ChatNotificationControl) {
        
        self.scheduledMeeting = scheduledMeeting
        self.router = router
        self.chatRoomUseCase = chatRoomUseCase
        self.chatUseCase = chatUseCase
        self.callUseCase = callUseCase
        self.audioSessionUseCase = audioSessionUseCase
        self.scheduledMeetingUseCase = scheduledMeetingUseCase
        self.chatNotificationControl = chatNotificationControl
        self.isMuted = chatNotificationControl.isChatDNDEnabled(chatId: scheduledMeeting.chatId)

        if let chatRoomEntity = chatRoomUseCase.chatRoom(forChatId: scheduledMeeting.chatId) {
            self.chatRoomAvatarViewModel = ChatRoomAvatarViewModel(
                title: scheduledMeeting.title,
                peerHandle: chatRoomEntity.peers.first?.handle ?? .invalid,
                chatRoomEntity: chatRoomEntity,
                chatRoomUseCase: chatRoomUseCase,
                userImageUseCase: userImageUseCase,
                chatUseCase: chatUseCase,
                userUseCase: userUseCase
            )
            self.shouldShowUnreadCount = chatRoomEntity.unreadCount != 0
            self.unreadCountString = chatRoomEntity.unreadCount > 0 ? "\(chatRoomEntity.unreadCount)" : "\(-chatRoomEntity.unreadCount)+"
        } else {
            self.chatRoomAvatarViewModel = nil
        }
        
        self.futureMeetingSearchStringTask = createFutureMeetingSearchStringTask()
        
        self.existsInProgressCallInChatRoom = chatUseCase.isCallInProgress(for: scheduledMeeting.chatId)
        monitorActiveCallChanges()
        self.contextMenuOptions = constructContextMenuOptions()
    }
    
    func contains(searchText: String) -> Bool {
        searchString.localizedCaseInsensitiveContains(searchText)
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
    
    //MARK: - Private methods.
    
    private func createFutureMeetingSearchStringTask() -> Task<Void, Never> {
        Task { [weak self] in
            guard let self,
                    let chatRoom = self.chatRoomUseCase.chatRoom(forChatId: self.scheduledMeeting.chatId) else {
                return
            }
            
            async let fullNamesTask = self.chatRoomUseCase.userFullNames(forPeerIds: chatRoom.peers.map(\.handle), chatId: self.scheduledMeeting.chatId).joined(separator: " ")
            
            async let userNickNamesTask = self.chatRoomUseCase.userNickNames(forChatId: chatRoom.chatId).values.joined(separator: " ")
            
            async let userEmailsTask = self.chatRoomUseCase.userEmails(forChatId: chatRoom.chatId).values.joined(separator: " ")
            
            do {
                let (fullNames, userNickNames, userEmails) = try await (fullNamesTask, userNickNamesTask, userEmailsTask)
                
                if let title = chatRoom.title {
                    self.searchString = title + " " + fullNames + " " + userNickNames + " " + userEmails
                } else {
                    self.searchString = fullNames + " " + userNickNames + " " + userEmails
                }
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
        chatRoomUseCase.archive(true, chatId: scheduledMeeting.chatId)
    }
    
    private func monitorActiveCallChanges() {
        chatUseCase.monitorChatCallStatusUpdate()
            .sink { [weak self] call in
                guard let self, call.chatId == self.scheduledMeeting.chatId else { return }
                self.existsInProgressCallInChatRoom = call.status == .inProgress || call.status == .userNoPresent
                self.contextMenuOptions = self.constructContextMenuOptions()
            }
            .store(in: &subscriptions)
    }
    
    private func startOrJoinMeetingTapped() {
        DevicePermissionsHelper.audioPermissionModal(true, forIncomingCall: false) { [weak self] granted in
            guard granted else {
                DevicePermissionsHelper.alertAudioPermission(forIncomingCall: false)
                return
            }
            
            self?.startOrJoinCall()
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
                case .success(_):
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
}

extension FutureMeetingRoomViewModel: Equatable {
    static func == (lhs: FutureMeetingRoomViewModel, rhs: FutureMeetingRoomViewModel) -> Bool {
        lhs.scheduledMeeting.scheduledId == rhs.scheduledMeeting.scheduledId
    }
}
