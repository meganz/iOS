import AVFoundation
import AVKit
import Combine
import Foundation
import MEGADomain
import UIKit

@MainActor
final class PreviewVideoPlayer: VideoPlayerProtocol {

    @Published var state: PlaybackState
    @Published var currentTime: Duration
    @Published var duration: Duration
    @Published var bufferRange: (start: Duration, end: Duration)?
    @Published var scalingMode: VideoScalingMode
    @Published var canPlayNext: Bool
    @Published var nodeName: String

    let debugMessage: String
    nonisolated let option: VideoPlayerOption

    var statePublisher: AnyPublisher<PlaybackState, Never> {
        $state.eraseToAnyPublisher()
    }

    var currentTimePublisher: AnyPublisher<Duration, Never> {
        $currentTime.eraseToAnyPublisher()
    }

    var durationPublisher: AnyPublisher<Duration, Never> {
        $duration.eraseToAnyPublisher()
    }

    var bufferRangePublisher: AnyPublisher<(start: Duration, end: Duration)?, Never> {
        $bufferRange.eraseToAnyPublisher()
    }

    var canPlayNextPublisher: AnyPublisher<Bool, Never> {
        $canPlayNext.eraseToAnyPublisher()
    }

    var nodeNamePublisher: AnyPublisher<String, Never> {
        $nodeName.eraseToAnyPublisher()
    }

    var scalingModePublisher: AnyPublisher<VideoScalingMode, Never> {
        $scalingMode.eraseToAnyPublisher()
    }

    nonisolated var debugMessagePublisher: AnyPublisher<String, Never> {
        Just(debugMessage).eraseToAnyPublisher()
    }

    var isLoopEnabled: Bool = false

    var currentNode: (any PlayableNode)?

    init(
        option: VideoPlayerOption = .avPlayer,
        state: PlaybackState = .stopped,
        currentTime: Duration = .seconds(0),
        duration: Duration = .seconds(0),
        scalingMode: VideoScalingMode = .fit,
        canPlayNext: Bool = false,
        nodeName: String = "",
        debugMessage: String = ""
    ) {
        self.option = option
        self.state = state
        self.currentTime = currentTime
        self.duration = duration
        self.scalingMode = scalingMode
        self.debugMessage = debugMessage
        self.canPlayNext = canPlayNext
        self.nodeName = nodeName
    }

    func play() {}
    func pause() {}
    func stop() {}
    func jumpForward(by seconds: TimeInterval) {}
    func jumpBackward(by seconds: TimeInterval) {}
    func seek(to time: TimeInterval) {}
    func seek(to time: TimeInterval) async -> Bool {
        true
    }
    func loadNode(_ node: some PlayableNode) {}
    func setupPlayer(in layer: any PlayerViewProtocol) {}
    func resizePlayer(to frame: CGRect) {}
    func setScalingMode(_ mode: VideoScalingMode) {
        scalingMode = mode
    }
    func changeRate(to rate: Float) {}
    func setLooping(_ enabled: Bool) { }

    func captureSnapshot() async -> UIImage? {
        UIImage()
    }
    
    func loadPIPController() -> AVPictureInPictureController? {
        return nil
    }

    func playNext() {}

    func playPrevious() {}

    func streamVideoNodes(for node: some PlayableNode) {}

    var onNodeDeleted: (() -> Void)?
}
