import Foundation

@objc protocol OverDiskQuotaInfomationType {
    typealias Email = String
    typealias Deadline = Date
    typealias WarningDates = [Date]
    typealias FileCount = UInt
    typealias Storage = NSNumber
    typealias AvailablePlanName = String

    var email: Email { get }
    var deadline: Deadline { get }
    var warningDates: WarningDates { get }
    var numberOfFilesOnCloud: FileCount { get }
    var cloudStorage: Storage { get }
    var availablePlan: AvailablePlanName { get }
}

@objc final class OverDiskQuotaInformation: NSObject, OverDiskQuotaInfomationType {
    let email: Email
    let deadline: Deadline
    let warningDates: WarningDates
    let numberOfFilesOnCloud: FileCount
    let cloudStorage: Storage
    let availablePlan: AvailablePlanName

    init(email: Email,
         deadline: Deadline,
         warningDates: WarningDates,
         numberOfFilesOnCloud: FileCount,
         cloudStorage: Storage,
         availablePlans: AvailablePlanName) {
        self.email = email
        self.deadline = deadline
        self.warningDates = warningDates
        self.numberOfFilesOnCloud = numberOfFilesOnCloud
        self.cloudStorage = cloudStorage
        self.availablePlan = availablePlans
    }
}

@objc final class OverDiskQuotaServiceImpl: NSObject {

    // MARK: - Static

    private static var shared: OverDiskQuotaServiceImpl = OverDiskQuotaServiceImpl()

    // MARK: - OverDiskQuotaService

    private static func getUserData(_ api: MEGASdk, retries: Int) {
        let userDataDelegate = GetUserDataMEGARequestDelegate()

        userDataDelegate.callback = { [shared] delegateReturnedAPI, error in
            var retainedDelegate: GetUserDataMEGARequestDelegate? = userDataDelegate
            defer { retainedDelegate = nil }

            guard error == .apiOk else {
                if retries >= 0 { getUserData(api, retries: retries - 1) }
                return
            }
            shared.updateUserData(withSDK: delegateReturnedAPI)
        }
        api.getUserData(with: userDataDelegate)
    }

    private static func getPricing(_ api: MEGASdk, retries: Int) {
        let getPricingDelegate = GetPricingMEGARequestDelegate()

        getPricingDelegate.callback = { [shared] delegateReturnedAPI, pricing, error in
            var retainedDelegate: GetPricingMEGARequestDelegate? = getPricingDelegate
            defer { retainedDelegate = nil }

            guard error == .apiOk else {
                if retries >= 0 { getPricing(api, retries: retries - 1) }
                return
            }
            shared.updatePricing(pricing, withSDK: delegateReturnedAPI)
        }
        api.getPricingWith(getPricingDelegate)
    }

    @objc static func prepareOverDiskQuotaInformation(withSDK api: MEGASdk,
                                                      callback: @escaping (OverDiskQuotaInfomationType) -> Void) {
        shared.informationReadyCallback = callback
        getUserData(api, retries: 3)
        getPricing(api, retries: 3)
    }

    // MARK: - Instance

    fileprivate lazy var internalStore = OverDiskQuotaStore()

    private var informationReadyCallback: ((OverDiskQuotaInfomationType) -> Void)?

    private var pricing: MEGAPricing?

    // MARK: - Lifecycle

    private override init() {}

    // MARK: - Instance Method

    fileprivate func updatePricing(_ pricing: MEGAPricing, withSDK api: MEGASdk) {
        internalStore.availablePlans = (0..<pricing.products).map { productIndex in
            (pricing.storageGB(atProductIndex: productIndex),
            pricing.description(atProductIndex: productIndex))
        }

        if let validStore = validated(internalStore) {
            informationReadyCallback?(validStore)
        }
    }

    fileprivate func updateUserData(withSDK api: MEGASdk) {
        internalStore.email = api.myEmail
        internalStore.deadline = api.overquotaDeadlineDate()
        internalStore.warningDates = api.overquotaWarningDateList()
        internalStore.numberOfFilesOnCloud = api.totalNodes
        internalStore.cloudStorage = api.mnz_accountDetails?.storageUsed

        if let validStore = validated(internalStore) {
            informationReadyCallback?(validStore)
        }
    }

    fileprivate func validated(_ internalStore: OverDiskQuotaStore) -> OverDiskQuotaInformation? {
        guard let email = internalStore.email else { return nil }
        guard let deadline = internalStore.deadline else { return nil }
        guard let warningDate = internalStore.warningDates else { return nil }
        guard let numberOfFiles = internalStore.numberOfFilesOnCloud else { return nil }
        guard let cloudStorage = internalStore.cloudStorage else { return nil }
        guard let availablePlans = internalStore.availablePlans else { return nil }

        guard let lowestPlan = (availablePlans.first { (storage, planName) -> Bool in
            (Double(storage) >= cloudStorage.doubleValue / 1024 / 1024 / 1024)
        }) else { return nil }

        return OverDiskQuotaInformation(email: email,
                                        deadline: deadline,
                                        warningDates: warningDate,
                                        numberOfFilesOnCloud: numberOfFiles,
                                        cloudStorage: cloudStorage,
                                        availablePlans: lowestPlan.1)
    }

    // MARK: - Internal Store

    typealias Email = String
    typealias Deadline = Date
    typealias WarningDates = [Date]
    typealias FileCount = UInt
    typealias Storage = NSNumber
    typealias AvailablePlans = [(Int, String)]

    fileprivate struct OverDiskQuotaStore {
        var email: Email?
        var deadline: Deadline?
        var warningDates: WarningDates?
        var numberOfFilesOnCloud: FileCount?
        var cloudStorage: Storage?
        var availablePlans: AvailablePlans?
    }

    // MARK: - SDK MEGARequest Delegate

    fileprivate final class GetUserDataMEGARequestDelegate: NSObject, MEGARequestDelegate {

        var callback: ((MEGASdk, MEGAErrorType) -> Void)?

        func onRequestFinish(_ api: MEGASdk, request: MEGARequest, error: MEGAError) {
            callback?(api, error.type)
        }
    }

    fileprivate final class GetPricingMEGARequestDelegate: NSObject, MEGARequestDelegate {

        var callback: ((MEGASdk, MEGAPricing, MEGAErrorType) -> Void)?

        func onRequestFinish(_ api: MEGASdk, request: MEGARequest, error: MEGAError) {
            callback?(api, request.pricing, error.type)
        }
    }
}
