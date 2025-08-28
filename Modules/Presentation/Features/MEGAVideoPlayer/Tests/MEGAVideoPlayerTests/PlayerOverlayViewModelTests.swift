import Combine
import Foundation
@testable import MEGAVideoPlayer
import MEGAVideoPlayerMock
import Testing

@MainActor
struct PlayerOverlayViewModelTests {

    // MARK: - Helper

    private func makeSUT(
        player: some VideoPlayerProtocol = MockVideoPlayer(),
        didTapBackAction: @escaping () -> Void = {},
        didTapRotateAction: @escaping () -> Void = {}
    ) -> PlayerOverlayViewModel {
        PlayerOverlayViewModel(
            player: player,
            didTapBackAction: didTapBackAction,
            didTapRotateAction: didTapRotateAction
        )
    }

    // MARK: - Initial State Tests

    @Test
    func initialState() {
        let sut = makeSUT()

        #expect(sut.state == .stopped)
        #expect(sut.currentTime == .seconds(0))
        #expect(sut.duration == .seconds(0))
        #expect(sut.isControlsVisible == true)
        #expect(sut.currentSpeed == .normal)
        #expect(sut.isLoopEnabled == false)
        #expect(sut.isPlaybackBottomSheetPresented == false)
        #expect(sut.scalingMode == .fit)
        #expect(sut.isSeeking == false)
    }

    // MARK: - State Change Tests

    struct StateChangeTestCase {
        let initialState: PlaybackState
        let newState: PlaybackState

        init(
            initialState: PlaybackState = .stopped,
            newState: PlaybackState
        ) {
            self.initialState = initialState
            self.newState = newState
        }
    }

    @Test(
        arguments: [
            StateChangeTestCase(
                newState: .opening,
            ),
            StateChangeTestCase(
                initialState: .opening,
                newState: .playing
            ),
            StateChangeTestCase(
                initialState: .playing,
                newState: .paused
            ),
            StateChangeTestCase(
                initialState: .playing,
                newState: .buffering
            ),
            StateChangeTestCase(
                initialState: .playing,
                newState: .ended
            ),
            StateChangeTestCase(
                initialState: .playing,
                newState: .error("Test error")
            ),
            StateChangeTestCase(
                initialState: .playing,
                newState: .stopped
            )
        ]
    )
    func stateChange(_ testCase: StateChangeTestCase) async {
        let mockPlayer = MockVideoPlayer(state: testCase.initialState)
        let sut = makeSUT(player: mockPlayer)
        sut.viewWillAppear()

        mockPlayer.state = testCase.newState

        try? await Task.sleep(for: .milliseconds(100))

        #expect(sut.state == testCase.newState)
    }

    // MARK: - Controls Visibility Tests

    @Test
    func showControls() {
        let sut = makeSUT()

        sut.showControls()

        #expect(sut.isControlsVisible == true)
    }

    @Test
    func hideControls() {
        let sut = makeSUT()

        sut.hideControls()

        #expect(sut.isControlsVisible == false)
    }

    @Test(arguments: [
        (true, false),
        (false, true)
    ])
    func didTapVideoArea(
        initialControlsVisible: Bool,
        afterControlsVisible: Bool
    ) {
        let sut = makeSUT()
        sut.isControlsVisible = initialControlsVisible

        sut.didTapVideoArea()

        #expect(sut.isControlsVisible == afterControlsVisible)
    }

    @Test(arguments: [
        (PlaybackState.playing, false),
        (.paused, true),
        (.buffering, true),
        (.opening, false),
        (.stopped, false),
        (.ended, false),
        (.error("Test error"), false)
    ])
    func autoHideTimer_whenShowControlsAfterThreeSeconds_shouldChangeControlVisibility(
        playerState: PlaybackState,
        expectedIsControlsVisible: Bool
    ) async {
        let sut = makeSUT()
        sut.state = playerState
        sut.isControlsVisible = false
        sut.showControls()
        #expect(sut.isControlsVisible == true)

        try? await Task.sleep(nanoseconds: 3_100_000_000) // 3.1 seconds
        
        #expect(sut.isControlsVisible == expectedIsControlsVisible)
    }

    @Test(arguments: [
        (PlaybackState.playing, false),
        (.paused, true),
        (.buffering, true),
        (.opening, false),
        (.stopped, false),
        (.ended, false),
        (.error("Test error"), false)
    ])
    func autoHideTimer_whenControlTappedAndAfterThreeSeconds_shouldChangeControlVisibility(
        playerState: PlaybackState,
        expectedIsControlsVisible: Bool
    ) async {
        let sut = makeSUT()
        sut.state = playerState
        sut.isControlsVisible = true

        sut.didTapPlay()

        try? await Task.sleep(nanoseconds: 3_100_000_000) // 3.1 seconds

        #expect(sut.isControlsVisible == expectedIsControlsVisible)
    }

    // MARK: - User Interaction Tests

    @Test(arguments: [
        PlaybackState.stopped, .ended
    ])
    func didTapPlay_whenStoppedOrEnded_seeksToZeroAndPlays(
        playerState: PlaybackState
    ) {
        let mockPlayer = MockVideoPlayer()
        let sut = makeSUT(player: mockPlayer)
        sut.state = playerState

        sut.didTapPlay()

        #expect(mockPlayer.seekCallCount == 1)
        #expect(mockPlayer.seekTime == 0)
        #expect(mockPlayer.playCallCount == 1)
    }

    @Test
    func didTapPlay_whenPlaying_justPlays() {
        let mockPlayer = MockVideoPlayer()
        let expectedSeekTime = 1.0
        mockPlayer.seekTime = expectedSeekTime
        let sut = makeSUT(player: mockPlayer)
        sut.state = .playing

        sut.didTapPlay()

        #expect(mockPlayer.seekCallCount == 0)
        #expect(mockPlayer.playCallCount == 1)
        #expect(mockPlayer.seekTime == expectedSeekTime)
    }

    @Test
    func didTapPause_callsPause() {
        let mockPlayer = MockVideoPlayer()
        let sut = makeSUT(player: mockPlayer)

        sut.didTapPause()

        #expect(mockPlayer.pauseCallCount == 1)
    }

    @Test(arguments: [
        (15, 50, 65.0),
        (15, 90, 100.0),
        (-15, 50, 35.0),
        (-15, 0, 0.0),
    ])
    func didTapJump(
        seconds: Int,
        initialTime: Int = 50,
        expectedSeekTime: TimeInterval
    ) async {
        let mockPlayer = MockVideoPlayer()
        let sut = makeSUT(player: mockPlayer)
        sut.duration = .seconds(100)
        sut.currentTime = .seconds(initialTime)

        await sut.didTapJump(by: seconds)

        #expect(sut.currentTime == Duration.seconds(expectedSeekTime))
        #expect(mockPlayer.seekTime == expectedSeekTime)
        #expect(mockPlayer.seekCallCount == 1)
    }

    @Test
    func didTapPlaybackSpeed_shouldShowSelectPlaybackSpeedBottomSheet() async throws {
        let sut = makeSUT()
        #expect(sut.isPlaybackBottomSheetPresented == false)

        sut.didTapPlaybackSpeed()

        #expect(sut.isPlaybackBottomSheetPresented == true)
    }

    @Test(arguments: [
        (PlaybackSpeed.quarter, PlaybackSpeed.half),
        (.half, .threeQuarter),
        (.threeQuarter, .normal),
        (.normal, .oneQuarter),
        (.oneQuarter, .oneHalf),
        (.oneHalf, .oneThreeQuarter),
        (.oneThreeQuarter, .double),
        (.double, .quarter)
    ])
    func didSelectPlaybackSpeed(
        currentSpeed: PlaybackSpeed,
        expectedNextSpeed: PlaybackSpeed
    ) async throws {
        let sut = makeSUT()
        sut.currentSpeed = currentSpeed

        sut.didSelectPlaybackSpeed(expectedNextSpeed)

        #expect(sut.currentSpeed == expectedNextSpeed)
    }

    // MARK: - Time and Duration Tests

    @Test
    func currentTimeUpdates() {
        let sut = makeSUT()
        let expectedTime = Duration.seconds(125)
        
        sut.currentTime = expectedTime

        #expect(sut.currentTime == expectedTime)
    }

    @Test
    func durationUpdates() {
        let sut = makeSUT()
        let expectedDuration = Duration.seconds(3600)
        
        sut.duration = expectedDuration

        #expect(sut.duration == expectedDuration)
    }

    // MARK: - UI Logic Tests

    @Test(arguments: [
        (Duration.seconds(125), Duration.seconds(130), "02:05 / 02:10"),
        (.seconds(3661), .seconds(3671), "01:01:01 / 01:01:11")
    ])
    func currentTimeString_formatsCorrectly(
        time: Duration,
        duration: Duration,
        expectedString: String
    ) {
        let sut = makeSUT()
        sut.currentTime = time
        sut.duration = duration
        #expect(sut.currentTimeAndDurationString == expectedString)
    }

    @Test(arguments: [
        (Duration.seconds(30), Duration.seconds(120), 0.25),
        (.seconds(30), .seconds(0), 0),
        (.seconds(0), .seconds(120), 0)
    ])
    func progress_calculatesCorrectly(
        currentTime: Duration,
        duration: Duration,
        expectedProgress: Double
    ) {
        let sut = makeSUT()
        sut.currentTime = currentTime
        sut.duration = duration

        #expect(abs(sut.progress - expectedProgress) < 0.001)
    }

    @Test(arguments: [
        (PlaybackSpeed.quarter, "0.25x"),
        (.half, "0.5x"),
        (.threeQuarter, "0.75x"),
        (.normal, "1x"),
        (.oneQuarter, "1.25x"),
        (.oneHalf, "1.5x"),
        (.oneThreeQuarter, "1.75x"),
        (.double, "2x")
    ])
    func currentSpeedString(
        currentSpeed: PlaybackSpeed,
        expectedCurrentSpeedString: String
    ) async throws {
        let sut = makeSUT()
        sut.currentSpeed = currentSpeed

        #expect(sut.currentSpeedString == expectedCurrentSpeedString)
    }
    
    // MARK: - Loop Button Tests
    
    @Test
    func didTapLoopButton_togglesLoopEnabled() {
        let mockPlayer = MockVideoPlayer()
        let sut = makeSUT(player: mockPlayer)
        
        // Initial state
        #expect(sut.isLoopEnabled == false)
        #expect(mockPlayer.setLoopingCallCount == 0)

        // First tap - should enable loop
        sut.didTapLoopButton()
        #expect(sut.isLoopEnabled == true)
        #expect(mockPlayer.setLoopingCallCount == 1)
        #expect(mockPlayer.setLoopingValue == true)

        // Second tap - should disable loop
        sut.didTapLoopButton()
        #expect(sut.isLoopEnabled == false)
        #expect(mockPlayer.setLoopingCallCount == 2)
        #expect(mockPlayer.setLoopingValue == false)
    }

    // MARK: - Rotation Tests
    
    @Test
    func didTapRotate_callsRotateAction() {
        var rotateActionCalled = false
        let sut = makeSUT(
            didTapRotateAction: {
                rotateActionCalled = true
            }
        )
        
        sut.didTapRotate()
        
        #expect(rotateActionCalled == true)
    }
    
    // MARK: - Scaling Tests
    
    @Test
    func didTapScalingButton_togglesScalingMode() {
        let mockPlayer = MockVideoPlayer()
        let sut = makeSUT(player: mockPlayer)
        #expect(sut.scalingMode == .fit)

        // First tap - should switch to fill mode
        sut.didTapScalingButton()
        #expect(sut.scalingMode == .fill)
        #expect(mockPlayer.setScalingModeCallCount == 1)
        #expect(mockPlayer.setScalingModeValue == .fill)

        // Second tap - should switch back to fit mode
        sut.didTapScalingButton()
        #expect(sut.scalingMode == .fit)
        #expect(mockPlayer.setScalingModeCallCount == 2)
        #expect(mockPlayer.setScalingModeValue == .fit)
    }
    
    @Test(arguments: [
        (VideoScalingMode.fill, 0.5, VideoScalingMode.fit, 2),
        (.fill, 1.5, .fill, 1),
        (.fit, 0.5, .fit, 1),
        (.fit, 1.5, .fill, 2)
    ])
    func handlePinchGesture(
        initialScale: VideoScalingMode,
        pinchScale: CGFloat,
        expectedScale: VideoScalingMode,
        expectedSetScalingModeCallCount: Int
    ) {
        let mockPlayer = MockVideoPlayer()
        mockPlayer.setScalingMode(initialScale)
        let sut = makeSUT(player: mockPlayer)
        sut.scalingMode = initialScale

        sut.handlePinchGesture(scale: pinchScale)

        #expect(sut.scalingMode == expectedScale)
        #expect(mockPlayer.setScalingModeCallCount == expectedSetScalingModeCallCount)
        #expect(mockPlayer.setScalingModeValue == expectedScale)
    }
    
    // MARK: - Seek Bar Tests
    
    @Test(arguments: [
        (Duration.seconds(100), true),
        (.seconds(0), false)
    ])
    func updateSeekBarDrag_whenDifferentDuration_shouldSetCorrectSeekingState(
        duration: Duration,
        expectedIsSeeking: Bool
    ) {
        let sut = makeSUT()
        sut.duration = duration
        let frame = CGRect(x: 0, y: 0, width: 100, height: 20)
        let location = CGPoint(x: 50, y: 10)

        sut.updateSeekBarDrag(at: location, in: frame)
        
        #expect(sut.isSeeking == expectedIsSeeking)
    }

    @Test(arguments: [
        (0, 0.0, "00:00 / 01:40"),
        (25, 0.25, "00:25 / 01:40"),
        (50, 0.50, "00:50 / 01:40"),
        (75, 0.75, "01:15 / 01:40"),
        (100, 1.0, "01:40 / 01:40")
    ])
    func updateSeekBarDrag_whenDifferentLocation_shouldSetCorrectProgressAndTimeString(
        location: CGFloat,
        expectedProgress: CGFloat,
        expectedCurrentTimeAndDurationString: String
    ) {
        let sut = makeSUT()
        sut.duration = .seconds(100)
        let frame = CGRect(x: 0, y: 0, width: 100, height: 20)
        let location = CGPoint(x: location, y: 10)

        sut.updateSeekBarDrag(at: location, in: frame)

        #expect(sut.isSeeking == true)
        #expect(sut.progress == expectedProgress)
        #expect(sut.currentTimeAndDurationString == expectedCurrentTimeAndDurationString)
    }
    
    @Test(arguments: [
        (0, 0, 0.0, Duration.seconds(0)),
        (25, 25, 0.25, Duration.seconds(25)),
        (50, 50, 0.50, Duration.seconds(50)),
        (75, 75, 0.75, Duration.seconds(75)),
        (100, 100, 1.0, Duration.seconds(100))
    ])
    func endSeekBarDrag_whenDifferentLocation_shouldUpdateSeekTimeAndProgressAndCurrentTime(
        location: CGFloat,
        expectedSeekTime: TimeInterval,
        expectedProgress: CGFloat,
        expectedCurrentTime: Duration
    ) async {
        let mockPlayer = MockVideoPlayer()
        let sut = makeSUT(player: mockPlayer)
        sut.duration = .seconds(100)

        let frame = CGRect(x: 0, y: 0, width: 100, height: 20)
        let location = CGPoint(x: location, y: 10)

        await sut.endSeekBarDrag(at: location, in: frame)

        #expect(sut.isSeeking == false)
        #expect(mockPlayer.seekTime == expectedSeekTime)
        #expect(sut.progress == expectedProgress)
        #expect(sut.currentTime == expectedCurrentTime)
    }

    @Test(arguments: [
        (Duration.seconds(100), true),
        (.seconds(0), false)
    ])
    func shouldShownJumpButtons(
        duration: Duration,
        expectedShouldShownJumpButtons: Bool
    ) {
        let sut = makeSUT()
        sut.duration = duration

        #expect(sut.shouldShownJumpButtons == expectedShouldShownJumpButtons)
    }
}
