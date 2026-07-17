#if DEBUG || QA_CONFIG
import MEGADomain

/// A `QuotaDialogUseCaseProtocol` backed by explicit, in-memory values.
///
/// Lets the QA dialog simulator render the storage / transfer quota dialogs against a configured
/// `AccountDetailsEntity` + `PlanEntity` instead of live account data. Pass `plan: nil` to drive the
/// "no upgrade available" state.
public struct QAQuotaDialogUseCase: QuotaDialogUseCaseProtocol {
    private let account: AccountDetailsEntity
    private let plan: PlanEntity?

    public init(accountDetails: AccountDetailsEntity, plan: PlanEntity?) {
        self.account = accountDetails
        self.plan = plan
    }

    func upgradeOption() async throws -> QuotaUpgradeOption {
        if let plan {
            .available(accountDetails: account, plan: plan)
        } else {
            .unavailable(accountDetails: account)
        }
    }
}
#endif
