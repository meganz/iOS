import MEGADomain
import SwiftUI

public enum StorageQuotaSeverity: Equatable, Sendable {
    case almostFull
    case full
}

public enum TransferQuotaSeverity: Equatable, Sendable {
    case limitedDownload
    case downloadExceeded
    case streamingExceeded
}

public struct QuotaWarningDialogView: View {
    public enum Kind {
        case storage(StorageQuotaSeverity)
        case transfer(TransferQuotaSeverity)
    }
    
    public struct Dependency {
        let quotaDialogUseCase: any QuotaDialogUseCaseProtocol
        
        public init(accountPlanPurchaseUseCase: any AccountPlanPurchaseUseCaseProtocol) {
            self.quotaDialogUseCase = QuotaDialogUseCaseFactory.make(accountPlanPurchaseUseCase: accountPlanPurchaseUseCase)
        }
        
        func storageDialogDependency(_ severity: StorageQuotaSeverity) -> QuotaDialogContentView.Dependency {
            QuotaDialogContentView.Dependency(
                useCase: quotaDialogUseCase,
                mapper: StorageQuotaDialogMapper(severity: severity)
            )
        }
        
        func transferDialogDependency(_ severity: TransferQuotaSeverity) -> QuotaDialogContentView.Dependency {
            QuotaDialogContentView.Dependency(
                useCase: quotaDialogUseCase,
                mapper: TransferQuotaDialogMapper(severity: severity)
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
extension QuotaWarningDialogView.Dependency {
    /// For Preview only.
    init(previewUseCase: PreviewQuotaDialogUseCase) {
        self.quotaDialogUseCase = previewUseCase
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
        kind: .storage(.full),
        onClose: {},
        onViewAllPlans: {}
    )
}

#Preview("No upgrade") {
    QuotaWarningDialogView(
        dependency: .init(previewUseCase: PreviewQuotaDialogUseCase(plan: nil)),
        kind: .storage(.full),
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
