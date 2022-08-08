import Foundation
@testable import MEGA
import MEGADomain

extension AccountDetailsEntity {
    init() {
        self.init(
            storageUsed: 0,
            versionsStorageUsed: 0,
            storageMax: 0,
            transferOwnUsed: 0,
            transferMax: 0,
            proLevel: .free,
            proExpiration: 0,
            subscriptionStatus: .none,
            subscriptionRenewTime: 0,
            subscriptionMethod: nil,
            subscriptionCycle: nil,
            numberUsageItems: 0)
    }
}
