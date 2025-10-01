import AVFoundation
import Combine
import MEGAAnalyticsiOS
import MEGAAppPresentation

@MainActor
@objc final class VideoMetricsTracker: NSObject, Sendable {
    private var startTimeStamp: CFTimeInterval?          // start time of a new playback
    private var firstFrameTimeStamp: TimeInterval?
    private var hasStartupFailure: Bool = false
    private var stallStartTime: CFTimeInterval?
    private var totalStallTime: TimeInterval = 0
    private var pauseStartTime: CFTimeInterval?
    private var totalPauseTime: TimeInterval = 0
     
    private weak var player: AVPlayer?
    private weak var playerItem: AVPlayerItem?
    private var subscriptions = Set<AnyCancellable>()
    private let tracker: any AnalyticsTracking
    private let deviceUUID: String
    private var commonMap = [String: Any]()
     
    init(player: AVPlayer, playerItem: AVPlayerItem, tracker: some AnalyticsTracking) {
        self.player = player
        self.playerItem = playerItem
        self.tracker = tracker
        self.deviceUUID = UIDevice.current.identifierForVendor?.uuidString ?? ""
        self.commonMap = ["did": deviceUUID]
        super.init()
        setupObservers()
    }
    
    deinit {
        subscriptions.removeAll()
    }
    
    private func setupObservers() {
        guard let player, let playerItem else { return }
         
        // monitor playback status change - used for first frame time and rebuffer detection
        player.publisher(for: \.timeControlStatus)
           .receive(on: DispatchQueue.main)
           .sink { [weak self] newStatus in
               self?.handleTimeControlStatusChange(newStatus)
           }
           .store(in: &subscriptions)
         
        // monitor PlayerItem status - used for firstframe failure detection
        playerItem.publisher(for: \.status)
           .receive(on: DispatchQueue.main)
           .sink { [weak self] status in
               self?.handlePlayerItemStatusChange(status)
           }
           .store(in: &subscriptions)
         
        // monitor end of play
        NotificationCenter.default
           .publisher(for: .AVPlayerItemDidPlayToEndTime, object: playerItem)
           .receive(on: DispatchQueue.main)
           .sink { [weak self] _ in
               MEGALogInfo("[VideoMetrics] player item play to end")
               guard let self else { return }
               trackFinalMetrics()
               firstFrameTimeStamp = nil
               startTimeStamp = nil
           }
           .store(in: &subscriptions)
        
        // Use scan to keep track of previous and current values
        player.publisher(for: \.rate)
            .scan((previous: Float(0), current: Float(0))) { previous, current in
                return (previous: previous.current, current: current)
            }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] rates in
                self?.handleRateChange(oldRate: rates.previous, newRate: rates.current)
            }
            .store(in: &subscriptions)
    }
     
    // MARK: - First frame time tracking
    @objc func startStartupTracking() {
        MEGALogInfo("[VideoMetrics] starting to track video playing")
    }
    
    @objc func stopTracking() {
        if firstFrameTimeStamp != nil {
            trackFinalMetrics()
        } else {
            MEGALogError("[VideoMetrics] Stop tracking before first frame time was recorded - assuming")
            tracker.trackAnalyticsEvent(with: VideoPlaybackStartupFailureEvent(scenario: VideoPlaybackStartupFailure.VideoPlaybackScenario.manualclick,
                                                                        commonMap: ""))
        }
    }
    
    private func handleRateChange(oldRate: Float, newRate: Float) {
        MEGALogInfo("[VideoMetrics] oldRate: \(oldRate), newRate: \(newRate)")
        if oldRate == 0, newRate > 0 {
            MEGALogInfo("[VideoMetrics] playback start")
            if startTimeStamp == nil {
                startTimeStamp = CACurrentMediaTime()
            }
        }
    }
    
    private func handleTimeControlStatusChange(_ newStatus: AVPlayer.TimeControlStatus) {
        switch newStatus {
        case .playing:
            MEGALogInfo("[VideoMetrics] enter playing")
            recordPauseTimeIfNeeded()
            endStallIfNeeded()
            recordFirstFrameTimeIfNeeded()
        case .waitingToPlayAtSpecifiedRate:
            MEGALogInfo("[VideoMetrics] waiting to play:\(reasonForWaitingToPlay())")
            recordPauseTimeIfNeeded()
            startStallIfNeeded()
        case .paused:
            MEGALogInfo("[VideoMetrics] paused")
            updatePauseStartTimeIfNeeded()
            endStallIfNeeded()
        @unknown default:
           break
        }
    }
    
    private func reasonForWaitingToPlay() -> String {
        guard let reason = player?.reasonForWaitingToPlay else {
            return "Unknown"
        }
        switch reason {
        case .toMinimizeStalls:
            return "Minimizing stalls (buffering)"
        case .evaluatingBufferingRate:
            return "Evaluating buffering rate"
        case .noItemToPlay:
            return "No item to play"
        default:
            return "Unknown"
        }
    }
    
    private func recordPauseTimeIfNeeded() {
        guard let pauseStartTime else { return }
        let pauseDuration = CACurrentMediaTime() - pauseStartTime
        totalPauseTime += pauseDuration
        MEGALogInfo("[VideoMetrics] paused for \(pauseDuration)s, totalPauseTime:\(totalPauseTime)s")
        self.pauseStartTime = nil
    }

    private func recordFirstFrameTimeIfNeeded() {
        guard firstFrameTimeStamp == nil else { return }
        firstFrameTimeStamp = CACurrentMediaTime()
        trackFirstFrameTime()
    }
    
    // MARK: - First frame failure tracking
    private func handlePlayerItemStatusChange(_ status: AVPlayerItem.Status) {
        switch status {
        case .failed:
            MEGALogInfo("[VideoMetrics] failed")
            guard !hasStartupFailure, firstFrameTimeStamp == nil else { return }
            hasStartupFailure = true
            trackStartupFailure()
        case .readyToPlay:
            MEGALogInfo("[VideoMetrics] readyToPlay")
            recordFirstFrameTimeIfNeeded()
            updatePauseStartTimeIfNeeded()
            startStallIfNeeded()
        case .unknown:
            MEGALogInfo("[VideoMetrics] unknown")
        @unknown default:
            break
        }
    }
     
    // MARK: - stall time tracking
    private func updatePauseStartTimeIfNeeded() {
        guard firstFrameTimeStamp != nil, player?.timeControlStatus == .paused, pauseStartTime == nil else { return }
        pauseStartTime = CACurrentMediaTime()
        MEGALogInfo("[VideoMetrics] pauseStartTime updated")
    }
    
    private func startStallIfNeeded() {
        guard firstFrameTimeStamp != nil, stallStartTime == nil, player?.timeControlStatus == .waitingToPlayAtSpecifiedRate else { return }
        stallStartTime = CACurrentMediaTime()
        MEGALogInfo("[VideoMetrics] stall started")
    }
     
    private func endStallIfNeeded() {
        guard firstFrameTimeStamp != nil, let startTime = stallStartTime else { return }
        let stallTime = CACurrentMediaTime() - startTime
        totalStallTime += stallTime
        MEGALogInfo("[VideoMetrics] stall Time: \(stallTime)s, totalStallTime:\(totalStallTime)s")
        stallStartTime = nil
    }
     
    // MARK: - statistics report
    private func trackFirstFrameTime() {
        guard let firstFrameTimeStamp, let startTimeStamp else { return }
        let firstFrameTime = firstFrameTimeStamp - startTimeStamp
        MEGALogInfo("[VideoMetrics] firstFrame Time: \(firstFrameTime)s")
        tracker.trackAnalyticsEvent(with: VideoPlaybackFirstFrameEvent(time: Int32(firstFrameTime*1000),
                                                                  scenario: VideoPlaybackFirstFrame.VideoPlaybackScenario.manualclick,
                                                                  commonMap: ""))
    }

    private func trackStartupFailure() {
        MEGALogError("[VideoMetrics] Startup Failure occurred")
        tracker.trackAnalyticsEvent(with: VideoPlaybackStartupFailureEvent(scenario: VideoPlaybackStartupFailure.VideoPlaybackScenario.manualclick,
                                                                    commonMap: ""))
    }

    private func trackFinalMetrics() {
        guard let firstFrameTimeStamp else { return }
        recordPauseTimeIfNeeded()
        endStallIfNeeded()
        let effectivePlayTime = CACurrentMediaTime() - firstFrameTimeStamp - totalPauseTime
        guard effectivePlayTime > 0, totalStallTime >= 0 else { return }
        let stallTimeInHundredSeconds = totalStallTime/effectivePlayTime * 100.0 * 1000.0
        MEGALogInfo("[VideoMetrics] stallTimeInHundredSeconds: \(Int(stallTimeInHundredSeconds))ms, totalPlayTime: \(effectivePlayTime)s")
        totalStallTime = 0
        totalPauseTime = 0
        tracker.trackAnalyticsEvent(with: VideoPlaybackStallEvent(time: Int32(stallTimeInHundredSeconds),
                                                                  scenario: VideoPlaybackStall.VideoPlaybackScenario.manualclick,
                                                                  commonMap: ""))
    }
    
    // MARK: - utility method
    private func dictToJsonString(_ dict: [String: Any]) -> String? {
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: dict, options: .prettyPrinted)
            return String(data: jsonData, encoding: .utf8)
        } catch {
            MEGALogInfo("[VideoMetrics] json convert error: \(error)")
            return nil
        }
    }
}
