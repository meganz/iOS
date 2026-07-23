#if DEBUG || QA_CONFIG
import MEGAAppPresentation

public extension QuotaWarningDialogView.Dependency {
    /// QA simulator seam: a scripted dialog use case + a caller-supplied scripted `PlanPurchasing`
    /// so every purchase branch can be exercised without real StoreKit.
    init(
        quotaDialogUseCase: QAQuotaDialogUseCase,
        planPurchaser: any PlanPurchasing
    ) {
        self.quotaDialogUseCase = quotaDialogUseCase
        self.planPurchaser = planPurchaser
    }
}
#endif
