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
    var suggestedPlanName: AvailablePlanName { get }
}

@objc final class OverDiskQuotaInformation: NSObject, OverDiskQuotaInfomationType {
    let email: Email
    let deadline: Deadline
    let warningDates: WarningDates
    let numberOfFilesOnCloud: FileCount
    let cloudStorage: Storage
    let suggestedPlanName: AvailablePlanName

    init(email: Email,
         deadline: Deadline,
         warningDates: WarningDates,
         numberOfFilesOnCloud: FileCount,
         cloudStorage: Storage,
         suggestedPlanName: AvailablePlanName) {
        self.email = email
        self.deadline = deadline
        self.warningDates = warningDates
        self.numberOfFilesOnCloud = numberOfFilesOnCloud
        self.cloudStorage = cloudStorage
        self.suggestedPlanName = suggestedPlanName
    }
}

@objc final class OverDiskQuotaService: NSObject {

    // MARK: - Static

    private static var shared: OverDiskQuotaService = OverDiskQuotaService()

    // MARK: - OverDiskQuotaService

    private static func getUserData(with api: MEGASdk) {
        api.getUserData(with: MEGAGenericRequestDelegate(completion: { [shared] (request, error) in
            shared.updateUserData(withSDK: api)
        }))
    }

    private static func getMEGAPlans(with api: MEGASdk) {
        MEGAPlanService.loadMegaPlans(with: api) { [shared] plans in
            shared.updateMEGAPlans(plans)
        }
    }

    @objc static func prepareOverDiskQuotaInformation(withSDK api: MEGASdk,
                                                      callback: @escaping (OverDiskQuotaInfomationType) -> Void) {
        shared.informationReadyCallback = callback
        getUserData(with: api)
        getMEGAPlans(with: api)
    }

    @objc static func prepareOverDiskQuotaInformation(withUserCloudStorageUsed storageUsed: NSNumber) {
        shared.updateUserStroage(storageUsed)
    }

    // MARK: - Instance

    fileprivate lazy var internalStore = OverDiskQuotaStore()

    private var informationReadyCallback: ((OverDiskQuotaInfomationType) -> Void)?

    // MARK: - Lifecycle

    private override init() {}

    // MARK: - Instance Method

    // MARK: - Capture ODQ information

    private func updateMEGAPlans(_ plans: [MEGAPlan]) {
        internalStore.availablePlans = plans
        noticeListenerIfOverDiskQuotaInformationReady()
    }

    private func updateUserStroage(_ storage: NSNumber) {
        internalStore.cloudStorageTaking = storage
        noticeListenerIfOverDiskQuotaInformationReady()
    }

    private func updateUserData(withSDK api: MEGASdk) {
        internalStore.email = api.myEmail
        internalStore.deadline = api.overquotaDeadlineDate()
        internalStore.warningDates = api.overquotaWarningDateList()
        internalStore.numberOfFilesOnCloud = api.totalNodes
        noticeListenerIfOverDiskQuotaInformationReady()
    }

    private func noticeListenerIfOverDiskQuotaInformationReady() {
        guard let internalOverDiskQuotaStore = validated(internalStore) else { return }
        informationReadyCallback?(internalOverDiskQuotaStore)
        informationReadyCallback = nil
    }

    // MARK: - Validate internal store

    private func suggestMinimumPlan(ofStorage minimumStorage: NSNumber, availablePlans: [MEGAPlan]) -> [MEGAPlan] {
        let query = { (storage: Int64) -> QueryConstraint in
            return QueryConstraint { plans in
                QueryConstraint.minimumPrice.run(
                    QueryConstraint.storagGreaterThan(storage).run(plans))
            }
        }
        return query(minimumStorage.int64Value).run(availablePlans)
    }

    fileprivate func validated(_ internalStore: OverDiskQuotaStore) -> OverDiskQuotaInformation? {
        guard let email = internalStore.email else { return nil }
        guard let deadline = internalStore.deadline else { return nil }
        guard let warningDate = internalStore.warningDates else { return nil }
        guard let numberOfFiles = internalStore.numberOfFilesOnCloud else { return nil }
        guard let cloudStorage = internalStore.cloudStorageTaking else { return nil }
        guard let availablePlans = internalStore.availablePlans,
            let minimumPlan = suggestMinimumPlan(ofStorage: cloudStorage, availablePlans: availablePlans).first
            else { return nil }

        return OverDiskQuotaInformation(email: email,
                                        deadline: deadline,
                                        warningDates: warningDate,
                                        numberOfFilesOnCloud: numberOfFiles,
                                        cloudStorage: cloudStorage,
                                        suggestedPlanName: minimumPlan.readableName)
    }

    // MARK: - Internal Store

    typealias Email = String
    typealias Deadline = Date
    typealias WarningDates = [Date]
    typealias FileCount = UInt
    typealias Storage = NSNumber
    typealias AvailablePlans = [MEGAPlan]

    fileprivate struct OverDiskQuotaStore {
        var email: Email?
        var deadline: Deadline?
        var warningDates: WarningDates?
        var numberOfFilesOnCloud: FileCount?
        var cloudStorageTaking: Storage?
        var availablePlans: AvailablePlans?
    }
}
