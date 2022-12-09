import Foundation
import MEGAFoundation

@objc final class OverDiskQuotaCommand: NSObject {

    // MARK: - Typealias

    typealias OverDiskQuotaFetchResult =
        Result<OverDiskQuotaInfomationProtocol, OverDiskQuotaService.DataObtainingError>

    // MARK: - Properties

    private var completionAction: (OverDiskQuotaInfomationProtocol?) -> Void

    var storageUsed: NSNumber?

    // MARK: - Lifecycles

    @objc init(storageUsed: NSNumber?,
               completionAction: @escaping (OverDiskQuotaInfomationProtocol?) -> Void) {
        self.completionAction = completionAction
        self.storageUsed = storageUsed
    }

    // MARK: - Exposed

    func execute(
        with api: MEGASdk,
        completion: @escaping (OverDiskQuotaCommand?, OverDiskQuotaFetchResult) -> Void
    ) {
        guard let storageUsed = storageUsed else {
            assertionFailure("Do not schedule a command to execute while stroage used is still nil.")
            completion(self, .failure(.illegaillyScheduling))
            return
        }

        let task = OverDiskQuotaQueryTask()
        task.updatedStorageStore(with: storageUsed)
        task.start(with: api) { [weak self] result in
            var retainedTask: OverDiskQuotaQueryTask? = task
            defer { retainedTask = nil }
            _ = retainedTask

            self?.completionAction(try? result.get())
            completion(self, result)
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
        completion: @escaping (Result<OverDiskQuotaInfomationProtocol, OverDiskQuotaService.DataObtainingError>) -> Void
    ) {
        if let userDataStore = userDataStore,
            let storageUsedStore = storageUsedStore,
            let availablePlansStore = availablePlansStore {
            let overDiskQuotaData = extractedInformation(userDataStore: userDataStore,
                                                         storageStore: storageUsedStore,
                                                         planStore: availablePlansStore)
            completion(.success(overDiskQuotaData))
            return
        }

        guard !shouldFetchUserData(userDataStore, errors: errors) else {
            fetchUserData(api, completion)
            return
        }

        guard !shouldFetchMEGAPlans(availablePlansStore, errors: errors) else {
            fetchMEGAPlans(api, completion)
            return
        }

        assertionFailure("OverDiskQuotaQueryTask run into a state that not fetches enough information and terminated.")
        completion(.failure(.unexpectedlyCancellation))
    }

    func updatedStorageStore(with storage: NSNumber) {
        self.storageUsedStore = OverDiskQuotaStorageUsed(cloudStorageTaking: .bytes(of: storage.int64Value))
    }

    // MARK: - Privates

    // MARK: - Fetch User's Data

    private func shouldFetchUserData(
        _ userDataStore: OverDiskQuotaUserData?,
        errors: Set<OverDiskQuotaService.DataObtainingError>) -> Bool {
        return ((userDataStore == nil) && !errors.contains(.invalidUserEmail))
    }

    private func fetchUserData(
        _ api: MEGASdk,
        _ completion: @escaping (Result<OverDiskQuotaInfomationProtocol,OverDiskQuotaService.DataObtainingError>) -> Void
    ) {
        api.getUserData(with: MEGAGenericRequestDelegate(completion: { [weak self] (_, error) in
            guard let self = self else {
                assertionFailure("OverDiskQuotaQueryTask instance is unexpected released.")
                completion(.failure(.unexpectedlyCancellation))
                return
            }

            guard error.type == .apiOk else {
                completion(.failure(.unableToFetchUserData))
                return
            }

            switch self.updatedUserData(with: api) {
            case .failure(let error):
                self.errors.insert(error)
                completion(.failure(error))
            case .success(let userData):
                self.userDataStore = userData
                self.start(with: api, completion: completion)
            }
        }))
    }

    // MARK: - Fetch MEGA Plans

    private func shouldFetchMEGAPlans(
        _ plansStore: OverDiskQuotaPlans?,
        errors: Set<OverDiskQuotaService.DataObtainingError>) -> Bool {
        return (plansStore == nil)
    }

    private func fetchMEGAPlans(
        _ api: MEGASdk,
        _ completion: @escaping (Result<OverDiskQuotaInfomationProtocol, OverDiskQuotaService.DataObtainingError>) -> Void
    ) {
        MEGAPlanService.shared.send(MEGAPlanCommand { [weak self] result  in
            guard let self = self else {
                assertionFailure("OverDiskQuotaQueryTask instance is unexpected released.")
                completion(.failure(.unexpectedlyCancellation))
                return
            }

            switch result {
            case .failure: completion(.failure(.unableToFetchMEGAPlans))
            case .success(let plans):
                self.availablePlansStore = OverDiskQuotaPlans(availablePlans: plans)
                self.start(with: api, completion: completion)
            }
        })
    }

    // MARK: - Update User's Data

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
        let planUpgradeAdvice = MEGAPlanUpgradeAdviser.suggestMinimumPlan(ofStorage: storageStore.cloudStorageTaking,
                                                                          from: planStore.availablePlans)
        return OverDiskQuotaInformation(email: userDataStore.email,
                                        deadline: userDataStore.deadline,
                                        warningDates: userDataStore.warningDates,
                                        numberOfFilesOnCloud: userDataStore.numberOfFilesOnCloud,
                                        cloudStorage: storageStore.cloudStorageTaking.valueNumber,
                                        suggestedPlanName: planUpgradeAdvice.plan?.readableName)
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
    typealias StorageUsedInBytes = Measurement<UnitDataStorage>
    var cloudStorageTaking: StorageUsedInBytes
}
