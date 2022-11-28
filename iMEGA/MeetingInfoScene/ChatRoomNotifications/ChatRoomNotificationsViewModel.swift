import MEGADomain

final class ChatRoomNotificationsViewModel: ObservableObject {
    private var chatRoom: ChatRoomEntity
    private var isChatNotificationsActionCancelled = false
    lazy private var globalDNDNotificationControl = GlobalDNDNotificationControl(delegate: self)
    lazy private var chatNotificationControl = ChatNotificationControl(delegate: self)
    
    @Published var isChatNotificationsOn = true
    @Published var showDNDTurnOnOptions = false
    
    init(chatRoom: ChatRoomEntity) {
        self.chatRoom = chatRoom
        
        self.isChatNotificationsOn = !chatNotificationControl.isChatDNDEnabled(chatId: chatRoom.chatId)
    }
    
    func dndTurnOnOptions() -> [DNDTurnOnOption] {
        ChatNotificationControl.dndTurnOnOptions()
    }
    
    func turnOnDNDOption(_ option: DNDTurnOnOption) {
        chatNotificationControl.turnOnDND(chatId: chatRoom.chatId, option: option)
    }
    
    func remainingDNDTime() -> String {
        chatNotificationControl.timeRemainingForDNDDeactivationString(chatId: chatRoom.chatId) ?? ""
    }
    
    func chatNotificationsValueChanged(to enabled: Bool) {
        toggleDND()
    }
    
    func cancelChatNotificationsChange() {
        isChatNotificationsActionCancelled = true
        isChatNotificationsOn.toggle()
    }
    
    private func toggleDND() {
        guard !isChatNotificationsActionCancelled else {
            isChatNotificationsActionCancelled = false
            return
        }
        if chatNotificationControl.isChatDNDEnabled(chatId: chatRoom.chatId) {
            chatNotificationControl.turnOffDND(chatId: chatRoom.chatId)
        } else {
            showDNDTurnOnOptions = true
        }
    }
    
    private func updateChatNotificationsIfNeeded() {
        if showDNDTurnOnOptions {
            return
        }
        let notificationsEnabled = !chatNotificationControl.isChatDNDEnabled(chatId: chatRoom.chatId)
        guard notificationsEnabled != isChatNotificationsOn else {
            return
        }
        isChatNotificationsOn = notificationsEnabled
    }
}

extension ChatRoomNotificationsViewModel: PushNotificationControlProtocol {
    func reloadDataIfNeeded() {
        updateChatNotificationsIfNeeded()
    }
    
    func pushNotificationSettingsLoaded() {
        updateChatNotificationsIfNeeded()
    }
}
