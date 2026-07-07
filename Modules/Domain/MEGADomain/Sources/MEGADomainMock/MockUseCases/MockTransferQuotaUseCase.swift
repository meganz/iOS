import MEGADomain
import MEGASwift

public final class MockTransferQuotaUseCase: TransferQuotaUseCaseProtocol {
    private let overquotaSubject = AsyncStream<Bool>.makeStream()
    private let injectedUpdates: AnyAsyncSequence<Bool>?

    public let isOverquota: Bool

    public var overquotaUpdates: AnyAsyncSequence<Bool> {
        injectedUpdates ?? overquotaSubject.stream.eraseToAnyAsyncSequence()
    }

    public init(
        isOverquota: Bool = false,
        overquotaUpdates: AnyAsyncSequence<Bool>? = nil
    ) {
        self.isOverquota = isOverquota
        self.injectedUpdates = overquotaUpdates
    }

    public func triggerOverquotaUpdate(_ isOverquota: Bool) {
        overquotaSubject.continuation.yield(isOverquota)
    }
}
