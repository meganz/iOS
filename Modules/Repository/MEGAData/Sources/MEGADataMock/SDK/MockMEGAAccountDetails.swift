import MEGASdk
import MEGAData

public final class MockMEGAAccountDetails: MEGAAccountDetails {
    private var _storageUsed: NSNumber
    private var _versionsStorageUsed: Int64
    private var _storageMax: NSNumber
    private var _transferOwnUsed: NSNumber
    private var _transferMax: NSNumber
    private var _type: MEGAAccountType
    private var _proExpiration: Int
    private var _subscriptionStatus: MEGASubscriptionStatus
    private var _subscriptionRenewTime: Int
    private var _subscriptionMethod: String?
    private var _subscriptionCycle: String
    private var _numberUsageItems: Int
    
    public init(storageUsed: NSNumber = 0,
                versionsStorageUsed: Int64 = 0,
                storageMax: NSNumber = 0,
                transferOwnUsed: NSNumber = 0,
                transferMax: NSNumber = 0,
                type: MEGAAccountType = .free,
                proExpiration: Int = 0,
                subscriptionStatus: MEGASubscriptionStatus = .none,
                subscriptionRenewTime: Int = 0,
                subscriptionMethod: String? = nil,
                subscriptionCycle: String = "",
                numberUsageItems: Int = 0) {
        _storageUsed = storageUsed
        _versionsStorageUsed = versionsStorageUsed
        _storageMax = storageMax
        _transferOwnUsed = transferOwnUsed
        _transferMax = transferMax
        _type = type
        _proExpiration = proExpiration
        _subscriptionStatus = subscriptionStatus
        _subscriptionRenewTime = subscriptionRenewTime
        _subscriptionMethod = subscriptionMethod
        _subscriptionCycle = subscriptionCycle
        _numberUsageItems = numberUsageItems
    }
    
    public override var storageUsed: NSNumber { _storageUsed }
    public override var versionStorageUsed: Int64 { _versionsStorageUsed }
    public override var storageMax: NSNumber { _storageMax }
    public override var transferOwnUsed: NSNumber { _transferOwnUsed }
    public override var transferMax: NSNumber { _transferMax }
    public override var type: MEGAAccountType { _type }
    public override var proExpiration: Int { _proExpiration }
    public override var subscriptionStatus: MEGASubscriptionStatus { _subscriptionStatus }
    public override var subscriptionRenewTime: Int { _subscriptionRenewTime }
    public override var subscriptionMethod: String? { _subscriptionMethod }
    public override var subscriptionCycle: String { _subscriptionCycle }
    public override var numberUsageItems: Int { _numberUsageItems }
}
