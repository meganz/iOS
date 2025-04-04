import MEGAAppSDKRepo
import MEGASdk

public final class MockMEGAAccountDetails: MEGAAccountDetails, @unchecked Sendable {
    private var _storageUsed: Int64
    private var _versionsStorageUsed: Int64
    private var _storageMax: Int64
    private var _transferUsed: Int64
    private var _transferMax: Int64
    private var _type: MEGAAccountType
    private var _proExpiration: Int
    private var _subscriptionStatus: MEGASubscriptionStatus
    private var _subscriptionRenewTime: Int
    private var _subscriptionMethod: String?
    private var _subscriptionCycle: String
    private var _numberUsageItems: Int
    private var _nodeSizes: [UInt64: Int64]
    
    public init(storageUsed: Int64 = 0,
                versionsStorageUsed: Int64 = 0,
                storageMax: Int64 = 0,
                transferUsed: Int64 = 0,
                transferMax: Int64 = 0,
                type: MEGAAccountType = .free,
                proExpiration: Int = 0,
                subscriptionStatus: MEGASubscriptionStatus = .none,
                subscriptionRenewTime: Int = 0,
                subscriptionMethod: String? = nil,
                subscriptionCycle: String = "",
                numberUsageItems: Int = 0,
                nodeSizes: [UInt64: Int64] = [:]
    ) {
        _storageUsed = storageUsed
        _versionsStorageUsed = versionsStorageUsed
        _storageMax = storageMax
        _transferUsed = transferUsed
        _transferMax = transferMax
        _type = type
        _proExpiration = proExpiration
        _subscriptionStatus = subscriptionStatus
        _subscriptionRenewTime = subscriptionRenewTime
        _subscriptionMethod = subscriptionMethod
        _subscriptionCycle = subscriptionCycle
        _numberUsageItems = numberUsageItems
        _nodeSizes = nodeSizes
    }
    
    public override var storageUsed: Int64 { _storageUsed }
    public override var versionStorageUsed: Int64 { _versionsStorageUsed }
    public override var storageMax: Int64 { _storageMax }
    public override var transferUsed: Int64 { _transferUsed }
    public override var transferMax: Int64 { _transferMax }
    public override var type: MEGAAccountType { _type }
    public override var proExpiration: Int { _proExpiration }
    public override var subscriptionStatus: MEGASubscriptionStatus { _subscriptionStatus }
    public override var subscriptionRenewTime: Int { _subscriptionRenewTime }
    public override var subscriptionMethod: String? { _subscriptionMethod }
    public override var subscriptionCycle: String { _subscriptionCycle }
    public override var numberUsageItems: Int { _numberUsageItems }
    public override func storageUsed(forHandle handle: UInt64) -> Int64 {
        _nodeSizes[handle] ?? 0
    }
}
