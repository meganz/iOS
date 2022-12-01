import MEGADomain

final class FutureMeetingRoomViewModel: ObservableObject, Identifiable {
    let scheduledMeeting: ScheduledMeetingEntity
    let chatRoomAvatarViewModel: ChatRoomAvatarViewModel?
    private let chatRoomUseCase: ChatRoomUseCaseProtocol
    private var searchString = ""
    private(set) var contextMenuOptions: [ChatRoomContextMenuOption]?

    var title: String {
        scheduledMeeting.title
    }
    
    var time: String {
        let dateFormatter = DateFormatter.timeShort()
        let start = dateFormatter.localisedString(from: scheduledMeeting.startDate)
        let end = dateFormatter.localisedString(from: scheduledMeeting.endDate)
        return "\(start) - \(end)"
    }

    private let router: ChatRoomsListRouting
    private var futureMeetingSearchStringTask: Task<Void, Never>?

    init(scheduledMeeting: ScheduledMeetingEntity,
         router: ChatRoomsListRouting,
         chatRoomUseCase: ChatRoomUseCaseProtocol,
         userImageUseCase: UserImageUseCaseProtocol,
         chatUseCase: ChatUseCaseProtocol,
         userUseCase: UserUseCaseProtocol) {
        
        self.scheduledMeeting = scheduledMeeting
        self.router = router
        self.chatRoomUseCase = chatRoomUseCase
        
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
        
        options += [
            ChatRoomContextMenuOption(
                title: Strings.Localizable.info,
                imageName: Asset.Images.Generic.info.name,
                action: { [weak self] in
                    guard let self else { return }
                    self.showChatRoomInfo()
                })
        ]
        
        return options
    }
    
    private func showChatRoomInfo() {
        router.showMeetingInfo(for: scheduledMeeting)
    }
}
