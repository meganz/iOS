import MEGADomain

protocol AppLoadingRepositoryProtocol: RepositoryProtocol, Sendable {
    var waitingReason: WaitingReasonEntity { get }
}
