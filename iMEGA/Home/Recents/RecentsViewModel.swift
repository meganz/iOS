import MEGADomain
import MEGAFoundation

@MainActor
@objc final class RecentsViewModel: NSObject, ObservableObject {
    private let recentNodesUseCase: any RecentNodesUseCaseProtocol
    private var monitorRecentActionsUpdatesTask: Task<Void, Never>? {
        didSet {
            oldValue?.cancel()
        }
    }
    private let recentsViewReloadDebouncer = Debouncer(delay: 0.5)
    
    var recentActionsUpdates: (() -> Void)?
    
    init(recentNodesUseCase: any RecentNodesUseCaseProtocol) {
        self.recentNodesUseCase = recentNodesUseCase
    }
    
    deinit {
        monitorRecentActionsUpdatesTask = nil
    }
    
    func onViewDidLoad() {
        startMonitoringRecentActionsUpdates()
    }
    
    private func startMonitoringRecentActionsUpdates() {
        monitorRecentActionsUpdatesTask = Task { [weak self, recentNodesUseCase] in
            for await _ in recentNodesUseCase.recentActionBucketsUpdates {
                guard !Task.isCancelled else { break }
                self?.handleRecentActionUpdates()
            }
        }
    }
    
    private func handleRecentActionUpdates() {
        recentsViewReloadDebouncer.start { [weak self] in
            self?.recentActionsUpdates?()
        }
    }
}
