import ActivityKit
import Foundation
import MEGASwift
@testable import Transfer

@available(iOS 16.2, *)
final class MockTransferLiveActivityProviding: TransferLiveActivityProviding, @unchecked Sendable {

    struct RequestCall: Equatable {
        let state: TransferLiveActivityAttributes.ContentState
        let staleDate: Date?
    }

    struct UpdateCall: Equatable {
        let activityId: String
        let state: TransferLiveActivityAttributes.ContentState
        let staleDate: Date?
    }

    struct EndCall: Equatable {
        let activityId: String
        let state: TransferLiveActivityAttributes.ContentState
        let dismissTimeInterval: TimeInterval?
    }

    private(set) var requestCalls: [RequestCall] = []
    private(set) var updateCalls: [UpdateCall] = []
    private(set) var endCalls: [EndCall] = []

    var areActivitiesEnabled: Bool = true
    var hasActiveActivity: Bool = false
    var activeActivityId: String?
    var requestError: Error?
    var requestedActivityId = "test-activity-1"

    private var stateContinuation: AsyncStream<ActivityState>.Continuation?

    func request(
        initialState: TransferLiveActivityAttributes.ContentState,
        staleDate: Date?
    ) throws -> String {
        if let error = requestError { throw error }
        requestCalls.append(RequestCall(state: initialState, staleDate: staleDate))
        return requestedActivityId
    }

    func update(
        activityId: String,
        state: TransferLiveActivityAttributes.ContentState,
        staleDate: Date?
    ) async {
        updateCalls.append(UpdateCall(activityId: activityId, state: state, staleDate: staleDate))
    }

    func end(
        activityId: String,
        state: TransferLiveActivityAttributes.ContentState,
        dismissTimeInterval: TimeInterval?
    ) async {
        endCalls.append(EndCall(activityId: activityId, state: state, dismissTimeInterval: dismissTimeInterval))
    }

    func stateUpdates(forActivityId activityId: String) -> AnyAsyncSequence<ActivityState> {
        let stream = AsyncStream<ActivityState> { continuation in
            self.stateContinuation = continuation
        }
        return AnyAsyncSequence(stream)
    }

    // MARK: - Test helpers

    func emitActivityState(_ state: ActivityState) {
        stateContinuation?.yield(state)
    }

    func finishStateUpdates() {
        stateContinuation?.finish()
    }
}
