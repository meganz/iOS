import Combine
import Foundation
import MEGADomain
import MEGAPermissions
import MEGASwift
import MEGAUI

final class ChatRoomViewModel: ObservableObject, Identifiable, CallInProgressTimeReporting {
    let chatListItem: ChatListItemEntity
    private let chatRoomUseCase: any ChatRoomUseCaseProtocol
    private let chatRoomUserUseCase: any ChatRoomUserUseCaseProtocol
    private let chatUseCase: any ChatUseCaseProtocol
    private let accountUseCase: any AccountUseCaseProtocol
    private let callUseCase: any CallUseCaseProtocol
    private let audioSessionUseCase: any AudioSessionUseCaseProtocol
    private let scheduledMeetingUseCase: any ScheduledMeetingUseCaseProtocol
    
    private let router: any ChatRoomsListRouting
    private var chatNotificationControl: ChatNotificationControl
    private let notificationCenter: NotificationCenter
    
    private(set) var description: String?
    private(set) var hybridDescription: ChatRoomHybridDescriptionViewState?
    @Published var chatStatus: ChatStatusEntity = .invalid
    @Published var showDNDTurnOnOptions = false
    @Published var existsInProgressCallInChatRoom = false
    @Published var totalCallDuration: TimeInterval = 0
    
    private(set) var contextMenuOptions: [ChatRoomContextMenuOption]?
    private(set) var isMuted: Bool
    
    private(set) var displayDateString: String?
    
    private var subscriptions = Set<AnyCancellable>()
    private var loadingChatRoomInfoTask: Task<Void, Never>?
    
    private var isViewOnScreen = false
    private var loadingChatRoomInfoSubscription: AnyCancellable?
    private var searchString = ""
    
    private var isInfoLoaded = false
    let chatRoomAvatarViewModel: ChatRoomAvatarViewModel?
    
    let shouldShowUnreadCount: Bool
    let unreadCountString: String
    
    var callDurationTotal: TimeInterval?
    var callDurationCapturedTime: TimeInterval?
    var timerSubscription: AnyCancellable?
    let permissionHandler: any DevicePermissionsHandling
    
    init(chatListItem: ChatListItemEntity,
         router: some ChatRoomsListRouting,
         chatRoomUseCase: any ChatRoomUseCaseProtocol,
         chatRoomUserUseCase: any ChatRoomUserUseCaseProtocol,
         userImageUseCase: any UserImageUseCaseProtocol,
         chatUseCase: any ChatUseCaseProtocol,
         accountUseCase: any AccountUseCaseProtocol,
         megaHandleUseCase: any MEGAHandleUseCaseProtocol,
         callUseCase: any CallUseCaseProtocol,
         audioSessionUseCase: any AudioSessionUseCaseProtocol,
         scheduledMeetingUseCase: any ScheduledMeetingUseCaseProtocol,
         chatNotificationControl: ChatNotificationControl,
         permissionHandler: some DevicePermissionsHandling,
         notificationCenter: NotificationCenter = .default) {
        self.chatListItem = chatListItem
        self.router = router
        self.chatRoomUseCase = chatRoomUseCase
        self.chatRoomUserUseCase = chatRoomUserUseCase
        self.chatUseCase = chatUseCase
        self.accountUseCase = accountUseCase
        self.callUseCase = callUseCase
        self.audioSessionUseCase = audioSessionUseCase
        self.scheduledMeetingUseCase = scheduledMeetingUseCase
        self.chatNotificationControl = chatNotificationControl
        self.permissionHandler = permissionHandler
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
                chatRoomUserUseCase: chatRoomUserUseCase,
                userImageUseCase: userImageUseCase,
                chatUseCase: chatUseCase,
                accountUseCase: accountUseCase,
                megaHandleUseCase: megaHandleUseCase
            )
        } else {
            self.chatRoomAvatarViewModel = nil
        }
        
        self.displayDateString = formattedLastMessageSentDate()
        
        self.existsInProgressCallInChatRoom = chatUseCase.isCallInProgress(for: chatListItem.chatId)
        if let call = callUseCase.call(for: chatListItem.chatId) {
            configureCallInProgress(for: call)
        }
        monitorActiveCallChanges()
        
        if !chatListItem.group {
            self.chatStatus = chatRoomUseCase.userStatus(forUserHandle: chatListItem.peerHandle)
            self.listeningForChatStatusUpdate()
        }
        
        contextMenuOptions = constructContextMenuOptions()
        loadChatRoomSearchString()
    }
    
    // MARK: - Interface methods
    
    func onViewAppear() {
        isViewOnScreen = true
        
        loadChatRoomInfo()
    }
    
    func cancelLoading() {
        isViewOnScreen = false
        
        cancelChatRoomInfoTask()
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
    
    func presentMoreOptionsForChat() {
        router.presentMoreOptionsForChat(
            withDNDEnabled: chatNotificationControl.isChatDNDEnabled(chatId: chatListItem.chatId)
        ) { [weak self] in
            self?.toggleDND()
        } markAsReadAction: { [weak self] in
            guard let self, let chatRoom = self.chatRoomUseCase.chatRoom(forChatId: self.chatListItem.chatId) else { return }
            self.chatRoomUseCase.setMessageSeenForChat(forChatRoom: chatRoom, messageId: self.chatListItem.lastMessageId)
        } infoAction: { [weak self] in
            self?.showChatRoomInfo()
        } archiveAction: { [weak self] in
            guard let self, let chatRoom = self.chatRoomUseCase.chatRoom(forChatId: self.chatListItem.chatId) else { return }
            self.chatRoomUseCase.archive(true, chatRoom: chatRoom)
        }
    }
    
    func dndTurnOnOptions() -> [DNDTurnOnOption] {
        ChatNotificationControl.dndTurnOnOptions()
    }
    
    func turnOnDNDOption(_ option: DNDTurnOnOption) {
        chatNotificationControl.turnOnDND(chatId: chatListItem.chatId, option: option)
    }
    
    func archiveChat() {
        guard let chatRoom = chatRoomUseCase.chatRoom(forChatId: chatListItem.chatId) else { return }
        chatRoomUseCase.archive(true, chatRoom: chatRoom)
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
    
    // MARK: - Private methods
    
    private func formattedLastMessageSentDate() -> String? {
        guard let seventhDayPriorDate = Calendar.autoupdatingCurrent.date(byAdding: .day, value: -7, to: Date()) else { return nil }
        
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
        if chatListItem.meeting && scheduledMeetingUseCase.scheduledMeetingsByChat(chatId: chatListItem.chatId).isNotEmpty {
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
                        guard let self, let chatRoom = self.chatRoomUseCase.chatRoom(forChatId: self.chatListItem.chatId) else { return }
                        self.chatRoomUseCase.setMessageSeenForChat(
                            forChatRoom: chatRoom,
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
    
    private func cancelChatRoomInfoTask() {
        loadingChatRoomInfoTask?.cancel()
        loadingChatRoomInfoTask = nil
    }
    
    private func loadChatRoomInfo() {
        loadingChatRoomInfoTask = Task { [weak self] in
            guard let self else { return }
            
            let chatId = chatListItem.chatId
            
            defer {
                cancelChatRoomInfoTask()
            }
            
            do {
                try await self.updateDescription()
            } catch {
                MEGALogDebug("Unable to load description for \(chatId) - \(error.localizedDescription)")
            }
            
            guard self.isViewOnScreen else { return }
            
            do {
                try Task.checkCancellation()
                await sendObjectChangeNotification()
            } catch {
                MEGALogDebug("Task cancelled for \(chatId)")
            }
        }
    }
    
    private func loadChatRoomSearchString() {
        Task { [weak self] in
            guard let self, let chatRoom = self.chatRoomUseCase.chatRoom(forChatId: self.chatListItem.chatId) else {
                return
            }
            
            do {
                self.searchString = try await self.chatRoomUserUseCase.chatRoomUsersDescription(for: chatRoom)
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
            if let scheduledMeeting = scheduledMeetingUseCase.scheduledMeetingsByChat(chatId: chatListItem.chatId).first {
                router.showMeetingInfo(for: scheduledMeeting)
            } else {
                guard let chatRoom = chatRoomUseCase.chatRoom(forChatId: chatListItem.chatId),
                      let chatIdString = chatRoomUseCase.base64Handle(forChatRoom: chatRoom),
                      MEGALinkManager.joiningOrLeavingChatBase64Handles.notContains(where: { element in
                          if let elementId = element as? String, elementId == chatIdString {
                              return true
                          }
                          return false
                      }) else {
                    return
                }
                guard let chatRoom = chatRoomUseCase.chatRoom(forChatId: chatListItem.chatId) else {
                    return
                }
                router.showGroupChatInfo(forChatRoom: chatRoom)
            }
        } else {
            guard let chatRoom = chatRoomUseCase.chatRoom(forChatId: chatListItem.chatId),
                  let userHandle = chatRoomUseCase.peerHandles(forChatRoom: chatRoom).first,
                  let userEmail = chatRoomUserUseCase.contactEmail(forUserHandle: userHandle) else {
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
                self.configureCallInProgress(for: call)
                self.contextMenuOptions = self.constructContextMenuOptions()
            }
            .store(in: &subscriptions)
    }
    
    private func username(forUserHandle userHandle: HandleEntity, shouldUseMeText: Bool) async throws -> String? {
        if userHandle == accountUseCase.currentUserHandle {
            return shouldUseMeText ? Strings.Localizable.me : chatUseCase.myFullName()
        } else {
            guard let chatRoom = chatRoomUseCase.chatRoom(forChatId: chatListItem.chatId) else { return nil }
            let usernames = try await chatRoomUserUseCase.userDisplayNames(forPeerIds: [userHandle], in: chatRoom)
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
              let lastMessageUsername = try await chatRoomUserUseCase.userDisplayNames(forPeerIds: [chatListItem.lastMessageHandle], in: chatRoom).first else {
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
              let lastMessageUsername = try await chatRoomUserUseCase.userDisplayNames(forPeerIds: [chatListItem.lastMessageHandle], in: chatRoom).first else {
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
    
    private func updateDescriptionForTruncate() async throws {
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
            if userHandle == accountUseCase.currentUserHandle {
                return Strings.Localizable.callWasNotAnswered
            } else {
                return Strings.Localizable.missedCall
            }
        case .failed:
            return Strings.Localizable.callFailed
        case .cancelled:
            if userHandle == accountUseCase.currentUserHandle {
                return Strings.Localizable.callWasCancelled
            } else {
                return Strings.Localizable.missedCall
            }
        }
    }
    
    private func removeFormatters(fromString string: String) -> String {
        var formattedString = string
        if #available(iOS 16.0, *) {
            // swiftlint:disable opening_brace
            formattedString.replace(/\[.{1, 2}\]/, with: "")
            // swiftlint:enable opening_brace
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
        guard let chatRoom = chatRoomUseCase.chatRoom(forChatId: chatListItem.chatId) else { return }
        let message = chatRoomUseCase.message(forChatRoom: chatRoom, messageId: chatListItem.lastMessageId)
        
        guard let image = UIImage(named: chatListItem.unreadCount > 0 ? "voiceMessage" : "voiceMessageGrey") else {
            return
        }
        
        let duration = TimeInterval(message?.nodes?.first?.duration ?? 0).timeString
        if let sender {
            updateHybridDescription(with: "\(sender):", image: image, duration: duration)
        } else {
            updateHybridDescription(with: nil, image: image, duration: duration)
        }
    }
    
    private func updateDescriptionForDefault() async throws {
        let sender = try await username(forUserHandle: chatListItem.lastMessageSender, shouldUseMeText: true)
        if chatListItem.lastMessageType == .containsMeta {
            guard let chatRoom = chatRoomUseCase.chatRoom(forChatId: chatListItem.chatId) else { return }
            let message = chatRoomUseCase.message(forChatRoom: chatRoom, messageId: chatListItem.lastMessageId)
            
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
        guard let sender = try await username(forUserHandle: chatListItem.lastMessageSender, shouldUseMeText: true), let chatRoom = chatRoomUseCase.chatRoom(forChatId: chatListItem.chatId), let message = chatRoomUseCase.message(forChatRoom: chatRoom, messageId: chatListItem.lastMessageId) else {
            return
        }
        
        if chatRoomUseCase.hasScheduledMeetingChange(.cancelled, for: message, inChatRoom: chatRoom) {
            updateDescription(withMessage: Strings.Localizable.Meetings.Scheduled.ManagementMessages.cancelled(sender))
        } else {
            updateDescription(withMessage: Strings.Localizable.Chat.Listing.Description.MeetingCreated.message(sender))
        }
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
        } else if monthsModulo == 0 {
            let months = seconds / secondsInAMonth
            return Strings.Localizable.General.Format.RetentionPeriod.month(months)
        } else if weeksModulo == 0 {
            let weeks = seconds / secondsInAWeek
            return Strings.Localizable.General.Format.RetentionPeriod.week(weeks)
        } else if daysModulo == 0 {
            let days = seconds / secondsInADay
            return Strings.Localizable.General.Format.RetentionPeriod.day(days)
        } else if hoursModulo == 0 {
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
    
    var permissionRouter: PermissionAlertRouter {
        .makeRouter(deviceHandler: permissionHandler)
    }
    
    private func startOrJoinMeetingTapped() {
        permissionRouter.audioPermission(modal: true, incomingCall: false) {[weak self] granted in
            guard let self else { return }
            guard granted else {
                permissionRouter.alertAudioPermission(incomingCall: false)
                return
            }
            
            startOrJoinCall()
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
            if let scheduledMeeting = scheduledMeetingUseCase.scheduledMeetingsByChat(chatId: chatListItem.chatId).first {
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
                    self?.router.showErrorMessage(Strings.Localizable.Error.noMoreParticipantsAreAllowedInThisGroupCall)
                default:
                    self?.router.showErrorMessage(Strings.Localizable.somethingWentWrong)
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
}

extension ChatRoomViewModel: Equatable {
    static func == (lhs: ChatRoomViewModel, rhs: ChatRoomViewModel) -> Bool {
        lhs.chatListItem == rhs.chatListItem
    }
}
