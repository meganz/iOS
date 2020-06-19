import Foundation

@objc final class OverDiskQuotaCommand: NSObject {

    private(set) var completionAction: (OverDiskQuotaInfomationType) -> Void
    private(set) var api: MEGASdk

    @objc init(api: MEGASdk, completionAction: @escaping (OverDiskQuotaInfomationType) -> Void) {
        self.completionAction = completionAction
        self.api = api
    }

    fileprivate func execute(with overDiskQuotaInformation: OverDiskQuotaInfomationType) {
        completionAction(overDiskQuotaInformation)
    }
}

fileprivate final class OverDiskQuotaQueryTask {

    let progressID: UUID

    // MARK: - Command for this progress

    private let command: OverDiskQuotaCommand

    private let completionAction: (UUID) -> Void

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

    init(command: OverDiskQuotaCommand, completion: @escaping (UUID) -> Void) {
        self.command = command
        self.progressID = UUID()
        self.completionAction = completion
    }

    func startProgress() {
        let api = command.api

        if let userDataStore = userDataStore,
            let storageUsedStore = storageUsedStore,
            let availablePlansStore = availablePlansStore {
            let overDiskQuotaData = extractedInformation(userDataStore: userDataStore,
                                                        storageStore: storageUsedStore,
                                                        planStore: availablePlansStore)
            command.execute(with: overDiskQuotaData)
            completionAction(progressID)
            return
        }

        if shouldFetchUserData(userDataStore, errors: errors) {
            api.getUserData(with: MEGAGenericRequestDelegate(completion: { [weak self] (_, _) in
                guard let self = self else { return }
                switch self.updatedUserData(with: api) {
                case .failure(let error): self.errors.insert(error)
                case .success(let userData):
                    self.userDataStore = userData
                    self.startProgress()
                }
            }))
            return
        }

        if shouldFetchMEGAPlans(availablePlansStore, errors: errors) {
            MEGAPlanService.loadMegaPlans(with: api) { [weak self] plans in
                guard let self = self else { return }
                self.availablePlansStore = OverDiskQuotaPlans(availablePlans: plans)
                self.startProgress()
           }
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

@objc final class OverDiskQuotaService: NSObject {

    // MARK: - Static

    @objc(sharedService) static var shared: OverDiskQuotaService = OverDiskQuotaService()

    // MARK: - OverDiskQuotaService

    // MARK: - Instance

    private var inProgressTasks: [OverDiskQuotaQueryTask] = []

    private var currentUserCloudStroageUsed: NSNumber?

    // MARK: - Lifecycle

    private override init() {}

    // MARK: - Instance Method

    @objc func invalidate() {
        inProgressTasks = []
    }

    @objc func setUserStorageUsed(_ stroageUsed: NSNumber) {
        currentUserCloudStroageUsed = stroageUsed

        inProgressTasks.forEach { progress in
            progress.updatedStorageStore(with: stroageUsed)
            progress.startProgress()
        }
    }

    @objc func send(_ command: OverDiskQuotaCommand) {
        let queryProgress = OverDiskQuotaQueryTask(command: command) { [weak self] uuid in
            self?.inProgressTasks.removeAll { (progress) -> Bool in
                progress.progressID == uuid
            }
        }

        if let storageUsed = currentUserCloudStroageUsed {
            queryProgress.updatedStorageStore(with: storageUsed)
        }

        inProgressTasks.append(queryProgress)
        queryProgress.startProgress()
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
