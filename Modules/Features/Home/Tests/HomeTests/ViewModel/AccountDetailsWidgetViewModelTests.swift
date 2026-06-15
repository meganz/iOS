import MEGAAnalyticsiOS
import MEGAAppPresentation
import MEGADesignToken
import MEGADomain
import MEGASwift
import SwiftUI
import Testing
@testable import Home

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

    // MARK: - Helpers

    private func makeSUT(storageDetail: AccountStorageDetails?) -> AccountDetailsWidgetViewModel {
        let sut = AccountDetailsWidgetViewModel(
            dependency: .init(
                userNameUseCase: StubUserNameUseCase(),
                planUseCase: StubPlanUseCase(),
                storageUseCase: StubStorageUseCase(),
                avatarUseCase: StubAvatarUseCase(),
                tracker: StubTracker()
            )
        )
        sut.storageDetail = storageDetail
        return sut
    }
}

// MARK: - Stubs (no mocks exist for these protocols; sequences are never iterated in these tests)

private struct StubUserNameUseCase: AccountDetailsUserNameUseCaseProtocol {
    var names: AnyAsyncSequence<String> {
        get async { AsyncStream<String> { _ in }.eraseToAnyAsyncSequence() }
    }
}

private struct StubPlanUseCase: AccountDetailsPlanUseCaseProtocol {
    var currentPlan: AnyAsyncSequence<AccountTypeEntity?> {
        AsyncStream<AccountTypeEntity?> { _ in }.eraseToAnyAsyncSequence()
    }
}

private struct StubStorageUseCase: AccountDetailsStorageUseCaseProtocol {
    var storageDetails: AnyAsyncSequence<AccountStorageDetails?> {
        AsyncStream<AccountStorageDetails?> { _ in }.eraseToAnyAsyncSequence()
    }
}

private struct StubAvatarUseCase: AccountDetailsAvatarUseCaseProtocol {
    var avatar: AnyAsyncSequence<Image> {
        AsyncStream<Image> { _ in }.eraseToAnyAsyncSequence()
    }
}

private struct StubTracker: AnalyticsTracking {
    func trackAnalyticsEvent(with eventIdentifier: any EventIdentifier) {}
}
