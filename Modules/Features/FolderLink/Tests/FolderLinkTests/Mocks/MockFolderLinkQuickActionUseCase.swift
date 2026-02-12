import FolderLink
import MEGADomain

final class MockFolderLinkQuickActionUseCase: FolderLinkQuickActionUseCaseProtocol {
    func shouldEnableQuickActions(for nodeHandle: HandleEntity) -> Bool {
        false
    }
}

