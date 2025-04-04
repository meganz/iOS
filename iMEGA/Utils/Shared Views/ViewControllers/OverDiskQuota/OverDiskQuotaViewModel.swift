import Combine
import MEGAAppPresentation
import MEGAAppSDKRepo
import MEGADomain

enum OverDiskQuotaViewAction: ActionType, Equatable {
    case onViewDidLoad
    case didTapUpgradeButton
    case didTapDismissButton
}

final class OverDiskQuotaViewModel: NSObject, ViewModelType {
    enum Command: CommandType, Equatable {}
    var invokeCommand: ((Command) -> Void)?
    
    private let router: (any OverDiskQuotaViewRouting)?
    private let notificationCenter: NotificationCenter
    private var subscriptions = Set<AnyCancellable>()
    
    init(
        router: (some OverDiskQuotaViewRouting)?,
        notificationCenter: NotificationCenter = .default
    ) {
        self.router = router
        self.notificationCenter = notificationCenter
    }
    
    // MARK: - Dispatch action
    func dispatch(_ action: OverDiskQuotaViewAction) {
        switch action {
        case .onViewDidLoad:
            setupSubscriptions()
        case .didTapUpgradeButton:
            router?.showUpgradePlanPage()
        case .didTapDismissButton:
            router?.dismiss()
        }
    }
    
    private func setupSubscriptions() {
        notificationCenter
            .publisher(for: .accountDidPurchasedPlan)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                Task { @MainActor [weak self] in
                    // Added delay to prevent abrupt dismissal of ODQ page while
                    // Upgrade plan page is being dismissed
                    try await Task.sleep(nanoseconds: 1_000_000_000)
                    self?.router?.dismiss()
                }
            }
            .store(in: &subscriptions)
    }
}
