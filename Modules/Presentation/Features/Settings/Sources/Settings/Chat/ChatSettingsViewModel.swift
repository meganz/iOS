import Combine
import MEGADomain
import MEGAPreference

@MainActor
public final class ChatSettingsViewModel: ObservableObject {
    private let accountUseCase: any AccountUseCaseProtocol
    private let chatUseCase: any ChatUseCaseProtocol
    private let chatPresenceUseCase: any ChatPresenceUseCaseProtocol

    @PreferenceWrapper(key: PreferenceKeyEntity.richLinksPreviewEnabled, defaultValue: false)
    var richLinksPreviewEnabled: Bool
    
    @Published var isRichLinkPreviewEnabled: Bool = false
    @Published var onlineStatusString: String?

    private let navigateToStatus: () -> Void
    private let navigateToNotifications: () -> Void
    private let navigateToMediaQuality: () -> Void

    public init(
        accountUseCase: some AccountUseCaseProtocol,
        chatUseCase: some ChatUseCaseProtocol,
        chatPresenceUseCase: some ChatPresenceUseCaseProtocol,
        navigateToStatus: @escaping () -> Void,
        navigateToNotifications: @escaping () -> Void,
        navigateToMediaQuality: @escaping () -> Void
    ) {
        self.accountUseCase = accountUseCase
        self.chatUseCase = chatUseCase
        self.chatPresenceUseCase = chatPresenceUseCase
        self.navigateToStatus = navigateToStatus
        self.navigateToNotifications = navigateToNotifications
        self.navigateToMediaQuality = navigateToMediaQuality
    }
    
    func fetchData() async {
        let isRichLinkPreviewEnabled = await accountUseCase.isRichLinkPreviewEnabled()
        richLinksPreviewEnabled = isRichLinkPreviewEnabled
        self.isRichLinkPreviewEnabled = isRichLinkPreviewEnabled
        
        onlineStatusString = chatPresenceUseCase.onlineStatus().localizedIdentifier
        monitorOnChatOnlineStatusUpdate()
    }

    private func monitorOnChatOnlineStatusUpdate() {
        let onlineStatusUpdate = chatPresenceUseCase.monitorOnChatOnlineStatusUpdate()
        Task { [weak self] in
            for await onlineStatus in onlineStatusUpdate {
                guard !onlineStatus.inProgress,
                      onlineStatus.userHandle == self?.chatUseCase
                    .myUserHandle() else { return }
                self?.onlineStatusString = onlineStatus.status.localizedIdentifier
            }
        }
    }
    
    func toggleEnableRichLinkPreview(isCurrentlyEnabled: Bool) {
        accountUseCase.enableRichLinkPreview(!isCurrentlyEnabled)
        isRichLinkPreviewEnabled = !isCurrentlyEnabled
        richLinksPreviewEnabled = !isCurrentlyEnabled
    }
    
    func statusViewTapped() {
        navigateToStatus()
    }
    
    func notificationsViewTapped() {
        navigateToNotifications()
    }
    
    func mediaQualityViewTapped() {
        navigateToMediaQuality()
    }
}
