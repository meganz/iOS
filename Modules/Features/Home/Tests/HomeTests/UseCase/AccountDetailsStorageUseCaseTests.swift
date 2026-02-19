import Foundation
import Home
import MEGAAppSDKRepoMock
import MEGADomain
import MEGADomainMock
import MEGASwift
import Testing

@Suite("AccountDetailsStorageUseCase")
struct AccountDetailsStorageUseCaseTests {

    // MARK: - Initial emission

    @Test("storageDetails emits .limited immediately for a standard paid account")
    func storageDetailsEmitsLimitedImmediatelyForPaidAccount() async throws {
        let sut = makeSUT(
            accountDetails: MockMEGAAccountDetails(
                storageUsed: 500,
                storageMax: 1000,
                type: .proI
            ).toAccountDetailsEntity()
        )

        var iterator = sut.storageDetails.makeAsyncIterator()
        let initial = await iterator.next()

        #expect(initial == .limited(500, storageMax: 1000))
    }

    @Test("storageDetails emits .unlimited immediately for a business account")
    func storageDetailsEmitsUnlimitedImmediatelyForBusinessAccount() async throws {
        let sut = makeSUT(
            accountDetails: MockMEGAAccountDetails(
                storageUsed: 200,
                type: .business
            ).toAccountDetailsEntity()
        )

        var iterator = sut.storageDetails.makeAsyncIterator()
        let initial = await iterator.next()

        #expect(initial == .unlimited(200))
    }

    @Test("storageDetails emits .unlimited immediately for a Pro Flexi account")
    func storageDetailsEmitsUnlimitedImmediatelyForProFlexiAccount() async throws {
        let sut = makeSUT(
            accountDetails: MockMEGAAccountDetails(
                storageUsed: 300,
                type: .proFlexi
            ).toAccountDetailsEntity()
        )

        var iterator = sut.storageDetails.makeAsyncIterator()
        let initial = await iterator.next()

        #expect(initial == .unlimited(300))
    }

    @Test("storageDetails emits nil immediately when no account details are available")
    func storageDetailsEmitsNilWhenNoAccountDetails() async throws {
        let sut = makeSUT(accountDetails: nil)

        var iterator = sut.storageDetails.makeAsyncIterator()
        let emission: AccountStorageDetails?? = await iterator.next()
        let initial = try #require(emission, "Expected a value from the sequence, but it ended")

        #expect(initial == nil)
    }

    @Test("storageDetails emits .limited immediately for a free account")
    func storageDetailsEmitsLimitedImmediatelyForFreeAccount() async throws {
        let sut = makeSUT(
            accountDetails: MockMEGAAccountDetails(
                storageUsed: 100,
                storageMax: 20_000,
                type: .free
            ).toAccountDetailsEntity()
        )

        var iterator = sut.storageDetails.makeAsyncIterator()
        let initial = await iterator.next()

        #expect(initial == .limited(100, storageMax: 20_000))
    }

    // MARK: - Reacting to storageSumUpdates

    @Test("storageDetails emits updated .limited when storageSumUpdates fires")
    func storageDetailsEmitsUpdatedLimitedOnStorageSumUpdate() async throws {
        let (storageSumStream, storageSumContinuation) = AsyncStream<Int64>.makeStream()
        let accountUseCase = MockAccountUseCase(
            currentAccountDetails: MockMEGAAccountDetails(
                storageUsed: 100,
                storageMax: 1000,
                type: .proI
            ).toAccountDetailsEntity()
        )
        let sut = makeSUT(
            accountUseCase: accountUseCase,
            storageSumUpdates: storageSumStream.eraseToAnyAsyncSequence()
        )

        var iterator = sut.storageDetails.makeAsyncIterator()
        _ = await iterator.next()   // initial

        accountUseCase.setCurrentAccountDetails(
            MockMEGAAccountDetails(storageUsed: 800, storageMax: 1000, type: .proI).toAccountDetailsEntity()
        )
        storageSumContinuation.yield(800)

        let updated = await iterator.next()
        #expect(updated == .limited(800, storageMax: 1000))
    }

    @Test("storageDetails emits .unlimited when business account storage sum updates")
    func storageDetailsEmitsUnlimitedOnStorageSumUpdateForBusinessAccount() async throws {
        let (storageSumStream, storageSumContinuation) = AsyncStream<Int64>.makeStream()
        let accountUseCase = MockAccountUseCase(
            currentAccountDetails: MockMEGAAccountDetails(
                storageUsed: 200,
                type: .business
            ).toAccountDetailsEntity()
        )
        let sut = makeSUT(
            accountUseCase: accountUseCase,
            storageSumUpdates: storageSumStream.eraseToAnyAsyncSequence()
        )

        var iterator = sut.storageDetails.makeAsyncIterator()
        _ = await iterator.next()   // initial

        accountUseCase.setCurrentAccountDetails(
            MockMEGAAccountDetails(storageUsed: 500, type: .business).toAccountDetailsEntity()
        )
        storageSumContinuation.yield(500)

        let updated = await iterator.next()
        #expect(updated == .unlimited(500))
    }

    @Test("storageDetails emits multiple distinct updates from storageSumUpdates in order")
    func storageDetailsEmitsMultipleUpdatesFromStorageSumUpdates() async throws {
        let (storageSumStream, storageSumContinuation) = AsyncStream<Int64>.makeStream()
        let accountUseCase = MockAccountUseCase(
            currentAccountDetails: MockMEGAAccountDetails(
                storageUsed: 100,
                storageMax: 1000,
                type: .proI
            ).toAccountDetailsEntity()
        )
        let sut = makeSUT(
            accountUseCase: accountUseCase,
            storageSumUpdates: storageSumStream.eraseToAnyAsyncSequence()
        )

        var received: [AccountStorageDetails?] = []
        var iterator = sut.storageDetails.makeAsyncIterator()
        if let first = await iterator.next() { received.append(first) }

        accountUseCase.setCurrentAccountDetails(
            MockMEGAAccountDetails(storageUsed: 400, storageMax: 1000, type: .proI).toAccountDetailsEntity()
        )
        storageSumContinuation.yield(400)
        if let second = await iterator.next() { received.append(second) }

        accountUseCase.setCurrentAccountDetails(
            MockMEGAAccountDetails(storageUsed: 900, storageMax: 1000, type: .proI).toAccountDetailsEntity()
        )
        storageSumContinuation.yield(900)
        if let third = await iterator.next() { received.append(third) }

        #expect(received == [
            .limited(100, storageMax: 1000),
            .limited(400, storageMax: 1000),
            .limited(900, storageMax: 1000)
        ])
    }

    // MARK: - Reacting to onAccountRequestFinish

    @Test("storageDetails emits updated .limited when an accountDetails request finishes")
    func storageDetailsEmitsUpdatedLimitedOnAccountDetailsRequestFinish() async throws {
        let (stream, continuation) = AsyncStream<Result<AccountRequestEntity, any Error>>.makeStream()
        let accountUseCase = MockAccountUseCase(
            currentAccountDetails: MockMEGAAccountDetails(
                storageUsed: 100,
                storageMax: 1000,
                type: .proI
            ).toAccountDetailsEntity(),
            onAccountRequestFinish: stream.eraseToAnyAsyncSequence()
        )
        let sut = makeSUT(accountUseCase: accountUseCase)

        var iterator = sut.storageDetails.makeAsyncIterator()
        _ = await iterator.next()   // initial

        accountUseCase.setCurrentAccountDetails(
            MockMEGAAccountDetails(storageUsed: 800, storageMax: 1000, type: .proI).toAccountDetailsEntity()
        )
        continuation.yield(.success(AccountRequestEntity(type: .accountDetails, file: nil, userAttribute: nil, email: nil)))

        let updated = await iterator.next()
        #expect(updated == .limited(800, storageMax: 1000))
    }

    @Test("storageDetails emits .unlimited when account is upgraded to business after an accountDetails request")
    func storageDetailsEmitsUnlimitedWhenAccountBecomesBusinessAfterUpdate() async throws {
        let (stream, continuation) = AsyncStream<Result<AccountRequestEntity, any Error>>.makeStream()
        let accountUseCase = MockAccountUseCase(
            currentAccountDetails: MockMEGAAccountDetails(
                storageUsed: 200,
                storageMax: 1000,
                type: .proI
            ).toAccountDetailsEntity(),
            onAccountRequestFinish: stream.eraseToAnyAsyncSequence()
        )
        let sut = makeSUT(accountUseCase: accountUseCase)

        var iterator = sut.storageDetails.makeAsyncIterator()
        _ = await iterator.next()   // initial

        accountUseCase.setCurrentAccountDetails(
            MockMEGAAccountDetails(storageUsed: 200, type: .business).toAccountDetailsEntity()
        )
        continuation.yield(.success(AccountRequestEntity(type: .accountDetails, file: nil, userAttribute: nil, email: nil)))

        let updated = await iterator.next()
        #expect(updated == .unlimited(200))
    }

    @Test("storageDetails emits .unlimited when account is upgraded to Pro Flexi after an accountDetails request")
    func storageDetailsEmitsUnlimitedWhenAccountBecomesProFlexiAfterUpdate() async throws {
        let (stream, continuation) = AsyncStream<Result<AccountRequestEntity, any Error>>.makeStream()
        let accountUseCase = MockAccountUseCase(
            currentAccountDetails: MockMEGAAccountDetails(
                storageUsed: 150,
                storageMax: 2000,
                type: .proII
            ).toAccountDetailsEntity(),
            onAccountRequestFinish: stream.eraseToAnyAsyncSequence()
        )
        let sut = makeSUT(accountUseCase: accountUseCase)

        var iterator = sut.storageDetails.makeAsyncIterator()
        _ = await iterator.next()   // initial

        accountUseCase.setCurrentAccountDetails(
            MockMEGAAccountDetails(storageUsed: 150, type: .proFlexi).toAccountDetailsEntity()
        )
        continuation.yield(.success(AccountRequestEntity(type: .accountDetails, file: nil, userAttribute: nil, email: nil)))

        let updated = await iterator.next()
        #expect(updated == .unlimited(150))
    }

    // MARK: - Multiple sequential updates across both triggers

    @Test("storageDetails emits each distinct storage update in order across both triggers")
    func storageDetailsEmitsMultipleDistinctUpdatesAcrossBothTriggers() async throws {
        let (requestStream, requestContinuation) = AsyncStream<Result<AccountRequestEntity, any Error>>.makeStream()
        let (storageSumStream, storageSumContinuation) = AsyncStream<Int64>.makeStream()
        let accountUseCase = MockAccountUseCase(
            currentAccountDetails: MockMEGAAccountDetails(
                storageUsed: 100,
                storageMax: 1000,
                type: .proI
            ).toAccountDetailsEntity(),
            onAccountRequestFinish: requestStream.eraseToAnyAsyncSequence()
        )
        let sut = makeSUT(
            accountUseCase: accountUseCase,
            storageSumUpdates: storageSumStream.eraseToAnyAsyncSequence()
        )

        var received: [AccountStorageDetails?] = []
        var iterator = sut.storageDetails.makeAsyncIterator()
        if let first = await iterator.next() { received.append(first) }

        // Update via storageSumUpdates.
        accountUseCase.setCurrentAccountDetails(
            MockMEGAAccountDetails(storageUsed: 500, storageMax: 1000, type: .proI).toAccountDetailsEntity()
        )
        storageSumContinuation.yield(500)
        if let second = await iterator.next() { received.append(second) }

        // Update via onAccountRequestFinish — account upgraded to business.
        accountUseCase.setCurrentAccountDetails(
            MockMEGAAccountDetails(storageUsed: 500, type: .business).toAccountDetailsEntity()
        )
        requestContinuation.yield(.success(AccountRequestEntity(type: .accountDetails, file: nil, userAttribute: nil, email: nil)))
        if let third = await iterator.next() { received.append(third) }

        #expect(received == [
            .limited(100, storageMax: 1000),
            .limited(500, storageMax: 1000),
            .unlimited(500)
        ])
    }

    // MARK: - Helpers

    private func makeSUT(
        accountDetails: AccountDetailsEntity? = nil,
        onAccountRequestFinish: AnyAsyncSequence<Result<AccountRequestEntity, any Error>> = AsyncStream { _ in }.eraseToAnyAsyncSequence(),
        storageSumUpdates: AnyAsyncSequence<Int64> = AsyncStream { _ in }.eraseToAnyAsyncSequence()
    ) -> AccountDetailsStorageUseCase {
        makeSUT(
            accountUseCase: MockAccountUseCase(
                currentAccountDetails: accountDetails,
                onAccountRequestFinish: onAccountRequestFinish
            ),
            storageSumUpdates: storageSumUpdates
        )
    }

    private func makeSUT(
        accountUseCase: MockAccountUseCase,
        storageSumUpdates: AnyAsyncSequence<Int64> = AsyncStream { _ in }.eraseToAnyAsyncSequence()
    ) -> AccountDetailsStorageUseCase {
        AccountDetailsStorageUseCase(
            accountUseCase: accountUseCase,
            accountStorageUseCase: MockAccountStorageUseCase(storageSumUpdates: storageSumUpdates)
        )
    }
}

// MARK: - Test doubles

private struct MockAccountStorageUseCase: AccountStorageUseCaseProtocol {
    var storageSumUpdates: AnyAsyncSequence<Int64>

    init(storageSumUpdates: AnyAsyncSequence<Int64> = AsyncStream { _ in }.eraseToAnyAsyncSequence()) {
        self.storageSumUpdates = storageSumUpdates
    }

    func willStorageQuotaExceed(after nodes: some Sequence<NodeEntity>) -> Bool { false }
    func refreshCurrentAccountDetails() async throws {}
    func refreshCurrentStorageState() async throws -> StorageStatusEntity? { nil }
    func updateLastStorageBannerDismissDate() {}
    var onStorageStatusUpdates: AnyAsyncSequence<StorageStatusEntity> { AsyncStream { _ in }.eraseToAnyAsyncSequence() }
    var currentStorageStatus: StorageStatusEntity { .noStorageProblems }
    var shouldRefreshStorageStatus: Bool { false }
    var shouldShowStorageBanner: Bool { false }
    var isUnlimitedStorageAccount: Bool { false }
    var isPaywalled: Bool { false }
}
