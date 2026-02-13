import Home
import Foundation
import MEGAAppPresentation
import MEGAAppSDKRepo
import MEGAAppSDKRepoMock
import MEGADomain
import MEGADomainMock
import MEGASwift
import Testing

@Suite("AccountMenuUserNameUseCase")
@MainActor
struct AccountDetailsUserNameUseCaseTests {

    @Test("names emits the current full name immediately on subscription")
    func namesEmitsCurrentNameImmediately() async throws {
        let sut = makeSUT(fullNameHandler: { _ in "Name" })

        var iterator = sut.names.makeAsyncIterator()
        let firstName = await iterator.next()

        #expect(firstName == "Name")
    }

    @Test("names emits an updated name when a firstName attribute request finishes")
    func namesEmitsUpdateOnFirstNameChange() async throws {
        let (stream, continuation) = AsyncStream<Result<AccountRequestEntity, any Error>>.makeStream()
        @Atomic var callCount = 0
        let sut = makeSUT(
            onAccountRequestFinish: stream.eraseToAnyAsyncSequence(),
            fullNameHandler: { _ in
                $callCount.mutate { $0 += 1 }
                return callCount == 1 ? "Old" : "New"
            }
        )

        continuation.yield(.success(AccountRequestEntity(type: .getAttrUser, file: nil, userAttribute: .firstName, email: nil)))

        let name = try await firstValue(after: "Old", from: sut.names)
        #expect(name == "New")
    }

    @Test("names emits an updated name when a lastName attribute request finishes")
    func namesEmitsUpdateOnLastNameChange() async throws {
        let (stream, continuation) = AsyncStream<Result<AccountRequestEntity, any Error>>.makeStream()
        @Atomic var callCount = 0
        let sut = makeSUT(
            onAccountRequestFinish: stream.eraseToAnyAsyncSequence(),
            fullNameHandler: { _ in
                $callCount.mutate { $0 += 1 }
                return callCount == 1 ? "Old" : "New"
            }
        )

        continuation.yield(.success(AccountRequestEntity(type: .getAttrUser, file: nil, userAttribute: .lastName, email: nil)))

        let name = try await firstValue(after: "Old", from: sut.names)
        #expect(name == "New")
    }

    @Test("names does not emit when a non-name attribute request finishes")
    func namesIgnoresIrrelevantRequestTypes() async throws {
        let (stream, continuation) = AsyncStream<Result<AccountRequestEntity, any Error>>.makeStream()
        let sut = makeSUT(
            onAccountRequestFinish: stream.eraseToAnyAsyncSequence(),
            fullNameHandler: { _ in "Old" }
        )

        continuation.yield(.success(AccountRequestEntity(type: .accountDetails, file: nil, userAttribute: nil, email: nil)))

        let didReceiveUpdate = await valueReceived(from: sut.names, after: "Old", timeout: 0.3)
        #expect(didReceiveUpdate == false)
    }

    @Test("names does not emit when request is for a contact attribute (email is not nil)")
    func namesIgnoresContactAttributeRequests() async throws {
        let (stream, continuation) = AsyncStream<Result<AccountRequestEntity, any Error>>.makeStream()
        let sut = makeSUT(
            onAccountRequestFinish: stream.eraseToAnyAsyncSequence(),
            fullNameHandler: { _ in "Old" }
        )

        continuation.yield(.success(AccountRequestEntity(type: .getAttrUser, file: nil, userAttribute: .firstName, email: "contact@example.com")))

        let didReceiveUpdate = await valueReceived(from: sut.names, after: "Old", timeout: 0.3)
        #expect(didReceiveUpdate == false)
    }

    @Test("names does not emit when request finishes with an error")
    func namesIgnoresFailedRequests() async throws {
        let (stream, continuation) = AsyncStream<Result<AccountRequestEntity, any Error>>.makeStream()
        let sut = makeSUT(
            onAccountRequestFinish: stream.eraseToAnyAsyncSequence(),
            fullNameHandler: { _ in "Old" }
        )

        continuation.yield(.failure(MockError()))

        let didReceiveUpdate = await valueReceived(from: sut.names, after: "Old", timeout: 0.3)
        #expect(didReceiveUpdate == false)
    }

    @Test("names does not emit duplicate values")
    func namesRemovesDuplicates() async throws {
        let (stream, continuation) = AsyncStream<Result<AccountRequestEntity, any Error>>.makeStream()
        let sut = makeSUT(
            onAccountRequestFinish: stream.eraseToAnyAsyncSequence(),
            fullNameHandler: { _ in "Old" }  // handler always returns the same name
        )

        continuation.yield(.success(AccountRequestEntity(type: .getAttrUser, file: nil, userAttribute: .firstName, email: nil)))

        let didReceiveUpdate = await valueReceived(from: sut.names, after: "Old", timeout: 0.3)
        #expect(didReceiveUpdate == false)
    }

    @Test("names emits each distinct update in order")
    func namesEmitsMultipleDistinctUpdates() async throws {
        let (stream, continuation) = AsyncStream<Result<AccountRequestEntity, any Error>>.makeStream()
        let names = ["Name1", "Name2", "Name3"]
        @Atomic var index = 0
        let sut = makeSUT(
            onAccountRequestFinish: stream.eraseToAnyAsyncSequence(),
            fullNameHandler: { _ in
                let name = names[min(index, names.count - 1)]
                $index.mutate { $0 += 1 }
                return name
            }
        )

        var received: [String] = []
        var iterator = sut.names.makeAsyncIterator()

        // Initial emission
        if let first = await iterator.next() { received.append(first) }

        // Trigger two more updates
        continuation.yield(.success(AccountRequestEntity(type: .getAttrUser, file: nil, userAttribute: .firstName, email: nil)))
        if let second = await iterator.next() { received.append(second) }

        continuation.yield(.success(AccountRequestEntity(type: .getAttrUser, file: nil, userAttribute: .lastName, email: nil)))
        if let third = await iterator.next() { received.append(third) }

        #expect(received == ["Name1", "Name2", "Name3"])
    }

    // MARK: - Helpers

    private func makeSUT(
        onAccountRequestFinish: AnyAsyncSequence<Result<AccountRequestEntity, any Error>> = AsyncStream<Result<AccountRequestEntity, any Error>> { _ in }.eraseToAnyAsyncSequence(),
        fullNameHandler: @escaping @Sendable (CurrentUserSource) -> String = { _ in "" }
    ) -> AccountDetailsUserNameUseCase {
        AccountDetailsUserNameUseCase(
            currentUserSource: CurrentUserSource(sdk: MockSdk()),
            accountUseCase: MockAccountUseCase(onAccountRequestFinish: onAccountRequestFinish),
            fullNameHandler: fullNameHandler
        )
    }

    /// Waits for the first value emitted after `initialValue`, with a timeout.
    /// Returns the new value, or throws if the timeout is exceeded.
    private func firstValue(
        after initialValue: String,
        from sequence: AnyAsyncSequence<String>,
        timeout: TimeInterval = 2.0
    ) async throws -> String {
        try await withThrowingTaskGroup(of: String?.self) { group in
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
            return try #require(result, "Timed out waiting for a value after '\(initialValue)'")
        }
    }

    /// Returns `true` if a value different from `initialValue` is received before the timeout.
    private func valueReceived(
        from sequence: AnyAsyncSequence<String>,
        after initialValue: String,
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
