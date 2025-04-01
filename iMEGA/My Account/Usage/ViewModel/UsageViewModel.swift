import MEGAAppPresentation
import MEGADomain

enum StorageType {
    case cloud, backups, rubbishBin, incomingShares, chart
}

enum UsageAction: ActionType {
    case loadCurrentStorageStatus
    case loadRootNodeStorage
    case loadBackupStorage
    case loadRubbishBinStorage
    case loadIncomingSharedStorage
    case loadStorageDetails
    case loadTransferDetails
}

final class UsageViewModel: ViewModelType {
    var invokeCommand: ((Command) -> Void)?
    
    private let accountUseCase: any AccountUseCaseProtocol
    private let accountStorageUseCase: any AccountStorageUseCaseProtocol
    var accountType: AccountTypeEntity?
    
    enum Command: CommandType, Equatable {
        case loaded(StorageType, Int64)
        case loadedStorage(used: Int64, max: Int64)
        case loadedTransfer(used: Int64, max: Int64)
        case startLoading(StorageType)
        case stopLoading(StorageType)
    }
    
    init(
        accountUseCase: some AccountUseCaseProtocol,
        accountStorageUseCase: some AccountStorageUseCaseProtocol
    ) {
        self.accountUseCase = accountUseCase
        self.accountStorageUseCase = accountStorageUseCase
    }
    
    func dispatch(_ action: UsageAction) {
        switch action {
        case .loadCurrentStorageStatus: loadCurrentStorageStatus()
        case .loadRootNodeStorage: updateRootNodeStorageUsed()
        case .loadBackupStorage: updateBackupNodeStorageUsed()
        case .loadRubbishBinStorage: updateRubbishBinStorageUsed()
        case .loadIncomingSharedStorage: updateIncomingSharesStorageUsed()
        case .loadStorageDetails: loadStorageDetails()
        case .loadTransferDetails: loadTransferDetails()
        }
    }
    
    private func loadDetails(commandType: UsageViewModel.Command) {
        Task {
            invokeCommand?(commandType)
        }
    }
    
    private func loadStorageDetails() {
        loadDetails(
            commandType: .loadedStorage(
                used: accountUseCase.currentAccountDetails?.storageUsed ?? 0,
                max: accountUseCase.currentAccountDetails?.storageMax ?? 0
            )
        )
    }
    
    private func loadTransferDetails() {
        loadDetails(
            commandType: .loadedTransfer(
                used: accountUseCase.currentAccountDetails?.transferUsed ?? 0,
                max: accountUseCase.currentAccountDetails?.transferMax ?? 0
            )
        )
    }
    
    private func updateStorageUsedAsync(for type: StorageType, storageUsedAsync: @escaping () async throws -> Int64) async {
        invokeCommand?(.startLoading(type))
        do {
            let storageSize = try await storageUsedAsync()
            invokeCommand?(.loaded(type, storageSize))
        } catch {
            invokeCommand?(.loaded(type, 0))
        }
    }
    
    private func updateStorageUsed(for type: StorageType, storageUsedFunction: @escaping () -> Int64) {
        Task {
            invokeCommand?(.startLoading(type))
            let storageSize = storageUsedFunction()
            invokeCommand?(.loaded(type, storageSize))
        }
    }
    
    private func updateBackupNodeStorageUsed() {
        Task {
            await updateStorageUsedAsync(
                for: .backups,
                storageUsedAsync: accountUseCase.backupStorageUsed
            )
        }
    }
    
    private func updateRootNodeStorageUsed() {
        updateStorageUsed(
            for: .cloud,
            storageUsedFunction: accountUseCase.rootStorageUsed
        )
    }

    private func updateRubbishBinStorageUsed() {
        updateStorageUsed(
            for: .rubbishBin,
            storageUsedFunction: accountUseCase.rubbishBinStorageUsed
        )
    }

    private func updateIncomingSharesStorageUsed() {
        updateStorageUsed(
            for: .incomingShares,
            storageUsedFunction: accountUseCase.incomingSharesStorageUsed
        )
    }
    
    var isBusinessAccount: Bool {
        accountUseCase.isAccountType(.business)
    }
    
    var isProFlexiAccount: Bool {
        accountUseCase.isAccountType(.proFlexi)
    }
    
    var isFreeAccount: Bool {
        accountUseCase.isAccountType(.free)
    }
    
    var currentStorageStatus: StorageStatusEntity {
        accountStorageUseCase.currentStorageStatus
    }
    
    var currentTransferStatus: TransferStatusEntity {
        return switch transferUsedPercentage {
        case 0...80: .noTransferProblems
        case 81..<100: .almostFull
        default: .full
        }
    }
    
    var storageUsedPercentage: Float {
        guard let used = accountUseCase.currentAccountDetails?.storageUsed,
              let max = accountUseCase.currentAccountDetails?.storageMax,
              max > 0 else { return 0 }
        return (Float(used) / Float(max)) * 100
    }
    
    var transferUsedPercentage: Float {
        guard let used = accountUseCase.currentAccountDetails?.transferUsed,
              let max = accountUseCase.currentAccountDetails?.transferMax,
              max > 0 else { return 0 }
        return (Float(used) / Float(max)) * 100
    }
    
    func loadCurrentStorageStatus() {
        Task {
            invokeCommand?(.startLoading(.chart))
            _ = try? await accountStorageUseCase.refreshCurrentStorageState()
            invokeCommand?(.stopLoading(.chart))
        }
    }
}
