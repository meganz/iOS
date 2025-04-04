import Foundation
import MEGAAppSDKRepo
import MEGAFoundation

@objc final class OverDiskQuotaCommand: NSObject {

    // MARK: - Typealias

    typealias OverDiskQuotaFetchResult =
        Result<any OverDiskQuotaInfomationProtocol, OverDiskQuotaService.DataObtainingError>

    // MARK: - Properties

    private var completionAction: ((any OverDiskQuotaInfomationProtocol)?) -> Void

    var storageUsed: Int64

    // MARK: - Lifecycles

    @objc init(storageUsed: Int64,
               completionAction: @escaping ((any OverDiskQuotaInfomationProtocol)?) -> Void) {
        self.completionAction = completionAction
        self.storageUsed = storageUsed
    }

    // MARK: - Exposed

    func execute(
        with api: MEGASdk,
        completion: @escaping (OverDiskQuotaCommand?, OverDiskQuotaFetchResult) -> Void
    ) {
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

private final class OverDiskQuotaQueryTask {

    // MARK: - Errors

    private var errors: Set<OverDiskQuotaService.DataObtainingError> = []

    // MARK: - Over Disk Quota Data Store

    private var userDataStore: OverDiskQuotaUserData?

    private var storageUsedStore: OverDiskQuotaStorageUsed?

    private var availablePlansStore: OverDiskQuotaPlans?

    // MARK: - Methods

    func start(
        with api: MEGASdk,
        completion: @escaping (Result<any OverDiskQuotaInfomationProtocol, OverDiskQuotaService.DataObtainingError>) -> Void
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

    func updatedStorageStore(with storage: Int64) {
        self.storageUsedStore = OverDiskQuotaStorageUsed(cloudStorageTaking: .bytes(of: storage))
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
        _ completion: @escaping (Result<any OverDiskQuotaInfomationProtocol, OverDiskQuotaService.DataObtainingError>) -> Void
    ) {
        api.getUserData(with: RequestDelegate { [weak self] result in
            guard let self else {
                assertionFailure("OverDiskQuotaQueryTask instance is unexpected released.")
                completion(.failure(.unexpectedlyCancellation))
                return
            }

            if case .failure = result {
                completion(.failure(.unableToFetchUserData))
                return
            }

            switch updatedUserData(with: api) {
            case .failure(let error):
                errors.insert(error)
                completion(.failure(error))
            case .success(let userData):
                userDataStore = userData
                start(with: api, completion: completion)
            }
        })
    }

    // MARK: - Fetch MEGA Plans

    private func shouldFetchMEGAPlans(
        _ plansStore: OverDiskQuotaPlans?,
        errors: Set<OverDiskQuotaService.DataObtainingError>) -> Bool {
        return (plansStore == nil)
    }

    private func fetchMEGAPlans(
        _ api: MEGASdk,
        _ completion: @escaping (Result<any OverDiskQuotaInfomationProtocol, OverDiskQuotaService.DataObtainingError>) -> Void
    ) {
        MEGAPlanService.shared.send(MEGAPlanCommand { [weak self] result  in
            guard let self else {
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
        guard let email = MEGASdk.currentUserEmail else { return .failure(.invalidUserEmail) }
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

private struct OverDiskQuotaUserData {
    typealias Email = String
    typealias Deadline = Date
    typealias WarningDates = [Date]
    typealias FileCount = UInt64

    var email: Email
    var deadline: Deadline
    var warningDates: WarningDates
    var numberOfFilesOnCloud: FileCount
}

private struct OverDiskQuotaPlans {
    typealias AvailablePlans = [MEGAPlan]
    var availablePlans: AvailablePlans
}

private struct OverDiskQuotaStorageUsed {
    typealias StorageUsedInBytes = Measurement<UnitDataStorage>
    var cloudStorageTaking: StorageUsedInBytes
}
