import Combine
import MEGAAppPresentation
import MEGADomain
import MEGAL10n

@MainActor
final class ChatRoomNotificationsViewModel: ObservableObject {
    private var chatRoom: ChatRoomEntity
    private let networkMonitorUseCase: any NetworkMonitorUseCaseProtocol
    private let isNewOfflineModeEnabled: Bool
    lazy private var chatNotificationControl = ChatNotificationControl(delegate: self)
    
    @Published var isChatNotificationsOn = true
    @Published var showDNDTurnOnOptions = false
    @Published private var isConnectedToNetwork: Bool

    private var subscriptions = Set<AnyCancellable>()
    private var networkMonitorTask: Task<Void, Never>?

    /// Changing the setting writes it to the API. Offline the request sits in the SDK retry queue,
    /// so the progress indicator it shows would never be dismissed, leaving the screen stuck on a
    /// spinner. The toggle is disabled instead, with the reason spelled out below it.
    var isChatNotificationsToggleEnabled: Bool {
        isConnectedToNetwork || !isNewOfflineModeEnabled
    }

    var noConnectionMessage: String? {
        isChatNotificationsToggleEnabled ? nil : Strings.Localizable.noInternetConnection
    }

    init(
        chatRoom: ChatRoomEntity,
        networkMonitorUseCase: some NetworkMonitorUseCaseProtocol,
        featureFlagProvider: some FeatureFlagProviderProtocol = DIContainer.featureFlagProvider
    ) {
        self.chatRoom = chatRoom
        self.networkMonitorUseCase = networkMonitorUseCase
        self.isNewOfflineModeEnabled = featureFlagProvider.isNewOfflineModeEnabled
        self.isConnectedToNetwork = networkMonitorUseCase.isConnected()
        synchronizeChatNotificationsOn()
        listenToChatNotificationSwitchChanges()
        monitorNetworkChanges()
    }

    deinit {
        networkMonitorTask?.cancel()
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
        guard isChatNotificationsToggleEnabled else { return }
        let notificationsEnabled = !chatNotificationControl.isChatDNDEnabled(chatId: chatRoom.chatId)
        guard isOn != notificationsEnabled else { return }
        
        if isOn {
            chatNotificationControl.turnOffDND(chatId: chatRoom.chatId)
        } else {
            showDNDTurnOnOptions = true
        }
    }
    
    private func monitorNetworkChanges() {
        let connectionSequence = networkMonitorUseCase.connectionSequence
        networkMonitorTask?.cancel()
        networkMonitorTask = Task { [weak self] in
            for await isConnected in connectionSequence {
                self?.isConnectedToNetwork = isConnected
            }
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
