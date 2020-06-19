import Foundation

@objc final class OverDiskQuotaCommand: NSObject {

    private var completionAction: (OverDiskQuotaInfomationType) -> Void

    private var task: OverDiskQuotaQueryTask?

    var storageUsed: NSNumber?

    @objc init(storageUsed: NSNumber?, completionAction: @escaping (OverDiskQuotaInfomationType) -> Void) {
        self.completionAction = completionAction
        self.storageUsed = storageUsed
    }

    func execute(with api: MEGASdk, completion: @escaping (OverDiskQuotaCommand) -> Void) {
        guard let storageUsed = storageUsed else {
            assertionFailure("Do not schedule a command to execute while stroage used is still nil.")
            return
        }

        self.task = OverDiskQuotaQueryTask()
        task?.updatedStorageStore(with: storageUsed)
        task?.start(with: api) { [weak self] overDiskQuotaInformation in
            guard let self = self else { return }
            self.completionAction(overDiskQuotaInformation)
            completion(self)
        }
    }
}

fileprivate final class OverDiskQuotaQueryTask {

    // MARK: - Errors

    fileprivate enum DataObtainingError: Error {
        case invalidUserEmail
    }

    private var errors: Set<DataObtainingError> = []

    // MARK: - Over Disk Quota Data Store

    private var userDataStore: OverDiskQuotaUserData?

    private var storageUsedStore: OverDiskQuotaStorageUsed?

    private var availablePlansStore: OverDiskQuotaPlans?

    // MARK: - Lifecycle

    init() { }

    // MARK: - Methods

    func start(with api: MEGASdk, completion: @escaping (OverDiskQuotaInfomationType) -> Void) {

        if let userDataStore = userDataStore,
            let storageUsedStore = storageUsedStore,
            let availablePlansStore = availablePlansStore {
            let overDiskQuotaData = extractedInformation(userDataStore: userDataStore,
                                                        storageStore: storageUsedStore,
                                                        planStore: availablePlansStore)
            completion(overDiskQuotaData)
            return
        }

        if shouldFetchUserData(userDataStore, errors: errors) {
            api.getUserData(with: MEGAGenericRequestDelegate(completion: { [weak self] (_, _) in
                guard let self = self else { return }
                switch self.updatedUserData(with: api) {
                case .failure(let error): self.errors.insert(error)
                case .success(let userData):
                    self.userDataStore = userData
                    self.start(with: api, completion: completion)
                }
            }))
            return
        }

        if shouldFetchMEGAPlans(availablePlansStore, errors: errors) {
            MEGAPlanService.shared.send(MEGAPlanCommand { [weak self] plans in
                guard let self = self else { return }
                self.availablePlansStore = OverDiskQuotaPlans(availablePlans: plans)
                self.start(with: api, completion: completion)
            })
        }
    }

    func updatedStorageStore(with storage: NSNumber) {
        self.storageUsedStore = OverDiskQuotaStorageUsed(cloudStorageTaking: storage)
    }

    // MARK: - Privates

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
