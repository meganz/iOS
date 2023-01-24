import MEGADomain
import Combine
import MEGASwift
import Foundation
import MEGAUI
import Combine

final class ChatRoomViewModel: ObservableObject, Identifiable {
    let chatListItem: ChatListItemEntity
    private let chatRoomUseCase: ChatRoomUseCaseProtocol
    private let chatUseCase: ChatUseCaseProtocol
    private let userUseCase: UserUseCaseProtocol
    private let callUseCase: CallUseCaseProtocol
    private let audioSessionUseCase: AudioSessionUseCaseProtocol

    private let router: ChatRoomsListRouting
    private var chatNotificationControl: ChatNotificationControl
    private let notificationCenter: NotificationCenter

    private(set) var description: String?
    private(set) var hybridDescription: ChatRoomHybridDescriptionViewState?
    @Published var chatStatus: ChatStatusEntity = .invalid
    @Published var showDNDTurnOnOptions = false
    @Published var existsInProgressCallInChatRoom = false
    
    private(set) var contextMenuOptions: [ChatRoomContextMenuOption]?
    private(set) var isMuted: Bool

    private(set) var displayDateString: String?

    private var subscriptions = Set<AnyCancellable>()
    private var loadingChatRoomInfoTask: Task<Void, Never>?
    
    private var isViewOnScreen = false
    private var loadingChatRoomInfoSubscription: AnyCancellable?
    
    private var loadingChatRoomSearchStringTask: Task<Void, Never>?
    private var searchString = ""

    private var isInfoLoaded = false
    let chatRoomAvatarViewModel: ChatRoomAvatarViewModel?
    
    let shouldShowUnreadCount: Bool
    let unreadCountString: String

    init(chatListItem: ChatListItemEntity,
         router: ChatRoomsListRouting,
         chatRoomUseCase: ChatRoomUseCaseProtocol,
         userImageUseCase: UserImageUseCaseProtocol,
         chatUseCase: ChatUseCaseProtocol,
         userUseCase: UserUseCaseProtocol,
         callUseCase: CallUseCaseProtocol,
         audioSessionUseCase: AudioSessionUseCaseProtocol,
         chatNotificationControl: ChatNotificationControl,
         notificationCenter: NotificationCenter = .default) {
        self.chatListItem = chatListItem
        self.router = router
        self.chatRoomUseCase = chatRoomUseCase
        self.chatUseCase = chatUseCase
        self.userUseCase = userUseCase
        self.callUseCase = callUseCase
        self.audioSessionUseCase = audioSessionUseCase
        self.chatNotificationControl = chatNotificationControl
        self.notificationCenter = notificationCenter
        self.isMuted = chatNotificationControl.isChatDNDEnabled(chatId: chatListItem.chatId)
        self.shouldShowUnreadCount = chatListItem.unreadCount != 0
        self.unreadCountString = chatListItem.unreadCount > 0 ? "\(chatListItem.unreadCount)" : "\(-chatListItem.unreadCount)+"
        
        if let chatRoomEntity = chatRoomUseCase.chatRoom(forChatId: chatListItem.chatId) {
            self.chatRoomAvatarViewModel = ChatRoomAvatarViewModel(
                title: chatListItem.title ?? "",
                peerHandle: chatListItem.peerHandle,
                chatRoomEntity: chatRoomEntity,
                chatRoomUseCase: chatRoomUseCase,
                userImageUseCase: userImageUseCase,
                chatUseCase: chatUseCase,
                userUseCase: userUseCase
            )
        } else {
            self.chatRoomAvatarViewModel = nil
        }

        self.displayDateString = formattedLastMessageSentDate()
        
        self.existsInProgressCallInChatRoom = chatUseCase.isCallInProgress(for: chatListItem.chatId)
        monitorActiveCallChanges()
        
        if !chatListItem.group {
            self.chatStatus = chatRoomUseCase.userStatus(forUserHandle: chatListItem.peerHandle)
            self.listeningForChatStatusUpdate()
        }

        self.loadingChatRoomInfoTask = createLoadingChatRoomInfoTask()
        self.loadingChatRoomSearchStringTask = createLoadingChatRoomSearchStringTask()
        self.contextMenuOptions = constructContextMenuOptions()
    }
    
    //MARK: - Interface methods
    
    func loadChatRoomInfo() {
        isViewOnScreen = true
    }
    
    func cancelLoading() {
        isViewOnScreen = false
    }
    
    func chatStatusColor(forChatStatus chatStatus: ChatStatusEntity) -> UIColor? {
        switch chatStatus {
        case .online:
            return Colors.Chat.Status.online.color
        case .offline:
            return Colors.Chat.Status.offline.color
        case .away:
            return Colors.Chat.Status.away.color
        case .busy:
            return Colors.Chat.Status.busy.color
        default:
            return nil
        }
    }

    func contains(searchText: String) -> Bool {
        searchString.localizedCaseInsensitiveContains(searchText)
    }
    
    func showDetails() {
        guard let chatRoom = chatRoomUseCase.chatRoom(forChatId: chatListItem.chatId) else { return }
        router.showDetails(forChatId: chatListItem.chatId, unreadMessagesCount: chatRoom.unreadCount)
    }
    
    func presentMoreOptionsForChat(){
        router.presentMoreOptionsForChat(
            withDNDEnabled: chatNotificationControl.isChatDNDEnabled(chatId: chatListItem.chatId)
        ) { [weak self] in
            self?.toggleDND()
        } markAsReadAction: { [weak self] in
            guard let self else { return }
            self.chatRoomUseCase.setMessageSeenForChat(forChatId: self.chatListItem.chatId, messageId: self.chatListItem.lastMessageId)
        } infoAction: { [weak self] in
            self?.showChatRoomInfo()
        } archiveAction: { [weak self] in
            guard let self else { return }
            self.chatRoomUseCase.archive(true, chatId: self.chatListItem.chatId)
        }
    }
    
    func dndTurnOnOptions() -> [DNDTurnOnOption] {
        ChatNotificationControl.dndTurnOnOptions()
    }
    
    func turnOnDNDOption(_ option: DNDTurnOnOption) {
        chatNotificationControl.turnOnDND(chatId: chatListItem.chatId, option: option)
    }
    
    func archiveChat() {
        chatRoomUseCase.archive(true, chatId: chatListItem.chatId)
    }
    
    func pushNotificationSettingsChanged() {
        let newValue = chatNotificationControl.isChatDNDEnabled(chatId: chatListItem.chatId)
        guard isMuted != newValue else { return }
        
        contextMenuOptions = constructContextMenuOptions()
        isMuted = newValue
        objectWillChange.send()
    }
    
    func updateDescription() async throws {
        switch chatListItem.lastMessageType {
        case .loading:
            updateDescription(withMessage: Strings.Localizable.loading)
        case .invalid:
            updateDescription(withMessage: Strings.Localizable.noConversationHistory)
        case .attachment:
            try await updateDescriptionForAttachment()
        case .voiceClip:
            try await updateDescriptionForVoiceClip()
        case .contact:
            try await updateDescriptionForContact()
        case .truncate:
            try await updateDescriptionForTruncate()
        case .privilegeChange:
            try await updateDescriptionForPrivilageChange()
        case .alterParticipants:
            try await updateDescriptionForAlertParticipants()
        case .setRetentionTime:
           try await updateDescriptionForRententionTime()
        case .chatTitle:
            try await updateDesctiptionWithChatTitleChange()
        case .callEnded:
            await updateDescriptionForCallEnded()
        case .callStarted:
            updateDescription(withMessage: Strings.Localizable.callStarted)
        case .publicHandleCreate:
            try await updateDescriptionWithSender(usingMessage: Strings.Localizable.createdAPublicLinkForTheChat)
        case .publicHandleDelete:
            try await updateDescriptionWithSender(usingMessage: Strings.Localizable.removedAPublicLinkForTheChat)
        case .setPrivateMode:
            try await updateDescriptionWithSender(usingMessage: Strings.Localizable.enabledEncryptedKeyRotation)
        case .scheduledMeeting:
            try await updateDescriptionForScheduledMeeting()
        default:
            try await updateDescriptionForDefault()
        }
    }
    
    //MARK: - Private methods

    private func formattedLastMessageSentDate() -> String? {
        guard let seventhDayPriorDate = Calendar.autoupdatingCurrent.date(byAdding: .day, value: -7, to:Date()) else { return nil }
        
        if Calendar.autoupdatingCurrent.isDateInToday(chatListItem.lastMessageDate) {
            return chatListItem.lastMessageDate.string(withDateFormat: "HH:mm")
        } else if chatListItem.lastMessageDate.compare(seventhDayPriorDate) == .orderedDescending {
            return chatListItem.lastMessageDate.string(withDateFormat: "EEE")
        } else {
            return chatListItem.lastMessageDate.string(withDateFormat: "dd/MM/yy")
        }
    }
    
    private func constructContextMenuOptions() -> [ChatRoomContextMenuOption] {
        var options: [ChatRoomContextMenuOption] = []
        if chatListItem.meeting && chatUseCase.scheduledMeetingsByChat(chatId: chatListItem.chatId).isNotEmpty {
            options.append(
                ChatRoomContextMenuOption(
                    title: existsInProgressCallInChatRoom ? Strings.Localizable.Meetings.Scheduled.ContextMenu.joinMeeting : Strings.Localizable.Meetings.Scheduled.ContextMenu.startMeeting,
                    imageName: existsInProgressCallInChatRoom ? Asset.Images.Meetings.Scheduled.ContextMenu.joinMeeting2.name : Asset.Images.Meetings.Scheduled.ContextMenu.startMeeting2.name,
                    action: { [weak self] in
                        self?.startOrJoinMeetingTapped()
                    }))
        }

        if chatListItem.unreadCount > 0 {
            options.append(
                ChatRoomContextMenuOption(
                    title: Strings.Localizable.markAsRead,
                    imageName: Asset.Images.Chat.ContextualMenu.markUnreadMenu.name,
                    action: { [weak self] in
                        guard let self else { return }
                        self.chatRoomUseCase.setMessageSeenForChat(
                            forChatId: self.chatListItem.chatId,
                            messageId: self.chatListItem.lastMessageId
                        )
                    })
            )
        }
        
        let isDNDEnabled = chatNotificationControl.isChatDNDEnabled(chatId: chatListItem.chatId)
        
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
        
    private func createLoadingChatRoomInfoTask() -> Task<Void, Never> {
        Task { [weak self] in
            let chatId = chatListItem.chatId
            do {
                try await self?.updateDescription()
            } catch {
                MEGALogDebug("Unable to load description for \(chatId) - \(error.localizedDescription)")
            }
            
            guard let self, self.isViewOnScreen else { return }
            
            do {
                try Task.checkCancellation()
                await self.sendObjectChangeNotification()
            } catch {
                MEGALogDebug("Task cancelled for \(chatId)")
            }
        }
    }
    
    private func createLoadingChatRoomSearchStringTask() -> Task<Void, Never> {
        Task { [weak self] in
            guard let self,
                    let chatRoom = self.chatRoomUseCase.chatRoom(forChatId: self.chatListItem.chatId) else {
                return
            }
            
            async let fullNamesTask = self.chatRoomUseCase.userFullNames(forPeerIds: chatRoom.peers.map(\.handle), chatId: self.chatListItem.chatId).joined(separator: " ")
            
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
                MEGALogDebug("Unable to populate search string for \(chatListItem.chatId) with error \(error.localizedDescription)")
            }
        }
    }

    @MainActor
    private func sendObjectChangeNotification() {
        objectWillChange.send()
    }
    
    private func showChatRoomInfo() {
        if chatListItem.group {
            if let scheduledMeeting = chatUseCase.scheduledMeetingsByChat(chatId: chatListItem.chatId).first {
                router.showMeetingInfo(for: scheduledMeeting)
            } else {
                guard let chatIdString = chatRoomUseCase.base64Handle(forChatId: chatListItem.chatId),
                      MEGALinkManager.joiningOrLeavingChatBase64Handles.notContains(where: { element in
                          if let elementId = element as? String, elementId == chatIdString {
                              return true
                          }
                          return false
                      }) else {
                          return
                      }
                
                router.showGroupChatInfo(forChatId: chatListItem.chatId)
            }
        } else {
            guard let userHandle = chatRoomUseCase.peerHandles(forChatId: chatListItem.chatId).first,
                    let userEmail = chatRoomUseCase.contactEmail(forUserHandle: userHandle) else {
                return
            }
            
            router.showContactDetailsInfo(forUseHandle: userHandle, userEmail: userEmail)
        }
    }
    
    private func toggleDND() {
        if chatNotificationControl.isChatDNDEnabled(chatId: chatListItem.chatId) {
            chatNotificationControl.turnOffDND(chatId: chatListItem.chatId)
        } else {
            showDNDTurnOnOptions = true
        }
    }
    
    private func listeningForChatStatusUpdate() {
        chatUseCase
            .monitorChatStatusChange()
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { error in
                MEGALogDebug("error fetching the changed status \(error)")
            }, receiveValue: { [weak self] statusForUser in
                guard let self, statusForUser.0 == self.chatListItem.peerHandle else { return }
                self.chatStatus = statusForUser.1
            })
            .store(in: &subscriptions)
    }
    
    private func monitorActiveCallChanges() {
        chatUseCase.monitorChatCallStatusUpdate()
            .sink { [weak self] call in
                guard let self, call.chatId == self.chatListItem.chatId else { return }
                self.existsInProgressCallInChatRoom = call.status == .inProgress || call.status == .userNoPresent
                self.contextMenuOptions = self.constructContextMenuOptions()
            }
            .store(in: &subscriptions)
    }
    
    private func username(forUserHandle userHandle: HandleEntity, shouldUseMeText: Bool) async throws -> String? {
        if userHandle == userUseCase.myHandle {
            return shouldUseMeText ? Strings.Localizable.me : chatUseCase.myFullName()
        } else {
            let usernames = try await chatRoomUseCase.userDisplayNames(forPeerIds: [userHandle], chatId: chatListItem.chatId)
            return usernames.first
        }
    }
    
    private func updateDescriptionForAttachment() async throws {
        let senderString = chatListItem.group ? try await username(forUserHandle: chatListItem.lastMessageSender, shouldUseMeText: true) : nil
        guard let lastMessage = chatListItem.lastMessage else { return }
        let components = lastMessage.components(separatedBy: "\\x01")
        let message: String
        if components.count == 1 {
            message = Strings.Localizable.attachedFile(lastMessage)
        } else {
            message = Strings.Localizable.attachedXFiles(String(format: "%tu", components.count))
        }
        if let senderString {
            updateDescription(withMessage: "\(senderString): \(message)")
        } else {
            updateDescription(withMessage: message)
        }
    }
    
    private func updateDescriptionForCallEnded() async {
        let components = chatListItem.lastMessage?.components(separatedBy: String(format: "%c", 0x01))
        let durationString = components?.first ?? ""
        let duration = chatListItem.group ? nil : Int(durationString)
        
        let endCallReason: ChatMessageEndCallReasonEntity
        if let components,
            components.count >= 2,
            let secondComponentIntValue = Int(components[1]) {
            endCallReason = ChatMessageEndCallReasonEntity(secondComponentIntValue) ?? .ended
        } else {
            endCallReason = .ended
        }

        let message = message(forEndCallReason: endCallReason,
                              userHandle: chatListItem.lastMessageSender,
                              duration: duration)
        
        updateDescription(withMessage: message)
    }
    
    private func updateDescriptionForRententionTime() async throws {
        guard let sender = try await username(forUserHandle: chatListItem.lastMessageSender, shouldUseMeText: false),
              let chatRoom = chatRoomUseCase.chatRoom(forChatId: chatListItem.chatId) else {
            return
        }
        
        if chatRoom.retentionTime <= 0 {
            let message = removeFormatters(fromString: Strings.Localizable.A1SABDisabledMessageClearing.b(sender))
            updateDescription(withMessage: message)
        } else {
            guard let retention = retentionDuration(fromSeconds: Int(chatRoom.retentionTime)) else {
                return
            }
            let message = removeFormatters(fromString: Strings.Localizable.A1SABChangedTheMessageClearingTimeToBA2SAB.b(sender, retention))
            updateDescription(withMessage: message)
        }
    }
    
    private func updateDescriptionForAlertParticipants() async throws {
        let sender = try await username(forUserHandle: chatListItem.lastMessageSender, shouldUseMeText: false)
        guard let chatRoom = chatRoomUseCase.chatRoom(forChatId: chatListItem.chatId),
              let lastMessageUsername = try await chatRoomUseCase.userDisplayNames(forPeerIds: [chatListItem.lastMessageHandle], chatId: chatRoom.chatId).first else {
            return
        }
        
        switch chatListItem.lastMessagePriv {
        case .unknown:
            if let sender, sender != lastMessageUsername {
                var message = Strings.Localizable.wasRemovedFromTheGroupChatBy
                message = message.replacingOccurrences(of: "[A]", with: lastMessageUsername)
                message = message.replacingOccurrences(of: "[B]", with: sender)
                updateDescription(withMessage: message)
            } else {
                var message = Strings.Localizable.leftTheGroupChat
                message = message.replacingOccurrences(of: "[A]", with: lastMessageUsername)
                updateDescription(withMessage: message)
            }
        case .joinedGroupChat:
            if let sender, sender != lastMessageUsername {
                var message = Strings.Localizable.joinedTheGroupChatByInvitationFrom
                message = message.replacingOccurrences(of: "[A]", with: lastMessageUsername)
                message = message.replacingOccurrences(of: "[B]", with: sender)
                updateDescription(withMessage: message)
            } else {
                let message = Strings.Localizable.joinedTheGroupChat(lastMessageUsername)
                updateDescription(withMessage: message)
            }
        default:
            break
        }
    }
    
    private func updateDescriptionForPrivilageChange() async throws {
        guard let sender = try await username(forUserHandle: chatListItem.lastMessageSender, shouldUseMeText: false),
              let chatRoom = chatRoomUseCase.chatRoom(forChatId: chatListItem.chatId),
              let lastMessageUsername = try await chatRoomUseCase.userDisplayNames(forPeerIds: [chatListItem.lastMessageHandle], chatId: chatRoom.chatId).first else {
            return
        }
        
        var message: String?
        
        switch chatListItem.lastMessagePriv {
        case .invalid:
            message = Strings.Localizable.Chat.Message.ChangedRole.readOnly
        case .alterParticipants:
            message = Strings.Localizable.Chat.Message.ChangedRole.standard
        case .truncate:
            message = Strings.Localizable.Chat.Message.ChangedRole.host
        default:
            break
        }
        
        guard var message else {
            MEGALogDebug("Privilage code did not match")
            return
        }
        
        message = message.replacingOccurrences(of: "[A]", with: lastMessageUsername)
        message = message.replacingOccurrences(of: "[B]", with: sender)
        message = removeFormatters(fromString: message)
        updateDescription(withMessage: message)
    }
    
    private func updateDescriptionForTruncate() async throws  {
        guard let sender = try await username(forUserHandle: chatListItem.lastMessageSender, shouldUseMeText: false) else {
            return
        }
        let message = Strings.Localizable.clearedTheChatHistory.replacingOccurrences(of: "[A]", with: sender)
        updateDescription(withMessage: message)
    }
    
    private func message(forEndCallReason endCallReason: ChatMessageEndCallReasonEntity,
                         userHandle: HandleEntity,
                         duration: Int?) -> String {
        switch endCallReason {
        case .ended, .byModerator:
            if chatListItem.group {
                if let duration, duration > 0 {
                    let durationString = callDurationString(fromSeconds: duration) ?? "\(duration)"
                    var message = Strings.Localizable.AGroupCallEndedAC.durationC
                    message = message.replacingOccurrences(of: "[/C]", with: durationString)
                    message = removeFormatters(fromString: message)
                    return message
                }
                
                return Strings.Localizable.groupCallEnded
            } else {
                if let duration {
                    return "\(Strings.Localizable.callEnded) \(Strings.Localizable.duration(callDurationString(fromSeconds: duration) ?? "\(duration)"))"
                } else {
                    return "\(Strings.Localizable.callEnded)"
                }
            }
        case .rejected:
            return Strings.Localizable.callWasRejected
        case .noAnswer:
            if userHandle == userUseCase.myHandle {
                return Strings.Localizable.callWasNotAnswered
            } else {
                return Strings.Localizable.missedCall
            }
        case .failed:
            return Strings.Localizable.callFailed
        case .cancelled:
            if userHandle == userUseCase.myHandle {
                return Strings.Localizable.callWasCancelled
            } else {
                return Strings.Localizable.missedCall
            }
        }
    }
    
    private func removeFormatters(fromString string: String) -> String {
        var formattedString = string
        if #available(iOS 16.0, *) {
            formattedString.replace(/\[.{1, 2}\]/, with: "")
        } else {
            formattedString = formattedString.replacingOccurrences(of: #"\[.{1,2}\]"#, with: "", options: .regularExpression)
        }
        
        return formattedString
    }
    
    private func updateDescriptionWithSender(usingMessage message: (Any) -> String) async throws {
        guard let sender = try await username(forUserHandle: chatListItem.lastMessageSender, shouldUseMeText: false) else { return }
        updateDescription(withMessage: message(sender))
    }
    
    private func updateDesctiptionWithChatTitleChange() async throws {
        guard let sender = try await username(forUserHandle: chatListItem.lastMessageSender, shouldUseMeText: false) else {
            return
        }
        var changedGroupChatNameTo = Strings.Localizable.changedGroupChatNameTo
        changedGroupChatNameTo = changedGroupChatNameTo.replacingOccurrences(of: "[A]", with: sender)
        changedGroupChatNameTo = changedGroupChatNameTo.replacingOccurrences(of: "[B]", with: chatListItem.lastMessage ?? "")
        updateDescription(withMessage: changedGroupChatNameTo)
    }
    
    private func updateDescriptionForContact() async throws {
        let sender = try await username(forUserHandle: chatListItem.lastMessageSender, shouldUseMeText: false)
        guard let lastMessage = chatListItem.lastMessage else {
            return
        }
        
        let components = lastMessage.components(separatedBy: "\\x01")
        let message: String
        if components.count == 1 {
            message = Strings.Localizable.sentContact(lastMessage)
        } else {
            message = Strings.Localizable.sentXContacts(String(format: "%tu", components.count))
        }
        
        if let sender, chatListItem.group {
            updateDescription(withMessage: "\(sender): \(message)")
        } else {
            updateDescription(withMessage: message)
        }
    }
    
    private func updateDescriptionForVoiceClip() async throws {
        let sender = try await username(forUserHandle: chatListItem.lastMessageSender, shouldUseMeText: true)
        let message = chatRoomUseCase.message(forChatId: chatListItem.chatId, messageId: chatListItem.lastMessageId)
        
        guard let duration = TimeInterval(message?.nodes?.first?.duration ?? 0).timeDisplayString(),
              let image = UIImage(named: chatListItem.unreadCount > 0 ? "voiceMessage" : "voiceMessageGrey") else {
            return
        }

        if let sender {
            updateHybridDescription(with: "\(sender):", image: image, duration: duration)
        } else {
            updateHybridDescription(with: nil, image: image, duration: duration)
        }
    }
    
    private func updateDescriptionForDefault() async throws {
        let sender = try await username(forUserHandle: chatListItem.lastMessageSender, shouldUseMeText: true)
        if chatListItem.lastMessageType == .containsMeta {
            let message = chatRoomUseCase.message(forChatId: chatListItem.chatId, messageId: chatListItem.lastMessageId)
            
            if message?.containsMeta?.type == .geolocation,
                let image = UIImage(named: chatListItem.unreadCount > 0 ? "locationMessage" : "locationMessageGrey") {
                if let sender {
                    updateHybridDescription(with: "\(sender):", image: image, duration: Strings.Localizable.pinnedLocation)
                } else {
                    updateHybridDescription(with: nil, image: image, duration: Strings.Localizable.pinnedLocation)
                }
            }
        }
        
        if let message = chatListItem.lastMessage {
            if let sender {
                updateDescription(withMessage: sender + ": " + message)

            } else {
                updateDescription(withMessage: message)
            }
        }
    }
    
    private func updateDescriptionForScheduledMeeting() async throws {
        guard let sender = try await username(forUserHandle: chatListItem.lastMessageSender, shouldUseMeText: true) else {
            return
        }
        
        updateDescription(withMessage: Strings.Localizable.Chat.Listing.Description.MeetingCreated.message(sender))
    }
    
    private func callDurationString(fromSeconds seconds: Int) -> String? {
        if seconds >= 60 {
            if seconds >= 3600 {
                return seconds.string(allowedUnits: [.hour, .minute])
            } else {
                return seconds.string(allowedUnits: [.minute])
            }
        } else {
            return seconds.string(allowedUnits: [.second])
        }
    }
    
    private func retentionDuration(fromSeconds seconds: Int) -> String? {
        let secondsInAnHour = 60 * 60
        let secondsInADay = secondsInAnHour * 24
        let secondsInAWeek = secondsInADay * 7
        let secondsInAMonth = secondsInADay * 30
        let secondsInAYear = secondsInADay * 365
        
        let hoursModulo = seconds % secondsInAnHour
        let daysModulo = seconds % secondsInADay
        let weeksModulo = seconds % secondsInAWeek
        let monthsModulo = seconds % secondsInAMonth
        let yearModulo = seconds % secondsInAYear
        
        if yearModulo == 0 {
            return Strings.Localizable.General.Format.RetentionPeriod.year(1)
        } else if (monthsModulo == 0) {
            let months = seconds / secondsInAMonth
            return Strings.Localizable.General.Format.RetentionPeriod.month(months)
        } else if (weeksModulo == 0) {
            let weeks = seconds / secondsInAWeek
            return Strings.Localizable.General.Format.RetentionPeriod.week(weeks)
        } else if (daysModulo == 0) {
            let days = seconds / secondsInADay
            return Strings.Localizable.General.Format.RetentionPeriod.day(days)
        } else if (hoursModulo == 0) {
            let hours = seconds / secondsInAHour
            return Strings.Localizable.General.Format.RetentionPeriod.hour(hours)
        }
        
        return nil
    }
    
    private func updateHybridDescription(with sender: String?, image: UIImage, duration: String) {
        hybridDescription = ChatRoomHybridDescriptionViewState(sender: sender, image: image, duration: duration)
    }
    
    private func updateDescription(withMessage message: String) {
        description = message
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
        guard let chatRoom = chatRoomUseCase.chatRoom(forChatId: chatListItem.chatId) else {
            MEGALogError("Not able to fetch chat room for start or join call")
            return
        }
        
        if let call = callUseCase.call(for: chatRoom.chatId), call.status != .userNoPresent {
            prepareAndShowCallUI(for: call, in: chatRoom)
        } else {
            if let scheduledMeeting = chatUseCase.scheduledMeetingsByChat(chatId: chatListItem.chatId).first {
                startMeetingCallNoRinging(for: scheduledMeeting, in: chatRoom)
            } else {
                startCall(in: chatRoom)
            }
        }
    }
    
    private func startCall(in chatRoom: ChatRoomEntity) {
        callUseCase.startCall(for: chatRoom.chatId, enableVideo: false, enableAudio: true) { [weak self] result in
            switch result {
            case .success(let call):
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
    }
    
    private func startMeetingCallNoRinging(for scheduledMeeting: ScheduledMeetingEntity, in chatRoom: ChatRoomEntity) {
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

extension ChatRoomViewModel: Equatable {
    static func == (lhs: ChatRoomViewModel, rhs: ChatRoomViewModel) -> Bool {
        lhs.chatListItem == rhs.chatListItem
    }
}
