import Combine
import SwiftUI

@MainActor
public final class PlayerOverlayViewModel: ObservableObject {
    @Published var state: PlaybackState = .stopped

    @Published var currentTime: Duration = .seconds(0)
    @Published var duration: Duration = .seconds(0)
    
    @Published var isLoading: Bool = true
    @Published var isControlsVisible: Bool = false
    @Published var currentSpeed: PlaybackSpeed = .normal
    @Published var isLoopEnabled: Bool = false
    @Published var isPlaybackBottomSheetPresented: Bool = false
    @Published var scalingMode: VideoScalingMode = .fit
    @Published var isSeeking: Bool = false

    private var autoHideTimer: Timer?
    private var dragProgress: CGFloat = 0
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
           .assign(to: &$currentTime)
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
        didTapControl()
    }

    func didTapPause() {
        player.pause()
        didTapControl()
    }

    func didTapJumpForward() {
        player.jumpForward(by: 10)
        didTapControl()
    }

    func didTapJumpBackward() {
        player.jumpBackward(by: 10)
        didTapControl()
    }
}

// MARK: - Timeline logic

extension PlayerOverlayViewModel {
    var currentTimeAndDurationString: String {
        let timeToDisplay = isSeeking ? dragTime : currentTime
        let currentTimeString = string(from: timeToDisplay)
        let durationString = string(from: duration)
        return "\(currentTimeString) / \(durationString)"
    }

    var progress: CGFloat {
        let durationSeconds = duration.components.seconds
        guard durationSeconds > 0 else { return 0 }

        let seconds = isSeeking ? dragTime.components.seconds : currentTime.components.seconds
        let result = CGFloat(seconds) / CGFloat(durationSeconds)
        return result
    }

    func updateSeekBarDrag(at location: CGPoint, in frame: CGRect) {
        guard duration.components.seconds > 0 else { return }
        isSeeking = true
        cancelAutoHideTimer()
        dragProgress = calculateDragProgress(from: location.x, in: frame.width)
    }

    func endSeekBarDrag(at location: CGPoint, in frame: CGRect) async {
        guard duration.components.seconds > 0 else { return }
        dragProgress = calculateDragProgress(from: location.x, in: frame.width)
        guard await seekToProgress(dragProgress) else { return }
        currentTime = dragTime
        isSeeking = false
        dragProgress = 0
        didTapControl()
    }

    private func calculateDragProgress(from xPosition: CGFloat, in width: CGFloat) -> CGFloat {
        let clampedX = max(0, min(xPosition, width))
        let progress = clampedX / width
        return max(0, min(progress, 1.0))
    }
    
    private func seekToProgress(_ progress: CGFloat) async -> Bool {
        let durationSeconds = duration.components.seconds
        guard durationSeconds > 0 else { return false }
        
        let targetTime = progress * Double(durationSeconds)
        return await player.seek(to: targetTime)
    }

    private var dragTime: Duration {
        let durationSeconds = duration.components.seconds
        guard durationSeconds > 0 else { return .seconds(0) }

        let dragSeconds = dragProgress * Double(durationSeconds)
        return .seconds(dragSeconds)
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
        didTapControl()
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
        didTapControl()
    }

    func didTapRotate() {
        didTapRotateAction()
        didTapControl()
    }
    
    func didTapScalingButton() {
        scalingMode = scalingMode.toggled()
        player.setScalingMode(scalingMode)
        didTapControl()
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
        startAutoHideTimer()
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

    private func didTapControl() {
        startAutoHideTimer()
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

    private func handleStateChange(_ newState: PlaybackState) {
        state = newState
        switch newState {
        case .opening, .buffering:
            isLoading = true
        case .playing, .paused, .ended, .error, .stopped:
            isLoading = false
        }
    }
}
