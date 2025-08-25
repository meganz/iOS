import Combine
import Foundation
import MEGAVideoPlayer

@MainActor
public final class MockVideoPlayer: VideoPlayerProtocol {
    @Published public var state: PlaybackState
    @Published public var currentTime: Duration
    @Published public var duration: Duration

    let debugMessage: String
    public nonisolated let option: VideoPlayerOption

    public var statePublisher: AnyPublisher<PlaybackState, Never> {
        $state.eraseToAnyPublisher()
    }

    public var currentTimePublisher: AnyPublisher<Duration, Never> {
        $currentTime.eraseToAnyPublisher()
    }

    public var durationPublisher: AnyPublisher<Duration, Never> {
        $duration.eraseToAnyPublisher()
    }

    public nonisolated var debugMessagePublisher: AnyPublisher<String, Never> {
        Just(debugMessage).eraseToAnyPublisher()
    }

    // MARK: - Call Tracking
    public var playCallCount: Int = 0
    public var pauseCallCount: Int = 0
    public var stopCallCount: Int = 0
    public var jumpForwardCallCount: Int = 0
    public var jumpForwardSeconds: TimeInterval = 0
    public var jumpBackwardCallCount: Int = 0
    public var jumpBackwardSeconds: TimeInterval = 0
    public var seekCallCount: Int = 0
    public var seekTime: TimeInterval = 0
    public var changeRateCallCount: Int = 0
    public var changeRateValue: Float = 1.0
    public var setLoopingCallCount: Int = 0
    public var setLoopingValue: Bool = false
    public var isLoopEnabled: Bool = false
    public var loadNodeCallCount: Int = 0
    public var loadedNode: (any PlayableNode)?
    public var setupPlayerCallCount: Int = 0
    public var resizePlayerCallCount: Int = 0
    public var resizedFrame: CGRect = .zero
    public var setScalingModeCallCount: Int = 0
    public var setScalingModeValue: VideoScalingMode = .fit

    public init(
        option: VideoPlayerOption = .avPlayer,
        state: PlaybackState = .stopped,
        currentTime: Duration = .seconds(0),
        duration: Duration = .seconds(0),
        debugMessage: String = ""
    ) {
        self.option = option
        self.state = state
        self.currentTime = currentTime
        self.duration = duration
        self.debugMessage = debugMessage
    }

    public func play() {
        playCallCount += 1
    }
    
    public func pause() {
        pauseCallCount += 1
    }
    
    public func stop() {
        stopCallCount += 1
    }
    
    public func jumpForward(by seconds: TimeInterval) {
        jumpForwardCallCount += 1
        jumpForwardSeconds = seconds
    }
    
    public func jumpBackward(by seconds: TimeInterval) {
        jumpBackwardCallCount += 1
        jumpBackwardSeconds = seconds
    }
    
    public func seek(to time: TimeInterval) {
        seekCallCount += 1
        seekTime = time
    }

    public func changeRate(to rate: Float) {
        changeRateCallCount += 1
        changeRateValue = rate
    }
    
    public func setLooping(_ enabled: Bool) {
        setLoopingCallCount += 1
        setLoopingValue = enabled
        isLoopEnabled = enabled
    }

    public func loadNode(_ node: some PlayableNode) {
        loadNodeCallCount += 1
        loadedNode = node
    }
    
    public func setupPlayer(in layer: any PlayerLayerProtocol) {
        setupPlayerCallCount += 1
    }
    
    public func resizePlayer(to frame: CGRect) {
        resizePlayerCallCount += 1
        resizedFrame = frame
    }
    
    public func setScalingMode(_ mode: VideoScalingMode) {
        setScalingModeCallCount += 1
        setScalingModeValue = mode
    }
    
    // MARK: - Reset for testing
    public func resetCallCounts() {
        playCallCount = 0
        pauseCallCount = 0
        stopCallCount = 0
        jumpForwardCallCount = 0
        jumpForwardSeconds = 0
        jumpBackwardCallCount = 0
        jumpBackwardSeconds = 0
        seekCallCount = 0
        seekTime = 0
        loadNodeCallCount = 0
        loadedNode = nil
        setupPlayerCallCount = 0
        resizePlayerCallCount = 0
        resizedFrame = .zero
        setScalingModeCallCount = 0
        setScalingModeValue = .fit
    }
}
