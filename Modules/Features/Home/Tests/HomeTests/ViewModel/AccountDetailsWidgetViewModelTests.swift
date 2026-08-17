@testable import Home
import MEGAAnalyticsiOS
import MEGAAppPresentation
import MEGADesignToken
import MEGADomain
import MEGASwift
import SwiftUI
import Testing

@Suite("AccountDetailsWidgetViewModelTests")
@MainActor
struct AccountDetailsWidgetViewModelTests {

    // MARK: - Color is driven solely by StorageStatusEntity (matches the Usage screen gauge)

    @Test("noStorageProblems is green even when the used fraction is high (>= 0.8)")
    func colorIsSuccessForNoStorageProblemsRegardlessOfFraction() {
        // 85% used but the SDK reports no problems -> must stay green, matching the Usage gauge.
        let sut = makeSUT(storageDetail: .limited(85, storageMax: 100, storageStatus: .noStorageProblems))

        #expect(sut.storageUsedFraction == 0.85) // fraction still computed (drives bar width), just not color
        #expect(sut.storageUsedFractionColor == TokenColors.Support.success.swiftUI)
        #expect(sut.shouldShowUpgrade == false)
    }

    @Test("almostFull is warning")
    func colorIsWarningForAlmostFull() {
        let sut = makeSUT(storageDetail: .limited(50, storageMax: 100, storageStatus: .almostFull))

        #expect(sut.storageUsedFractionColor == TokenColors.Support.warning.swiftUI)
        #expect(sut.shouldShowUpgrade == true)
    }

    @Test("full is error")
    func colorIsErrorForFull() {
        let sut = makeSUT(storageDetail: .limited(100, storageMax: 100, storageStatus: .full))

        #expect(sut.storageUsedFractionColor == TokenColors.Support.error.swiftUI)
        #expect(sut.shouldShowUpgrade == true)
    }

    @Test("missing storage detail defaults to green and hides upgrade")
    func colorIsSuccessWhenStorageDetailIsNil() {
        let sut = makeSUT(storageDetail: nil)

        #expect(sut.storageUsedFractionColor == TokenColors.Support.success.swiftUI)
        #expect(sut.shouldShowUpgrade == false)
    }

    // MARK: - nil clears the widget back to its loading state

    @Test("plan is cleared when the plan sequence emits nil")
    func planIsClearedWhenPlanEmitsNil() async {
        let (stream, continuation) = AsyncStream<AccountTypeEntity?>.makeStream()
        let sut = makeSUT(
            storageDetail: nil,
            planUseCase: StubPlanUseCase(currentPlan: stream.eraseToAnyAsyncSequence())
        )
        sut.plan = "Pro I"

        continuation.yield(nil)
        continuation.finish()
        await sut.onTask()

        #expect(sut.plan == nil)
    }

    @Test("storageDetail is cleared when the storage sequence emits nil")
    func storageDetailIsClearedWhenStorageEmitsNil() async {
        let (stream, continuation) = AsyncStream<AccountStorageDetails?>.makeStream()
        let sut = makeSUT(
            storageDetail: .limited(50, storageMax: 100, storageStatus: .noStorageProblems),
            storageUseCase: StubStorageUseCase(storageDetails: stream.eraseToAnyAsyncSequence())
        )

        continuation.yield(nil)
        continuation.finish()
        await sut.onTask()

        #expect(sut.storageDetail == nil)
    }

    // MARK: - Helpers

    private func makeSUT(
        storageDetail: AccountStorageDetails?,
        planUseCase: StubPlanUseCase = StubPlanUseCase(),
        storageUseCase: StubStorageUseCase = StubStorageUseCase()
    ) -> AccountDetailsWidgetViewModel {
        let sut = AccountDetailsWidgetViewModel(
            dependency: .init(
                userNameUseCase: StubUserNameUseCase(),
                planUseCase: planUseCase,
                storageUseCase: storageUseCase,
                avatarUseCase: StubAvatarUseCase(),
                tracker: StubTracker()
            )
        )
        sut.storageDetail = storageDetail
        return sut
    }
}

// MARK: - Stubs (no mocks exist for these protocols)

/// Sequences default to an already-finished stream so `onTask()` returns instead of hanging on the
/// monitors a given test does not drive.
private func finishedStream<Element>(of type: Element.Type = Element.self) -> AnyAsyncSequence<Element> {
    AsyncStream<Element> { $0.finish() }.eraseToAnyAsyncSequence()
}

private struct StubUserNameUseCase: AccountDetailsUserNameUseCaseProtocol {
    var names: AnyAsyncSequence<String> {
        get async { finishedStream() }
    }
}

private struct StubPlanUseCase: AccountDetailsPlanUseCaseProtocol {
    var currentPlan: AnyAsyncSequence<AccountTypeEntity?> = finishedStream()
}

private struct StubStorageUseCase: AccountDetailsStorageUseCaseProtocol {
    var storageDetails: AnyAsyncSequence<AccountStorageDetails?> = finishedStream()
}

private struct StubAvatarUseCase: AccountDetailsAvatarUseCaseProtocol {
    var avatar: AnyAsyncSequence<Image> = finishedStream()
}

private struct StubTracker: AnalyticsTracking {
    func trackAnalyticsEvent(with eventIdentifier: any EventIdentifier) {}
}
