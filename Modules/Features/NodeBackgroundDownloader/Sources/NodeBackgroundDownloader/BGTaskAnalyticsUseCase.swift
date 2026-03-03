import MEGAAnalyticsiOS
import MEGAAppPresentation

package enum BGTaskAppState: Sendable { case active, background }
package enum BGTaskScheduleFailureReason: Sendable { case registerFailed, submitFailed }

package protocol BGTaskAnalyticsUseCaseProtocol: Sendable {
    func trackTaskCompleted(durationSeconds: TimeInterval)
    func trackTaskExpired(durationSeconds: TimeInterval, completionPercentage: Double, appState: BGTaskAppState)
    func trackScheduleFailure(reason: BGTaskScheduleFailureReason)
    func trackSchedulingDelay(delaySeconds: TimeInterval)
}

package struct BGTaskAnalyticsUseCase: BGTaskAnalyticsUseCaseProtocol {
    private let tracker: any AnalyticsTracking

    package init(tracker: some AnalyticsTracking) {
        self.tracker = tracker
    }

    package func trackTaskCompleted(durationSeconds: TimeInterval) {
        tracker.trackAnalyticsEvent(with: BGTaskCompletedEvent())
        trackDuration(durationSeconds)
    }

    package func trackTaskExpired(
        durationSeconds: TimeInterval,
        completionPercentage: Double,
        appState: BGTaskAppState
    ) {
        tracker.trackAnalyticsEvent(with: BGTaskExpiredEvent())
        trackDuration(durationSeconds)
        trackProgressAtExpiration(completionPercentage)
        trackAppStateAtExpiration(appState)
    }

    package func trackScheduleFailure(reason: BGTaskScheduleFailureReason) {
        switch reason {
        case .registerFailed:
            tracker.trackAnalyticsEvent(with: BGTaskScheduleFailedRegisterEvent())
        case .submitFailed:
            tracker.trackAnalyticsEvent(with: BGTaskScheduleFailedSubmitEvent())
        }
    }

    package func trackSchedulingDelay(delaySeconds: TimeInterval) {
        switch delaySeconds {
        case ..<5:
            tracker.trackAnalyticsEvent(with: BGTaskSchedulingDelayUnder5sEvent())
        case ..<30:
            tracker.trackAnalyticsEvent(with: BGTaskSchedulingDelayUnder30sEvent())
        case ..<60:
            tracker.trackAnalyticsEvent(with: BGTaskSchedulingDelayUnder1MinEvent())
        default:
            tracker.trackAnalyticsEvent(with: BGTaskSchedulingDelayOver1MinEvent())
        }
    }

    // MARK: - Private

    private func trackDuration(_ seconds: TimeInterval) {
        switch seconds {
        case ..<60:
            tracker.trackAnalyticsEvent(with: BGTaskDurationUnder1MinEvent())
        case ..<300:
            tracker.trackAnalyticsEvent(with: BGTaskDurationUnder5MinEvent())
        case ..<600:
            tracker.trackAnalyticsEvent(with: BGTaskDurationUnder10MinEvent())
        default:
            tracker.trackAnalyticsEvent(with: BGTaskDurationOver10MinEvent())
        }
    }

    private func trackProgressAtExpiration(_ percentage: Double) {
        switch percentage {
        case ..<25:
            tracker.trackAnalyticsEvent(with: BGTaskProgressAtExpirationUnder25Event())
        case ..<50:
            tracker.trackAnalyticsEvent(with: BGTaskProgressAtExpirationUnder50Event())
        case ..<75:
            tracker.trackAnalyticsEvent(with: BGTaskProgressAtExpirationUnder75Event())
        default:
            tracker.trackAnalyticsEvent(with: BGTaskProgressAtExpirationOver75Event())
        }
    }

    private func trackAppStateAtExpiration(_ appState: BGTaskAppState) {
        switch appState {
        case .active:
            tracker.trackAnalyticsEvent(with: BGTaskExpiredWhileAppActiveEvent())
        case .background:
            tracker.trackAnalyticsEvent(with: BGTaskExpiredWhileAppBackgroundEvent())
        }
    }
}
