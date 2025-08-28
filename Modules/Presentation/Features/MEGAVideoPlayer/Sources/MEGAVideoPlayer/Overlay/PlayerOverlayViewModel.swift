import Combine
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
    @Published var scalingMode: VideoScalingMode = .fit
    @Published var isSeeking: Bool = false

    private var autoHideTimer: Timer?
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
        guard duration.components.seconds > 0 else { return }
        isSeeking = true
        cancelAutoHideTimer()
        updateCurrentTimeForSeek(by: second)
        guard await seekToCurrentTime() else { return }
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
        updateCurrentTimeForSeek(from: location.x, in: frame.width)
    }

    func endSeekBarDrag(at location: CGPoint, in frame: CGRect) async {
        guard duration.components.seconds > 0 else { return }
        isSeeking = true
        cancelAutoHideTimer()
        updateCurrentTimeForSeek(from: location.x, in: frame.width)
        guard await seekToCurrentTime() else { return }
        isSeeking = false
        resetAutoHide()
    }

    private func updateCurrentTimeForSeek(
        from xPosition: CGFloat,
        in width: CGFloat
    ) {
        let durationInSeconds = duration.components.seconds
        guard durationInSeconds > 0 else { return }
        let clampedX = max(0, min(xPosition, width))
        let progress = clampedX / width
        let finalProgress = max(0, min(progress, 1.0))
        let targetTime = finalProgress * Double(durationInSeconds)
        currentTime = Duration.milliseconds(targetTime * 1000)
    }

    private func updateCurrentTimeForSeek(by seconds: Int) {
        let durationInSeconds = duration.components.seconds
        guard durationInSeconds > 0 else { return }
        let targetTime = Int(currentTime.components.seconds) + seconds
        currentTime = Duration.seconds(
            max(0, min(targetTime, Int(durationInSeconds)))
        )
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
}

// MARK: - Overlay Visibility Management

extension PlayerOverlayViewModel {
    func showControls() {
        isControlsVisible = true
        resetAutoHide()
    }

    func hideControls() {
        isControlsVisible = false
        cancelAutoHideTimer()
    }

    func didTapVideoArea() {
        if isControlsVisible {
            hideControls()
        } else {
            showControls()
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
