import ActivityKit
import Foundation
import MEGASwift

@available(iOS 16.2, *)
protocol TransferLiveActivityProviding: Sendable {
    /// Starts a new Live Activity and returns its identifier.
    func request(initialState: TransferLiveActivityAttributes.ContentState) throws -> String
    /// Pushes an updated content state to an existing Live Activity.
    func update(activityId: String, state: TransferLiveActivityAttributes.ContentState, staleDate: Date?) async
    /// Ends a Live Activity with the given dismissal policy.
    /// - Parameter dismissTimeInterval: `nil` for system default, `<= 0` for immediate
    ///   dismissal, `> 0` for delayed dismissal in seconds.
    func end(activityId: String, state: TransferLiveActivityAttributes.ContentState, dismissTimeInterval: TimeInterval?) async
    /// Emits each `ActivityState` transition for the given activity (e.g. user-initiated
    /// dismissal, system-ended). The sequence terminates when the activity is no longer live.
    func stateUpdates(forActivityId activityId: String) -> AnyAsyncSequence<ActivityState>
    /// Whether the user has granted permission for Live Activities.
    var areActivitiesEnabled: Bool { get }
    /// Whether a transfer Live Activity is currently running.
    var hasActiveActivity: Bool { get }
    /// The identifier of an existing transfer Live Activity, if one is still active from a prior session.
    var activeActivityId: String? { get }
}

@available(iOS 16.2, *)
struct TransferLiveActivityProvider {}

// MARK: - TransferLiveActivityProviding

@available(iOS 16.2, *)
extension TransferLiveActivityProvider: TransferLiveActivityProviding {

    func request(initialState: TransferLiveActivityAttributes.ContentState) throws -> String {
        let content = ActivityContent(state: initialState, staleDate: Date().addingTimeInterval(30))
        let activity = try Activity<TransferLiveActivityAttributes>.request(
            attributes: TransferLiveActivityAttributes(),
            content: content,
            pushType: nil
        )
        return activity.id
    }

    func update(activityId: String, state: TransferLiveActivityAttributes.ContentState, staleDate: Date?) async {
        let content = ActivityContent(state: state, staleDate: staleDate)
        guard let activity = Activity<TransferLiveActivityAttributes>.activities.first(where: { $0.id == activityId }) else {
            return
        }
        await activity.update(content)
    }

    func end(
        activityId: String,
        state: TransferLiveActivityAttributes.ContentState,
        dismissTimeInterval: TimeInterval?
    ) async {
        let content = ActivityContent(state: state, staleDate: nil)
        guard let activity = Activity<TransferLiveActivityAttributes>.activities.first(where: { $0.id == activityId }) else {
            return
        }
        let policy: ActivityUIDismissalPolicy = switch dismissTimeInterval {
        case .none: .default
        case .some(let interval) where interval <= 0: .immediate
        case .some(let interval): .after(.now + interval)
        }
        await activity.end(content, dismissalPolicy: policy)
    }

    func stateUpdates(forActivityId activityId: String) -> AnyAsyncSequence<ActivityState> {
        let stream = AsyncStream<ActivityState> { continuation in
            guard let activity = Activity<TransferLiveActivityAttributes>.activities.first(where: { $0.id == activityId }) else {
                continuation.finish()
                return
            }
            let task = Task {
                for await state in activity.activityStateUpdates {
                    continuation.yield(state)
                }
                continuation.finish()
            }
            continuation.onTermination = { _ in
                task.cancel()
            }
        }
        return AnyAsyncSequence(stream)
    }

    var areActivitiesEnabled: Bool {
        ActivityAuthorizationInfo().areActivitiesEnabled
    }

    var hasActiveActivity: Bool {
        Activity<TransferLiveActivityAttributes>.activities.contains(where: Self.isLive)
    }

    var activeActivityId: String? {
        Activity<TransferLiveActivityAttributes>.activities.first(where: Self.isLive)?.id
    }

    /// `Activity.activities` briefly retains `.dismissed`/`.ended` activities after the
    /// system tears them down, so identity queries must filter to live states only;
    /// otherwise the manager can adopt a zombie id and silently no-op on update.
    private static func isLive(_ activity: Activity<TransferLiveActivityAttributes>) -> Bool {
        activity.activityState == .active || activity.activityState == .stale
    }
}
