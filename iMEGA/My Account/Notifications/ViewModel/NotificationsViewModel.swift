import Foundation
import MEGADesignToken
import MEGAPresentation
import Notifications

@objc enum NotificationSection: Int {
    case promos = 0, userAlerts
}

@objc final class NotificationsViewModel: NSObject {
    private let featureFlagProvider: any FeatureFlagProviderProtocol
    private(set) var promoList: [NotificationItem] = []
    
    init(featureFlagProvider: some FeatureFlagProviderProtocol) {
        self.featureFlagProvider = featureFlagProvider
        super.init()
        
        fetchPromoList()
    }
    
    // MARK: - Feature flag
    @objc var isPromoEnabled: Bool {
        featureFlagProvider.isFeatureFlagEnabled(for: .notificationCenter)
    }
    
    // MARK: - Sections
    @objc var numberOfSections: Int {
        // With Promos - Section 0: Promos, Section 1: User Alerts
        // No Promos - Section 0: User Alerts
        isPromoEnabled ? 2 : 1
    }
    
    @objc var promoSectionNumberOfRows: Int {
        promoList.count
    }
    
    func fetchPromoList() {
        // Promo list fetching logic
    }
}
