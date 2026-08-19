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
        /// Not a parameter of the public initialiser: production always tracks for real, and only the
        /// in-module preview and QA seams below substitute a tracker that discards events.
        let tracker: any AnalyticsTracking

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
            self.tracker = DIContainer.tracker
        }

        func storageDialogDependency(_ severity: StorageQuotaSeverity) -> QuotaDialogContentView.Dependency {
            QuotaDialogContentView.Dependency(
                useCase: quotaDialogUseCase,
                mapper: StorageQuotaDialogMapper(severity: severity),
                planPurchaser: planPurchaser,
                tracker: tracker
            )
        }

        func transferDialogDependency(_ severity: TransferQuotaSeverity) -> QuotaDialogContentView.Dependency {
            QuotaDialogContentView.Dependency(
                useCase: quotaDialogUseCase,
                mapper: TransferQuotaDialogMapper(severity: severity),
                planPurchaser: planPurchaser,
                tracker: tracker
            )
        }
    }
    
    private let dependency: QuotaDialogContentView.Dependency
    private let kind: Kind
    private let onClose: @MainActor () -> Void
    private let onViewAllPlans: @MainActor () -> Void
    private let onSignIn: @MainActor () -> Void

    /// - Parameter onSignIn: starts the login flow. Only a signed-out viewer can reach it, and both of that
    /// dialog's buttons lead here — there is nothing to purchase without an account.
    public init(
        dependency: QuotaWarningDialogView.Dependency,
        kind: Kind,
        onClose: @escaping @MainActor () -> Void,
        onViewAllPlans: @escaping @MainActor () -> Void,
        onSignIn: @escaping @MainActor () -> Void
    ) {
        self.dependency = switch kind {
        case .storage(let severity):
            dependency.storageDialogDependency(severity)
        case .transfer(let severity):
            dependency.transferDialogDependency(severity)
        }
        self.kind = kind
        self.onClose = onClose
        self.onViewAllPlans = onViewAllPlans
        self.onSignIn = onSignIn
    }
    
    public var body: some View {
        QuotaDialogContentView(
            dependency: dependency,
            kind: kind,
            onClose: onClose,
            onViewAllPlans: onViewAllPlans,
            onSignIn: onSignIn
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
        self.tracker = NoOpAnalyticsTracker()
    }
}

#Preview("Storage — almost full") {
    QuotaWarningDialogView(
        dependency: .init(previewUseCase: PreviewQuotaDialogUseCase()),
        kind: .storage(.almostFull),
        onClose: {},
        onViewAllPlans: {},
        onSignIn: {}
    )
}

#Preview("Storage — full") {
    QuotaWarningDialogView(
        dependency: .init(previewUseCase: PreviewQuotaDialogUseCase()),
        kind: .storage(.full(.storageState)),
        onClose: {},
        onViewAllPlans: {},
        onSignIn: {}
    )
}

#Preview("Storage — full, upload attempt") {
    QuotaWarningDialogView(
        dependency: .init(previewUseCase: PreviewQuotaDialogUseCase()),
        kind: .storage(.full(.uploadAttempt)),
        onClose: {},
        onViewAllPlans: {},
        onSignIn: {}
    )
}

#Preview("No upgrade") {
    QuotaWarningDialogView(
        dependency: .init(previewUseCase: PreviewQuotaDialogUseCase(plan: nil)),
        kind: .storage(.full(.storageState)),
        onClose: {},
        onViewAllPlans: {},
        onSignIn: {}
    )
}

#Preview("Transfer — download exceeded") {
    QuotaWarningDialogView(
        dependency: .init(previewUseCase: PreviewQuotaDialogUseCase()),
        kind: .transfer(.downloadExceeded),
        onClose: {},
        onViewAllPlans: {},
        onSignIn: {}
    )
}

#Preview("Transfer — download exceeded — signed out") {
    QuotaWarningDialogView(
        dependency: .init(previewUseCase: PreviewQuotaDialogUseCase(signedOut: true)),
        kind: .transfer(.downloadExceeded),
        onClose: {},
        onViewAllPlans: {},
        onSignIn: {}
    )
}

#Preview("Transfer — streaming exceeded — dark") {
    QuotaWarningDialogView(
        dependency: .init(previewUseCase: PreviewQuotaDialogUseCase()),
        kind: .transfer(.streamingExceeded),
        onClose: {},
        onViewAllPlans: {},
        onSignIn: {}
    )
    .preferredColorScheme(.dark)
}
#endif
