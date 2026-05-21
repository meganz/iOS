import ActivityKit
@preconcurrency import Combine
import Foundation
import MEGAAppSDKRepo
import MEGAL10n
import MEGASwift

@available(iOS 16.2, *)
@MainActor
final class TransferLiveActivityManager {

    private let activityProvider: any TransferLiveActivityProviding
    private var cancellable: AnyCancellable?

    private var activityId: String?
    private var lastPushedState: TransferLiveActivityState?
    private var lastContentState: TransferLiveActivityAttributes.ContentState?

    private var endActivityTask: Task<Void, Never>? {
        didSet { oldValue?.cancel() }
    }
    private var updateTask: Task<Void, Never>? {
        didSet { oldValue?.cancel() }
    }
    private var stateObservationTask: Task<Void, Never>? {
        didSet { oldValue?.cancel() }
    }

    private var lastUpdateTime: ContinuousClock.Instant?
    private static let minimumUpdateInterval: Duration = .seconds(1)

    /// True between the moment the AppDelegate expiration handler pushes a
    /// `.suspended` frame and the moment the app returns to foreground. While
    /// set, `handleSnapshot` defers processing (and stores the latest snapshot
    /// in `latestSnapshotWhileLocked`) so the ~5s of remaining background time
    /// can't overwrite the suspended frame with stale active snapshots. Cleared
    /// by `clearSuspendedLock` (called from `applicationDidBecomeActive`) or by
    /// `reset` when the activity ends externally.
    private var isSuspendedFrameLocked = false

    /// The latest snapshot received from the publisher while the lock was
    /// active. Replayed by `clearSuspendedLock` so transfers that completed,
    /// errored, or progressed during the brief grace window before iOS
    /// suspended us are reflected the moment the user foregrounds.
    ///
    /// `.empty` means nothing was buffered. `.received(nil)` means the publisher
    /// emitted `nil` while locked (which `handleSnapshot` treats as "no active
    /// transfers, schedule end activity"), and must be distinguished from
    /// `.empty` so the replay still triggers the end-activity path.
    private enum BufferedSnapshot {
        case empty
        case received(TransferStatusSnapshot?)
    }
    private var latestSnapshotWhileLocked: BufferedSnapshot = .empty

    init(activityProvider: some TransferLiveActivityProviding) {
        self.activityProvider = activityProvider
    }

    deinit {
        cancellable?.cancel()
        endActivityTask?.cancel()
        updateTask?.cancel()
        stateObservationTask?.cancel()
    }

    func startMonitoring(snapshotPublisher: AnyPublisher<TransferStatusSnapshot?, Never>) {
        adoptExistingActivity()
        cancellable = snapshotPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] snapshot in
                self?.handleSnapshot(snapshot)
            }
    }

    private func adoptExistingActivity() {
        guard activityId == nil, let existingId = activityProvider.activeActivityId else { return }
        activityId = existingId
        observeActivityState(id: existingId)
    }

    func stopMonitoring() {
        cancellable?.cancel()
        cancellable = nil
        endActivityTask = nil
        endActivityImmediately()
    }

    // MARK: - Snapshot Handling

    /// Projects the latest transfer snapshot onto the live activity.
    ///
    /// `.error` and `.overquota` are deliberately not treated as terminal here —
    /// they fall through to the update path and the activity persists on the lock
    /// screen until either the tracker clears the terminal state (snapshot goes
    /// nil → `scheduleEndActivity`) or iOS's ~8h system cap expires. This mirrors
    /// `TransferIndicatorViewModel`'s behavior of keeping the in-app indicator
    /// visible on warning/error states so the user has a persistent surface to
    /// resolve the failure from.
    private func handleSnapshot(_ snapshot: TransferStatusSnapshot?) {
        if isSuspendedFrameLocked {
            latestSnapshotWhileLocked = .received(snapshot)
            return
        }

        guard let snapshot else {
            if activityId != nil, endActivityTask == nil {
                scheduleEndActivity()
            }
            return
        }

        let contentState = Self.makeContentState(from: snapshot)
        lastContentState = contentState

        if snapshot.isCompleted {
            guard activityId != nil else { return }
            lastPushedState = contentState.state
            pushUpdate(contentState)
            scheduleEndActivity()
            return
        }

        endActivityTask?.cancel()
        endActivityTask = nil

        startActivity(with: contentState)

        let isStateChange = contentState.state != lastPushedState
        lastPushedState = contentState.state

        if isStateChange {
            pushUpdate(contentState)
        } else {
            pushUpdateThrottled(contentState)
        }
    }

    /// Called from the AppDelegate background-task expiration handler. Replaces
    /// the last pushed active or user-paused state with a `.suspended` frame so
    /// the Lock Screen LA stops showing data that's about to become stale once
    /// iOS suspends the process. No-op when the LA is not running or when the
    /// last pushed state is terminal or warning (`.error`, `.overquota`,
    /// `.completed`) which the user expects to see preserved.
    func pushSuspendedState() {
        guard activityId != nil,
              let lastContentState,
              lastContentState.state == .active || lastContentState.state == .paused else { return }

        let suspendedState = TransferLiveActivityAttributes.ContentState(
            progressFraction: lastContentState.progressFraction,
            state: .suspended,
            direction: lastContentState.direction,
            statusText: Self.makeStatusText(state: .suspended, direction: lastContentState.direction),
            percentageText: lastContentState.percentageText,
            fileCountText: lastContentState.fileCountText,
            formattedSpeed: Self.makeFormattedSpeed(for: .suspended, bytesPerSecond: 0)
        )
        lastPushedState = .suspended
        self.lastContentState = suspendedState
        isSuspendedFrameLocked = true
        // No staleDate: the suspended frame is the final word until the user
        // foregrounds. Marking it stale 30s later would deprioritize it in the
        // system's activity ordering and risk earlier dismissal under pressure.
        pushUpdate(suspendedState, staleDate: nil)
    }

    /// Clears the suspended-frame lock so the snapshot publisher can resume
    /// driving the activity. Called by the AppDelegate when the app returns to
    /// foreground.
    func clearSuspendedLock() {
        isSuspendedFrameLocked = false
        switch latestSnapshotWhileLocked {
        case .empty:
            return
        case .received(let snapshot):
            latestSnapshotWhileLocked = .empty
            handleSnapshot(snapshot)
        }
    }

    // MARK: - Activity Lifecycle

    private func startActivity(with state: TransferLiveActivityAttributes.ContentState) {
        guard activityId == nil,
              activityProvider.areActivitiesEnabled,
              !activityProvider.hasActiveActivity else {
            return
        }
        let newId: String
        do {
            newId = try activityProvider.request(initialState: state)
        } catch {
            MEGALogError("[Transfer Live Activity] Failed to start activity: \(error)")
            return
        }
        activityId = newId
        observeActivityState(id: newId)
    }

    /// Subscribes to ActivityKit lifecycle events for `id`. When the activity ends
    /// outside our control (user swipe, system dismiss, stale expiry), `reset()` is
    /// called so the next snapshot can start a fresh activity rather than silently
    /// no-op'ing on a stale identifier.
    private func observeActivityState(id: String) {
        stateObservationTask = Task { [activityProvider] in
            for await state in activityProvider.stateUpdates(forActivityId: id) {
                if state == .dismissed || state == .ended {
                    self.handleExternalActivityEnd(id: id)
                    return
                }
            }
            if !Task.isCancelled {
                self.handleExternalActivityEnd(id: id)
            }
        }
    }

    private func handleExternalActivityEnd(id: String) {
        guard activityId == id else { return }
        reset()
    }

    private func scheduleEndActivity() {
        guard endActivityTask == nil else { return }
        endActivityTask = Task {
            do {
                try await Task.sleep(for: .seconds(6))
            } catch {
                return
            }
            await endActivity()
        }
    }

    private func endActivity() async {
        guard let activityId else { return }
        guard !Task.isCancelled else { return }
        let finalState = Self.terminalState(from: lastContentState)
        await activityProvider.end(
            activityId: activityId,
            state: finalState,
            dismissTimeInterval: 10
        )
        guard !Task.isCancelled else { return }
        reset()
    }

    private func endActivityImmediately() {
        guard let activityId else { return }
        let id = activityId
        let finalState = Self.terminalState(from: lastContentState)
        reset()
        Task { [activityProvider] in
            await activityProvider.end(activityId: id, state: finalState, dismissTimeInterval: 0)
        }
    }

    // MARK: - Update Helpers

    private func pushUpdate(
        _ state: TransferLiveActivityAttributes.ContentState,
        staleDate: Date? = Date().addingTimeInterval(30)
    ) {
        guard let activityId else { return }
        lastUpdateTime = .now
        updateTask = Task { [activityProvider] in
            await activityProvider.update(
                activityId: activityId,
                state: state,
                staleDate: staleDate
            )
        }
    }

    private func pushUpdateThrottled(_ state: TransferLiveActivityAttributes.ContentState) {
        if let lastUpdateTime,
           ContinuousClock.now - lastUpdateTime < Self.minimumUpdateInterval {
            return
        }
        pushUpdate(state)
    }

    private func reset() {
        activityId = nil
        lastPushedState = nil
        lastContentState = nil
        lastUpdateTime = nil
        endActivityTask = nil
        updateTask = nil
        stateObservationTask = nil
        isSuspendedFrameLocked = false
        latestSnapshotWhileLocked = .empty
    }

    // MARK: - Mapping

    private static func makeContentState(
        from snapshot: TransferStatusSnapshot
    ) -> TransferLiveActivityAttributes.ContentState {
        let state: TransferLiveActivityState
        if snapshot.hasError {
            state = .error
        } else if snapshot.hasOverquota {
            state = .overquota
        } else if snapshot.isPaused {
            state = .paused
        } else if snapshot.isCompleted {
            state = .completed
        } else {
            state = .active
        }

        let direction = Self.makeDirection(
            activeUploadCount: snapshot.activeUploadCount,
            activeDownloadCount: snapshot.activeDownloadCount
        )
        let progressFraction = Double(snapshot.progress)
        return TransferLiveActivityAttributes.ContentState(
            progressFraction: progressFraction,
            state: state,
            direction: direction,
            statusText: Self.makeStatusText(state: state, direction: direction),
            percentageText: Self.makePercentageText(progressFraction: progressFraction),
            fileCountText: Self.makeFileCountText(
                completed: snapshot.completedFileCount,
                total: snapshot.totalFileCount
            ),
            formattedSpeed: Self.makeFormattedSpeed(for: state, bytesPerSecond: snapshot.speedBytesPerSecond)
        )
    }

    /// Builds the final frame pushed to ActivityKit when the activity ends.
    ///
    /// Preserves the last-known outcome (`state`, progress, file counts) so error and
    /// over-quota batches don't get a misleading "all complete" terminal frame. Speed
    /// is hidden because nothing is in flight once the activity ends.
    private static func terminalState(
        from lastState: TransferLiveActivityAttributes.ContentState?
    ) -> TransferLiveActivityAttributes.ContentState {
        let progressFraction = lastState?.progressFraction ?? 1
        let state = lastState?.state ?? .completed
        return TransferLiveActivityAttributes.ContentState(
            progressFraction: progressFraction,
            state: state,
            direction: nil,
            statusText: Self.makeStatusText(state: state, direction: nil),
            percentageText: Self.makePercentageText(progressFraction: progressFraction),
            fileCountText: lastState?.fileCountText ?? "",
            formattedSpeed: Self.makeFormattedSpeed(for: state, bytesPerSecond: 0)
        )
    }

    // MARK: - Display Formatting

    private static func makeDirection(
        activeUploadCount: Int,
        activeDownloadCount: Int
    ) -> TransferLiveActivityDirection? {
        switch (activeUploadCount, activeDownloadCount) {
        case (0, 0): nil
        case (_, 0): .uploading
        case (0, _): .downloading
        default: .mixed
        }
    }

    private static func makeStatusText(
        state: TransferLiveActivityState,
        direction: TransferLiveActivityDirection?
    ) -> String {
        switch state {
        case .paused: Strings.Localizable.paused
        case .suspended: Strings.Localizable.Transfer.LiveActivity.openMEGAToResume
        case .error: Strings.Localizable.transferFailed
        case .overquota: Strings.Localizable.Transfer.LiveActivity.requiresAttention
        case .completed: Strings.Localizable.completed
        case .active:
            switch direction {
            case .mixed: Strings.Localizable.Notification.Transfer.Download.title
            case .downloading: Strings.Localizable.Transfer.LiveActivity.downloadingFiles
            case .uploading, .none: Strings.Localizable.Transfer.LiveActivity.uploadingFiles
            }
        }
    }

    /// Displayed percentage, clamped at `99%` until `progressFraction` reaches `1.0`.
    ///
    /// `progressFraction` is byte-based (`completedBytes / totalBytes`), so the counters
    /// can briefly equal total before the SDK's `onTransferFinish` callback arrives —
    /// at which point files are still pending finalization. Reserving `100%` for the
    /// moment progress truly reaches `1.0` matches the convention used across most
    /// upload UIs and avoids a premature "complete" frame while transfers are resolving.
    private static func makePercentageText(progressFraction: Double) -> String {
        let displayedPercentage: Int
        if progressFraction >= 1 {
            displayedPercentage = 100
        } else {
            displayedPercentage = min(Int(progressFraction * 100), 99)
        }
        return "\(displayedPercentage)%"
    }

    private static func makeFileCountText(completed: Int, total: Int) -> String {
        Strings.localized("%1 of %2", comment: "")
            .replacingOccurrences(of: "%1", with: "\(completed)")
            .replacingOccurrences(of: "%2", with: "\(total)")
    }

    private static let speedFormatter: ByteCountFormatter = {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .binary
        formatter.allowedUnits = [.useKB, .useMB, .useGB]
        return formatter
    }()

    /// Speed is only meaningful while transfers are actively in flight. For
    /// paused, suspended, error, over-quota, and completed states we return an
    /// empty string so the LA hides the speed line entirely (per design).
    private static func makeFormattedSpeed(
        for state: TransferLiveActivityState,
        bytesPerSecond: Int64
    ) -> String {
        guard state == .active else { return "" }
        return "\(speedFormatter.string(fromByteCount: bytesPerSecond))/s"
    }
}
