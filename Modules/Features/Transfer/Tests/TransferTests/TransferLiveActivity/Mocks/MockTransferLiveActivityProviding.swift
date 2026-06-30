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

    var pauseRequest = false

    private var stateContinuation: AsyncStream<ActivityState>.Continuation?
    private var enablementContinuation: AsyncStream<Bool>.Continuation?
    private var requestContinuation: CheckedContinuation<Void, Never>?

    func request(
        initialState: TransferLiveActivityAttributes.ContentState,
        staleDate: Date?
    ) async throws -> String {
        if let error = requestError { throw error }
        requestCalls.append(RequestCall(state: initialState, staleDate: staleDate))
        if pauseRequest {
            await withCheckedContinuation { self.requestContinuation = $0 }
        }
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

    var enablementUpdates: AnyAsyncSequence<Bool> {
        let stream = AsyncStream<Bool> { continuation in
            self.enablementContinuation = continuation
        }
        return AnyAsyncSequence(stream)
    }

    // MARK: - Test helpers

    func emitActivityState(_ state: ActivityState) {
        stateContinuation?.yield(state)
    }

    func emitEnablement(_ enabled: Bool) {
        enablementContinuation?.yield(enabled)
    }

    func releaseRequest() {
        requestContinuation?.resume()
        requestContinuation = nil
    }

    func finishStateUpdates() {
        stateContinuation?.finish()
    }
}
