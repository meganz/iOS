import MEGADesignToken
import SwiftUI

public struct PlayerOverlayView: View {
    @StateObject var viewModel: PlayerOverlayViewModel

    public var body: some View {
        ZStack {
            backgroundColor
                .ignoresSafeArea()
                .contentShape(Rectangle())
                .onTapGesture {
                    viewModel.didTapVideoArea()
                }
            
            if viewModel.isControlsVisible {
                topToolbar
                centerPlaybackButtons
                bottomToolbar
            }

            if viewModel.isLoading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
            }
        }
        .animation(.easeInOut(duration: 0.3), value: viewModel.isControlsVisible)
        .buttonStyle(.plain)
        .task { viewModel.viewWillAppear() }
    }

    private var backgroundColor: Color {
        if viewModel.isControlsVisible {
            TokenColors.Background.blur.swiftUI
        } else {
            Color.clear
        }
    }

    private func controlButton(
        name: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Image(name, bundle: .module)
                .renderingMode(.template)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 24, height: 24)
                .foregroundStyle(TokenColors.Icon.onColor.swiftUI)
        }
    }
}

// MARK: - Top Toolbar
extension PlayerOverlayView {
    var topToolbar: some View {
        HStack(alignment: .center, spacing: TokenSpacing._5) {
            backButton
            Spacer()
            moreTopButton
        }
        .padding(TokenSpacing._5)
        .frame(maxWidth: .infinity, alignment: .center)
        .background(.clear)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    var backButton: some View {
        controlButton(name: "back", action: viewModel.didTapBack)
    }

    var moreTopButton: some View {
        controlButton(name: "moreTop", action: {
            // Implement more top functionality
        })
    }
}

// MARK: - Center Playback Button

extension PlayerOverlayView {
    var centerPlaybackButtons: some View {
        HStack(alignment: .center, spacing: 48) {
            jumpBackwardButton
            skipBackwardButton
            playPauseButton
            skipForwardButton
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
            Image("playback", bundle: .module)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 56, height: 56)
                .foregroundStyle(TokenColors.Icon.onColor.swiftUI)
        }
    }

    var pauseButton: some View {
        Button {
            viewModel.didTapPause()
        } label: {
            Image("pause", bundle: .module)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 56, height: 56)
                .foregroundStyle(TokenColors.Icon.onColor.swiftUI)
        }
    }

    var skipBackwardButton: some View {
        controlButton(name: "skipForward", action: {
            // Implement skip backward functionality
        })
        .scaleEffect(x: -1, y: 1)
    }

    var skipForwardButton: some View {
        controlButton(name: "skipForward", action: {
            // Implement skip forward functionality
        })
    }

    var jumpBackwardButton: some View {
        controlButton(name: "backward15", action: viewModel.didTapJumpBackward)
    }

    var jumpForwardButton: some View {
        controlButton(name: "forward15", action: viewModel.didTapJumpForward)
    }
}

// MARK: - Bottom Toolbar

extension PlayerOverlayView {
    var bottomToolbar: some View {
        VStack(spacing: TokenSpacing._7) {
            timeLineView
            bottomControls
        }
        .padding(TokenSpacing._5)
        .frame(maxWidth: .infinity, alignment: .center)
        .background(.clear)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
    }

    var timeLineView: some View {
        HStack(alignment: .center, spacing: TokenSpacing._3) {
            Text(viewModel.currentTimeString)
                .foregroundStyle(TokenColors.Text.onColor.swiftUI)
                .font(.footnote)
                .frame(minWidth: 40, alignment: .leading)
            seekBar
            Text(viewModel.durationString)
                .foregroundStyle(TokenColors.Text.onColor.swiftUI)
                .font(.footnote)
                .frame(minWidth: 40, alignment: .trailing)
        }
        .frame(height: TokenSpacing._7)
    }

    private var seekBar: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Background track
                Rectangle()
                    .frame(height: 4)
                    .foregroundStyle(Color.white.opacity(0.3))
                    .cornerRadius(2)
                
                // Progress bar
                Rectangle()
                    .frame(width: viewModel.progress * geometry.size.width, height: 4)
                    .foregroundStyle(Color.red)
                    .cornerRadius(2)
                
                // Thumb/handle
                Circle()
                    .frame(width: 16, height: 16)
                    .foregroundStyle(Color.red)
                    .offset(x: viewModel.progress * geometry.size.width - 8)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        }
    }

    var bottomControls: some View {
        HStack(alignment: .center, spacing: TokenSpacing._1) {
            playbackSpeedButton
                .frame(minWidth: 60, alignment: .center)
            Spacer()
            loopButton
                .frame(minWidth: 60, alignment: .center)
            Spacer()
            zoomToFillButton
                .frame(minWidth: 60, alignment: .center)
            Spacer()
            lockButton
                .frame(minWidth: 60, alignment: .center)
            Spacer()
            moreBottomButton
                .frame(minWidth: 60, alignment: .center)
        }
    }

    var playbackSpeedButton: some View {
        Button {
            viewModel.didTapPlaybackSpeed()
        } label: {
            Text(viewModel.currentSpeedString)
                .foregroundStyle(TokenColors.Text.onColor.swiftUI)
                .font(.system(size: 18))
        }
    }

    var loopButton: some View {
        controlButton(
            name: viewModel.isLoopEnabled ? "loopEnabled" : "loop",
            action: viewModel.didTapLoopButton
        )
    }

    var zoomToFillButton: some View {
        controlButton(name: "zoomToFill", action: {
            // Implement zoom to fit functionality
        })
    }   

    var lockButton: some View {
        controlButton(name: "lock", action: {
            // Implement zoom to fit functionality
        })
    }

    var moreBottomButton: some View {
        controlButton(name: "moreBottom", action: {
            // Implement more bottom functionality
        })
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Image("sampleVideoFeed", bundle: .module)
            .resizable()
            .aspectRatio(contentMode: .fit)
        PlayerOverlayView(
            viewModel: PlayerOverlayViewModel(
                player: PreviewVideoPlayer(
                    state: .playing,
                    currentTime: .seconds(345),
                    duration: .seconds(1_234)
                )
            ) {}
        )
    }
    .background(.black)
}
