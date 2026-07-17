import MEGASwiftUI
import MEGAUIComponent
import SwiftUI

public enum StorageQuotaSeverity: Equatable, Sendable {
    case almostFull
    case full
}

public struct StorageQuotaDialogView: View {
    @StateObject private var viewModel: QuotaDialogViewModel
    private let severity: StorageQuotaSeverity
    private let onClose: () -> Void

    public init(
        severity: StorageQuotaSeverity,
        onClose: @escaping () -> Void = {}
    ) {
        self.severity = severity
        self.onClose = onClose
        _viewModel = StateObject(wrappedValue: QuotaDialogViewModel(useCase: Dependency.quotaDialogUseCase))
    }

#if DEBUG || QA_CONFIG
    /// Renders the dialog against a QA-provided use case (configured account + plan) instead of live data.
    /// Used by the QA dialog simulator so every rendering factor can be driven.
    public init(
        severity: StorageQuotaSeverity,
        useCase: QAQuotaDialogUseCase,
        onClose: @escaping () -> Void = {}
    ) {
        self.severity = severity
        self.onClose = onClose
        _viewModel = StateObject(wrappedValue: QuotaDialogViewModel(useCase: useCase))
    }
#endif

#if DEBUG
    /// For Preview only
    fileprivate init(
        severity: StorageQuotaSeverity,
        useCase: PreviewQuotaDialogUseCase,
        onClose: @escaping () -> Void = {}
    ) {
        self.severity = severity
        self.onClose = onClose
        _viewModel = StateObject(wrappedValue: QuotaDialogViewModel(useCase: useCase))
    }
#endif

    public var body: some View {
        dialog
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(action: onClose) {
                        XmarkCloseButton()
                    }
                }
            }
            .onFirstLoad { await viewModel.load() }
    }

    @ViewBuilder private var dialog: some View {
        switch viewModel.viewState {
        case .loading:
            QuotaDialogSkeletonView()
        case .error:
            QuotaDialogErrorView()
        case let .upgradeAvailable(accountDetailsEntity, planEntity):
            QuotaDialogView(
                header: {
                    StorageQuotaHeaderView(
                        severity: severity,
                        quotaProgress: viewModel.currentStorageQuotaProgress(severity: severity, accountDetailsEntity: accountDetailsEntity)
                    )
                },
                currentPlanCard: {
                    CurrentPlanView(currentPlan: viewModel.storageCurrentPlan(severity: severity, accountDetailsEntity: accountDetailsEntity))
                },
                recommendedPlanCard: {
                    RecommendedPlanView(plan: viewModel.storageRecommendedPlan(accountDetailsEntity: accountDetailsEntity, planEntity: planEntity))
                },
                footer: {
                    RecommendedPlanFooterView(plan: planEntity)
                }
            )
        case let .noUpgradeAvailable(accountDetailsEntity):
            QuotaDialogView(
                header: {
                    StorageQuotaHeaderView(
                        severity: severity,
                        quotaProgress: viewModel.currentStorageQuotaProgress(severity: severity, accountDetailsEntity: accountDetailsEntity)
                    )
                },
                currentPlanCard: {
                    CurrentPlanView(currentPlan: viewModel.storageCurrentPlan(severity: severity, accountDetailsEntity: accountDetailsEntity))
                },
                footer: { ContactSupportFooterView() }
            )
        }
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
