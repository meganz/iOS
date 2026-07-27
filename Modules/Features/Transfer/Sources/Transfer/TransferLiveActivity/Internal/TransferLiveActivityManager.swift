import ActivityKit
@preconcurrency import Combine
import Foundation
import MEGAAppSDKRepo
import MEGAL10n
import MEGASwift

@MainActor
final class TransferLiveActivityManager {

    private let activityProvider: any TransferLiveActivityProviding
    private var cancellable: AnyCancellable?

    private var activityId: String?
    private var lastPushedStatus: TransferLiveActivityStatus?
    private var lastContentState: TransferLiveActivityAttributes.ContentState?
    private var latestSnapshot: TransferStatusSnapshot?

    private var endActivityTask: Task<Void, Never>? {
        didSet { oldValue?.cancel() }
    }
    private var updateTask: Task<Void, Never>? {
        didSet { oldValue?.cancel() }
    }
    private var stateObservationTask: Task<Void, Never>? {
        didSet { oldValue?.cancel() }
    }
    private var enablementObservationTask: Task<Void, Never>? {
        didSet { oldValue?.cancel() }
    }
    private var startActivityTask: Task<Void, Never>? {
        didSet { oldValue?.cancel() }
    }

    private var isStartBlocked = false

    private var isStartingActivity = false

    private var lastUpdateTime: ContinuousClock.Instant?
    private static let minimumUpdateInterval: Duration = .seconds(1)

    init(activityProvider: some TransferLiveActivityProviding) {
        self.activityProvider = activityProvider
    }

    deinit {
        cancellable?.cancel()
        endActivityTask?.cancel()
        updateTask?.cancel()
        stateObservationTask?.cancel()
        enablementObservationTask?.cancel()
        startActivityTask?.cancel()
    }

    func startMonitoring(snapshotPublisher: AnyPublisher<TransferStatusSnapshot?, Never>) {
        adoptExistingActivity()
        observeEnablement()
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

    /// Clears `isStartBlocked` whenever Live Activities authorization changes, so a
    /// start that was denied (`ActivityAuthorizationError.denied`) can be retried once
    /// the user re-enables Live Activities — without re-attempting on every snapshot.
    private func observeEnablement() {
        enablementObservationTask = Task { [weak self, activityProvider] in
            for await _ in activityProvider.enablementUpdates {
                self?.isStartBlocked = false
            }
        }
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
        latestSnapshot = snapshot
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
            lastPushedStatus = contentState.status
            pushUpdate(contentState)
            scheduleEndActivity()
            return
        }

        endActivityTask?.cancel()
        endActivityTask = nil

        startActivity(with: contentState)

        let isStatusChange = contentState.status != lastPushedStatus
        lastPushedStatus = contentState.status

        if isStatusChange {
            pushUpdate(contentState)
        } else {
            pushUpdateThrottled(contentState)
        }
    }

    // MARK: - Activity Lifecycle

    private func startActivity(with contentState: TransferLiveActivityAttributes.ContentState) {
        guard activityId == nil,
              !isStartingActivity,
              activityProvider.areActivitiesEnabled,
              !isStartBlocked,
              !activityProvider.hasActiveActivity else {
            return
        }
        isStartingActivity = true
        startActivityTask = Task { [weak self] in
            await self?.performStartActivity(with: contentState)
        }
    }

    private func performStartActivity(with contentState: TransferLiveActivityAttributes.ContentState) async {
        defer { isStartingActivity = false }
        let newId: String
        do {
            newId = try await activityProvider.request(
                initialState: contentState,
                staleDate: Self.staleDate(for: contentState.status)
            )
        } catch {
            let failureReason = (error as? ActivityAuthorizationError)?.failureReason ?? "n/a"
            MEGALogError("[Transfer Live Activity] Failed to start activity: \(error) - reason: \(failureReason)")
            if Self.isAuthorizationDenied(error) {
                isStartBlocked = true
            }
            return
        }

        guard !Task.isCancelled, activityId == nil else {
            let finalState = Self.terminalState(from: contentState)
            Task { [activityProvider] in
                await activityProvider.end(
                    activityId: newId,
                    state: finalState,
                    dismissTimeInterval: 0
                )
            }
            return
        }

        activityId = newId
        lastPushedStatus = contentState.status
        lastUpdateTime = .now
        observeActivityState(id: newId)
        handleSnapshot(latestSnapshot)
    }

    private static func isAuthorizationDenied(_ error: any Error) -> Bool {
        guard let authorizationError = error as? ActivityAuthorizationError else { return false }
        switch authorizationError {
        case .denied, .unentitled, .unsupported: return true
        default: return false
        }
    }

    /// Subscribes to ActivityKit lifecycle events for `id`. When the activity ends
    /// outside our control (user swipe, system dismiss, stale expiry), `reset()` is
    /// called so the next snapshot can start a fresh activity rather than silently
    /// no-op'ing on a stale identifier.
    private func observeActivityState(id: String) {
        stateObservationTask = Task { [weak self, activityProvider] in
            for await state in activityProvider.stateUpdates(forActivityId: id) {
                if state == .dismissed || state == .ended {
                    self?.handleExternalActivityEnd(id: id)
                    return
                }
            }
            if !Task.isCancelled {
                self?.handleExternalActivityEnd(id: id)
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

    // MARK: - Update Helpers

    private func pushUpdate(_ contentState: TransferLiveActivityAttributes.ContentState) {
        guard let activityId else { return }
        lastUpdateTime = .now
        let staleDate = Self.staleDate(for: contentState.status)
        updateTask = Task { [activityProvider] in
            await activityProvider.update(
                activityId: activityId,
                state: contentState,
                staleDate: staleDate
            )
        }
    }

    /// `.active` is the only state where "no recent update" implies the app stopped pushing.
    /// `.paused`, `.error`, and `.overquota` describe transfers that are intentionally not
    /// progressing; they must never auto-flip to stale, otherwise the views would falsely
    /// surface "Open MEGA to resume" on a user-paused or terminal state.
    private static func staleDate(for status: TransferLiveActivityStatus) -> Date? {
        switch status {
        case .active: Date().addingTimeInterval(8)
        case .paused, .error, .overquota, .completed: nil
        }
    }

    private func pushUpdateThrottled(_ contentState: TransferLiveActivityAttributes.ContentState) {
        if let lastUpdateTime,
           ContinuousClock.now - lastUpdateTime < Self.minimumUpdateInterval {
            return
        }
        pushUpdate(contentState)
    }

    private func reset() {
        activityId = nil
        lastPushedStatus = nil
        lastContentState = nil
        latestSnapshot = nil
        lastUpdateTime = nil
        endActivityTask = nil
        updateTask = nil
        stateObservationTask = nil
        startActivityTask = nil
        isStartingActivity = false
    }

    // MARK: - Mapping

    private static func makeContentState(
        from snapshot: TransferStatusSnapshot
    ) -> TransferLiveActivityAttributes.ContentState {
        let status: TransferLiveActivityStatus
        if snapshot.hasError {
            status = .error
        } else if snapshot.hasOverquota {
            status = .overquota
        } else if snapshot.isPaused {
            status = .paused
        } else if snapshot.isCompleted {
            status = .completed
        } else {
            status = .active
        }

        let direction = Self.makeDirection(
            activeUploadCount: snapshot.activeUploadCount,
            activeDownloadCount: snapshot.activeDownloadCount
        )
        let progressFraction = Double(snapshot.progress)
        return TransferLiveActivityAttributes.ContentState(
            progressFraction: progressFraction,
            status: status,
            direction: direction,
            statusText: Self.makeStatusText(status: status, direction: direction),
            percentageText: Self.makePercentageText(progressFraction: progressFraction),
            fileCountText: Self.makeFileCountText(
                completed: snapshot.completedFileCount,
                total: snapshot.totalFileCount
            ),
            formattedSpeed: Self.makeFormattedSpeed(for: status, bytesPerSecond: snapshot.speedBytesPerSecond)
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
        let status = lastState?.status ?? .completed
        return TransferLiveActivityAttributes.ContentState(
            progressFraction: progressFraction,
            status: status,
            direction: nil,
            statusText: Self.makeStatusText(status: status, direction: nil),
            percentageText: Self.makePercentageText(progressFraction: progressFraction),
            fileCountText: lastState?.fileCountText ?? "",
            formattedSpeed: Self.makeFormattedSpeed(for: status, bytesPerSecond: 0)
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
        status: TransferLiveActivityStatus,
        direction: TransferLiveActivityDirection?
    ) -> String {
        switch status {
        case .paused: Strings.Localizable.paused
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
    /// paused, error, over-quota, and completed states we return an empty
    /// string so the LA hides the speed line entirely (per design).
    private static func makeFormattedSpeed(
        for status: TransferLiveActivityStatus,
        bytesPerSecond: Int64
    ) -> String {
        guard status == .active else { return "" }
        return "\(speedFormatter.string(fromByteCount: bytesPerSecond))/s"
    }
}
