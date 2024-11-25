import AsyncAlgorithms
import Foundation
import MEGADomain

@MainActor
final class NodeTagsCellViewModel: ObservableObject, Sendable {
    private let node: NodeEntity
    private let accountUseCase: any AccountUseCaseProtocol
    private let notificationCenter: NotificationCenter
    private let isSelectionAvailable: Bool = false

    /// Enum type to represent the status of the "Pro only" badge display
    /// Important notes::
    ///  - "Pro only" badge is shown to free user and is NOT shown to users with expired business or expired pro flexi plan
    enum ProBadgeState {
        case notDetermined, show, hide
        var isLoading: Bool { self == .notDetermined }
    }
    
    @Published private(set) var state: ProBadgeState
    
    var isLoading: Bool {
        state.isLoading
    }
    
    var showsProTag: Bool {
        state == .show
    }
    
    // Checks if the user has non expired subscription.
    var hasValidSubscription: Bool { accountUseCase.hasValidSubscription }
    var tags: [String] { node.tags }

    private(set) lazy var nodeTagsViewModel = {
        NodeTagsViewModel(
            tagViewModels: node.tags.map {
                NodeTagViewModel(tag: $0, isSelectionEnabled: isSelectionAvailable, isSelected: isSelectionAvailable)
            }
        )
    }()

    init(node: NodeEntity, accountUseCase: some AccountUseCaseProtocol, notificationCenter: NotificationCenter) {
        self.node = node
        self.accountUseCase = accountUseCase
        self.notificationCenter = notificationCenter
        if accountUseCase.currentAccountDetails != nil {
            state = accountUseCase.isFreeTierUser ? .show : .hide
        } else {
            state = .notDetermined
        }
    }
    
    func startMonitoringAccountDetails() async {
        let values = merge(
            notificationCenter.notifications(named: .accountDidFinishFetchAccountDetails).map { [accountUseCase] _ -> ProBadgeState in accountUseCase.isFreeTierUser ? .show : .hide },
            notificationCenter.notifications(named: .refreshAccountDetails).map { _ -> ProBadgeState in .notDetermined }
        )
        for await state in values {
            self.state = state
        }
    }
}
