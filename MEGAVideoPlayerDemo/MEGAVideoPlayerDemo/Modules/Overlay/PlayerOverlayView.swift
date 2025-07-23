import MEGADesignToken
import SwiftUI

struct PlayerOverlayView: View {
    @StateObject var viewModel: PlayerOverlayViewModel

    var body: some View {
        ZStack {
            centerPlaybackButtons
            bottomToolbar
        }
        .buttonStyle(.plain)
        .task { viewModel.viewWillAppear() }
    }
}

// MARK: - Center Playback Button

extension PlayerOverlayView {
    var centerPlaybackButtons: some View {
        HStack(alignment: .center, spacing: 48) {
            jumpBackwardButton
            playPauseButton
            jumpForwardButton
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        .foregroundStyle(TokenColors.Icon.onColor.swiftUI)
    }

    @ViewBuilder var playPauseButton: some View {
        switch viewModel.state {
        case .playing, .buffering, .opening:
            pauseButton
        case .paused, .stopped, .error, .ended:
            playButton
        }
    }

    var playButton: some View {
        Button {
            viewModel.didTapPlay()
        } label: {
            Image(systemName: "play.fill")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 32, height: 32)
        }
    }

    var pauseButton: some View {
        Button {
            viewModel.didTapPause()
        } label: {
            Image(systemName: "pause.fill")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 32, height: 32)
        }
    }

    var jumpBackwardButton: some View {
        Button {
            viewModel.didTapJumpBackward()
        } label: {
            Image(systemName: "gobackward")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 32, height: 32)
        }
    }

    var jumpForwardButton: some View {
        Button {
            viewModel.didTapJumpForward()
        } label: {
            Image(systemName: "goforward")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 32, height: 32)
        }
    }
}

// MARK: - Bottom Toolbar

extension PlayerOverlayView {
    var bottomToolbar: some View {
        HStack(alignment: .center) {
            Text(viewModel.currentTimeString)
                .foregroundStyle(TokenColors.Text.primary.swiftUI)
            seekBar
            Text(viewModel.durationString)
                .foregroundStyle(TokenColors.Text.primary.swiftUI)
        }
        .padding(15)
        .frame(maxWidth: .infinity, alignment: .center)
        .background(TokenColors.Background.surface1.swiftUI.ignoresSafeArea())
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
    }

    // Temporary placeholder, will be worked on in future MR
    private var seekBar: some View {
        Rectangle()
            .frame(maxWidth: .infinity, maxHeight: 4, alignment: .center)
            .foregroundStyle(TokenColors.Background.surface2.swiftUI)
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Image(.sampleVideoFeed)
            .resizable()
            .aspectRatio(contentMode: .fit)
        PlayerOverlayView(
            viewModel: PlayerOverlayViewModel(
                player: MockVideoPlayer(
                    state: .playing, currentTime: .seconds(12), duration: .seconds(5_678)
                )
            )
        )
    }
    .background(.black)
}

#if DEBUG
import Combine

@MainActor
private final class MockVideoPlayer: VideoPlayerProtocol {
    @Published var state: PlaybackState
    @Published var currentTime: Duration
    @Published var duration: Duration

    let debugMessage: String
    let option: VideoPlayerOption

    var statePublisher: AnyPublisher<PlaybackState, Never> {
        $state.eraseToAnyPublisher()
    }

    var currentTimePublisher: AnyPublisher<Duration, Never> {
        $currentTime.eraseToAnyPublisher()
    }

    var durationPublisher: AnyPublisher<Duration, Never> {
        $duration.eraseToAnyPublisher()
    }

    nonisolated var debugMessagePublisher: AnyPublisher<String, Never> {
        Just(debugMessage).eraseToAnyPublisher()
    }

    init(
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

    func play() {}
    func pause() {}
    func stop() {}
    func jumpForward(by seconds: TimeInterval) {}
    func jumpBackward(by seconds: TimeInterval) {}
    func seek(to time: TimeInterval) {}
    func loadNode(_ node: any PlayableNode) {}
    func setupPlayer(in layer: any PlayerLayerProtocol) {}
    func resizePlayer(to frame: CGRect) {}
}
#endif
