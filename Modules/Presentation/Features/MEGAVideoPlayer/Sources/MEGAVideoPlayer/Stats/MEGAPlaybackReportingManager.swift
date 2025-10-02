import AVFoundation
import Combine
import MEGAAnalyticsiOS
import MEGAAppPresentation
import UIKit

@MainActor
final class MEGAPlaybackReportingManager {
    private var playbackStarted = false

    private var lastKnownState: PlaybackState?
    private var lastObservedTime: Duration?
    private var lastStalledTime: Duration?

    private var openTimeStamp: CFTimeInterval?
    private var firstFrameTimeStamp: CFTimeInterval?
    private var pauseStartTime: CFTimeInterval?
    private var totalPauseTime: CFTimeInterval = 0
    private var stallStartTime: CFTimeInterval?
    private var totalStallTime: CFTimeInterval = 0

    private var cancellables = Set<AnyCancellable>()

    private let playerOptionIdentifiable: any PlayerOptionIdentifiable
    private let playbackState: any PlaybackStateObservable
    private let playbackDebugMessage: any PlaybackDebugMessageObservable
    private let playbackReporter: any PlaybackReporting
    private let analyticsTracker: any AnalyticsTracking

    init(
        playerOptionIdentifiable: some PlayerOptionIdentifiable,
        playbackState: some PlaybackStateObservable,
        playbackDebugMessage: some PlaybackDebugMessageObservable,
        playbackReporter: some PlaybackReporting,
        analyticsTracker: some AnalyticsTracking
    ) {
        self.playerOptionIdentifiable = playerOptionIdentifiable
        self.playbackState = playbackState
        self.playbackDebugMessage = playbackDebugMessage
        self.playbackReporter = playbackReporter
        self.analyticsTracker = analyticsTracker
        playbackReporter.playbackPlayerOption(playerOptionIdentifiable.option)
    }

    convenience init(
        player: some VideoPlayerProtocol,
        playbackReporter: some PlaybackReporting,
        analyticsTracker: some AnalyticsTracking
    ) {
        self.init(
            playerOptionIdentifiable: player,
            playbackState: player,
            playbackDebugMessage: player,
            playbackReporter: playbackReporter,
            analyticsTracker: analyticsTracker
        )
    }

    func observePlayback() {
        observeDebugMessage()
        observeState()
        observeCurrentTime()
    }

    func recordOpenTimeStamp() {
        openTimeStamp = CACurrentMediaTime()
    }

    func trackVideoPlaybackFinalEvents() {
        trackVideoPlaybackRecordEvent()
        trackVideoPlaybackStallEvent()
    }

    private func observeDebugMessage() {
        playbackDebugMessage.debugMessagePublisher
            .sink { [weak self] in self?.newDebugMessage($0) }
            .store(in: &cancellables)
    }

    private func observeState() {
        playbackState.statePublisher
            .sink { [weak self] in self?.stateDidChange(to: $0) }
            .store(in: &cancellables)
    }

    private func observeCurrentTime() {
        playbackState.currentTimePublisher
            .sink { [weak self] in self?.currentTimeDidChange(to: $0) }
            .store(in: &cancellables)
    }

    private func newDebugMessage(_ message: String) {
        playbackReporter.playbackDebugMessage(message)
    }

    private func stateDidChange(to newState: PlaybackState) {
        if newState != lastKnownState {
            playbackReporter.playbackStateDidChange(newState)
            lastKnownState = newState
            handleVideoPlaybackStateChangeForEventsTracking(newState)
        }

        detectStalling(newState, with: playbackState.currentTime)
    }

    private func currentTimeDidChange(to newTime: Duration) {
        if !playbackStarted, playbackState.currentTime.components.seconds >= 0 {
            playbackStarted = true
            playbackReporter.playbackStarted()
        }

        playbackReporter.playbackCurrentTimeDidChange(playbackState.currentTime)

        detectStalling(playbackState.state, with: newTime)
    }

    /// Stalling is when playback has not progressed for a detectable period, indicating potential buffering or network-related delay.
    private func detectStalling(_ newState: PlaybackState, with currentTime: Duration) {
        guard playbackStarted else { return }

        switch newState {
        case .paused, .stopped, .ended, .error, .opening:
            break
        default:
            if currentTime == lastObservedTime, lastStalledTime == nil {
                lastStalledTime = currentTime
                playbackReporter.playbackStallStarted()
            } else if currentTime != lastObservedTime, lastStalledTime != nil {
                lastStalledTime = nil
                playbackReporter.playbackStallEnded()
            }
        }

        lastObservedTime = currentTime
    }

    // MARK: - Events Tracking

    private func trackVideoPlaybackRecordEvent() {
        guard let openTimeStamp else { return }
        let delta = CACurrentMediaTime() - openTimeStamp
        let clamped = min(max(0, delta), Double(Int32.max))
        analyticsTracker.trackAnalyticsEvent(
            with: VideoPlaybackRecordNewVPEvent(duration: Int32(clamped))
        )
    }

    private func trackVideoPlaybackStallEvent() {
        guard let firstFrameTimeStamp else { return }
        let effectivePlayTime = CACurrentMediaTime() - firstFrameTimeStamp - totalPauseTime
        guard effectivePlayTime > 0, totalStallTime >= 0 else { return }
        // The ratio is multiplied by 100 to convert to percentage and then by 1000 make the final value accurate
        let stallTimeToEffectivePlayTime = totalStallTime/effectivePlayTime * 100.0 * 1000
        totalStallTime = 0
        totalPauseTime = 0
        analyticsTracker.trackAnalyticsEvent(
            with: VideoPlaybackStallNewVPEvent(
                time: Int32(stallTimeToEffectivePlayTime),
                scenario: VideoPlaybackStallNewVP.VideoPlaybackScenario.manualclick,
                commonMap: eventsCommonMap
            )
        )
    }

    private func handleVideoPlaybackStateChangeForEventsTracking(_ state: PlaybackState) {
        switch state {
        case .playing:
            if firstFrameTimeStamp == nil {
                firstFrameTimeStamp = CACurrentMediaTime()
                trackVideoPlaybackFirstFrameEvent()
            } else {
                recordPauseTime()
                recordStallTime()
            }
        case .buffering:
            guard firstFrameTimeStamp != nil else { return }
            stallStartTime = CACurrentMediaTime()
            recordPauseTime()
        case .paused:
            guard firstFrameTimeStamp != nil else { return }
            pauseStartTime = CACurrentMediaTime()
            recordStallTime()
        case .error:
            trackVideoPlaybackStartupFailureEvent()
        default:
            guard firstFrameTimeStamp != nil else { return }
            recordPauseTime()
            recordStallTime()
        }
    }

    private func trackVideoPlaybackFirstFrameEvent() {
        guard let firstFrameTimeStamp, let openTimeStamp else { return }
        let firstFrameTime = firstFrameTimeStamp - openTimeStamp
        analyticsTracker.trackAnalyticsEvent(
            with: VideoPlaybackFirstFrameNewVPEvent(
                time: Int32(firstFrameTime),
                scenario: VideoPlaybackFirstFrameNewVP.VideoPlaybackScenario.manualclick,
                commonMap: eventsCommonMap
            )
        )
    }

    private func recordPauseTime() {
        guard let pauseStartTime else { return }
        totalPauseTime += CACurrentMediaTime() - pauseStartTime
        self.pauseStartTime = nil
    }

    private func recordStallTime() {
        guard let stallStartTime else { return }
        totalStallTime += CACurrentMediaTime() - stallStartTime
        self.stallStartTime = nil
    }

    private func trackVideoPlaybackStartupFailureEvent() {
        analyticsTracker.trackAnalyticsEvent(
            with: VideoPlaybackStartupFailureNewVPEvent(
                scenario: VideoPlaybackStartupFailureNewVP.VideoPlaybackScenario.manualclick,
                commonMap: eventsCommonMap
            )
        )
    }

    private var eventsCommonMap: String = {
        // We use empty map for now.
        // After the map structure is confirm we will update it
        ""
    }()
}
