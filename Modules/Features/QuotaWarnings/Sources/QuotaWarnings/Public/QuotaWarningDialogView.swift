import MEGAAppPresentation
import MEGADomain
import SwiftUI

public enum StorageQuotaSeverity: Equatable, Sendable {
    case almostFull
    case full(FullTrigger)

    /// What brought up a full-storage dialog. Only affects the copy, not the severity itself.
    public enum FullTrigger: Equatable, Sendable {
        /// Surfaced on login/reload from the SDK storage state.
        case storageState
        /// The user just attempted an upload that was blocked (over-quota API error).
        case uploadAttempt
    }
}

public enum TransferQuotaSeverity: Equatable, Sendable {
    case limitedDownload
    case downloadExceeded
    case limitedStreaming
    case streamingExceeded
}

public struct QuotaWarningDialogView: View {
    public enum Kind: Sendable {
        case storage(StorageQuotaSeverity)
        case transfer(TransferQuotaSeverity)
    }
    
    public struct Dependency {
        let quotaDialogUseCase: any QuotaDialogUseCaseProtocol
        let planPurchaser: any PlanPurchasing

        public init(
            accountPlanPurchaseUseCase: some AccountPlanPurchaseUseCaseProtocol,
            pricingRequester: some PricingRequesting,
            planPurchaser: some PlanPurchasing
        ) {
            self.quotaDialogUseCase = QuotaDialogUseCaseFactory.make(
                accountPlanPurchaseUseCase: accountPlanPurchaseUseCase,
                pricingRequester: pricingRequester
            )
            self.planPurchaser = planPurchaser
        }

        func storageDialogDependency(_ severity: StorageQuotaSeverity) -> QuotaDialogContentView.Dependency {
            QuotaDialogContentView.Dependency(
                useCase: quotaDialogUseCase,
                mapper: StorageQuotaDialogMapper(severity: severity),
                planPurchaser: planPurchaser
            )
        }

        func transferDialogDependency(_ severity: TransferQuotaSeverity) -> QuotaDialogContentView.Dependency {
            QuotaDialogContentView.Dependency(
                useCase: quotaDialogUseCase,
                mapper: TransferQuotaDialogMapper(severity: severity),
                planPurchaser: planPurchaser
            )
        }
    }
    
    private let dependency: QuotaDialogContentView.Dependency
    private let onClose: @MainActor () -> Void
    private let onViewAllPlans: @MainActor () -> Void

    public init(
        dependency: QuotaWarningDialogView.Dependency,
        kind: Kind,
        onClose: @escaping @MainActor () -> Void,
        onViewAllPlans: @escaping @MainActor () -> Void
    ) {
        self.dependency = switch kind {
        case .storage(let severity):
            dependency.storageDialogDependency(severity)
        case .transfer(let severity):
            dependency.transferDialogDependency(severity)
        }
        self.onClose = onClose
        self.onViewAllPlans = onViewAllPlans
    }
    
    public var body: some View {
        QuotaDialogContentView(
            dependency: dependency,
            onClose: onClose,
            onViewAllPlans: onViewAllPlans
        )
    }
}

#if DEBUG
@MainActor
extension QuotaWarningDialogView.Dependency {
    /// For Preview only.
    init(previewUseCase: PreviewQuotaDialogUseCase) {
        self.quotaDialogUseCase = previewUseCase
        self.planPurchaser = PreviewPlanPurchasing()
    }
}

#Preview("Storage — almost full") {
    QuotaWarningDialogView(
        dependency: .init(previewUseCase: PreviewQuotaDialogUseCase()),
        kind: .storage(.almostFull),
        onClose: {},
        onViewAllPlans: {}
    )
}

#Preview("Storage — full") {
    QuotaWarningDialogView(
        dependency: .init(previewUseCase: PreviewQuotaDialogUseCase()),
        kind: .storage(.full(.storageState)),
        onClose: {},
        onViewAllPlans: {}
    )
}

#Preview("Storage — full, upload attempt") {
    QuotaWarningDialogView(
        dependency: .init(previewUseCase: PreviewQuotaDialogUseCase()),
        kind: .storage(.full(.uploadAttempt)),
        onClose: {},
        onViewAllPlans: {}
    )
}

#Preview("No upgrade") {
    QuotaWarningDialogView(
        dependency: .init(previewUseCase: PreviewQuotaDialogUseCase(plan: nil)),
        kind: .storage(.full(.storageState)),
        onClose: {},
        onViewAllPlans: {}
    )
}

#Preview("Transfer — download exceeded") {
    QuotaWarningDialogView(
        dependency: .init(previewUseCase: PreviewQuotaDialogUseCase()),
        kind: .transfer(.downloadExceeded),
        onClose: {},
        onViewAllPlans: {}
    )
}

#Preview("Transfer — streaming exceeded — dark") {
    QuotaWarningDialogView(
        dependency: .init(previewUseCase: PreviewQuotaDialogUseCase()),
        kind: .transfer(.streamingExceeded),
        onClose: {},
        onViewAllPlans: {}
    )
    .preferredColorScheme(.dark)
}
#endif
