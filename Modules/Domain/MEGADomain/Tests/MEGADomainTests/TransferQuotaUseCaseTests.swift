import Foundation
import MEGADomain
import MEGADomainMock
import MEGASwift
import Testing

@Suite("TransferQuotaUseCase Tests")
struct TransferQuotaUseCaseTests {

    private static func makeSUT(
        bandwidthOverquotaDelay: Int64 = 0,
        temporaryErrorUpdates: AnyAsyncSequence<TransferResponseEntity> = EmptyAsyncSequence().eraseToAnyAsyncSequence()
    ) -> TransferQuotaUseCase {
        TransferQuotaUseCase(
            accountRepository: MockAccountRepository(bandwidthOverquotaDelay: bandwidthOverquotaDelay),
            nodeTransferRepository: MockNodeTransferRepository(transferTemporaryErrorUpdates: temporaryErrorUpdates)
        )
    }

    private static func response(_ errorType: ErrorTypeEntity) -> TransferResponseEntity {
        TransferResponseEntity(transferEntity: TransferEntity(type: .download), error: ErrorEntity(type: errorType))
    }

    @Test("isOverquota is true when the bandwidth over-quota delay is non-zero")
    func isOverquotaWhenDelayPositive() {
        #expect(Self.makeSUT(bandwidthOverquotaDelay: 42).isOverquota)
    }

    @Test("isOverquota is false when the bandwidth over-quota delay is zero")
    func isNotOverquotaWhenNoDelay() {
        #expect(Self.makeSUT(bandwidthOverquotaDelay: 0).isOverquota == false)
    }

    @Test("overquotaUpdates emits only for quota-exceeded temporary errors")
    func overquotaUpdatesFiltersToQuotaExceeded() async {
        let updates = [
            Self.response(.tryAgain),
            Self.response(.quotaExceeded),
            Self.response(.ok)
        ].async.eraseToAnyAsyncSequence()
        let sut = Self.makeSUT(bandwidthOverquotaDelay: 60, temporaryErrorUpdates: updates)

        var received: [Bool] = []
        for await isOverquota in sut.overquotaUpdates {
            received.append(isOverquota)
        }

        #expect(received == [true])
    }

    @Test("overquotaUpdates collapses repeated identical states into one emission")
    func overquotaUpdatesRemovesConsecutiveDuplicates() async {
        let updates = [
            Self.response(.quotaExceeded),
            Self.response(.quotaExceeded),
            Self.response(.quotaExceeded)
        ].async.eraseToAnyAsyncSequence()
        let sut = Self.makeSUT(bandwidthOverquotaDelay: 60, temporaryErrorUpdates: updates)

        var received: [Bool] = []
        for await isOverquota in sut.overquotaUpdates {
            received.append(isOverquota)
        }

        #expect(received == [true])
    }
}
