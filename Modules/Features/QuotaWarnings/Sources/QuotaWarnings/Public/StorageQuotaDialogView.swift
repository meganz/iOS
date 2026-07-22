import MEGADomain
import SwiftUI

public enum StorageQuotaSeverity: Equatable, Sendable {
    case almostFull
    case full
}

public struct StorageQuotaDialogView: View {
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
        severity: StorageQuotaSeverity,
        dependency: Dependency,
        onClose: @escaping () -> Void = {},
        onViewAllPlans: @escaping @MainActor () -> Void = {}
    ) {
        self.onClose = onClose
        self.onViewAllPlans = onViewAllPlans
        _viewModel = StateObject(wrappedValue: QuotaDialogViewModel(
            useCase: dependency.useCase,
            mapper: StorageQuotaDialogMapper(severity: severity)
        ))
    }

#if DEBUG || QA_CONFIG
    /// Renders the dialog against a QA-provided use case (configured account + plan) instead of live data.
    public init(
        severity: StorageQuotaSeverity,
        useCase: QAQuotaDialogUseCase,
        onClose: @escaping () -> Void = {},
        onViewAllPlans: @escaping @MainActor () -> Void = {}
    ) {
        self.onClose = onClose
        self.onViewAllPlans = onViewAllPlans
        _viewModel = StateObject(wrappedValue: QuotaDialogViewModel(
            useCase: useCase,
            mapper: StorageQuotaDialogMapper(severity: severity)
        ))
    }
#endif

#if DEBUG
    /// For Preview only
    fileprivate init(
        severity: StorageQuotaSeverity,
        useCase: PreviewQuotaDialogUseCase,
        onClose: @escaping () -> Void = {},
        onViewAllPlans: @escaping @MainActor () -> Void = {}
    ) {
        self.onClose = onClose
        self.onViewAllPlans = onViewAllPlans
        _viewModel = StateObject(wrappedValue: QuotaDialogViewModel(
            useCase: useCase,
            mapper: StorageQuotaDialogMapper(severity: severity)
        ))
    }
#endif

    public var body: some View {
        QuotaDialogContentView(viewModel: viewModel, onClose: onClose, onViewAllPlans: onViewAllPlans)
    }
}

#if DEBUG
#Preview("Almost full") {
    StorageQuotaDialogView(severity: .almostFull, useCase: PreviewQuotaDialogUseCase())
}

#Preview("Full") {
    StorageQuotaDialogView(severity: .full, useCase: PreviewQuotaDialogUseCase())
}

#Preview("No upgrade") {
    StorageQuotaDialogView(severity: .full, useCase: PreviewQuotaDialogUseCase(plan: nil))
}

#Preview("Full — dark") {
    StorageQuotaDialogView(severity: .full, useCase: PreviewQuotaDialogUseCase())
        .preferredColorScheme(.dark)
}
#endif
