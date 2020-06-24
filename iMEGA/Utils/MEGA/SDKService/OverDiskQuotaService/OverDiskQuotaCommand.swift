import Foundation

@objc final class OverDiskQuotaCommand: NSObject {

    private var completionAction: (OverDiskQuotaInfomationProtocol?) -> Void

    private var task: OverDiskQuotaQueryTask?

    var storageUsed: NSNumber?

    @objc init(storageUsed: NSNumber?,
               completionAction: @escaping (OverDiskQuotaInfomationProtocol?) -> Void) {
        self.completionAction = completionAction
        self.storageUsed = storageUsed
    }

    func execute(with api: MEGASdk,
                 completion: @escaping (OverDiskQuotaCommand?, OverDiskQuotaService.DataObtainingError?) -> Void)
    {
        guard let storageUsed = storageUsed else {
            assertionFailure("Do not schedule a command to execute while stroage used is still nil.")
            completion(self, .unexpectedlyCancellation)
            return
        }

        let task = OverDiskQuotaQueryTask()
        task.updatedStorageStore(with: storageUsed)
        task.start(with: api) { [weak self] overDiskQuotaInformation, error in
            var retainedTask: OverDiskQuotaQueryTask? = task
            defer { retainedTask = nil }

            guard let overDiskQuotaInformation = overDiskQuotaInformation else {
                self?.completionAction(nil)
                completion(nil, error)
                return
            }

            self?.completionAction(overDiskQuotaInformation)
            completion(self, error)
        }
    }
}

fileprivate final class OverDiskQuotaQueryTask {

    // MARK: - Errors

    private var errors: Set<OverDiskQuotaService.DataObtainingError> = []

    // MARK: - Over Disk Quota Data Store

    private var userDataStore: OverDiskQuotaUserData?

    private var storageUsedStore: OverDiskQuotaStorageUsed?

    private var availablePlansStore: OverDiskQuotaPlans?

    // MARK: - Methods

    func start(
        with api: MEGASdk,
        completion: @escaping (OverDiskQuotaInfomationProtocol?, OverDiskQuotaService.DataObtainingError?
    ) -> Void) {

        if let userDataStore = userDataStore,
            let storageUsedStore = storageUsedStore,
            let availablePlansStore = availablePlansStore {
            let overDiskQuotaData = extractedInformation(userDataStore: userDataStore,
                                                        storageStore: storageUsedStore,
                                                        planStore: availablePlansStore)
            completion(overDiskQuotaData, nil)
            return
        }

        if shouldFetchUserData(userDataStore, errors: errors) {
            api.getUserData(with: MEGAGenericRequestDelegate(completion: { [weak self] (_, error) in
                guard let self = self else {
                    assertionFailure("OverDiskQuotaQueryTask instance is unexpected released.")
                    completion(nil, .unexpectedlyCancellation)
                    return
                }

                guard error.type == .apiOk else {
                    completion(nil, .unableToFetchUserData)
                    return
                }

                switch self.updatedUserData(with: api) {
                case .failure(let error):
                    self.errors.insert(error)
                    completion(nil, error)
                    return
                case .success(let userData):
                    self.userDataStore = userData
                    self.start(with: api, completion: completion)
                }
            }))
            return
        }

        if shouldFetchMEGAPlans(availablePlansStore, errors: errors) {
            MEGAPlanService.shared.send(MEGAPlanCommand { [weak self] plans, error  in
                guard let self = self else {
                    assertionFailure("OverDiskQuotaQueryTask instance is unexpected released.")
                    completion(nil, .unexpectedlyCancellation)
                    return
                }
                guard let plans = plans else {
                    completion(nil, .unableToFetchMEGAPlans)
                    return
                }

                self.availablePlansStore = OverDiskQuotaPlans(availablePlans: plans)
                self.start(with: api, completion: completion)
            })
            return
        }

        assertionFailure("OverDiskQuotaQueryTask run into a state that not fetches enough information and terminated.")
        completion(nil, .unexpectedlyCancellation)
    }

    func updatedStorageStore(with storage: NSNumber) {
        self.storageUsedStore = OverDiskQuotaStorageUsed(cloudStorageTaking: storage)
    }

    // MARK: - Privates

    private func shouldFetchUserData(
        _ userDataStore: OverDiskQuotaUserData?,
        errors: Set<OverDiskQuotaService.DataObtainingError>) -> Bool {
        return ((userDataStore == nil) && !errors.contains(.invalidUserEmail))
    }

    private func shouldFetchMEGAPlans(
        _ plansStore: OverDiskQuotaPlans?,
        errors: Set<OverDiskQuotaService.DataObtainingError>) -> Bool {
        return (plansStore == nil)
    }

    private func updatedUserData(with api: MEGASdk)
        -> Result<OverDiskQuotaUserData, OverDiskQuotaService.DataObtainingError> {
        guard let email = api.myEmail else { return .failure(.invalidUserEmail) }
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
