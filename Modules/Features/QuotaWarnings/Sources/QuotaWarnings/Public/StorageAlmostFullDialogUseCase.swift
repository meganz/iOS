import MEGAAppSDKRepo
import MEGADomain
import MEGAPreference

public struct StorageAlmostFullDialogUseCase: StorageAlmostFullDialogUseCaseProtocol {
    private let accountStorageUseCase: any AccountStorageUseCaseProtocol
    private let allowance: any DialogDisplayAllowance

    init(
        accountStorageUseCase: some AccountStorageUseCaseProtocol,
        allowance: some DialogDisplayAllowance
    ) {
        self.accountStorageUseCase = accountStorageUseCase
        self.allowance = allowance
    }

    public func shouldShowDialog() async throws -> Bool {
        // Allowance first: it is a local read, while refreshing the storage state is a request.
        // The triggers could fire often so there is no point asking the API once the day's allowance is spent.
        guard allowance.isAvailable else { return false }
        return try await accountStorageUseCase.refreshCurrentStorageState() == .almostFull
    }

    public func recordDialogShown() {
        allowance.consume()
    }

    /// **QA affordance only** The allowance this trigger draws on. Read by the QA surface in `+QA`.
    var _displayAllowance: any DialogDisplayAllowance { allowance }
}

// MARK: - Triggers
public extension StorageAlmostFullDialogUseCase {
    /// Checked when the open (either normal login or fast login). Once a day.
    static var onAppOpen: StorageAlmostFullDialogUseCase {
        make(allowance: .storageAlmostFullOnAppOpen)
    }

    /// Checked after an upload finishes successfully. Once a day.
    static var afterSuccessfulUpload: StorageAlmostFullDialogUseCase {
        make(allowance: .storageAlmostFullAfterUpload)
    }

    private static func make(allowance: DailyDialogAllowance) -> StorageAlmostFullDialogUseCase {
        StorageAlmostFullDialogUseCase(
            accountStorageUseCase: AccountStorageUseCase(
                accountRepository: AccountRepository.newRepo,
                preferenceUseCase: PreferenceUseCase.default
            ),
            allowance: allowance
        )
    }
}
