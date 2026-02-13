import Home
import Foundation
import MEGAAppSDKRepo
import MEGAAppSDKRepoMock
import MEGADomain
import MEGADomainMock
import MEGASwift
import Testing

@Suite("AccountDetailsPlanUseCase")
struct AccountDetailsPlanUseCaseTests {

    // MARK: - Initial emission

    @Test("currentPlan emits the pro level immediately when account details are available")
    func currentPlanEmitsInitialPlanImmediately() async throws {
        let sut = makeSUT(accountDetails: MockMEGAAccountDetails(type: .proI).toAccountDetailsEntity())

        var iterator = sut.currentPlan.makeAsyncIterator()
        let initial = await iterator.next()

        #expect(initial == .proI)
    }

    @Test("currentPlan emits nil immediately when no account details are available")
    func currentPlanEmitsNilWhenNoAccountDetails() async throws {
        let sut = makeSUT(accountDetails: nil)

        var iterator = sut.currentPlan.makeAsyncIterator()
        // iterator.next() returns AccountTypeEntity?? —
        // outer Optional: whether the sequence produced a value (nil = sequence ended)
        // inner Optional: the emitted AccountTypeEntity? payload
        // We unwrap the outer layer with #require, then assert the inner payload is nil.
        let emission: AccountTypeEntity?? = await iterator.next()
        let initial = try #require(emission, "Expected a value from the sequence, but it ended")

        #expect(initial == nil)
    }

    @Test("currentPlan emits business plan level immediately for a business account")
    func currentPlanEmitsBusinessPlanImmediately() async throws {
        let sut = makeSUT(accountDetails: MockMEGAAccountDetails(type: .business).toAccountDetailsEntity())

        var iterator = sut.currentPlan.makeAsyncIterator()
        let initial = await iterator.next()

        #expect(initial == .business)
    }

    @Test("currentPlan emits Pro Flexi plan level immediately for a Pro Flexi account")
    func currentPlanEmitsProFlexiPlanImmediately() async throws {
        let sut = makeSUT(accountDetails: MockMEGAAccountDetails(type: .proFlexi).toAccountDetailsEntity())

        var iterator = sut.currentPlan.makeAsyncIterator()
        let initial = await iterator.next()

        #expect(initial == .proFlexi)
    }

    // MARK: - Reacting to account detail updates

    @Test("currentPlan emits updated plan when an accountDetails request finishes")
    func currentPlanEmitsUpdateOnAccountDetailsRequestFinish() async throws {
        let (stream, continuation) = AsyncStream<Result<AccountRequestEntity, any Error>>.makeStream()
        let accountUseCase = MockAccountUseCase(
            currentAccountDetails: MockMEGAAccountDetails(type: .free).toAccountDetailsEntity(),
            onAccountRequestFinish: stream.eraseToAnyAsyncSequence()
        )
        let sut = AccountDetailsPlanUseCase(accountUseCase: accountUseCase)

        accountUseCase.setCurrentAccountDetails(MockMEGAAccountDetails(type: .proII).toAccountDetailsEntity())
        continuation.yield(.success(AccountRequestEntity(type: .accountDetails, file: nil, userAttribute: nil, email: nil)))

        let updated = try await firstValue(after: .free, from: sut.currentPlan)
        #expect(updated == .proII)
    }

    @Test("currentPlan emits the business plan level when account is upgraded to business after an accountDetails request")
    func currentPlanEmitsBusinessWhenAccountBecomesBusinessAfterUpdate() async throws {
        let (stream, continuation) = AsyncStream<Result<AccountRequestEntity, any Error>>.makeStream()
        let accountUseCase = MockAccountUseCase(
            currentAccountDetails: MockMEGAAccountDetails(type: .proI).toAccountDetailsEntity(),
            onAccountRequestFinish: stream.eraseToAnyAsyncSequence()
        )
        let sut = AccountDetailsPlanUseCase(accountUseCase: accountUseCase)

        accountUseCase.setCurrentAccountDetails(MockMEGAAccountDetails(type: .business).toAccountDetailsEntity())
        continuation.yield(.success(AccountRequestEntity(type: .accountDetails, file: nil, userAttribute: nil, email: nil)))

        let updated = try await firstValue(after: .proI, from: sut.currentPlan)
        #expect(updated == .business)
    }

    // MARK: - Ignoring irrelevant requests

    @Test("currentPlan does not emit when a getAttrUser request finishes")
    func currentPlanIgnoresGetAttrUserRequest() async throws {
        let (stream, continuation) = AsyncStream<Result<AccountRequestEntity, any Error>>.makeStream()
        let sut = makeSUT(
            accountDetails: MockMEGAAccountDetails(type: .proI).toAccountDetailsEntity(),
            onAccountRequestFinish: stream.eraseToAnyAsyncSequence()
        )

        continuation.yield(.success(AccountRequestEntity(type: .getAttrUser, file: nil, userAttribute: .firstName, email: nil)))

        let didReceiveUpdate = await valueReceived(from: sut.currentPlan, after: .proI, timeout: 0.3)
        #expect(didReceiveUpdate == false)
    }

    @Test("currentPlan does not emit when a request finishes with an error")
    func currentPlanIgnoresFailedRequests() async throws {
        let (stream, continuation) = AsyncStream<Result<AccountRequestEntity, any Error>>.makeStream()
        let sut = makeSUT(
            accountDetails: MockMEGAAccountDetails(type: .proI).toAccountDetailsEntity(),
            onAccountRequestFinish: stream.eraseToAnyAsyncSequence()
        )

        continuation.yield(.failure(MockError()))

        let didReceiveUpdate = await valueReceived(from: sut.currentPlan, after: .proI, timeout: 0.3)
        #expect(didReceiveUpdate == false)
    }

    // MARK: - Duplicate suppression

    @Test("currentPlan does not emit when the plan has not changed after an accountDetails request")
    func currentPlanRemovesDuplicates() async throws {
        let (stream, continuation) = AsyncStream<Result<AccountRequestEntity, any Error>>.makeStream()
        let sut = makeSUT(
            accountDetails: MockMEGAAccountDetails(type: .proI).toAccountDetailsEntity(),
            onAccountRequestFinish: stream.eraseToAnyAsyncSequence()
        )

        // Same plan — should be swallowed by removeDuplicates()
        continuation.yield(.success(AccountRequestEntity(type: .accountDetails, file: nil, userAttribute: nil, email: nil)))

        let didReceiveUpdate = await valueReceived(from: sut.currentPlan, after: .proI, timeout: 0.3)
        #expect(didReceiveUpdate == false)
    }

    // MARK: - Multiple sequential updates

    @Test("currentPlan emits each distinct plan update in order")
    func currentPlanEmitsMultipleDistinctUpdates() async throws {
        let (stream, continuation) = AsyncStream<Result<AccountRequestEntity, any Error>>.makeStream()
        let accountUseCase = MockAccountUseCase(
            currentAccountDetails: MockMEGAAccountDetails(type: .free).toAccountDetailsEntity(),
            onAccountRequestFinish: stream.eraseToAnyAsyncSequence()
        )
        let sut = AccountDetailsPlanUseCase(accountUseCase: accountUseCase)

        var received: [AccountTypeEntity?] = []
        var iterator = sut.currentPlan.makeAsyncIterator()

        // Initial value
        if let first = await iterator.next() { received.append(first) }

        // Upgrade to Pro I
        accountUseCase.setCurrentAccountDetails(MockMEGAAccountDetails(type: .proI).toAccountDetailsEntity())
        continuation.yield(.success(AccountRequestEntity(type: .accountDetails, file: nil, userAttribute: nil, email: nil)))
        if let second = await iterator.next() { received.append(second) }

        // Upgrade to Pro III
        accountUseCase.setCurrentAccountDetails(MockMEGAAccountDetails(type: .proIII).toAccountDetailsEntity())
        continuation.yield(.success(AccountRequestEntity(type: .accountDetails, file: nil, userAttribute: nil, email: nil)))
        if let third = await iterator.next() { received.append(third) }

        #expect(received == [.free, .proI, .proIII])
    }

    // MARK: - Helpers

    private func makeSUT(
        accountDetails: AccountDetailsEntity? = nil,
        onAccountRequestFinish: AnyAsyncSequence<Result<AccountRequestEntity, any Error>> = AsyncStream<Result<AccountRequestEntity, any Error>> { _ in }.eraseToAnyAsyncSequence()
    ) -> AccountDetailsPlanUseCase {
        AccountDetailsPlanUseCase(
            accountUseCase: MockAccountUseCase(
                currentAccountDetails: accountDetails,
                onAccountRequestFinish: onAccountRequestFinish
            )
        )
    }

    /// Waits for the first value emitted after `initialValue` within a timeout.
    /// Throws if the timeout is exceeded before a new value arrives.
    private func firstValue(
        after initialValue: AccountTypeEntity?,
        from sequence: AnyAsyncSequence<AccountTypeEntity?>,
        timeout: TimeInterval = 2.0
    ) async throws -> AccountTypeEntity? {
        try await withThrowingTaskGroup(of: AccountTypeEntity??.self) { group in
            group.addTask {
                for await value in sequence where value != initialValue {
                    return value
                }
                return nil
            }
            group.addTask {
                try await Task.sleep(nanoseconds: UInt64(timeout * 1_000_000_000))
                return nil
            }
            let result = try await group.next() ?? nil
            group.cancelAll()
            _ = try #require(result, "Timed out waiting for a value after '\(String(describing: initialValue))'")
            return result ?? nil
        }
    }

    /// Returns `true` if any value different from `initialValue` is received before the timeout elapses.
    private func valueReceived(
        from sequence: AnyAsyncSequence<AccountTypeEntity?>,
        after initialValue: AccountTypeEntity?,
        timeout: TimeInterval
    ) async -> Bool {
        await withTaskGroup(of: Bool.self) { group in
            group.addTask {
                for await value in sequence where value != initialValue {
                    return true
                }
                return false
            }
            group.addTask {
                try? await Task.sleep(nanoseconds: UInt64(timeout * 1_000_000_000))
                return false
            }
            let result = await group.next() ?? false
            group.cancelAll()
            return result
        }
    }
}

private struct MockError: Error {}
