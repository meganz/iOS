import Combine
import MEGADomain
import MEGAL10n

@MainActor
public final class SetStatusViewModel: ObservableObject {
    private let chatUseCase: any ChatUseCaseProtocol
    private let chatPresenceUseCase: any ChatPresenceUseCaseProtocol

    @Published var currentStatus: ChatStatusEntity?
    @Published var isShowLastGreenEnabled: Bool = false
    @Published var isAutoAwayVisible: Bool = false

    @Published var isBottomSheetPresented = false
    @Published var autoAwayTimeString: String?

    var currentAutoAwayPreset: AutoAwayPreset?

    let chatOnlineStatuses: [ChatStatusEntity] = ChatStatusEntity.options()
    let autoAwayPresets: [AutoAwayPreset] = AutoAwayPreset.options()

    public init(
        chatUseCase: some ChatUseCaseProtocol,
        chatPresenceUseCase: some ChatPresenceUseCaseProtocol
    ) {
        self.chatUseCase = chatUseCase
        self.chatPresenceUseCase = chatPresenceUseCase
        
        monitorOnChatPresenceConfigUpdate()
    }
    
    func fetchData() async {
        guard let presenceConfig = chatPresenceUseCase.presenceConfig() else { return }
        updatePresenceConfig(presenceConfig)
    }
    
    func onlineStatusTapped(_ status: ChatStatusEntity) {
        guard status != currentStatus else { return }
        chatPresenceUseCase.setOnlineStatus(status)
    }
    
    func autoAwayTapped() {
        isBottomSheetPresented.toggle()
    }
    
    func autoAwayPresetTapped(_ preset: AutoAwayPreset) {
        switch preset {
        case .none:
            break
        case .never:
            chatPresenceUseCase.setAutoAwayPresence(false, seconds: 0)
        case .minutes(let minutes):
            chatPresenceUseCase.setAutoAwayPresence(true, seconds: minutes * 60)
        case .hours(let hours):
            chatPresenceUseCase.setAutoAwayPresence(true, seconds: hours * 60 * 60)
        }
        isBottomSheetPresented.toggle()
    }
    
    private func monitorOnChatPresenceConfigUpdate() {
        let presenceConfigUpdate = chatPresenceUseCase.monitorOnPresenceConfigUpdates()
        Task { [weak self] in
            for await presenceConfig in presenceConfigUpdate {
                self?.updatePresenceConfig(presenceConfig)
            }
        }
    }
    
    func toggleEnableShowLastGreen(isCurrentlyEnabled: Bool) {
        chatPresenceUseCase.setLastGreenVisible(!isCurrentlyEnabled)
        isShowLastGreenEnabled = !isCurrentlyEnabled
    }
    
    private func updatePresenceConfig(_ presenceConfig: ChatPresenceConfigEntity) {
        currentStatus = presenceConfig.status
        isShowLastGreenEnabled = presenceConfig.lastGreenVisible
        configureAutoAway(from: presenceConfig)
    }
    
    private func configureAutoAway(from presenceConfig: ChatPresenceConfigEntity) {
        isAutoAwayVisible = presenceConfig.status ==  .online
        if presenceConfig.autoAwayEnabled {
            currentAutoAwayPreset = AutoAwayPreset(fromMinutes: Int(presenceConfig.autoAwayTimeout) / 60)
            autoAwayTimeString = Strings.Localizable.Settings.Chat.Status.SetStatus.StatusSettings.AutoAway.subtitle(presenceConfig.autoAwayFormatString)
        } else {
            currentAutoAwayPreset = .never
            autoAwayTimeString = Strings.Localizable.never
        }
    }
}
