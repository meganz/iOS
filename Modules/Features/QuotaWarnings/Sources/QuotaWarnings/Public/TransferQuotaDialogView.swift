import MEGASwiftUI
import MEGAUIComponent
import SwiftUI

public enum TransferQuotaSeverity: Equatable, Sendable {
    case limitedDownload
    case downloadExceeded
    case streamingExceeded
}

public struct TransferQuotaDialogView: View {
    @StateObject private var viewModel: QuotaDialogViewModel
    private let severity: TransferQuotaSeverity
    private let onClose: () -> Void

    public init(
        severity: TransferQuotaSeverity,
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
        severity: TransferQuotaSeverity,
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
        severity: TransferQuotaSeverity,
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
                    TransferQuotaHeaderView(
                        severity: severity,
                        quotaProgress: viewModel.currentTransferQuotaProgress(severity: severity, accountDetailsEntity: accountDetailsEntity),
                        isFreePlan: accountDetailsEntity.isFree
                    )
                },
                currentPlanCard: {
                    CurrentPlanView(currentPlan: viewModel.transferCurrentPlan(severity: severity, accountDetailsEntity: accountDetailsEntity))
                },
                recommendedPlanCard: {
                    RecommendedPlanView(plan: viewModel.transferRecommendedPlan(accountDetailsEntity: accountDetailsEntity, planEntity: planEntity))
                },
                footer: {
                    RecommendedPlanFooterView(plan: planEntity)
                }
            )
        case let .noUpgradeAvailable(accountDetailsEntity):
            QuotaDialogView(
                header: {
                    TransferQuotaHeaderView(
                        severity: severity,
                        quotaProgress: viewModel.currentTransferQuotaProgress(severity: severity, accountDetailsEntity: accountDetailsEntity),
                        isFreePlan: accountDetailsEntity.isFree
                    )
                },
                currentPlanCard: {
                    CurrentPlanView(currentPlan: viewModel.transferCurrentPlan(severity: severity, accountDetailsEntity: accountDetailsEntity))
                },
                footer: { ContactSupportFooterView() }
            )
        }
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
