import FolderLink

final class MockFolderLinkLogoutPolicy: FolderLinkLogoutPolicyProtocol {
    private let shouldLogout: Bool
    
    init(shouldLogout: Bool = true) {
        self.shouldLogout = shouldLogout
    }
    
    func shouldLogoutUponFolderLinkDismiss() -> Bool {
        shouldLogout
    }
}
