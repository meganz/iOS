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

@objc final class OverDiskQuotaService: NSObject {

    // MARK: - Static

    private static var shared: OverDiskQuotaService = OverDiskQuotaService()

    // MARK: - OverDiskQuotaService

    private static func getUserData(_ api: MEGASdk) {
        api.getUserData(with: MEGAGenericRequestDelegate(completion: { [shared] (request, error) in
            shared.updateUserData(withSDK: api)
        }))
    }

    @objc static func prepareOverDiskQuotaInformation(withSDK api: MEGASdk,
                                                      callback: @escaping (OverDiskQuotaInfomationType) -> Void) {
        shared.informationReadyCallback = callback
        getUserData(api)
    }

    // MARK: - Instance

    fileprivate lazy var internalStore = OverDiskQuotaStore()

    private var informationReadyCallback: ((OverDiskQuotaInfomationType) -> Void)?

    // MARK: - Lifecycle

    private override init() {}

    // MARK: - Instance Method

    private func updateUserData(withSDK api: MEGASdk) {
        internalStore.email = api.myEmail
        internalStore.deadline = api.overquotaDeadlineDate()
        internalStore.warningDates = api.overquotaWarningDateList()
        internalStore.numberOfFilesOnCloud = api.totalNodes
        internalStore.cloudStorage = api.mnz_accountDetails?.storageUsed

        guard let cloudSpaceTaking = internalStore.cloudStorage else { return }

        findMinimumPriceMEGAPLan(withAtLeastStorage: cloudSpaceTaking.intValue / 1024 / 1024 / 1024, withSDK: api) { [weak self] advice in
            switch advice {
            case .noSatisfied: break
            case .upgradeTo(let plan):
                guard let self = self else { return }
                self.internalStore.availablePlans = plan
                if let validatedOverDiskQuotaInfomation = self.validated(self.internalStore) {
                    self.informationReadyCallback?(validatedOverDiskQuotaInfomation)
                    self.informationReadyCallback = nil
                }
            }
        }
    }

    private func findMinimumPriceMEGAPLan(withAtLeastStorage storage: Int,
                                          withSDK api: MEGASdk,
                                          completion: @escaping (MEGAPlanUpgradeAdvice) -> Void) {
        let query = QueryConstraint { plans in
            QueryConstraint.minimumPrice.run(
                QueryConstraint.storagGreaterThan(storage).run(plans))
        }

        MEGAPlanAdviser.suggestPlan(constraints: query, api: api) { advice in
            completion(advice)
        }
    }

    fileprivate func validated(_ internalStore: OverDiskQuotaStore) -> OverDiskQuotaInformation? {
        guard let email = internalStore.email else { return nil }
        guard let deadline = internalStore.deadline else { return nil }
        guard let warningDate = internalStore.warningDates else { return nil }
        guard let numberOfFiles = internalStore.numberOfFilesOnCloud else { return nil }
        guard let cloudStorage = internalStore.cloudStorage else { return nil }
        guard let availablePlans = internalStore.availablePlans else { return nil }

        return OverDiskQuotaInformation(email: email,
                                        deadline: deadline,
                                        warningDates: warningDate,
                                        numberOfFilesOnCloud: numberOfFiles,
                                        cloudStorage: cloudStorage,
                                        availablePlans: availablePlans.description)
    }

    // MARK: - Internal Store

    typealias Email = String
    typealias Deadline = Date
    typealias WarningDates = [Date]
    typealias FileCount = UInt
    typealias Storage = NSNumber
    typealias AvailablePlan = MEGAPlan

    fileprivate struct OverDiskQuotaStore {
        var email: Email?
        var deadline: Deadline?
        var warningDates: WarningDates?
        var numberOfFilesOnCloud: FileCount?
        var cloudStorage: Storage?
        var availablePlans: AvailablePlan?
    }
}
