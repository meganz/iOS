import Combine
import MEGADomain

@MainActor
final class ChatRoomNotificationsViewModel: ObservableObject {
    private var chatRoom: ChatRoomEntity
    lazy private var chatNotificationControl = ChatNotificationControl(delegate: self)
    
    @Published var isChatNotificationsOn = true
    @Published var showDNDTurnOnOptions = false
    
    private var subscriptions = Set<AnyCancellable>()

    init(chatRoom: ChatRoomEntity) {
        self.chatRoom = chatRoom
        synchronizeChatNotificationsOn()
        listenToChatNotificationSwitchChanges()
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
    
    func cancelChatNotificationsChange() {
        synchronizeChatNotificationsOn()
    }
    
    // MARK: - Private methods.
    
    private func updateChatNotificationsIfNeeded() {
        guard !showDNDTurnOnOptions else { return }
        synchronizeChatNotificationsOn()
    }
    
    private func listenToChatNotificationSwitchChanges() {
        $isChatNotificationsOn
            .dropFirst()
            .sink { [weak self] isChatNotificationSwitchOn in
                guard let self else { return }
                updateChatNotificationSetting(isOn: isChatNotificationSwitchOn)
            }
            .store(in: &subscriptions)
    }
    
    private func updateChatNotificationSetting(isOn: Bool) {
        let notificationsEnabled = !chatNotificationControl.isChatDNDEnabled(chatId: chatRoom.chatId)
        guard isOn != notificationsEnabled else { return }
        
        if isOn {
            chatNotificationControl.turnOffDND(chatId: chatRoom.chatId)
        } else {
            showDNDTurnOnOptions = true
        }
    }
    
    private func synchronizeChatNotificationsOn() {
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
