#if DEBUG || QA_CONFIG
public extension QuotaWarningDialogView.Dependency {
    init(
        quotaDialogUseCase: QAQuotaDialogUseCase
    ) {
        self.quotaDialogUseCase = quotaDialogUseCase
    }
}
#endif
