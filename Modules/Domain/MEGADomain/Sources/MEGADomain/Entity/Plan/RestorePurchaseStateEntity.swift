public enum RestorePurchaseStateEntity: Equatable, Sendable {
    case success
    case incomplete
    case failed(AccountPlanErrorEntity)
}
