import FolderLink
import MEGADomain

final class MockFolderLinkQuickActionUseCase: FolderLinkQuickActionUseCaseProtocol {
    private let quickActionsEnabled: Bool

    init(quickActionsEnabled: Bool = false) {
        self.quickActionsEnabled = quickActionsEnabled
    }

    func shouldEnableQuickActions(for nodeHandle: HandleEntity) -> Bool {
        quickActionsEnabled
    }
}

