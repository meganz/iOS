import MEGADomain

final class FutureMeetingRoomViewModel: ObservableObject, Identifiable {
    let scheduledMeeting: ScheduledMeetingEntity
    let chatRoomAvatarViewModel: ChatRoomAvatarViewModel?
    private let chatRoomUseCase: ChatRoomUseCaseProtocol
    private let chatUseCase: ChatUseCaseProtocol
    private var chatNotificationControl: ChatNotificationControl
    private var searchString = ""
    private(set) var contextMenuOptions: [ChatRoomContextMenuOption]?
    private(set) var isMuted: Bool

    var title: String {
        scheduledMeeting.title
    }
    
    var time: String {
        let dateFormatter = DateFormatter.timeShort()
        let start = dateFormatter.localisedString(from: scheduledMeeting.startDate)
        let end = dateFormatter.localisedString(from: scheduledMeeting.endDate)
        return "\(start) - \(end)"
    }
    
    var unreadChatCount: Int? {
        chatUseCase.chatListItem(forChatId: scheduledMeeting.chatId)?.unreadCount
    }
    
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

    init(scheduledMeeting: ScheduledMeetingEntity,
         router: ChatRoomsListRouting,
         chatRoomUseCase: ChatRoomUseCaseProtocol,
         userImageUseCase: UserImageUseCaseProtocol,
         chatUseCase: ChatUseCaseProtocol,
         userUseCase: UserUseCaseProtocol,
         chatNotificationControl: ChatNotificationControl) {
        
        self.scheduledMeeting = scheduledMeeting
        self.router = router
        self.chatRoomUseCase = chatRoomUseCase
        self.chatUseCase = chatUseCase
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
        } else {
            self.chatRoomAvatarViewModel = nil
        }
        
        self.futureMeetingSearchStringTask = createFutureMeetingSearchStringTask()
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
}

extension FutureMeetingRoomViewModel: Equatable {
    static func == (lhs: FutureMeetingRoomViewModel, rhs: FutureMeetingRoomViewModel) -> Bool {
        lhs.scheduledMeeting.scheduledId == rhs.scheduledMeeting.scheduledId
    }
}
