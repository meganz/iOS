@preconcurrency import Combine
import Foundation
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
        (.ended, true),
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
        #expect(mockPlayer.seekCallCount == 1)
        #expect(mockPlayer.seekTime == 65.0)
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
        #expect(mockPlayer.seekCallCount == 1)
        #expect(mockPlayer.seekTime == 35.0)
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
        #expect(mockPlayer.seekTime == 65.0)

        // Second tap within 3 seconds
        await sut.handleDoubleTapSeek(isForward: true)
        #expect(sut.doubleTapSeekSeconds == 30)
        #expect(mockPlayer.seekTime == 80.0)

        // Third tap within 3 seconds
        await sut.handleDoubleTapSeek(isForward: true)
        #expect(sut.doubleTapSeekSeconds == 45)
        #expect(mockPlayer.seekTime == 95.0)
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
        #expect(mockPlayer.seekTime == 35.0)

        // Second tap within 3 seconds
        await sut.handleDoubleTapSeek(isForward: false)
        #expect(sut.doubleTapSeekSeconds == -30)
        #expect(mockPlayer.seekTime == 20.0)

        // Third tap within 3 seconds
        await sut.handleDoubleTapSeek(isForward: false)
        #expect(sut.doubleTapSeekSeconds == -45)
        #expect(mockPlayer.seekTime == 5.0)
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
}
