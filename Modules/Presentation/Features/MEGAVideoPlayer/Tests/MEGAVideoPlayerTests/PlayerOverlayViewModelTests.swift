import Combine
@testable import MEGAVideoPlayer
import MEGAVideoPlayerMock
import Testing

@MainActor
struct PlayerOverlayViewModelTests {

    // MARK: - Helper

    private func makeSUT(
        player: VideoPlayerProtocol = MockVideoPlayer(),
        didTapBackAction: @escaping () -> Void = {}
    ) -> PlayerOverlayViewModel {
        PlayerOverlayViewModel(
            player: player,
            didTapBackAction: didTapBackAction
        )
    }

    // MARK: - Initial State Tests

    @Test
    func initialState() {
        let sut = makeSUT()

        #expect(sut.state == .stopped)
        #expect(sut.currentTime == .seconds(0))
        #expect(sut.duration == .seconds(0))
        #expect(sut.isLoading == true)
        #expect(sut.isControlsVisible == false)
    }

    // MARK: - State Change Tests

    struct StateChangeTestCase {
        let initialState: PlaybackState
        let newState: PlaybackState
        let expectedIsLoading: Bool

        init(
            initialState: PlaybackState = .stopped,
            newState: PlaybackState,
            expectedIsLoading: Bool
        ) {
            self.initialState = initialState
            self.newState = newState
            self.expectedIsLoading = expectedIsLoading
        }
    }

    @Test(
        arguments: [
            StateChangeTestCase(
                newState: .opening,
                expectedIsLoading: true
            ),
            StateChangeTestCase(
                initialState: .opening,
                newState: .playing,
                expectedIsLoading: false
            ),
            StateChangeTestCase(
                initialState: .playing,
                newState: .paused,
                expectedIsLoading: false
            ),
            StateChangeTestCase(
                initialState: .playing,
                newState: .buffering,
                expectedIsLoading: true
            ),
            StateChangeTestCase(
                initialState: .playing,
                newState: .ended,
                expectedIsLoading: false
            ),
            StateChangeTestCase(
                initialState: .playing,
                newState: .error("Test error"),
                expectedIsLoading: false
            ),
            StateChangeTestCase(
                initialState: .playing,
                newState: .stopped,
                expectedIsLoading: false
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
        #expect(sut.isLoading == testCase.expectedIsLoading)
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
        (.buffering, false),
        (.opening, false),
        (.stopped, false),
        (.ended, false),
        (.error("Test error"), false)
    ])
    func autoHideTimer_whenShowControlsAfter3Seconds(
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
        (.buffering, false),
        (.opening, false),
        (.stopped, false),
        (.ended, false),
        (.error("Test error"), false)
    ])
    func autoHideTimer_whenControlTappedAndAfterThreeSeconds(
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

    @Test
    func didTapJumpForward_callsJumpForward() {
        let mockPlayer = MockVideoPlayer()
        let sut = makeSUT(player: mockPlayer)

        sut.didTapJumpForward()

        #expect(mockPlayer.jumpForwardCallCount == 1)
        #expect(mockPlayer.jumpForwardSeconds == 10)
    }

    @Test
    func didTapJumpBackward_callsJumpBackward() {
        let mockPlayer = MockVideoPlayer()
        let sut = makeSUT(player: mockPlayer)

        sut.didTapJumpBackward()

        #expect(mockPlayer.jumpBackwardCallCount == 1)
        #expect(mockPlayer.jumpBackwardSeconds == 10)
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
    func didTapPlaybackSpeed(
        currentSpeed: PlaybackSpeed,
        expectedNextSpeed: PlaybackSpeed
    ) async throws {
        let sut = makeSUT()
        sut.currentSpeed = currentSpeed

        sut.didTapPlaybackSpeed()

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
        (Duration.seconds(125), "02:05"),
        (.seconds(3661), "01:01:01")
    ])
    func currentTimeString_formatsCorrectly(
        time: Duration,
        expectedString: String
    ) {
        let sut = makeSUT()
        sut.currentTime = time
        #expect(sut.currentTimeString == expectedString)
    }

    @Test(arguments: [
        (Duration.seconds(125), "02:05"),
        (.seconds(3661), "01:01:01")
    ])
    func durationString_formatsCorrectly(
        time: Duration,
        expectedString: String
    ) {
        let sut = makeSUT()
        sut.duration = time

        #expect(sut.durationString == expectedString)
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
}
