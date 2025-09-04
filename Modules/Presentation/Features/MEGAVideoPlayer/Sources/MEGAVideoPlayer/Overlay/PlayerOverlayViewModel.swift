import Combine
import MEGAL10n
import SwiftUI

@MainActor
public final class PlayerOverlayViewModel: ObservableObject {
    @Published var state: PlaybackState = .stopped

    @Published var currentTime: Duration = .seconds(0)
    @Published var duration: Duration = .seconds(0)
    
    @Published var isControlsVisible: Bool = true
    @Published var currentSpeed: PlaybackSpeed = .normal
    @Published var isLoopEnabled: Bool = false
    @Published var isPlaybackBottomSheetPresented: Bool = false
    @Published var isBottomMoreSheetPresented: Bool = false
    @Published var scalingMode: VideoScalingMode = .fit
    @Published var isSeeking: Bool = false
    @Published var isHoldSpeedActive: Bool = false
    @Published var isDoubleTapSeekActive: Bool = false
    @Published var doubleTapSeekSeconds: Int = 0
    
    // Lock feature properties
    @Published var isLocked: Bool = false
    @Published var isLockOverlayVisible: Bool = false

    private var autoHideTimer: Timer?
    private var doubleTapSeekTimer: Timer?
    private var lockOverlayTimer: Timer?
    private var cancellables = Set<AnyCancellable>()

    private let player: any VideoPlayerProtocol
    private let didTapBackAction: () -> Void
    private let didTapRotateAction: () -> Void

    public init(
        player: some VideoPlayerProtocol,
        didTapBackAction: @escaping () -> Void,
        didTapRotateAction: @escaping () -> Void = {}
    ) {
        self.player = player
        self.didTapBackAction = didTapBackAction
        self.didTapRotateAction = didTapRotateAction
    }

    func viewWillAppear() {
        observePlayer()
    }

    private func observePlayer() {
        observeState()
        observeCurrentTime()
        observeDuration()
    }

    private func observeState() {
        player
           .statePublisher
           .receive(on: DispatchQueue.main)
           .sink { [weak self] newState in
               self?.handleStateChange(newState)
           }
           .store(in: &cancellables)
    }

    private func observeCurrentTime() {
        player
           .currentTimePublisher
           .receive(on: DispatchQueue.main)
           .sink { [weak self] newTime in
               guard let self, !isSeeking else { return }
               currentTime = newTime
           }
           .store(in: &cancellables)
    }

    private func observeDuration() {
        player
            .durationPublisher
            .receive(on: DispatchQueue.main)
            .assign(to: &$duration)
    }
}

// MARK: - nav bar logic

extension PlayerOverlayViewModel {
    func didTapBack() {
        didTapBackAction()
    }

    func didTapMore() {
        // Placeholder for future functionality
    }

    var title: String {
        player.nodeName
    }
}

// MARK: - Center controls logic

extension PlayerOverlayViewModel {
    func didTapPlay() {
        switch state {
        case .ended, .stopped:
            player.seek(to: 0)
        default:
            break
        }

        player.play()
        resetAutoHide()
    }

    func didTapPause() {
        player.pause()
        resetAutoHide()
    }

    func didTapJump(by second: Int) async {
        await performSeek(by: second)
    }

    func performSeek(by seekTime: Int) async {
        guard duration.components.seconds > 0 else { return }
        isSeeking = true
        cancelAutoHideTimer()
        updateCurrentTimeForSeek(by: seekTime)
        guard await seekToCurrentTime() else { return }
        // Slight delay to ensure current time updates correctly after seeking
        try? await Task.sleep(nanoseconds: 100_000_000)
        isSeeking = false
        resetAutoHide()
    }
}

// MARK: - Timeline logic

extension PlayerOverlayViewModel {
    var currentTimeAndDurationString: String {
        let currentTimeString = string(from: currentTime)
        let durationString = string(from: duration)
        return "\(currentTimeString) / \(durationString)"
    }

    var progress: CGFloat {
        let durationSeconds = duration.components.seconds
        guard durationSeconds > 0 else { return 0 }

        let currentSeconds = currentTime.components.seconds
        let result = CGFloat(currentSeconds) / CGFloat(durationSeconds)
        return result
    }

    func updateSeekBarDrag(at location: CGPoint, in frame: CGRect) {
        guard duration.components.seconds > 0 else { return }
        isSeeking = true
        cancelAutoHideTimer()
        currentTime = calculateTargetTime(from: location.x, in: frame.width)
    }

    func endSeekBarDrag(at location: CGPoint, in frame: CGRect) async {
        let seekTimeInDuration = calculateSeekTime(from: location.x, in: frame.width)
        let seekTime = Int(seekTimeInDuration.components.seconds)
        await performSeek(by: seekTime)
    }

    private func calculateTargetTime(
        from xPosition: CGFloat,
        in width: CGFloat
    ) -> Duration {
        let durationInSeconds = duration.components.seconds
        guard durationInSeconds > 0 else { return .seconds(0) }
        let clampedX = max(0, min(xPosition, width))
        let progress = clampedX / width
        let finalProgress = max(0, min(progress, 1.0))
        let targetTime = finalProgress * Double(durationInSeconds)
        print("Target time: \(targetTime)")
        return Duration.milliseconds(targetTime * 1000)
    }

    private func calculateSeekTime(
        from xPosition: CGFloat,
        in width: CGFloat
    ) -> Duration {
        let targetTime = calculateTargetTime(from: xPosition, in: width)
        return targetTime - currentTime
    }

    private func updateCurrentTimeForSeek(by seconds: Int) {
        guard duration.components.seconds > 0 else { return }
        let seekTimeInDuration = Duration.seconds(seconds)
        let targetTime = currentTime + seekTimeInDuration
        let finalTargetTime = max(.seconds(0), min(targetTime, duration))
        currentTime = finalTargetTime
    }

    private func seekToCurrentTime() async -> Bool {
        let timeInSeconds = currentTime.components.seconds
        return await player.seek(to: Double(timeInSeconds))
    }

    private func string(from duration: Duration) -> String {
        guard duration.components.seconds >= 0 else { return string(from: .seconds(0)) }

        let secondsInHour = 3600
        if duration.components.seconds > secondsInHour {
            return duration.formatted(
                .time(
                    pattern: .hourMinuteSecond(
                        padHourToLength: 2,
                        roundFractionalSeconds: .towardZero
                    )
                )
            )
        } else {
            return duration.formatted(
                .time(
                    pattern: .minuteSecond(
                        padMinuteToLength: 2,
                        roundFractionalSeconds: .towardZero
                    )
                )
            )
        }
    }
}

// MARK: - Bottom controls logic

extension PlayerOverlayViewModel {
    func didTapPlaybackSpeed() {
        isPlaybackBottomSheetPresented = true
        resetAutoHide()
    }

    func didSelectPlaybackSpeed(_ speed: PlaybackSpeed) {
        currentSpeed = speed
        player.changeRate(to: speed.rawValue)
        isPlaybackBottomSheetPresented = false
    }

    var currentSpeedString: String {
        currentSpeed.displayText
    }

    func didTapLoopButton() {
        isLoopEnabled.toggle()
        player.setLooping(isLoopEnabled)
        resetAutoHide()
    }

    func didTapRotate() {
        didTapRotateAction()
        resetAutoHide()
    }
    
    func didTapScalingButton() {
        scalingMode = scalingMode.toggled()
        player.setScalingMode(scalingMode)
        resetAutoHide()
    }

    func didTapBottomMoreButton() {
        isBottomMoreSheetPresented = true
    }

    func handlePinchGesture(scale: CGFloat) {
        let threshold: CGFloat = 1.0
        
        if scale > threshold {
            // Pinch out - switch to fill mode
            if scalingMode != .fill {
                scalingMode = .fill
                player.setScalingMode(.fill)
            }
        } else if scale < threshold {
            // Pinch in - switch to fit mode
            if scalingMode != .fit {
                scalingMode = .fit
                player.setScalingMode(.fit)
            }
        }
    }
    
    // MARK: - Lock functionality

    func didTapLock() {
        isBottomMoreSheetPresented = false
        activateLock()
    }

    private func activateLock() {
        isLocked = true
        isLockOverlayVisible = true
        hideControls()
        startLockOverlayTimer()
    }
    
    private func deactivateLock() {
        isLocked = false
        isLockOverlayVisible = false
        cancelLockOverlayTimer()
        showControls()
    }
    
    func didTapDeactivateLock() {
        deactivateLock()
    }
    
    func didTapVideoAreaWhileLocked() {
        if isLockOverlayVisible {
            isLockOverlayVisible = false
            cancelLockOverlayTimer()
        } else {
            isLockOverlayVisible = true
            startLockOverlayTimer()
        }
    }
    
    private func startLockOverlayTimer() {
        cancelLockOverlayTimer()
        
        lockOverlayTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: false) { [weak self] _ in
            Task { @MainActor in
                self?.isLockOverlayVisible = false
            }
        }
    }
    
    private func cancelLockOverlayTimer() {
        lockOverlayTimer?.invalidate()
        lockOverlayTimer = nil
    }
}

// MARK: - Hold to Speed logic

extension PlayerOverlayViewModel {
    func beginHoldToSpeed() {
        guard duration.components.seconds > 0 else { return }
        isHoldSpeedActive = true
        player.changeRate(to: PlaybackSpeed.double.rawValue)
        isControlsVisible = false
    }

    func endHoldToSpeed() {
        isHoldSpeedActive = false
        player.changeRate(to: currentSpeed.rawValue)
    }
}

// MARK: - Double Tap Seek logic

extension PlayerOverlayViewModel {
    func handleDoubleTapSeek(isForward: Bool) async {
        guard duration.components.seconds > 0 else { return }
        isDoubleTapSeekActive = true
        let seekTime = isForward ? 15 : -15

        let isSameDirection = (seekTime >= 0 && doubleTapSeekSeconds >= 0) || (seekTime < 0 && doubleTapSeekSeconds < 0)

        if isSameDirection {
            doubleTapSeekSeconds += seekTime
        } else {
            doubleTapSeekSeconds = seekTime
        }

        await performSeek(by: seekTime)

        startDoubleTapSeekTimer()
    }
    
    private func startDoubleTapSeekTimer() {
        cancelDoubleTapSeekTimer()
        
        doubleTapSeekTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: false) { [weak self] _ in
            Task { @MainActor in
                self?.endDoubleTapSeek()
            }
        }
    }
    
    private func cancelDoubleTapSeekTimer() {
        doubleTapSeekTimer?.invalidate()
        doubleTapSeekTimer = nil
    }
    
    private func endDoubleTapSeek() {
        isDoubleTapSeekActive = false
        doubleTapSeekSeconds = 0
        cancelDoubleTapSeekTimer()
    }
    
    var doubleTapSeekDisplayText: String {
        let seconds = abs(doubleTapSeekSeconds)
        return Strings.Localizable.VideoPlayer.Chip.seekDisplayText(seconds)
    }

    func doubleTapSeekChipBottomPadding(isLandscape: Bool) -> CGFloat {
        if isControlsVisible {
            isLandscape ? 102 : 188
        } else {
            48
        }
    }
}

// MARK: - Overlay Visibility Management

extension PlayerOverlayViewModel {
    func showControls() {
        guard !isLocked else { return }
        isControlsVisible = true
        resetAutoHide()
    }

    func hideControls() {
        isControlsVisible = false
        cancelAutoHideTimer()
    }

    func didTapVideoArea() {
        if isLocked {
            didTapVideoAreaWhileLocked()
        } else {
            if isControlsVisible {
                hideControls()
            } else {
                showControls()
            }
        }
    }

    private func resetAutoHide() {
        if shouldAutoHide {
            startAutoHideTimer()
        } else {
            cancelAutoHideTimer()
        }
    }

    private func startAutoHideTimer() {
        cancelAutoHideTimer()

        autoHideTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: false) { [weak self] _ in
            Task { @MainActor in
                self?.hideControls()
            }
        }
    }

    private func cancelAutoHideTimer() {
        autoHideTimer?.invalidate()
        autoHideTimer = nil
    }

    private var shouldAutoHide: Bool {
        switch state {
        case .paused, .buffering:
            false
        case .playing, .opening, .stopped, .error, .ended:
            true
        }
    }

    private func handleStateChange(_ newState: PlaybackState) {
        state = newState
        resetAutoHide()
    }

    var shouldShownJumpButtons: Bool {
        duration.components.seconds > 0
    }
}
