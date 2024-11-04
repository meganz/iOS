import Combine
import Foundation
import MEGADomain
import MEGAL10n
import MEGAPermissions
import MEGAPresentation
import MEGASwift
import MEGAUI

@MainActor
final class ChatRoomViewModel: ObservableObject, Identifiable {
    let chatListItem: ChatListItemEntity
    private let router: any ChatRoomsListRouting
    private let chatRoomUseCase: any ChatRoomUseCaseProtocol
    private let chatRoomUserUseCase: any ChatRoomUserUseCaseProtocol
    private let chatUseCase: any ChatUseCaseProtocol
    private let accountUseCase: any AccountUseCaseProtocol
    private let callUseCase: any CallUseCaseProtocol
    private let audioSessionUseCase: any AudioSessionUseCaseProtocol
    private let scheduledMeetingUseCase: any ScheduledMeetingUseCaseProtocol
    private let handleUseCase: any MEGAHandleUseCaseProtocol
    private let callManager: any CallManagerProtocol
    private var chatNotificationControl: ChatNotificationControl
    private let permissionRouter: any PermissionAlertRouting
    private let chatListItemCacheUseCase: any ChatListItemCacheUseCaseProtocol
    private let callInProgressTimeReporter: any CallInProgressTimeReporting
    private var callInProgressTimeMonitorTask: Task<Void, Never>? {
        willSet {
            callInProgressTimeMonitorTask?.cancel()
        }
    }
    
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

    private var searchString = ""
    
    let chatRoomAvatarViewModel: ChatRoomAvatarViewModel?
    
    let shouldShowUnreadCount: Bool
    let unreadCountString: String
    
    init(
        chatListItem: ChatListItemEntity,
        router: some ChatRoomsListRouting,
        chatRoomUseCase: some ChatRoomUseCaseProtocol,
        chatRoomUserUseCase: some ChatRoomUserUseCaseProtocol,
        userImageUseCase: some UserImageUseCaseProtocol,
        chatUseCase: some ChatUseCaseProtocol,
        accountUseCase: some AccountUseCaseProtocol,
        megaHandleUseCase: some MEGAHandleUseCaseProtocol,
        callManager: some CallManagerProtocol,
        callUseCase: some CallUseCaseProtocol,
        audioSessionUseCase: some AudioSessionUseCaseProtocol,
        scheduledMeetingUseCase: some ScheduledMeetingUseCaseProtocol,
        chatNotificationControl: ChatNotificationControl,
        permissionRouter: some PermissionAlertRouting,
        chatListItemCacheUseCase: some ChatListItemCacheUseCaseProtocol,
        chatListItemDescription: ChatListItemDescriptionEntity? = nil,
        chatListItemAvatar: ChatListItemAvatarEntity? = nil,
        callInProgressTimeReporter: some CallInProgressTimeReporting = CallInProgressTimeReporter()
    ) {
        self.chatListItem = chatListItem
        self.router = router
        self.chatRoomUseCase = chatRoomUseCase
        self.chatRoomUserUseCase = chatRoomUserUseCase
        self.chatUseCase = chatUseCase
        self.accountUseCase = accountUseCase
        self.handleUseCase = megaHandleUseCase
        self.callManager = callManager
        self.callUseCase = callUseCase
        self.audioSessionUseCase = audioSessionUseCase
        self.scheduledMeetingUseCase = scheduledMeetingUseCase
        self.chatNotificationControl = chatNotificationControl
        self.permissionRouter = permissionRouter
        self.chatListItemCacheUseCase = chatListItemCacheUseCase
        self.description = chatListItemDescription?.description
        self.isMuted = chatNotificationControl.isChatDNDEnabled(chatId: chatListItem.chatId)
        self.shouldShowUnreadCount = chatListItem.unreadCount != 0
        self.callInProgressTimeReporter = callInProgressTimeReporter
        
        if chatListItem.unreadCount > 0 {
            self.unreadCountString = chatListItem.unreadCount > 99 ? "99+" : "\(chatListItem.unreadCount)"
        } else {
            self.unreadCountString = "\(-chatListItem.unreadCount)+"
        }
        
        if let chatRoomEntity = chatRoomUseCase.chatRoom(forChatId: chatListItem.chatId) {
            self.chatRoomAvatarViewModel = ChatRoomAvatarViewModel(
                title: chatListItem.title ?? "",
                peerHandle: chatListItem.peerHandle,
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
        } else {
            self.chatRoomAvatarViewModel = nil
        }
        
        self.displayDateString = formattedLastMessageSentDate()
        
        self.existsInProgressCallInChatRoom = chatUseCase.isCallInProgress(for: chatListItem.chatId)
        if let call = callUseCase.call(for: chatListItem.chatId) {
            startMonitoringCallInProgressTime(for: call)
        }
        monitorActiveCallChanges()
        
        if !chatListItem.group {
            self.chatStatus = chatRoomUseCase.userStatus(forUserHandle: chatListItem.peerHandle)
            self.listeningForChatStatusUpdate()
        }
        
        contextMenuOptions = constructContextMenuOptions()
        loadChatRoomSearchString()
    }
    
    deinit {
        callInProgressTimeMonitorTask?.cancel()
    }
    
    // MARK: - Interface methods
    
    func loadChatRoomInfo() async {
        let chatId = chatListItem.chatId
        
        guard !Task.isCancelled else {
            MEGALogDebug("Task cancelled for \(chatId) - won't update description")
            return
        }
        
        do {
            try await updateDescription()
        } catch {
            MEGALogDebug("Unable to load description for \(chatId) - \(error.localizedDescription)")
        }
        
        do {
            try Task.checkCancellation()
            sendObjectChangeNotification()
        } catch {
            MEGALogDebug("Task cancelled for \(chatId) - won't send object change notification")
        }
    }
    
    func chatStatusColor(forChatStatus chatStatus: ChatStatusEntity) -> UIColor? {
        switch chatStatus {
        case .online:
            return UIColor.chatStatusOnline
        case .offline:
            return UIColor.chatStatusOffline
        case .away:
            return UIColor.chatStatusAway
        case .busy:
            return UIColor.chatStatusBusy
        default:
            return nil
        }
    }
    
    func contains(searchText: String) -> Bool {
        searchString.localizedCaseInsensitiveContains(searchText)
    }
    
    func showDetails() {
        router.showDetails(forChatId: chatListItem.chatId)
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
            await updateDescription(withMessage: Strings.Localizable.loading)
        case .invalid:
            await updateDescription(withMessage: Strings.Localizable.noConversationHistory)
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
            await updateDescription(withMessage: Strings.Localizable.callStarted)
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
                    image: existsInProgressCallInChatRoom ? .joinMeeting2 : .startMeeting2,
                    action: {
                        self.startOrJoinMeetingTapped()
                    }))
        }
        
        if chatListItem.unreadCount > 0 {
            options.append(
                ChatRoomContextMenuOption(
                    title: Strings.Localizable.markAsRead,
                    image: .markUnreadMenu,
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
                image: .mutedChat,
                action: { [weak self] in
                    guard let self else { return }
                    self.toggleDND()
                }),
            ChatRoomContextMenuOption(
                title: Strings.Localizable.info,
                image: .info,
                action: { [weak self] in
                    guard let self else { return }
                    self.showChatRoomInfo()
                }),
            ChatRoomContextMenuOption(
                title: Strings.Localizable.archiveChat,
                image: .archiveChatMenu,
                action: { [weak self] in
                    guard let self else { return }
                    self.archiveChat()
                })
        ]
        
        return options
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
                chatStatus = statusForUser.1
            })
            .store(in: &subscriptions)
    }
    
    private func monitorActiveCallChanges() {
        chatUseCase.monitorChatCallStatusUpdate()
            .sink { [weak self] call in
                guard let self, call.chatId == self.chatListItem.chatId else { return }
                self.existsInProgressCallInChatRoom = call.status == .inProgress || call.status == .userNoPresent
                self.startMonitoringCallInProgressTime(for: call)
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
        
        let message = components.count == 1 ? 
        Strings.Localizable.attachedFile(lastMessage) :
        Strings.Localizable.Chat.Message.numberOfAttachments(components.count)

        if let senderString {
            await updateDescription(withMessage: "\(senderString): \(message)")
        } else {
            await updateDescription(withMessage: message)
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
        
        await updateDescription(withMessage: message)
    }
    
    private func updateDescriptionForRententionTime() async throws {
        guard let sender = try await username(forUserHandle: chatListItem.lastMessageSender, shouldUseMeText: false),
              let chatRoom = chatRoomUseCase.chatRoom(forChatId: chatListItem.chatId) else {
            return
        }
        
        if chatRoom.retentionTime <= 0 {
            let message = removeFormatters(fromString: Strings.Localizable.A1SABDisabledMessageClearing.b(sender))
            await updateDescription(withMessage: message)
        } else {
            guard let retention = retentionDuration(fromSeconds: Int(chatRoom.retentionTime)) else {
                return
            }
            let message = removeFormatters(fromString: Strings.Localizable.A1SABChangedTheMessageClearingTimeToBA2SAB.b(sender, retention))
            await updateDescription(withMessage: message)
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
                await updateDescription(withMessage: message)
            } else {
                var message = Strings.Localizable.leftTheGroupChat
                message = message.replacingOccurrences(of: "[A]", with: lastMessageUsername)
                await updateDescription(withMessage: message)
            }
        case .joinedGroupChat:
            if let sender, sender != lastMessageUsername {
                var message = Strings.Localizable.joinedTheGroupChatByInvitationFrom
                message = message.replacingOccurrences(of: "[A]", with: lastMessageUsername)
                message = message.replacingOccurrences(of: "[B]", with: sender)
                await updateDescription(withMessage: message)
            } else {
                let message = Strings.Localizable.joinedTheGroupChat(lastMessageUsername)
                await updateDescription(withMessage: message)
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
        await updateDescription(withMessage: message)
    }
    
    private func updateDescriptionForTruncate() async throws {
        guard let sender = try await username(forUserHandle: chatListItem.lastMessageSender, shouldUseMeText: false) else {
            return
        }
        let message = Strings.Localizable.clearedTheChatHistory.replacingOccurrences(of: "[A]", with: sender)
        await updateDescription(withMessage: message)
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
        await updateDescription(withMessage: message(sender))
    }
    
    private func updateDesctiptionWithChatTitleChange() async throws {
        guard let sender = try await username(forUserHandle: chatListItem.lastMessageSender, shouldUseMeText: false) else {
            return
        }
        var changedGroupChatNameTo = Strings.Localizable.changedGroupChatNameTo
        changedGroupChatNameTo = changedGroupChatNameTo.replacingOccurrences(of: "[A]", with: sender)
        changedGroupChatNameTo = changedGroupChatNameTo.replacingOccurrences(of: "[B]", with: chatListItem.lastMessage ?? "")
        await updateDescription(withMessage: changedGroupChatNameTo)
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
            await updateDescription(withMessage: "\(sender): \(message)")
        } else {
            await updateDescription(withMessage: message)
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
                await updateDescription(withMessage: sender + ": " + message)
                
            } else {
                await updateDescription(withMessage: message)
            }
        }
    }
    
    private func updateDescriptionForScheduledMeeting() async throws {
        guard let sender = try await username(forUserHandle: chatListItem.lastMessageSender, shouldUseMeText: true) else {
            return
        }
        
        await updateDescription(withMessage: Strings.Localizable.Meetings.Scheduled.ManagementMessages.updated(sender))
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
    
    private func updateDescription(withMessage message: String) async {
        guard !Task.isCancelled else { return }
        
        description = message
        await chatListItemCacheUseCase.setDescription(
            ChatListItemDescriptionEntity(description: message),
            for: chatListItem
        )
    }
    
    func startOrJoinMeetingTapped() {
        permissionRouter.audioPermission(modal: true, incomingCall: false) {[weak self] granted in
            guard let self else { return }
            guard granted else {
                permissionRouter.alertAudioPermission(incomingCall: false)
                return
            }
            
            guard !chatUseCase.existsActiveCall() else {
                router.presentMeetingAlreadyExists()
                return
            }
            
            if chatRoomUseCase.shouldOpenWaitingRoom(forChatId: chatListItem.chatId) {
                openWaitingRoom()
            } else {
                startOrJoinCall()
            }
        }
    }
    
    private func openWaitingRoom() {
        guard let scheduledMeeting = scheduledMeetingUseCase.scheduledMeetingsByChat(chatId: chatListItem.chatId).first else { return }
        router.presentWaitingRoom(for: scheduledMeeting)
    }
    
    func startOrJoinCall() {
        guard let chatRoom = chatRoomUseCase.chatRoom(forChatId: chatListItem.chatId) else {
            MEGALogError("Not able to fetch chat room for start or join call")
            return
        }
        
        if let call = callUseCase.call(for: chatRoom.chatId), call.status != .userNoPresent {
            prepareAndShowCallUI(for: call, in: chatRoom)
        } else {
            startCall(in: chatRoom)
        }
    }
    
    private func startCall(in chatRoom: ChatRoomEntity) {
        callManager.startCall(
            with: CallActionSync.startCallNoRinging(in: chatRoom)
        )
    }
    
    private func prepareAndShowCallUI(for call: CallEntity, in chatRoom: ChatRoomEntity) {
        audioSessionUseCase.enableLoudSpeaker()
        router.openCallView(for: call, in: chatRoom)
    }
    
    private func startMonitoringCallInProgressTime(for call: CallEntity) {
        callInProgressTimeMonitorTask = Task { [weak self, callInProgressTimeReporter] in
            for await timeInterval in callInProgressTimeReporter.configureCallInProgress(for: call) {
                self?.totalCallDuration = timeInterval
            }
        }
    }
}
