// Not `#if`-guarded — see the note in QAQuotaDialogUseCase.swift (QA config builds packages as release).
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
        /// Keeps QA not sending real events
        self.tracker = NoOpAnalyticsTracker()
    }
}
