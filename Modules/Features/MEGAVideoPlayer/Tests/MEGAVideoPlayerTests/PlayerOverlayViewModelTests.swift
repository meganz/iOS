import AVFoundation
@preconcurrency import Combine
import Foundation
import MEGADomain
import MEGADomainMock
import MEGAInfrastructure
import MEGAInfrastructureMocks
import MEGAPermissions
import MEGAPermissionsMock
@testable import MEGAVideoPlayer
import MEGAVideoPlayerMock
import Testing
import UIKit

@MainActor
struct PlayerOverlayViewModelTests {

    // MARK: - Helper

    private func makeSUT(
        player: some VideoPlayerProtocol = MockVideoPlayer(),
        devicePermissionsHandler: some DevicePermissionsHandling = MockDevicePermissionHandler(),
        saveSnapshotUseCase: some SaveSnapshotUseCaseProtocol = MockSaveSnapshotUseCase(),
        hapticFeedbackUseCase: some HapticFeedbackUseCaseProtocol = MockHapticFeedbackUseCase(),
        didTapBackAction: @escaping () -> Void = {},
        didTapMoreAction: @escaping ((any PlayableNode)?) -> Void = { _ in },
        didDragToDismissAction: @escaping () -> Void = {},
        didTapRotateAction: @escaping () -> Void = {},
        didTapPictureInPictureAction: @escaping () -> Void = {}
    ) -> PlayerOverlayViewModel {
        PlayerOverlayViewModel(
            player: player,
            devicePermissionsHandler: devicePermissionsHandler,
            saveSnapshotUseCase: saveSnapshotUseCase,
            hapticFeedbackUseCase: hapticFeedbackUseCase,
            didTapBackAction: didTapBackAction,
            didTapMoreAction: didTapMoreAction,
            didDragToDismissAction: didDragToDismissAction,
            didTapRotateAction: didTapRotateAction,
            didTapPictureInPictureAction: didTapPictureInPictureAction
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
        #expect(sut.shouldShowHoldToSpeedChip == false)
        #expect(sut.isDoubleTapSeekActive == false)
        #expect(sut.doubleTapSeekSeconds == 0)
        #expect(sut.isLocked == false)
        #expect(sut.isLockOverlayVisible == false)
        #expect(sut.bufferRange == nil)
        #expect(sut.shouldShowPhotoPermissionAlert == false)
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
        (.ended, true),
        // A failed playback keeps its controls: the play button is the only way out of it.
        (.error("Test error"), true)
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
        (.ended, true),
        // A failed playback keeps its controls: the play button is the only way out of it.
        (.error("Test error"), true)
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

    /// A failed item is terminal, so plain `play()` would neither resume nor reach the network. Rebuilding
    /// it re-issues the streaming request, which is what raises the over-quota warning again.
    @Test
    func didTapPlay_whenError_replaysCurrentNodeInsteadOfPlaying() {
        let mockPlayer = MockVideoPlayer()
        let sut = makeSUT(player: mockPlayer)
        sut.state = .error("Test error")

        sut.didTapPlay()

        #expect(mockPlayer.replayCurrentNodeCallCount == 1)
        // Resumes where playback died, so it must not rewind the way `.stopped` and `.ended` do.
        #expect(mockPlayer.seekCallCount == 0)
        #expect(mockPlayer.playCallCount == 0)
    }

    /// Playback can fail while the controls are hidden, leaving the user no play button to reach.
    @Test
    func stateChange_whenError_showsControls() async {
        let mockPlayer = MockVideoPlayer(state: .playing)
        let sut = makeSUT(player: mockPlayer)
        sut.viewWillAppear()
        sut.isControlsVisible = false

        mockPlayer.state = .error("Test error")

        try? await Task.sleep(for: .milliseconds(100))

        #expect(sut.isControlsVisible == true)
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
        (-15, 0, 0.0)
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
        #expect(mockPlayer.seekTimes == [expectedSeekTime])
        #expect(mockPlayer.seekTimes.count == 1)
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

    // MARK: - Hold to Speed Tests

    @Test(arguments: [
        (Duration.seconds(100), true, [HapticFeedbackType.light]),
        (.seconds(0), false, [])
    ])
    func beginHoldToSpeed_whenDifferentVideoLoadedState_shouldSetRightActivateHoldSpeed(
        duration: Duration,
        expectedShouldShowHoldToSpeedChip: Bool,
        expectedHapticFeedbacks: [HapticFeedbackType]
    ) {
        let mockPlayer = MockVideoPlayer()
        let mockHapticFeedbackUseCase = MockHapticFeedbackUseCase()
        let sut = makeSUT(
            player: mockPlayer,
            hapticFeedbackUseCase: mockHapticFeedbackUseCase
        )
        sut.duration = duration
        sut.state = .playing

        sut.beginHoldToSpeed()

        #expect(mockHapticFeedbackUseCase.feedbacks == expectedHapticFeedbacks)
        #expect(sut.shouldShowHoldToSpeedChip == expectedShouldShowHoldToSpeedChip)
    }

    @Test(arguments: [
        (PlaybackSpeed.quarter, true, [HapticFeedbackType.light]),
        (.half, true, [.light]),
        (.threeQuarter, true, [.light]),
        (.normal, true, [.light]),
        (.oneQuarter, true, [.light]),
        (.oneHalf, true, [.light]),
        (.oneThreeQuarter, true, [.light]),
        (.double, false, [])
    ])
    func beginHoldToSpeed_whenDifferentSpeeds_shouldActivateHoldSpeed(
        currentSpeed: PlaybackSpeed,
        expectedShouldShowHoldToSpeedChip: Bool,
        expectedHapticFeedbacks: [HapticFeedbackType]
    ) {
        let mockPlayer = MockVideoPlayer()
        let mockHapticFeedbackUseCase = MockHapticFeedbackUseCase()
        let sut = makeSUT(
            player: mockPlayer,
            hapticFeedbackUseCase: mockHapticFeedbackUseCase
        )
        sut.duration = .seconds(100)
        sut.currentSpeed = currentSpeed
        sut.state = .playing

        sut.beginHoldToSpeed()

        #expect(mockHapticFeedbackUseCase.feedbacks == expectedHapticFeedbacks)
        #expect(sut.shouldShowHoldToSpeedChip == expectedShouldShowHoldToSpeedChip)
        #expect(sut.isControlsVisible == false)
        #expect(mockPlayer.changeRateCallCount == 1)
        #expect(mockPlayer.changeRateValue == PlaybackSpeed.double.rawValue)
    }

    @Test
    func endHoldToSpeed_whenHoldActive_shouldDeactivateAndRestoreSpeed() {
        let mockPlayer = MockVideoPlayer()
        let sut = makeSUT(player: mockPlayer)
        sut.duration = .seconds(100)
        sut.currentSpeed = .normal
        sut.shouldShowHoldToSpeedChip = true
        sut.state = .playing
        sut.beginHoldToSpeed()
        #expect(sut.shouldShowHoldToSpeedChip == true)

        sut.endHoldToSpeed()

        #expect(sut.shouldShowHoldToSpeedChip == false)
        #expect(mockPlayer.changeRateCallCount == 2)
        #expect(mockPlayer.changeRateValue == PlaybackSpeed.normal.rawValue)
    }

    @Test
    func endHoldToSpeed_whenHoldNotActive_shouldNotChangeRate() {
        let mockPlayer = MockVideoPlayer()
        let sut = makeSUT(player: mockPlayer)
        sut.duration = .seconds(100)

        sut.endHoldToSpeed()

        #expect(mockPlayer.changeRateCallCount == 0)
    }

    // MARK: - Double Tap Seek Tests

    @Test(arguments: [
        (Duration.seconds(100), true, [HapticFeedbackType.light]),
        (.seconds(0), false, [])
    ])
    func handleDoubleTapSeek_whenDifferentVideoLoadedState_shouldSetRightActivateSeek(
        duration: Duration,
        expectedIsDoubleTapSeekActive: Bool,
        expectedHapticFeedbacks: [HapticFeedbackType]
    ) async {
        let mockPlayer = MockVideoPlayer()
        let mockHapticFeedbackUseCase = MockHapticFeedbackUseCase()
        let sut = makeSUT(
            player: mockPlayer,
            hapticFeedbackUseCase: mockHapticFeedbackUseCase
        )
        sut.duration = duration

        await sut.handleDoubleTapSeek(isForward: true)

        #expect(mockHapticFeedbackUseCase.feedbacks == expectedHapticFeedbacks)
        #expect(sut.isDoubleTapSeekActive == expectedIsDoubleTapSeekActive)
    }

    @Test
    func handleDoubleTapSeek_whenForwardSeek_shouldActivateAndSeekForward() async {
        let mockPlayer = MockVideoPlayer()
        let mockHapticFeedbackUseCase = MockHapticFeedbackUseCase()
        let sut = makeSUT(
            player: mockPlayer,
            hapticFeedbackUseCase: mockHapticFeedbackUseCase
        )
        sut.duration = .seconds(100)
        sut.currentTime = .seconds(50)

        await sut.handleDoubleTapSeek(isForward: true)

        #expect(mockHapticFeedbackUseCase.feedbacks == [HapticFeedbackType.light])
        #expect(sut.isDoubleTapSeekActive == true)
        #expect(sut.doubleTapSeekSeconds == 15)
        #expect(mockPlayer.seekTimes == [65.0])
    }

    @Test
    func handleDoubleTapSeek_whenBackwardSeek_shouldActivateAndSeekBackward() async {
        let mockPlayer = MockVideoPlayer()
        let mockHapticFeedbackUseCase = MockHapticFeedbackUseCase()
        let sut = makeSUT(
            player: mockPlayer,
            hapticFeedbackUseCase: mockHapticFeedbackUseCase
        )
        sut.duration = .seconds(100)
        sut.currentTime = .seconds(50)

        await sut.handleDoubleTapSeek(isForward: false)

        #expect(mockHapticFeedbackUseCase.feedbacks == [HapticFeedbackType.light])
        #expect(sut.isDoubleTapSeekActive == true)
        #expect(sut.doubleTapSeekSeconds == -15)
        #expect(mockPlayer.seekTimes == [35.0])
    }

    @Test
    func handleDoubleTapSeek_whenMultipleForwardTaps_shouldIncrementCorrectly() async {
        let mockPlayer = MockVideoPlayer()
        let sut = makeSUT(player: mockPlayer)
        sut.duration = .seconds(100)
        sut.currentTime = .seconds(50)

        // First tap
        await sut.handleDoubleTapSeek(isForward: true)
        #expect(sut.doubleTapSeekSeconds == 15)
        #expect(mockPlayer.seekTimes.last == 65.0)

        // Second tap within 3 seconds
        await sut.handleDoubleTapSeek(isForward: true)
        #expect(sut.doubleTapSeekSeconds == 30)
        #expect(mockPlayer.seekTimes.last == 80.0)

        // Third tap within 3 seconds
        await sut.handleDoubleTapSeek(isForward: true)
        #expect(sut.doubleTapSeekSeconds == 45)
        #expect(mockPlayer.seekTimes.last == 95.0)
    }

    @Test
    func handleDoubleTapSeek_whenMultipleBackwardTaps_shouldIncrementCorrectly() async {
        let mockPlayer = MockVideoPlayer()
        let sut = makeSUT(player: mockPlayer)
        sut.duration = .seconds(100)
        sut.currentTime = .seconds(50)

        // First tap
        await sut.handleDoubleTapSeek(isForward: false)
        #expect(sut.doubleTapSeekSeconds == -15)
        #expect(mockPlayer.seekTimes.last == 35.0)

        // Second tap within 3 seconds
        await sut.handleDoubleTapSeek(isForward: false)
        #expect(sut.doubleTapSeekSeconds == -30)
        #expect(mockPlayer.seekTimes.last == 20.0)

        // Third tap within 3 seconds
        await sut.handleDoubleTapSeek(isForward: false)
        #expect(sut.doubleTapSeekSeconds == -45)
        #expect(mockPlayer.seekTimes.last == 5.0)
    }

    @Test
    func doubleTapSeekTimer_whenThreeSecondsPass_shouldDeactivateSeek() async {
        let mockPlayer = MockVideoPlayer()
        let sut = makeSUT(player: mockPlayer)
        sut.duration = .seconds(100)
        sut.currentTime = .seconds(50)

        await sut.handleDoubleTapSeek(isForward: true)
        #expect(sut.isDoubleTapSeekActive == true)
        #expect(sut.doubleTapSeekSeconds == 15)

        // Wait for timer to expire
        try? await Task.sleep(nanoseconds: 3_100_000_000) // 3.1 seconds

        #expect(sut.isDoubleTapSeekActive == false)
        #expect(sut.doubleTapSeekSeconds == 0)
    }

    @Test(arguments: [
        (15, "15 seconds"),
        (-15, "15 seconds"),
        (30, "30 seconds"),
        (-30, "30 seconds"),
        (45, "45 seconds"),
        (-45, "45 seconds")
    ])
    func doubleTapSeekDisplayText_whenDifferentSeekValues_shouldFormatCorrectly(
        seekSeconds: Int,
        expectedText: String
    ) {
        let sut = makeSUT()
        sut.doubleTapSeekSeconds = seekSeconds

        #expect(sut.doubleTapSeekDisplayText == expectedText)
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

    @Test(arguments: [true, false])
    func init_adoptsLoopStateFromPlayer(_ playerLoopState: Bool) {
        let mockPlayer = MockVideoPlayer()
        mockPlayer.isLoopEnabled = playerLoopState

        let sut = makeSUT(player: mockPlayer)

        #expect(sut.isLoopEnabled == playerLoopState)
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
        (Duration.seconds(100), [TimeInterval(50)]),
        (.seconds(0), [])
    ])
    func updateSeekBarDrag_shouldOnlySeekOnceTheVideoIsLoaded(
        duration: Duration,
        expectedSeekTimes: [TimeInterval]
    ) async {
        let mockPlayer = MockVideoPlayer()
        let sut = makeSUT(player: mockPlayer)
        sut.duration = duration
        let frame = CGRect(x: 0, y: 0, width: 100, height: 20)
        let location = CGPoint(x: 50, y: 10)

        await sut.updateSeekBarDrag(at: location, in: frame)

        #expect(mockPlayer.seekTimes == expectedSeekTimes)
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
    ) async {
        let sut = makeSUT()
        sut.duration = .seconds(100)
        let frame = CGRect(x: 0, y: 0, width: 100, height: 20)
        let location = CGPoint(x: location, y: 10)

        await sut.updateSeekBarDrag(at: location, in: frame)

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
        #expect(mockPlayer.seekTimes.last == expectedSeekTime)
        #expect(sut.progress == expectedProgress)
        #expect(sut.currentTime == expectedCurrentTime)
    }

    @Test
    func updateSeekBarDrag_whenDraggingAcrossTheTimeline_shouldSeekToEveryPositionItPassesOver() async {
        let mockPlayer = MockVideoPlayer()
        let sut = makeSUT(player: mockPlayer)
        sut.duration = .seconds(100)
        let frame = CGRect(x: 0, y: 0, width: 100, height: 20)

        for x in [CGFloat(10), 20, 30] {
            await sut.updateSeekBarDrag(at: CGPoint(x: x, y: 10), in: frame)
        }
        await sut.endSeekBarDrag(at: CGPoint(x: 40, y: 10), in: frame)

        #expect(mockPlayer.seekTimes == [10, 20, 30, 40])
    }

    @Test
    func updateSeekBarDrag_whenDurationIsZero_shouldNotSeek() async {
        let mockPlayer = MockVideoPlayer()
        let sut = makeSUT(player: mockPlayer)
        sut.duration = .seconds(0)
        let frame = CGRect(x: 0, y: 0, width: 100, height: 20)

        await sut.updateSeekBarDrag(at: CGPoint(x: 50, y: 10), in: frame)
        await sut.endSeekBarDrag(at: CGPoint(x: 50, y: 10), in: frame)

        #expect(mockPlayer.seekTimes.isEmpty)
        #expect(sut.isScrubbing == false)
    }

    /// A whole-second grid would make it impossible to land on a particular frame, so the seek must
    /// keep the sub-second part of the dragged position.
    @Test(arguments: [
        (CGFloat(1.5), TimeInterval(1.5)),
        (5.5, 5.5),
        (7.5, 7.5)
    ])
    func seekBarDrag_shouldKeepSubSecondPrecision(
        location: CGFloat,
        expectedTime: TimeInterval
    ) async {
        let mockPlayer = MockVideoPlayer()
        let sut = makeSUT(player: mockPlayer)
        // 1000 seconds on a 1000 point wide bar: one point is one second, so half a point lands
        // between two seconds.
        sut.duration = .seconds(1000)
        let frame = CGRect(x: 0, y: 0, width: 1000, height: 20)

        await sut.updateSeekBarDrag(at: CGPoint(x: location, y: 10), in: frame)

        #expect(mockPlayer.seekTimes == [expectedTime])
        #expect(sut.currentTime == .milliseconds(expectedTime * 1000))
    }

    /// Playback is paused for the length of the drag, otherwise it keeps advancing past every seek
    /// and the scrubbed frames never settle on screen.
    @Test(arguments: [
        (PlaybackState.playing, 1),
        (.buffering, 1),
        (.paused, 0)
    ])
    func updateSeekBarDrag_shouldPausePlaybackForTheDrag(
        state: PlaybackState,
        expectedPauseCallCount: Int
    ) async {
        let mockPlayer = MockVideoPlayer()
        let sut = makeSUT(player: mockPlayer)
        sut.duration = .seconds(100)
        sut.state = state
        let frame = CGRect(x: 0, y: 0, width: 100, height: 20)

        await sut.updateSeekBarDrag(at: CGPoint(x: 10, y: 10), in: frame)
        await sut.updateSeekBarDrag(at: CGPoint(x: 20, y: 10), in: frame)

        #expect(sut.isScrubbing == true)
        // Pausing happens once for the whole drag, not on every drag update.
        #expect(mockPlayer.pauseCallCount == expectedPauseCallCount)
    }

    @Test(arguments: [
        (PlaybackState.playing, 1),
        (.paused, 0)
    ])
    func endSeekBarDrag_shouldOnlyResumePlaybackThatScrubbingPaused(
        state: PlaybackState,
        expectedPlayCallCount: Int
    ) async {
        let mockPlayer = MockVideoPlayer()
        let sut = makeSUT(player: mockPlayer)
        sut.duration = .seconds(100)
        sut.state = state
        let frame = CGRect(x: 0, y: 0, width: 100, height: 20)

        await sut.updateSeekBarDrag(at: CGPoint(x: 10, y: 10), in: frame)
        await sut.endSeekBarDrag(at: CGPoint(x: 20, y: 10), in: frame)

        #expect(mockPlayer.playCallCount == expectedPlayCallCount)
        #expect(mockPlayer.seekTimes.last == 20)
        #expect(sut.isScrubbing == false)
        #expect(sut.isSeeking == false)
    }

    /// Playback is handed back the moment the finger lifts, so a drag starting right after another
    /// one pauses again instead of inheriting a resume that has already been used.
    @Test
    func seekBarDrag_shouldPauseAndResumePlaybackOncePerDrag() async {
        let mockPlayer = MockVideoPlayer()
        let sut = makeSUT(player: mockPlayer)
        sut.duration = .seconds(100)
        sut.state = .playing
        let frame = CGRect(x: 0, y: 0, width: 100, height: 20)

        await sut.updateSeekBarDrag(at: CGPoint(x: 10, y: 10), in: frame)
        await sut.updateSeekBarDrag(at: CGPoint(x: 20, y: 10), in: frame)
        await sut.endSeekBarDrag(at: CGPoint(x: 30, y: 10), in: frame)

        #expect(mockPlayer.pauseCallCount == 1)
        #expect(mockPlayer.playCallCount == 1)

        await sut.updateSeekBarDrag(at: CGPoint(x: 60, y: 10), in: frame)
        await sut.endSeekBarDrag(at: CGPoint(x: 70, y: 10), in: frame)

        #expect(mockPlayer.pauseCallCount == 2)
        #expect(mockPlayer.playCallCount == 2)
        #expect(mockPlayer.seekTimes == [10, 20, 30, 60, 70])
        #expect(sut.isScrubbing == false)
        #expect(sut.isSeeking == false)
    }

    /// Playback is handed back the moment the finger lifts rather than waiting for the released
    /// position to be reached: the per-frame seeks already left the playhead under the finger, so a
    /// slow seek must not hold playback back. The timeline stays guarded until that seek lands.
    @Test
    func endSeekBarDrag_shouldResumePlaybackWithoutWaitingForTheSeek() async {
        let mockPlayer = MockVideoPlayer()
        mockPlayer.seekDelay = .milliseconds(300)
        let sut = makeSUT(player: mockPlayer)
        sut.duration = .seconds(100)
        sut.state = .playing
        let frame = CGRect(x: 0, y: 0, width: 100, height: 20)

        await sut.updateSeekBarDrag(at: CGPoint(x: 10, y: 10), in: frame)
        let drag = Task { await sut.endSeekBarDrag(at: CGPoint(x: 40, y: 10), in: frame) }
        try? await Task.sleep(for: .milliseconds(50))

        #expect(mockPlayer.playCallCount == 1, "playback is back before the seek lands")
        #expect(mockPlayer.seekTimes.last == 40)
        #expect(sut.isSeeking == true, "the timeline is still guarded while the seek is in flight")

        await drag.value

        #expect(sut.isSeeking == false)
    }

    /// A bar mid-layout reports a zero width, and the position/width ratio would come out NaN and
    /// clamp to zero — seeking the video back to its start. The drag must be dropped instead, and
    /// playback handed back rather than left paused.
    @Test
    func seekBarDrag_whenTheBarHasNoWidthYet_shouldNotSeekToTheStart() async {
        let mockPlayer = MockVideoPlayer()
        let sut = makeSUT(player: mockPlayer)
        sut.duration = .seconds(100)
        sut.state = .playing
        sut.currentTime = .seconds(42)
        let collapsed = CGRect(x: 0, y: 0, width: 0, height: 20)

        await sut.updateSeekBarDrag(at: CGPoint(x: 0, y: 10), in: collapsed)
        await sut.endSeekBarDrag(at: CGPoint(x: 0, y: 10), in: collapsed)

        #expect(mockPlayer.seekTimes.isEmpty)
        #expect(sut.currentTime == .seconds(42))
        #expect(sut.isScrubbing == false)
    }

    /// The same drag arriving on a bar that does have a width must still resume playback it paused.
    @Test
    func seekBarDrag_whenTheBarLosesItsWidthMidDrag_shouldStillHandPlaybackBack() async {
        let mockPlayer = MockVideoPlayer()
        let sut = makeSUT(player: mockPlayer)
        sut.duration = .seconds(100)
        sut.state = .playing
        let frame = CGRect(x: 0, y: 0, width: 100, height: 20)
        let collapsed = CGRect(x: 0, y: 0, width: 0, height: 20)

        await sut.updateSeekBarDrag(at: CGPoint(x: 30, y: 10), in: frame)
        await sut.endSeekBarDrag(at: CGPoint(x: 30, y: 10), in: collapsed)

        #expect(mockPlayer.pauseCallCount == 1)
        #expect(mockPlayer.playCallCount == 1)
        #expect(mockPlayer.seekTimes == [30])
        #expect(sut.isScrubbing == false)
    }

    /// Per-frame seeks are fire and forget, so a slow player neither stalls the drag nor lets the
    /// timeline slip out of the gesture's hands while the finger is still down.
    @Test
    func updateSeekBarDrag_whenThePlayerIsSlow_shouldKeepSeekingAndKeepHoldingTheTimeline() async {
        let mockPlayer = MockVideoPlayer()
        mockPlayer.seekDelay = .milliseconds(500)
        let sut = makeSUT(player: mockPlayer)
        sut.duration = .seconds(100)
        let frame = CGRect(x: 0, y: 0, width: 100, height: 20)

        // Issued the way the View issues them — each drag update in its own task — so the seeks
        // overlap instead of queueing behind one another. The gap only fixes the order they are
        // issued in; every seek is still in flight when the expectations below run.
        for x in [CGFloat(10), 20, 30] {
            Task { await sut.updateSeekBarDrag(at: CGPoint(x: x, y: 10), in: frame) }
            try? await Task.sleep(for: .milliseconds(20))
        }

        #expect(mockPlayer.seekTimes == [10, 20, 30])
        #expect(sut.isSeeking == true)
        #expect(sut.isScrubbing == true)
        #expect(mockPlayer.pauseCallCount == 0)
    }

    /// A new item makes a seek still in flight moot: keeping the timeline guarded would leave the bar
    /// frozen for the video that just started.
    @Test
    func openingANewItem_shouldStopGuardingTheTimeline() async {
        let mockPlayer = MockVideoPlayer(duration: .seconds(100))
        mockPlayer.seekDelay = .milliseconds(300)
        let sut = makeSUT(player: mockPlayer)
        sut.viewWillAppear()
        try? await Task.sleep(for: .milliseconds(50))

        let seek = Task { await sut.performSeek(to: .seconds(60)) }
        try? await Task.sleep(for: .milliseconds(50))
        #expect(sut.isSeeking == true)

        mockPlayer.state = .opening
        try? await Task.sleep(for: .milliseconds(50))

        #expect(sut.isSeeking == false)

        await seek.value
    }

    /// Until the seek lands the player still reports the position it is playing from, and that report
    /// must not drag the bar back from where the finger left it.
    @Test
    func endSeekBarDrag_whilePlayerReportsThePositionBeforeTheSeek_shouldNotSnapTheBarBack() async {
        let mockPlayer = MockVideoPlayer(currentTime: .seconds(10), duration: .seconds(100))
        mockPlayer.seekDelay = .milliseconds(300)
        let sut = makeSUT(player: mockPlayer)
        sut.viewWillAppear()
        try? await Task.sleep(for: .milliseconds(50))
        let frame = CGRect(x: 0, y: 0, width: 100, height: 20)

        let drag = Task { await sut.endSeekBarDrag(at: CGPoint(x: 60, y: 10), in: frame) }
        try? await Task.sleep(for: .milliseconds(50))
        mockPlayer.currentTime = .seconds(10)
        try? await Task.sleep(for: .milliseconds(50))

        #expect(sut.currentTime == .seconds(60))
        #expect(sut.progress == 0.6)

        await drag.value
        // Once the seek has landed, playback drives the bar again.
        mockPlayer.currentTime = .seconds(61)
        try? await Task.sleep(for: .milliseconds(50))

        #expect(sut.currentTime == .seconds(61))
    }

    @Test(arguments: [
        (Duration.seconds(10), 15, TimeInterval(25)),
        (.seconds(95), 15, 100),
        (.seconds(5), -15, 0)
    ])
    func performSeek_by_shouldForwardAnAbsoluteTargetClampedToTheVideo(
        currentTime: Duration,
        jump: Int,
        expectedTarget: TimeInterval
    ) async {
        let mockPlayer = MockVideoPlayer()
        let sut = makeSUT(player: mockPlayer)
        sut.duration = .seconds(100)
        sut.currentTime = currentTime

        await sut.performSeek(by: jump)

        #expect(mockPlayer.seekTimes == [expectedTarget])
    }

    /// Repeated taps and per-frame drag updates make these calls overlap. A superseded seek can
    /// resolve first, and it must not hand the timeline back while the newer one is still in flight.
    @Test
    func performSeek_whenASupersededSeekResolvesFirst_shouldNotReleaseTheTimeline() async {
        let mockPlayer = MockVideoPlayer(currentTime: .seconds(10), duration: .seconds(100))
        mockPlayer.seekDelay = .milliseconds(200)
        let sut = makeSUT(player: mockPlayer)
        sut.duration = .seconds(100)
        sut.currentTime = .seconds(10)

        let superseded = Task { await sut.performSeek(to: .seconds(25)) }
        try? await Task.sleep(for: .milliseconds(50))
        mockPlayer.seekDelay = .milliseconds(500)
        let newest = Task { await sut.performSeek(to: .seconds(40)) }
        await superseded.value

        #expect(sut.currentTime == .seconds(40))
        #expect(sut.isSeeking == true)

        await newest.value

        #expect(sut.isSeeking == false)
        #expect(mockPlayer.seekTimes == [25, 40])
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
    
    // MARK: - Buffer Range Tests
    
    @Test
    func bufferEndProgress_whenNilBufferRange_shouldReturnZero() {
        let sut = makeSUT()
        sut.duration = .seconds(100)
        sut.bufferRange = nil
        
        #expect(sut.bufferEndProgress == 0.0)
    }
    
    @Test
    func bufferEndProgress_whenZeroDuration_shouldReturnZero() {
        let sut = makeSUT()
        sut.duration = .seconds(0)
        sut.bufferRange = (start: .seconds(10), end: .seconds(40))

        #expect(sut.bufferEndProgress == 0.0)
    }
    
    @Test(arguments: [
        (0, 30, 100, 0.3),
        (10, 30, 100, 0.3),
        (25, 50, 100, 0.5),
        (0, 100, 100, 1.0),
        (50, 100, 200, 0.5)
    ])
    func bufferEndProgress_whenValidBufferRange_shouldReturnCorrectEndProgress(
        bufferStart: Double,
        bufferEnd: Double,
        totalDuration: Double,
        expectedEndProgress: CGFloat
    ) {
        let bufferRange = (
            start: Duration.seconds(bufferStart),
            end: Duration.seconds(bufferEnd)
        )
        let sut = makeSUT()
        sut.duration = .seconds(totalDuration)
        sut.bufferRange = bufferRange
        
        #expect(sut.bufferEndProgress == expectedEndProgress)
    }
    
    @Test
    func bufferStartProgress_whenNilBufferRange_shouldReturnZero() {
        let sut = makeSUT()
        sut.duration = .seconds(100)
        sut.bufferRange = nil
        
        #expect(sut.bufferStartProgress == 0.0)
    }
    
    @Test
    func bufferStartProgress_whenZeroDuration_shouldReturnZero() {
        let sut = makeSUT()
        sut.duration = .seconds(0)
        sut.bufferRange = (start: .seconds(10), end: .seconds(40))

        #expect(sut.bufferStartProgress == 0.0)
    }
    
    @Test(arguments: [
        (0, 30, 100, 0.0),
        (25, 75, 100, 0.25),
        (50, 75, 100, 0.5),
        (75, 100, 200, 0.375),
        (100, 200, 200, 0.5)
    ])
    func bufferStartProgress_whenValidBufferRange_shouldReturnCorrectStartProgress(
        bufferStart: Double,
        bufferEnd: Double,
        totalDuration: Double,
        expectedStartProgress: CGFloat
    ) {
        let bufferRange = (
            start: Duration.seconds(bufferStart),
            end: Duration.seconds(bufferEnd)
        )
        let sut = makeSUT()
        sut.duration = .seconds(totalDuration)
        sut.bufferRange = bufferRange
        
        #expect(sut.bufferStartProgress == expectedStartProgress)
    }
    
    @Test
    func bufferRangeObservation_whenPlayerBufferRangeChanges_shouldUpdateViewModel() async throws {
        let mockPlayer = MockVideoPlayer()
        let testRange = (start: Duration.seconds(10), end: Duration.seconds(40))
        let sut = makeSUT(player: mockPlayer)
        
        sut.viewWillAppear()
        
        mockPlayer.bufferRange = testRange

        _ = await sut.$bufferRange.values.first { @Sendable newRange in
            guard let newRange = newRange else { return false }
            return newRange == testRange
        }
        let bufferRange = try #require(sut.bufferRange)
        #expect(bufferRange == testRange)
    }
    
    // MARK: - Title Tests

    @Test
    func title_returnsPlayerTitle() async {
        let expectedTitle = "Test Video Title"
        let mockPlayer = MockVideoPlayer(nodeName: expectedTitle)
        let sut = makeSUT(player: mockPlayer)
        sut.viewWillAppear()

        let result = await sut.$title.values.first { @Sendable newTitle in
            newTitle == expectedTitle
        }

        #expect(result == expectedTitle)
    }

    @Test
    func title_whenPlayerTitleChanges_shouldUpdate() async {
        let mockPlayer = MockVideoPlayer(nodeName: "Initial Title")
        let sut = makeSUT(player: mockPlayer)
        sut.viewWillAppear()

        let result = await sut.$title.values.first { @Sendable newTitle in
            newTitle == "Initial Title"
        }

        #expect(result == "Initial Title")

        mockPlayer.nodeName = "Updated Title"

        let updatedResult = await sut.$title.values.first { @Sendable newTitle in
            newTitle == "Updated Title"
        }

        #expect(updatedResult == "Updated Title")
    }

    // MARK: - Lock Functionality Tests
    
    @Test
    func didTapLock_shouldCloseBottomMoreSheetAndAlwaysActivateLock() {
        let sut = makeSUT()
        
        sut.didTapLock()

        #expect(sut.isBottomMoreSheetPresented == false)
        #expect(sut.isLocked == true)
        #expect(sut.isLockOverlayVisible == true)
        #expect(sut.isControlsVisible == false)
    }
    
    @Test
    func didTapDeactivateLock_whenLocked_shouldUnlock() {
        let sut = makeSUT()
        sut.didTapLock()
        
        sut.didTapDeactivateLock()
        
        #expect(sut.isLocked == false)
        #expect(sut.isLockOverlayVisible == false)
        #expect(sut.isControlsVisible == true)
    }
    
    @Test
    func didTapVideoAreaWhileLocked_whenOverlayVisible_shouldHideOverlay() {
        let sut = makeSUT()
        sut.didTapLock()
        
        sut.didTapVideoAreaWhileLocked()
        
        #expect(sut.isLocked == true)
        #expect(sut.isLockOverlayVisible == false)
        #expect(sut.isControlsVisible == false)
    }
    
    @Test
    func didTapVideoAreaWhileLocked_whenOverlayHidden_shouldShowOverlay() {
        let sut = makeSUT()
        sut.didTapLock()
        sut.didTapVideoAreaWhileLocked()
        
        sut.didTapVideoAreaWhileLocked()
        
        #expect(sut.isLocked == true)
        #expect(sut.isLockOverlayVisible == true)
        #expect(sut.isControlsVisible == false)
    }
    
    @Test
    func didTapVideoArea_whenLocked_shouldCallLockedBehavior() {
        let sut = makeSUT()
        sut.didTapLock()
        
        sut.didTapVideoArea()
        
        #expect(sut.isLocked == true)
        #expect(sut.isLockOverlayVisible == false)
        #expect(sut.isControlsVisible == false)
    }

    @Test
    func lockOverlayTimer_shouldFadeOutAfter3Seconds() async {
        let sut = makeSUT()
        sut.didTapLock()
        #expect(sut.isLockOverlayVisible == true)
        
        try? await Task.sleep(for: .milliseconds(3100))
        
        #expect(sut.isLockOverlayVisible == false)
        #expect(sut.isLocked == true)
    }

    // MARK: - Snapshot Functionality Tests

    @Test
    func didTapSnapshot_whenPermissionGranted_shouldCaptureAndSaveSnapshot() async {
        let mockPlayer = MockVideoPlayer()
        let mockSaveSnapshotUseCase = MockSaveSnapshotUseCase()
        let mockDevicePermissionsHandler = MockDevicePermissionHandler(
            requestPhotoLibraryAddOnlyPermissionsGranted: true
        )
        mockPlayer.mockSnapshotImage = UIImage(systemName: "photo")

        let sut = makeSUT(
            player: mockPlayer,
            devicePermissionsHandler: mockDevicePermissionsHandler,
            saveSnapshotUseCase: mockSaveSnapshotUseCase
        )
        sut.isBottomMoreSheetPresented = true

        await sut.didTapSnapshot()

        #expect(sut.isBottomMoreSheetPresented == false)
        #expect(mockPlayer.captureSnapshotCallCount == 1)
        #expect(mockSaveSnapshotUseCase.saveToPhotoLibraryCallCount == 1)
        #expect(sut.shouldShowPhotoPermissionAlert == false)
    }

    @Test
    func didTapSnapshot_whenPermissionDenied_shouldNotCaptureSnapshotAndShowPermissionAlert() async {
        let mockPlayer = MockVideoPlayer()
        let mockSaveSnapshotUseCase = MockSaveSnapshotUseCase()
        let mockDevicePermissionsHandler = MockDevicePermissionHandler(
            requestPhotoLibraryAddOnlyPermissionsGranted: false
        )
        mockPlayer.mockSnapshotImage = UIImage(systemName: "photo")

        let sut = makeSUT(
            player: mockPlayer,
            devicePermissionsHandler: mockDevicePermissionsHandler,
            saveSnapshotUseCase: mockSaveSnapshotUseCase
        )
        sut.isBottomMoreSheetPresented = true

        await sut.didTapSnapshot()

        #expect(sut.isBottomMoreSheetPresented == false)
        #expect(mockPlayer.captureSnapshotCallCount == 0)
        #expect(mockSaveSnapshotUseCase.saveToPhotoLibraryCallCount == 0)
        #expect(sut.shouldShowPhotoPermissionAlert == true)
    }

    @Test
    func didTapSnapshot_whenPlayerReturnsNilImage_shouldNotSaveToGallery() async {
        let mockPlayer = MockVideoPlayer()
        let mockSaveSnapshotUseCase = MockSaveSnapshotUseCase()
        let mockDevicePermissionsHandler = MockDevicePermissionHandler(
            requestPhotoLibraryAddOnlyPermissionsGranted: true
        )
        mockPlayer.mockSnapshotImage = nil

        let sut = makeSUT(
            player: mockPlayer,
            devicePermissionsHandler: mockDevicePermissionsHandler,
            saveSnapshotUseCase: mockSaveSnapshotUseCase
        )

        await sut.didTapSnapshot()

        #expect(mockPlayer.captureSnapshotCallCount == 1)
        #expect(mockSaveSnapshotUseCase.saveToPhotoLibraryCallCount == 0)
        #expect(sut.showSnapshotSuccessMessage == false)
        #expect(sut.shouldShowPhotoPermissionAlert == false)
    }

    func checkToShowPhotoPermissionAlert_shouldSetShouldShowPhotoPermissionAlertToFalse() async {
        let mockPlayer = MockVideoPlayer()
        let mockSaveSnapshotUseCase = MockSaveSnapshotUseCase()
        let mockDevicePermissionsHandler = MockDevicePermissionHandler(
            requestPhotoLibraryAddOnlyPermissionsGranted: true
        )
        mockPlayer.mockSnapshotImage = UIImage(systemName: "photo")

        let sut = makeSUT(
            player: mockPlayer,
            devicePermissionsHandler: mockDevicePermissionsHandler,
            saveSnapshotUseCase: mockSaveSnapshotUseCase
        )
        sut.isBottomMoreSheetPresented = true

        await sut.didTapSnapshot()

        #expect(sut.shouldShowPhotoPermissionAlert == true)

        sut.checkToShowPhotoPermissionAlert()

        #expect(sut.shouldShowPhotoPermissionAlert == false)
    }

    // MARK: Picture in Picture Tests

    @Test
    func didTapPictureInPicture_shouldDismissBottomSheetAndCallAction() {
        var didTapPictureInPictureActionCallTimes = 0
        let sut = makeSUT(
            didTapPictureInPictureAction: {
                didTapPictureInPictureActionCallTimes += 1
            }
        )
        sut.isBottomMoreSheetPresented = true
        #expect(didTapPictureInPictureActionCallTimes == 0)

        sut.didTapPictureInPicture()

        #expect(sut.isBottomMoreSheetPresented == false)
        #expect(didTapPictureInPictureActionCallTimes == 1)
    }

    @Test
    func didTapAirPlay_shouldDismissBottomSheet() {
        let sut = makeSUT()
        sut.isBottomMoreSheetPresented = true

        sut.didTapAirPlay()

        #expect(sut.isBottomMoreSheetPresented == false)
    }

    // MARK: Play next or previous Tests

    @Test
    func didTapPlayNext_whenCalled_shouldCallThePlayerMethod() {
        let player = MockVideoPlayer()
        let sut = makeSUT(
            player: player
        )

        sut.didTapPlayNext()

        #expect(player.playNextCallCount == 1)
    }

    @Test
    func didTapPlayPrevious_whenCalled_shouldCallThePlayerMethod() {
        let player = MockVideoPlayer()
        let sut = makeSUT(
            player: player
        )

        sut.didTapPlayPrevious()

        #expect(player.playPreviousCallCount == 1)
    }

    // MARK: - Drag To Dismiss Tests

    @Test
    func didDragToDismiss_whenTheDragIsCommitted_shouldCallAction() {
        var didDragToDismissActionCallTimes = 0
        let sut = makeSUT(
            didDragToDismissAction: {
                didDragToDismissActionCallTimes += 1
            }
        )

        sut.didDragToDismiss(
            translation: CGSize(width: 0, height: PlayerDragToDismiss.distanceThreshold),
            velocity: .zero
        )

        #expect(didDragToDismissActionCallTimes == 1)
    }

    @Test
    func didDragToDismiss_whenTheDragIsTooShort_shouldNotCallAction() {
        var didDragToDismissActionCallTimes = 0
        let sut = makeSUT(
            didDragToDismissAction: {
                didDragToDismissActionCallTimes += 1
            }
        )

        sut.didDragToDismiss(
            translation: CGSize(width: 0, height: PlayerDragToDismiss.distanceThreshold - 1),
            velocity: .zero
        )

        #expect(didDragToDismissActionCallTimes == 0)
    }
}
