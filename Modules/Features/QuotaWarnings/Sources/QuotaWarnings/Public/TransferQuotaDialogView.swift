import MEGADomain
import SwiftUI

public enum TransferQuotaSeverity: Equatable, Sendable {
    case limitedDownload
    case downloadExceeded
    case streamingExceeded
}

public struct TransferQuotaDialogView: View {
    /// Injected dependencies for the live dialog. The plan catalog use case is provided by the app target
    /// (its repository depends on `MEGAPurchase`); everything else is composed inside the package.
    public struct Dependency {
        let useCase: any QuotaDialogUseCaseProtocol

        public init(accountPlanPurchaseUseCase: some AccountPlanPurchaseUseCaseProtocol) {
            useCase = QuotaDialogUseCaseFactory.make(accountPlanPurchaseUseCase: accountPlanPurchaseUseCase)
        }
    }

    @StateObject private var viewModel: QuotaDialogViewModel
    private let onClose: () -> Void
    private let onViewAllPlans: @MainActor () -> Void

    public init(
        severity: TransferQuotaSeverity,
        dependency: Dependency,
        onClose: @escaping () -> Void = {},
        onViewAllPlans: @escaping @MainActor () -> Void = {}
    ) {
        self.onClose = onClose
        self.onViewAllPlans = onViewAllPlans
        _viewModel = StateObject(wrappedValue: QuotaDialogViewModel(
            useCase: dependency.useCase,
            mapper: TransferQuotaDialogMapper(severity: severity)
        ))
    }

#if DEBUG || QA_CONFIG
    /// Renders the dialog against a QA-provided use case (configured account + plan) instead of live data.
    public init(
        severity: TransferQuotaSeverity,
        useCase: QAQuotaDialogUseCase,
        onClose: @escaping () -> Void = {},
        onViewAllPlans: @escaping @MainActor () -> Void = {}
    ) {
        self.onClose = onClose
        self.onViewAllPlans = onViewAllPlans
        _viewModel = StateObject(wrappedValue: QuotaDialogViewModel(
            useCase: useCase,
            mapper: TransferQuotaDialogMapper(severity: severity)
        ))
    }
#endif

#if DEBUG
    /// For Preview only
    fileprivate init(
        severity: TransferQuotaSeverity,
        useCase: PreviewQuotaDialogUseCase,
        onClose: @escaping () -> Void = {},
        onViewAllPlans: @escaping @MainActor () -> Void = {}
    ) {
        self.onClose = onClose
        self.onViewAllPlans = onViewAllPlans
        _viewModel = StateObject(wrappedValue: QuotaDialogViewModel(
            useCase: useCase,
            mapper: TransferQuotaDialogMapper(severity: severity)
        ))
    }
#endif

    public var body: some View {
        QuotaDialogContentView(viewModel: viewModel, onClose: onClose, onViewAllPlans: onViewAllPlans)
    }
}

#if DEBUG
#Preview("Limited download") {
    TransferQuotaDialogView(severity: .limitedDownload, useCase: PreviewQuotaDialogUseCase())
}

#Preview("Download exceeded") {
    TransferQuotaDialogView(severity: .downloadExceeded, useCase: PreviewQuotaDialogUseCase())
}

#Preview("No upgrade") {
    TransferQuotaDialogView(severity: .downloadExceeded, useCase: PreviewQuotaDialogUseCase(plan: nil))
}

#Preview("Streaming exceeded — dark") {
    TransferQuotaDialogView(severity: .streamingExceeded, useCase: PreviewQuotaDialogUseCase())
        .preferredColorScheme(.dark)
}
#endif
