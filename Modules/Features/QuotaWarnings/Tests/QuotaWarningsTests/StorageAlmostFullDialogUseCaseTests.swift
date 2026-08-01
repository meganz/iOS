import Foundation
import MEGADomain
import MEGASwift
@testable import QuotaWarnings
import Testing

@Suite("StorageAlmostFullDialogUseCaseTests")
struct StorageAlmostFullDialogUseCaseTests {
    private func makeSUT(
        storageState: StorageStatusEntity? = .almostFull,
        refreshError: (any Error)? = nil,
        isAllowanceAvailable: Bool = true
    ) -> (StorageAlmostFullDialogUseCase, MockAccountStorage, MockAllowance) {
        let accountStorageUseCase = MockAccountStorage(storageState: storageState, refreshError: refreshError)
        let allowance = MockAllowance(isAvailable: isAllowanceAvailable)
        let sut = StorageAlmostFullDialogUseCase(
            accountStorageUseCase: accountStorageUseCase,
            allowance: allowance
        )
        return (sut, accountStorageUseCase, allowance)
    }

    @Test("Shows the dialog when the allowance is available and the account is almost full")
    func showsWhenAlmostFull() async throws {
        let (sut, _, _) = makeSUT(storageState: .almostFull)

        #expect(try await sut.shouldShowDialog())
    }

    @Test("Does not show the dialog when the account is not almost full",
          arguments: [StorageStatusEntity.noStorageProblems, .full])
    func doesNotShowForOtherStates(storageState: StorageStatusEntity) async throws {
        let (sut, _, _) = makeSUT(storageState: storageState)

        #expect(try await sut.shouldShowDialog() == false)
    }

    @Test("Does not show the dialog when the storage state is unknown")
    func doesNotShowForUnknownState() async throws {
        let (sut, _, _) = makeSUT(storageState: nil)

        #expect(try await sut.shouldShowDialog() == false)
    }

    @Test("Does not show the dialog, or ask for the storage state, once the allowance is spent")
    func doesNotShowOrRefreshWhenAllowanceSpent() async throws {
        let (sut, accountStorage, _) = makeSUT(storageState: .almostFull, isAllowanceAvailable: false)

        #expect(try await sut.shouldShowDialog() == false)
        #expect(accountStorage.refreshCallCount == 0)
    }

    @Test("Rethrows a storage state refresh failure")
    func rethrowsRefreshFailure() async {
        let (sut, _, _) = makeSUT(refreshError: MockError.refreshFailed)

        await #expect(throws: MockError.refreshFailed) {
            try await sut.shouldShowDialog()
        }
    }

    @Test("Deciding to show does not spend the allowance on its own")
    func decidingDoesNotConsume() async throws {
        let (sut, _, allowance) = makeSUT(storageState: .almostFull)

        _ = try await sut.shouldShowDialog()

        #expect(allowance.consumeCallCount == 0)
    }

    @Test("Recording a presentation spends the allowance exactly once")
    func recordingConsumesOnce() {
        let (sut, _, allowance) = makeSUT()

        sut.recordDialogShown()

        #expect(allowance.consumeCallCount == 1)
    }
}

private enum MockError: Error {
    case refreshFailed
}

private final class MockAllowance: DialogDisplayAllowance, @unchecked Sendable {
    let isAvailable: Bool
    private(set) var consumeCallCount = 0

    init(isAvailable: Bool) {
        self.isAvailable = isAvailable
    }

    func consume() {
        consumeCallCount += 1
    }
}

/// A local double rather than `MEGADomainMock.MockAccountStorageUseCase`, which cannot count refresh
/// calls or inject a failure.
private final class MockAccountStorage: AccountStorageUseCaseProtocol, @unchecked Sendable {
    private let storageState: StorageStatusEntity?
    private let refreshError: (any Error)?
    private(set) var refreshCallCount = 0

    init(storageState: StorageStatusEntity?, refreshError: (any Error)?) {
        self.storageState = storageState
        self.refreshError = refreshError
    }

    func refreshCurrentStorageState() async throws -> StorageStatusEntity? {
        refreshCallCount += 1
        if let refreshError { throw refreshError }
        return storageState
    }

    // MARK: - Unused by this use case

    var onStorageStatusUpdates: AnyAsyncSequence<StorageStatusEntity> {
        EmptyAsyncSequence().eraseToAnyAsyncSequence()
    }
    var storageSumUpdates: AnyAsyncSequence<Int64> { EmptyAsyncSequence().eraseToAnyAsyncSequence() }
    var currentStorageStatus: StorageStatusEntity { storageState ?? .noStorageProblems }
    var shouldRefreshStorageStatus: Bool { false }
    var shouldShowStorageBanner: Bool { false }
    var isUnlimitedStorageAccount: Bool { false }
    var isPaywalled: Bool { false }

    func willStorageQuotaExceed(after nodes: some Sequence<NodeEntity>) -> Bool { false }
    func refreshCurrentAccountDetails() async throws {}
    func updateLastStorageBannerDismissDate() {}
}
