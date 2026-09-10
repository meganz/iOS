@testable import MEGA
import Testing

/// The shipped timings, which these tests pin by driving the scheduler's own defaults.
private let presentDelay = Duration.seconds(0.8)
private let minimumPresentation = Duration.seconds(1.2)

@MainActor
@Suite("Cancellable transfer alert scheduler", .timeLimit(.minutes(1)))
struct CancellableTransferAlertSchedulerTests {

    // MARK: - Presenting

    @Test(
        "The alert goes on screen only once its wait is over",
        arguments: [
            (presentDelay - .milliseconds(1), 0),
            (presentDelay, 1)
        ]
    )
    func scheduleForPresent(elapsed: Duration, expectedPresentations: Int) async {
        let clock = MockClock()
        let presenter = SpyPresenter()
        let sut = makeSUT(clock: clock, presenter: presenter)

        sut.scheduleForPresent()
        await clock.waitForSleepers()
        clock.advance(by: elapsed)
        await settle()

        #expect(presenter.calledTimes == expectedPresentations)
    }

    /// A second start drops the first wait rather than leaving it to present an alert of its own.
    @Test("Scheduling twice presents once and leaves no stray wait")
    func scheduleForPresentCalledTwice() async {
        let clock = MockClock()
        let presenter = SpyPresenter()
        let sut = makeSUT(clock: clock, presenter: presenter)

        sut.scheduleForPresent()
        sut.scheduleForPresent()
        await clock.waitForSleepers()
        await settle()

        #expect(clock.sleeperCount == 1)

        clock.advance(by: presentDelay)
        await settle()

        #expect(presenter.calledTimes == 1)
    }

    // MARK: - Finishing before the alert appears

    @Test("Finishing before the wait is over reports nothing on screen and never presents")
    func finishBeforeTheWaitIsOver() async {
        let clock = MockClock()
        let presenter = SpyPresenter()
        let sut = makeSUT(clock: clock, presenter: presenter)

        sut.scheduleForPresent()
        await clock.waitForSleepers()
        let isPresented = await sut.finish()
        clock.advance(by: presentDelay)
        await settle()

        #expect(!isPresented)
        #expect(presenter.calledTimes == 0)
    }

    /// Regression: the wait can be over with its continuation still queued when the batch ends.
    /// Nothing may put the alert on screen after that -- there would be nothing left to take it
    /// away, and the user would be stuck behind a modal alert.
    @Test("Finishing with the wait over but the alert not yet up never presents it afterwards")
    func finishWhenTheWaitIsOverButNothingIsOnScreen() async {
        let clock = MockClock()
        let presenter = SpyPresenter()
        let sut = makeSUT(clock: clock, presenter: presenter)

        sut.scheduleForPresent()
        await clock.waitForSleepers()
        clock.advance(by: presentDelay)
        let isPresented = await sut.finish()
        await settle()

        #expect(!isPresented)
        #expect(presenter.calledTimes == 0)
    }

    // MARK: - Finishing once the alert is up

    /// The minimum is time on screen, not time spent finishing: an alert that has already been up
    /// for part of it waits out only what is left of it.
    @Test(
        "Finishing waits out what is left of the alert's minimum time on screen",
        arguments: [Duration.zero, minimumPresentation - .milliseconds(100)]
    )
    func finishWhenPresented(alreadyOnScreen: Duration) async {
        let clock = MockClock()
        let sut = makeSUT(clock: clock, presenter: SpyPresenter())

        await present(sut, clock: clock)
        await clock.waitForSleepers()
        clock.advance(by: alreadyOnScreen)
        await settle()

        let finished = Recorder<Bool>()
        let finishing = Task { finished.value = await sut.finish() }
        await settle()

        #expect(finished.value == nil, "finish returned before the alert had its minimum time on screen")

        clock.advance(by: minimumPresentation - alreadyOnScreen)
        await finishing.value

        #expect(finished.value == true)
    }

    @Test("Finishing once the minimum time has already elapsed reports on screen without waiting")
    func finishWhenTheMinimumTimeHasAlreadyElapsed() async {
        let clock = MockClock()
        let sut = makeSUT(clock: clock, presenter: SpyPresenter())

        await present(sut, clock: clock)
        await clock.waitForSleepers()
        clock.advance(by: minimumPresentation)
        await settle()

        let isPresented = await sut.finish()

        #expect(isPresented)
    }

    /// The view model ends the presentation wherever the flow ends, and a cancel can follow a
    /// state that already ended it. The second call has nothing left to wait for, but the alert
    /// is still up and still has to be taken away.
    @Test("Finishing again once the alert is up still reports it on screen")
    func finishCalledAgainOnceTheAlertIsUp() async {
        let clock = MockClock()
        let sut = makeSUT(clock: clock, presenter: SpyPresenter())

        await present(sut, clock: clock)
        await clock.waitForSleepers()
        clock.advance(by: minimumPresentation)
        await settle()
        _ = await sut.finish()

        let isPresented = await sut.finish()

        #expect(isPresented)
    }

    /// The view model ends the presentation from inside the very task the user's cancel has just
    /// cancelled, so the wait for the alert's minimum time on screen has to outlive that
    /// cancellation -- otherwise a cancel whips the alert away the moment it appears.
    @Test("Finishing from a cancelled task still waits out the alert's minimum time on screen")
    func finishFromACancelledTask() async {
        let clock = MockClock()
        let sut = makeSUT(clock: clock, presenter: SpyPresenter())

        await present(sut, clock: clock)

        let finished = Recorder<Bool>()
        let finishing = Task { finished.value = await sut.finish() }
        finishing.cancel()
        await settle()

        #expect(finished.value == nil, "cancelling the caller cut the alert's time on screen short")

        clock.advance(by: minimumPresentation)
        await finishing.value

        #expect(finished.value == true)
    }

    // MARK: - A single cycle

    @Test("Scheduling once the alert is up does not schedule a second one")
    func scheduleForPresentOnceTheAlertIsUp() async {
        let clock = MockClock()
        let presenter = SpyPresenter()
        let sut = makeSUT(clock: clock, presenter: presenter)

        await present(sut, clock: clock)

        sut.scheduleForPresent()
        await settle()
        clock.advance(by: presentDelay)
        await settle()

        #expect(presenter.calledTimes == 1)
    }

    @Test("Scheduling after finishing does nothing")
    func scheduleForPresentAfterFinish() async {
        let clock = MockClock()
        let presenter = SpyPresenter()
        let sut = makeSUT(clock: clock, presenter: presenter)

        _ = await sut.finish()
        sut.scheduleForPresent()
        await settle()

        #expect(clock.sleeperCount == 0)

        clock.advance(by: presentDelay + minimumPresentation)
        await settle()

        #expect(presenter.calledTimes == 0)
    }

    // MARK: - Going away

    /// A scheduler dropped with its wait still running -- the flow torn down under it -- must not
    /// put an alert on screen afterwards: nothing would be left to take that alert away.
    @Test("A scheduler dropped with its wait still running drops it and never presents")
    func deinitWithTheWaitStillRunning() async {
        let clock = MockClock()
        let presenter = SpyPresenter()
        var sut: CancellableTransferAlertScheduler? = makeSUT(clock: clock, presenter: presenter)

        sut?.scheduleForPresent()
        await clock.waitForSleepers()
        sut = nil
        await settle()

        #expect(clock.sleeperCount == 0, "the wait outlived the scheduler")

        clock.advance(by: presentDelay)
        await settle()

        #expect(presenter.calledTimes == 0)
    }

    // MARK: - The shipped timings

    /// The screen builds the scheduler with its own defaults, so those are what has to work: a real
    /// clock, and the two delays these tests pin everywhere else. A batch that beats the wait --
    /// which is what finishing straight away stands for -- puts nothing on screen.
    @Test("Built with its own defaults it presents nothing when the batch beats the wait")
    func builtWithItsOwnDefaults() async {
        let presenter = SpyPresenter()
        let sut = CancellableTransferAlertScheduler { presenter.calledTimes += 1 }

        sut.scheduleForPresent()
        let isPresented = await sut.finish()

        #expect(!isPresented)
        #expect(presenter.calledTimes == 0)
    }

    // MARK: - Helpers

    /// Runs the scheduler up to the point where the alert is on screen and its minimum time is running.
    private func present(_ sut: CancellableTransferAlertScheduler, clock: MockClock) async {
        sut.scheduleForPresent()
        await clock.waitForSleepers()
        clock.advance(by: presentDelay)
        await settle()
    }

    /// Lets the main-actor work a clock advance released run before the next assertion.
    private func settle(yields: Int = 10) async {
        for _ in 0..<yields {
            await Task.yield()
        }
    }

    private func makeSUT(clock: MockClock, presenter: SpyPresenter) -> CancellableTransferAlertScheduler {
        CancellableTransferAlertScheduler(clock: clock) { presenter.calledTimes += 1 }
    }

    /// Counts how often the scheduler asked for the alert to be put on screen.
    @MainActor
    private final class SpyPresenter {
        var calledTimes = 0
    }

    /// Holds what a `Task` produced, which a test cannot read back through a captured local.
    @MainActor
    private final class Recorder<Value> {
        var value: Value?
    }
}
