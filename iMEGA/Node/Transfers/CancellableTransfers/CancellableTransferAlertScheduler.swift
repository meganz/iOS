import Foundation
import MEGAFoundation

/// For folder transfer, it is under a folder scanning and folder creation process which could takes time.
/// In such case, an alert could be presented showing the progress of that process, and a button for cancelling the transfers
///
/// This CancellableTransferAlertScheduling encapsulate the logic that decides when the cancellable transfer alert is presented and when it may be dismissed
@MainActor
protocol CancellableTransferAlertScheduling {
    /// Starts the wait after which the alert is shown, unless the batch transfer have started transferring first.
    func scheduleForPresent()

    /// Ends the presentation:
    /// - Do not present an alert that has not appeared yet, or
    /// - Once it is presented, ensure it is kept showing for a configured minimum of time before being dismissed
    ///
    /// - Returns: Whether the alert is being presented
    func finish() async -> Bool
}

@MainActor
final class CancellableTransferAlertScheduler: CancellableTransferAlertScheduling {
    private let clock: any Clock<Duration>
    /// The time to delay once `scheduleForPresent` is called.
    /// After this delay, if the batch transfer has not started transferring yet, the alert will be shown by the passed `presentHandler`
    private let presentDelay: Duration
    /// The minium duration of time that the alert stays showing once shown
    /// So it means the duration an alert is shown is the maximum of:
    /// - The time the batch transfer takes for all its files started transferring
    /// - This `minimumPresentation`
    private let minimumPresentation: Duration
    private let presentHandler: @MainActor () -> Void

    private var isPresented = false
    private var isFinished = false
    private var presentTask: Task<Void, any Error>?
    private var minimumPresentationTask: Task<Void, Never>?

    init(
        clock: any Clock<Duration> = ContinuousClock(),
        presentDelay: Duration = .seconds(0.8),
        minimumPresentation: Duration = .seconds(1.2),
        presentHandler: @escaping @MainActor () -> Void
    ) {
        self.clock = clock
        self.presentDelay = presentDelay
        self.minimumPresentation = minimumPresentation
        self.presentHandler = presentHandler
    }

    deinit {
        presentTask?.cancel()
        minimumPresentationTask?.cancel()
    }

    func scheduleForPresent() {
        guard !isPresented, !isFinished else {
            MEGALog.log(
                level: .debug,
                message: "[CancellableTransfer] alert not scheduled, cycle already over (isPresented: \(isPresented), isFinished: \(isFinished))"
            )
            return
        }

        MEGALog.log(level: .debug, message: "[CancellableTransfer] alert scheduled, presenting in \(presentDelay)")

        presentTask?.cancel()
        presentTask = Task { [weak self, clock, presentDelay] in
            try await clock.sleep(for: presentDelay)
            self?.present()
        }
    }

    /// Await the `minimumPresentationTask` before returning
    /// to ensure the minium duration of time that the alert stays showing
    func finish() async -> Bool {
        MEGALog.log(
            level: .debug,
            message: "[CancellableTransfer] alert finishing (isPresented: \(isPresented), isFinished: \(isFinished))"
        )
        presentTask?.cancel()
        presentTask = nil
        isFinished = true

        guard isPresented else { return false }

        MEGALog.log(level: .debug, message: "[CancellableTransfer] alert waiting out its minimum presentation")
        await minimumPresentationTask?.value
        minimumPresentationTask = nil
        MEGALog.log(level: .debug, message: "[CancellableTransfer] alert ready to be dismissed")
        return true
    }

    /// Presents the alert and starts its minimum time there with `minimumPresentationTask`.
    ///
    /// The batch transfer can have its files started transferring before or after this time
    /// In either case, the `finish()` is called and ended up awaitng the `minimumPresentationTask` before returning
    private func present() {
        guard !isFinished else {
            MEGALog.log(level: .debug, message: "[CancellableTransfer] alert presentation skipped, the cycle is over")
            return
        }
        MEGALog.log(level: .debug, message: "[CancellableTransfer] alert presenting")
        isPresented = true
        presentHandler()
        minimumPresentationTask = Task { [clock, minimumPresentation] in
            try? await clock.sleep(for: minimumPresentation)
        }
    }
}
