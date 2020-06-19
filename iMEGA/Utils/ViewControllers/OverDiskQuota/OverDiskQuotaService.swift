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
    var suggestedPlanName: AvailablePlanName? { get }
}

@objc final class OverDiskQuotaInformation: NSObject, OverDiskQuotaInfomationType {
    let email: Email
    let deadline: Deadline
    let warningDates: WarningDates
    let numberOfFilesOnCloud: FileCount
    let cloudStorage: Storage
    let suggestedPlanName: AvailablePlanName?

    init(email: Email,
         deadline: Deadline,
         warningDates: WarningDates,
         numberOfFilesOnCloud: FileCount,
         cloudStorage: Storage,
         suggestedPlanName: AvailablePlanName?) {
        self.email = email
        self.deadline = deadline
        self.warningDates = warningDates
        self.numberOfFilesOnCloud = numberOfFilesOnCloud
        self.cloudStorage = cloudStorage
        self.suggestedPlanName = suggestedPlanName
    }
}

@objc final class OverDiskQuotaCommand: NSObject {

    private(set) var completionAction: (OverDiskQuotaInfomationType) -> Void
    private(set) var api: MEGASdk

    @objc init(api: MEGASdk, completionAction: @escaping (OverDiskQuotaInfomationType) -> Void) {
        self.completionAction = completionAction
        self.api = api
    }

    fileprivate func execute(userDataStore: OverDiskQuotaUserData,
                             storageStore: OverDiskQuotaStorageUsed,
                             planStore: OverDiskQuotaPlans) {
        completionAction(
            extractedInformation(userDataStore: userDataStore, storageStore: storageStore, planStore: planStore))
    }

    private func extractedInformation(userDataStore: OverDiskQuotaUserData,
                                      storageStore: OverDiskQuotaStorageUsed,
                                      planStore: OverDiskQuotaPlans) -> OverDiskQuotaInformation {

        let minimumPlan = MEGAPlanAdviser.suggestMinimumPlan(ofStorage: storageStore.cloudStorageTaking,
                                                             availablePlans: planStore.availablePlans).first

        return OverDiskQuotaInformation(email: userDataStore.email,
                                        deadline: userDataStore.deadline,
                                        warningDates: userDataStore.warningDates,
                                        numberOfFilesOnCloud: userDataStore.numberOfFilesOnCloud,
                                        cloudStorage: storageStore.cloudStorageTaking,
                                        suggestedPlanName: minimumPlan?.readableName)
    }
}

@objc final class OverDiskQuotaService: NSObject {

    // MARK: - Static

    @objc(sharedService) static var shared: OverDiskQuotaService = OverDiskQuotaService()

    private static var cloudStorageObtainingAction: (() -> NSNumber)?

    // MARK: - OverDiskQuotaService

    fileprivate enum DataObtainingError: Error {
        case invalidUserEmail
    }

    // MARK: - Instance

    private var userDataStore: OverDiskQuotaUserData?

    private var storageUsedStore: OverDiskQuotaStorageUsed?

    private var availablePlansStore: OverDiskQuotaPlans?

    private var pendingCommand: OverDiskQuotaCommand?

    private var errors: Set<DataObtainingError> = []

    // MARK: - Lifecycle

    private override init() {}

    // MARK: - Instance Method

    @objc func invalidate() {
        userDataStore = nil
        storageUsedStore = nil
        availablePlansStore = nil
        pendingCommand = nil
        errors = []
    }

    @objc func setUserStorageUsed(_ stroageUsed: NSNumber) {
        storageUsedStore = updatedStorageStore(with: stroageUsed)
        if let pendingCommand = pendingCommand {
            prepareContextForExecutingCommand(with: pendingCommand.api)
        }
    }

    @objc func send(_ command: OverDiskQuotaCommand) {
        pendingCommand = command
        prepareContextForExecutingCommand(with: command.api)
    }

    // MARK: - Capture ODQ information

    private func prepareContextForExecutingCommand(with api: MEGASdk) {
        if let userDataStore = userDataStore, let storageUsedStore = storageUsedStore, let availablePlansStore = availablePlansStore {
            pendingCommand?.execute(userDataStore: userDataStore, storageStore: storageUsedStore, planStore: availablePlansStore)
            pendingCommand = nil
            errors = []
            return
        }

        if shouldFetchUserData(userDataStore, errors: errors) {
            api.getUserData(with: MEGAGenericRequestDelegate(completion: { [weak self] (_, _) in
                guard let self = self else { return }
                switch self.updatedUserData(with: api) {
                case .failure(let error): self.errors.insert(error)
                case .success(let userData):
                    self.userDataStore = userData
                    self.prepareContextForExecutingCommand(with: api)
                }
            }))
            return
        }

        if shouldFetchMEGAPlans(availablePlansStore, errors: errors) {
            MEGAPlanService.loadMegaPlans(with: api) { [weak self] plans in
                guard let self = self else { return }
                self.availablePlansStore = self.updatedMEGAPlans(plans)
                self.prepareContextForExecutingCommand(with: api)
            }
            return
        }
    }

    private func shouldFetchUserData(_ userDataStore: OverDiskQuotaUserData?, errors: Set<DataObtainingError>) -> Bool {
        if userDataStore != nil { return false }
        return !errors.contains(.invalidUserEmail)
    }

    private func shouldFetchMEGAPlans(_ plansStore: OverDiskQuotaPlans?, errors: Set<DataObtainingError>) -> Bool {
        if plansStore != nil { return false }
        return true
    }

    private func updatedUserData(with api: MEGASdk) -> Result<OverDiskQuotaUserData, DataObtainingError> {
        guard let email = api.myEmail else {
            return .failure(.invalidUserEmail)
        }

        return .success(OverDiskQuotaUserData(email: email,
                                              deadline: api.overquotaDeadlineDate(),
                                              warningDates: api.overquotaWarningDateList(),
                                              numberOfFilesOnCloud: api.totalNodes))
    }

    private func updatedMEGAPlans(_ plans: [MEGAPlan]) -> OverDiskQuotaPlans {
        return OverDiskQuotaPlans(availablePlans: plans)
    }

    private func updatedStorageStore(with storage: NSNumber) -> OverDiskQuotaStorageUsed {
        return OverDiskQuotaStorageUsed(cloudStorageTaking: storage)
    }
}

fileprivate struct OverDiskQuotaUserData {
    typealias Email = String
    typealias Deadline = Date
    typealias WarningDates = [Date]
    typealias FileCount = UInt

    var email: Email
    var deadline: Deadline
    var warningDates: WarningDates
    var numberOfFilesOnCloud: FileCount
}

fileprivate struct OverDiskQuotaPlans {
    typealias AvailablePlans = [MEGAPlan]
    var availablePlans: AvailablePlans
}

fileprivate struct OverDiskQuotaStorageUsed {
    typealias StorageUsedInBytes = NSNumber
    var cloudStorageTaking: StorageUsedInBytes
}
