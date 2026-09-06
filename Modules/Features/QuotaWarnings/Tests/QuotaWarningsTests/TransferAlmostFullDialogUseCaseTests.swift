import Foundation
import MEGADomain
import MEGASwift
@testable import QuotaWarnings
import Testing

@Suite("TransferAlmostFullDialogUseCaseTests")
struct TransferAlmostFullDialogUseCaseTests {
    typealias Activity = TransferAlmostFullDialogUseCase.TransferQuotaActivity

    private func makeSUT(
        states: [TransferQuotaStateEntity],
        activity: Activity = .download,
        allowanceLimit: Int = .max,
        isPresented: Bool = true
    ) -> (TransferAlmostFullDialogUseCase, MockDialogAllowance, PresentationSpy) {
        let allowance = MockDialogAllowance(dailyLimit: allowanceLimit)
        let spy = PresentationSpy(isPresented: isPresented)
        let sut = TransferAlmostFullDialogUseCase(
            stateProvider: MockTransferQuotaStateProvider(states: states),
            allowance: allowance,
            activity: activity,
            presentDialog: { severity in spy.present(severity) }
        )
        return (sut, allowance, spy)
    }

    /// Both triggers are this one use case, told apart only by the activity they monitor — the download
    /// prediction and the state a streaming read raises behave identically from here on, differing only
    /// in the severity each maps to for the presenter.
    @Test("Presents its own trigger's dialog for an orange state",
          arguments: [
            (Activity.download, TransferQuotaSeverity.limitedDownload),
            (Activity.streaming, TransferQuotaSeverity.limitedStreaming)
          ])
    func presentsForOrange(activity: Activity, expectedSeverity: TransferQuotaSeverity) async {
        let (sut, _, spy) = makeSUT(states: [.orange], activity: activity)

        await sut.monitorTransferQuotaState()

        #expect(spy.presentedSeverities == [expectedSeverity])
    }

    @Test("Ignores every state other than orange",
          arguments: [TransferQuotaStateEntity.green, .red])
    func ignoresOtherStates(state: TransferQuotaStateEntity) async {
        let (sut, allowance, spy) = makeSUT(states: [state])

        await sut.monitorTransferQuotaState()

        #expect(spy.presentedSeverities.isEmpty)
        #expect(allowance.consumeCallCount == 0)
    }

    @Test("Spends the day's allowance once the dialog was presented")
    func consumesWhenPresented() async {
        let (sut, allowance, _) = makeSUT(states: [.orange])

        await sut.monitorTransferQuotaState()

        #expect(allowance.consumeCallCount == 1)
    }

    /// The allowance is re-read for every state, not once per monitoring session: an orange state keeps
    /// raising the dialog while the day's budget lasts, and stops raising it the moment the budget is gone.
    @Test("Presents once per orange state until the day's allowance runs out")
    func presentsUntilTheDailyAllowanceIsSpent() async {
        let (sut, allowance, spy) = makeSUT(states: [.orange, .orange, .orange], allowanceLimit: 2)

        await sut.monitorTransferQuotaState()

        #expect(spy.presentedSeverities == [.limitedDownload, .limitedDownload])
        #expect(allowance.consumeCallCount == 2)
    }

    @Test("Does not spend the allowance when the presenter refused to present")
    func doesNotConsumeWhenPresentationRefused() async {
        let (sut, allowance, spy) = makeSUT(states: [.orange], activity: .download, isPresented: false)

        await sut.monitorTransferQuotaState()

        #expect(spy.presentedSeverities == [.limitedDownload])
        #expect(allowance.consumeCallCount == 0)
    }

    @Test("Does not even attempt to present once the allowance is spent")
    func doesNotPresentWhenAllowanceSpent() async {
        let (sut, _, spy) = makeSUT(states: [.orange], activity: .streaming, allowanceLimit: 0)

        await sut.monitorTransferQuotaState()

        #expect(spy.presentedSeverities.isEmpty)
    }

    @Test("Keeps monitoring after a state that warrants no dialog")
    func keepsMonitoringAfterIgnoredStates() async {
        let (sut, _, spy) = makeSUT(states: [.green, .orange], activity: .streaming)

        await sut.monitorTransferQuotaState()

        #expect(spy.presentedSeverities == [.limitedStreaming])
    }

    @Test("Stops monitoring when the owning task is cancelled")
    func stopsWhenCancelled() async {
        let (sut, _, spy) = makeSUT(states: [.orange, .orange])
        let task = Task { await sut.monitorTransferQuotaState() }
        task.cancel()

        await task.value

        #expect(spy.presentedSeverities.count <= 1)
    }
}

/// Records what the app target's presenter was asked to present, and answers with a fixed outcome.
private final class PresentationSpy: @unchecked Sendable {
    private let isPresented: Bool
    private let lock = NSLock()
    private var severities: [TransferQuotaSeverity] = []

    var presentedSeverities: [TransferQuotaSeverity] {
        lock.withLock { severities }
    }

    init(isPresented: Bool) {
        self.isPresented = isPresented
    }

    func present(_ severity: TransferQuotaSeverity) -> Bool {
        lock.withLock { severities.append(severity) }
        return isPresented
    }
}

/// Mirrors `DailyDialogAllowance`: available until the day's budget has been spent.
private final class MockDialogAllowance: DialogDisplayAllowance, @unchecked Sendable {
    private let dailyLimit: Int
    private let lock = NSLock()
    private var consumeCount = 0

    var isAvailable: Bool {
        lock.withLock { consumeCount < dailyLimit }
    }

    var consumeCallCount: Int {
        lock.withLock { consumeCount }
    }

    init(dailyLimit: Int) {
        self.dailyLimit = dailyLimit
    }

    func consume() {
        lock.withLock { consumeCount += 1 }
    }
}

private struct MockTransferQuotaStateProvider: TransferQuotaStateProviding {
    private let values: [TransferQuotaStateEntity]

    init(states: [TransferQuotaStateEntity]) {
        self.values = states
    }

    /// Finishes once the given states have been delivered, so `monitorTransferQuotaState()` returns
    /// instead of suspending forever the way the production stream does.
    var states: AnyAsyncSequence<TransferQuotaStateEntity> {
        let values = values
        return AsyncStream { continuation in
            values.forEach { continuation.yield($0) }
            continuation.finish()
        }.eraseToAnyAsyncSequence()
    }
}
