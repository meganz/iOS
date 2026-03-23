import Foundation
import Home
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

    @Test("names emits the current full name after initialization")
    func namesEmitsCurrentNameImmediately() async throws {
        let sut = makeSUT(userNameProvider: MockUserNameProvider(stubbedDisplayName: "Name"))

        let names = await sut.names
        let name = try await firstNonEmptyValue(from: names)

        #expect(name == "Name")
    }

    @Test("names emits an updated name when a firstName attribute request finishes")
    func namesEmitsUpdateOnFirstNameChange() async throws {
        let (stream, continuation) = AsyncStream<Result<AccountRequestEntity, any Error>>.makeStream()
        @Atomic var callCount = 0
        let sut = makeSUT(
            onAccountRequestFinish: stream.eraseToAnyAsyncSequence(),
            userNameProvider: MockUserNameProvider { _ in
                $callCount.mutate { $0 += 1 }
                return callCount == 1 ? "Old" : "New"
            }
        )

        let names = await sut.names

        // Wait for initial name to be emitted
        _ = try await firstNonEmptyValue(from: names)

        continuation.yield(.success(AccountRequestEntity(type: .getAttrUser, file: nil, userAttribute: .firstName, email: nil)))

        let name = try await firstValue(after: "Old", from: names)
        #expect(name == "New")
    }

    @Test("names emits an updated name when a lastName attribute request finishes")
    func namesEmitsUpdateOnLastNameChange() async throws {
        let (stream, continuation) = AsyncStream<Result<AccountRequestEntity, any Error>>.makeStream()
        @Atomic var callCount = 0
        let sut = makeSUT(
            onAccountRequestFinish: stream.eraseToAnyAsyncSequence(),
            userNameProvider: MockUserNameProvider { _ in
                $callCount.mutate { $0 += 1 }
                return callCount == 1 ? "Old" : "New"
            }
        )

        let names = await sut.names

        // Wait for initial name to be emitted
        _ = try await firstNonEmptyValue(from: names)

        continuation.yield(.success(AccountRequestEntity(type: .getAttrUser, file: nil, userAttribute: .lastName, email: nil)))

        let name = try await firstValue(after: "Old", from: names)
        #expect(name == "New")
    }

    @Test("names does not emit when a non-name attribute request finishes")
    func namesIgnoresIrrelevantRequestTypes() async throws {
        let (stream, continuation) = AsyncStream<Result<AccountRequestEntity, any Error>>.makeStream()
        let sut = makeSUT(
            onAccountRequestFinish: stream.eraseToAnyAsyncSequence(),
            userNameProvider: MockUserNameProvider(stubbedDisplayName: "Old")
        )

        let names = await sut.names

        // Wait for initial name to be emitted
        _ = try await firstNonEmptyValue(from: names)

        continuation.yield(.success(AccountRequestEntity(type: .accountDetails, file: nil, userAttribute: nil, email: nil)))

        let didReceiveUpdate = await valueReceived(from: names, after: "Old", timeout: 0.5)
        #expect(didReceiveUpdate == false)
    }

    @Test("names does not emit when request is for a contact attribute (email is not nil)")
    func namesIgnoresContactAttributeRequests() async throws {
        let (stream, continuation) = AsyncStream<Result<AccountRequestEntity, any Error>>.makeStream()
        let sut = makeSUT(
            onAccountRequestFinish: stream.eraseToAnyAsyncSequence(),
            userNameProvider: MockUserNameProvider(stubbedDisplayName: "Old")
        )

        let names = await sut.names

        // Wait for initial name to be emitted
        _ = try await firstNonEmptyValue(from: names)

        continuation.yield(.success(AccountRequestEntity(type: .getAttrUser, file: nil, userAttribute: .firstName, email: "contact@example.com")))

        let didReceiveUpdate = await valueReceived(from: names, after: "Old", timeout: 0.5)
        #expect(didReceiveUpdate == false)
    }

    @Test("names does not emit when request finishes with an error")
    func namesIgnoresFailedRequests() async throws {
        let (stream, continuation) = AsyncStream<Result<AccountRequestEntity, any Error>>.makeStream()
        let sut = makeSUT(
            onAccountRequestFinish: stream.eraseToAnyAsyncSequence(),
            userNameProvider: MockUserNameProvider(stubbedDisplayName: "Old")
        )

        let names = await sut.names

        // Wait for initial name to be emitted
        _ = try await firstNonEmptyValue(from: names)

        continuation.yield(.failure(MockError()))

        let didReceiveUpdate = await valueReceived(from: names, after: "Old", timeout: 0.5)
        #expect(didReceiveUpdate == false)
    }

    @Test("names does not emit duplicate values")
    func namesRemovesDuplicates() async throws {
        let (stream, continuation) = AsyncStream<Result<AccountRequestEntity, any Error>>.makeStream()
        let sut = makeSUT(
            onAccountRequestFinish: stream.eraseToAnyAsyncSequence(),
            userNameProvider: MockUserNameProvider(stubbedDisplayName: "Old") // provider always returns the same name
        )

        let names = await sut.names

        // Wait for initial name to be emitted
        _ = try await firstNonEmptyValue(from: names)

        continuation.yield(.success(AccountRequestEntity(type: .getAttrUser, file: nil, userAttribute: .firstName, email: nil)))

        let didReceiveUpdate = await valueReceived(from: names, after: "Old", timeout: 0.3)
        #expect(didReceiveUpdate == false)
    }

    @Test("names emits each distinct update in order")
    func namesEmitsMultipleDistinctUpdates() async throws {
        let (stream, continuation) = AsyncStream<Result<AccountRequestEntity, any Error>>.makeStream()
        let expectedNames = ["Name1", "Name2", "Name3"]
        @Atomic var index = 0
        let sut = makeSUT(
            onAccountRequestFinish: stream.eraseToAnyAsyncSequence(),
            userNameProvider: MockUserNameProvider { _ in
                let name = expectedNames[min(index, expectedNames.count - 1)]
                $index.mutate { $0 += 1 }
                return name
            }
        )

        let names = await sut.names
        let received = try await collectNames(
            from: names,
            triggeringUpdates: {
                try? await Task.sleep(nanoseconds: 10_000_000) // 10ms
                continuation.yield(.success(AccountRequestEntity(type: .getAttrUser, file: nil, userAttribute: .firstName, email: nil)))
                try? await Task.sleep(nanoseconds: 10_000_000) // 10ms
                continuation.yield(.success(AccountRequestEntity(type: .getAttrUser, file: nil, userAttribute: .lastName, email: nil)))
            },
            expectedCount: 3
        )

        #expect(received == ["Name1", "Name2", "Name3"])
    }

    @Test("names emits an updated name when a fetchNodes request finishes")
    func namesEmitsUpdateOnFetchNodes() async throws {
        let (stream, continuation) = AsyncStream<Result<AccountRequestEntity, any Error>>.makeStream()
        @Atomic var callCount = 0
        let sut = makeSUT(
            onAccountRequestFinish: stream.eraseToAnyAsyncSequence(),
            userNameProvider: MockUserNameProvider { _ in
                $callCount.mutate { $0 += 1 }
                return callCount == 1 ? "Old" : "New"
            }
        )

        let names = await sut.names

        // Wait for initial name to be emitted
        _ = try await firstNonEmptyValue(from: names)

        continuation.yield(.success(AccountRequestEntity(type: .fetchNodes, file: nil, userAttribute: nil, email: nil)))

        let name = try await firstValue(after: "Old", from: names)
        #expect(name == "New")
    }

    // MARK: - Helpers

    private func makeSUT(
        onAccountRequestFinish: AnyAsyncSequence<Result<AccountRequestEntity, any Error>> = AsyncStream<Result<AccountRequestEntity, any Error>> { _ in }.eraseToAnyAsyncSequence(),
        userNameProvider: MockUserNameProvider = MockUserNameProvider(stubbedDisplayName: "")
    ) -> AccountDetailsUserNameUseCase {
        AccountDetailsUserNameUseCase(
            currentUserSource: CurrentUserSource(sdk: MockSdk(myUser: MockUser(handle: 1))),
            accountUseCase: MockAccountUseCase(onAccountRequestFinish: onAccountRequestFinish),
            userNameProvider: userNameProvider
        )
    }

    /// Waits for the first non-empty value emitted, with a timeout.
    /// Returns the value, or throws if the timeout is exceeded.
    private func firstNonEmptyValue(
        from sequence: AnyAsyncSequence<String>,
        timeout: TimeInterval = 2.0
    ) async throws -> String {
        try await withTimeout(seconds: timeout) {
            for await value in sequence where !value.isEmpty {
                return value
            }
            throw TimedOutError()
        }
    }

    /// Waits for the first value emitted after `initialValue`, with a timeout.
    /// Returns the new value, or throws if the timeout is exceeded.
    private func firstValue(
        after initialValue: String,
        from sequence: AnyAsyncSequence<String>,
        timeout: TimeInterval = 2.0
    ) async throws -> String {
        try await withTimeout(seconds: timeout) {
            for await value in sequence where value != initialValue {
                return value
            }
            throw TimedOutError()
        }
    }

    /// Returns `true` if a value different from `initialValue` is received before the timeout.
    private func valueReceived(
        from sequence: AnyAsyncSequence<String>,
        after initialValue: String,
        timeout: TimeInterval
    ) async -> Bool {
        do {
            _ = try await withTimeout(seconds: timeout) {
                for await value in sequence where value != initialValue {
                    return value
                }
                throw TimedOutError()
            }
            return true
        } catch {
            return false
        }
    }

    /// Collects names from a single iteration, triggering updates after the first value.
    /// Uses a single iterator to avoid the single-consumer AsyncStream issue.
    private func collectNames(
        from sequence: AnyAsyncSequence<String>,
        triggeringUpdates: @Sendable @escaping () async -> Void,
        expectedCount: Int,
        timeout: TimeInterval = 2.0
    ) async throws -> [String] {
        try await withTimeout(seconds: timeout) {
            var collected: [String] = []
            var triggeredUpdates = false
            for await value in sequence {
                guard !value.isEmpty else { continue }
                collected.append(value)
                if !triggeredUpdates {
                    triggeredUpdates = true
                    await triggeringUpdates()
                }
                if collected.count >= expectedCount {
                    return collected
                }
            }
            throw TimedOutError()
        }
    }
}

private struct MockError: Error {}

private final class MockUserNameProvider: UserNameProviderProtocol, @unchecked Sendable {
    private let displayNameHandler: @Sendable (UserEntity) -> String?

    init(stubbedDisplayName: String?) {
        self.displayNameHandler = { _ in stubbedDisplayName }
    }

    init(displayNameHandler: @escaping @Sendable (UserEntity) -> String?) {
        self.displayNameHandler = displayNameHandler
    }

    func displayName(for user: UserEntity) -> String? {
        displayNameHandler(user)
    }
}
