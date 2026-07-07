import AsyncAlgorithms
import MEGASwift

// MARK: - Use case protocol

public protocol TransferQuotaUseCaseProtocol: Sendable {
    /// Whether the account is currently over its transfer (bandwidth) quota.
    ///
    /// The SDK reports a non-zero bandwidth over-quota delay (the number of seconds the
    /// user must wait before transfers resume) while over quota, so a delay greater than
    /// zero means the account is over transfer quota.
    var isOverquota: Bool { get }

    /// Emits the transfer over-quota state when it changes, triggered by the SDK reporting
    /// a transfer temporary error caused by the transfer quota being exceeded. Consecutive
    /// duplicate values are filtered out, so observers only see transitions.
    var overquotaUpdates: AnyAsyncSequence<Bool> { get }
}

// MARK: - Use case

public struct TransferQuotaUseCase: TransferQuotaUseCaseProtocol {
    private let accountRepository: any AccountRepositoryProtocol
    private let nodeTransferRepository: any NodeTransferRepositoryProtocol

    public init(
        accountRepository: some AccountRepositoryProtocol,
        nodeTransferRepository: some NodeTransferRepositoryProtocol
    ) {
        self.accountRepository = accountRepository
        self.nodeTransferRepository = nodeTransferRepository
    }

    public var isOverquota: Bool {
        // The SDK exposes no direct "over transfer quota" flag. What it exposes is the number
        // of seconds the account must wait before transfers resume (`bandwidthOverquotaDelay`),
        // which is non-zero exactly while the account is over transfer quota.
        accountRepository.bandwidthOverquotaDelay > 0
    }

    public var overquotaUpdates: AnyAsyncSequence<Bool> {
        // A transfer hitting the bandwidth limit surfaces as a temporary transfer error of type
        // `.quotaExceeded`. That error is only the trigger to re-evaluate: the emitted value
        // re-reads the account-level state exactly as `isOverquota` does, so both APIs share a
        // single source of truth (the SDK's over-quota delay) and can never disagree.
        nodeTransferRepository.transferTemporaryErrorUpdates
            .compactMap { [accountRepository] response -> Bool? in
                guard response.error.type == .quotaExceeded else { return nil }
                return accountRepository.bandwidthOverquotaDelay > 0
            }
            .removeDuplicates()
            .eraseToAnyAsyncSequence()
    }
}
