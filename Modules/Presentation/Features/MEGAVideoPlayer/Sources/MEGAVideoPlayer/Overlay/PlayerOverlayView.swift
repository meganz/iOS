import MEGADesignToken
import SwiftUI

public struct PlayerOverlayView: View {
    @StateObject var viewModel: PlayerOverlayViewModel

    public var body: some View {
        ZStack {
            backgroundColor
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
}

// MARK: - Top Toolbar
extension PlayerOverlayView {
    var topToolbar: some View {
        HStack(alignment: .center, spacing: TokenSpacing._5) {
            backButton
            Spacer()
            downloadButton
            shareButton
            snapshotButton
            moreTopButton
        }
        .padding(TokenSpacing._5)
        .frame(maxWidth: .infinity, alignment: .center)
        .background(.clear)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    var backButton: some View {
        Button {
            viewModel.didTapBack()
        } label: {
            Image("back", bundle: .module)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 24, height: 24)
                .foregroundStyle(TokenColors.Icon.onColor.swiftUI)
        }
    }

    var downloadButton: some View {
        Button {
            // TODO: Implement download functionality
        } label: {
            Image("download", bundle: .module)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 24, height: 24)
                .foregroundStyle(TokenColors.Icon.onColor.swiftUI)
        }
    }

    var shareButton: some View {
        Button {
            // TODO: Implement share functionality
        } label: {
            Image("share", bundle: .module)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 24, height: 24)
                .foregroundStyle(TokenColors.Icon.onColor.swiftUI)
        }
    }

    var snapshotButton: some View {
        Button {
            // TODO: Implement snapshot functionality
        } label: {
            Image("snapshot", bundle: .module)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 24, height: 24)
                .foregroundStyle(TokenColors.Icon.onColor.swiftUI)
        }
    }

    var moreTopButton: some View {
        Button {
            // TODO: Implement more top functionality
        } label: {
            Image("moreTop", bundle: .module)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 24, height: 24)
                .foregroundStyle(TokenColors.Icon.onColor.swiftUI)
        }
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
        Button {
            // TODO: Implement skip backward functionality
        } label: {
            Image("skipForward", bundle: .module)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .scaleEffect(x: -1, y: 1)
                .frame(width: 24, height: 24)
                .foregroundStyle(TokenColors.Icon.onColor.swiftUI)
        }
    }

    var skipForwardButton: some View {
        Button {
            // TODO: Implement skip forward functionality
        } label: {
            Image("skipForward", bundle: .module)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 24, height: 24)
                .foregroundStyle(TokenColors.Icon.onColor.swiftUI)
        }
    }

    var jumpBackwardButton: some View {
        Button {
            viewModel.didTapJumpBackward()
        } label: {
            Image("backward15", bundle: .module)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 24, height: 24)
                .foregroundStyle(TokenColors.Icon.onColor.swiftUI)
        }
    }

    var jumpForwardButton: some View {
        Button {
            viewModel.didTapJumpForward()
        } label: {
            Image("forward15", bundle: .module)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 24, height: 24)
                .foregroundStyle(TokenColors.Icon.onColor.swiftUI)
        }
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
            Spacer()
            loopButton
            Spacer()
            zoomToFillButton
            Spacer()
            lockButton
            Spacer()
            moreBottomButton
        }
    }

    var playbackSpeedButton: some View {
        Button {
            // TODO: Implement playback speed functionality
        } label: {
            Text("1x")
                .foregroundStyle(TokenColors.Text.onColor.swiftUI)
                .font(.system(size: 18))
        }
    }

    var loopButton: some View {
        Button {    
            // TODO: Implement loop functionality
        } label: {
            Image("loop", bundle: .module)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 24, height: 24)
                .foregroundStyle(TokenColors.Icon.onColor.swiftUI)
        }
    }

    var zoomToFillButton: some View {
        Button {
            // TODO: Implement zoom to fit functionality
        } label: {  
            Image("zoomToFill", bundle: .module)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 24, height: 24)
                .foregroundStyle(TokenColors.Icon.onColor.swiftUI)
        }
    }   

    var lockButton: some View {
        Button {
            // TODO: Implement lock functionality
        } label: {
            Image("lock", bundle: .module)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 24, height: 24)
                .foregroundStyle(TokenColors.Icon.onColor.swiftUI)
        }
    }

    var moreBottomButton: some View {
        Button {
            // TODO: Implement more bottom functionality
        } label: {
            Image("moreBottom", bundle: .module)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 24, height: 24)
                .foregroundStyle(TokenColors.Icon.onColor.swiftUI)
        }
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
