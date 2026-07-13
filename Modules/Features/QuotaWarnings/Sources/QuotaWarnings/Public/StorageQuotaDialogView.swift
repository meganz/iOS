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
        _viewModel = StateObject(wrappedValue: QuotaDialogViewModel(useCase: PreviewQuotaDialogUseCase()))
    }

    /// For Preview only
    fileprivate init(
        severity: StorageQuotaSeverity,
        useCase: some QuotaDialogUseCaseProtocol,
        onClose: @escaping () -> Void = {}
    ) {
        self.severity = severity
        self.onClose = onClose
        _viewModel = StateObject(wrappedValue: QuotaDialogViewModel(useCase: useCase))
    }

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
