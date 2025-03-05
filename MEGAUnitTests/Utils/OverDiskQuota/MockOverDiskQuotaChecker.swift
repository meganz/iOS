@testable import MEGA

struct MockOverDiskQuotaChecker: OverDiskQuotaChecking {
    private let isPaywalled: Bool
    
    nonisolated init(isPaywalled: Bool = false) {
        self.isPaywalled = isPaywalled
    }
    
    func showOverDiskQuotaIfNeeded() -> Bool {
        isPaywalled
    }
}
