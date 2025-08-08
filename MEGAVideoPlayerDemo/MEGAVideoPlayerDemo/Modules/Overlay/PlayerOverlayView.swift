import MEGADesignToken
import SwiftUI

struct PlayerOverlayView: View {
    @StateObject var viewModel: PlayerOverlayViewModel

    var body: some View {
        ZStack {
            topToolbar
            centerPlaybackButtons
            bottomToolbar
        }

        .buttonStyle(.plain)
        .task { viewModel.viewWillAppear() }
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
            Image(.back)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 24, height: 24)
        }
    }

    var downloadButton: some View {
        Button {
            // TODO: Implement download functionality
        } label: {
            Image(.download)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 24, height: 24)
        }
    }

    var shareButton: some View {
        Button {
            // TODO: Implement share functionality
        } label: {
            Image(.share)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 24, height: 24)
        }
    }

    var snapshotButton: some View {
        Button {
            // TODO: Implement snapshot functionality
        } label: {
            Image(.snapshot)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 24, height: 24)
        }
    }

    var moreTopButton: some View {
        Button {
            // TODO: Implement more top functionality
        } label: {
            Image(.moreTop)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 24, height: 24)
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
            Image(.playback)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 56, height: 56)
        }
    }

    var pauseButton: some View {
        Button {
            viewModel.didTapPause()
        } label: {
            Image(.pause)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 56, height: 56)
        }
    }

    var skipBackwardButton: some View {
        Button {
            // TODO: Implement skip backward functionality
        } label: {
            Image(.skipForward)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .scaleEffect(x: -1, y: 1)
                .frame(width: 24, height: 24)
        }
    }

    var skipForwardButton: some View {
        Button {
            // TODO: Implement skip forward functionality
        } label: {
            Image(.skipForward)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 24, height: 24)
        }
    }

    var jumpBackwardButton: some View {
        Button {
            viewModel.didTapJumpBackward()
        } label: {
            Image(.backward15)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 24, height: 24)
        }
    }

    var jumpForwardButton: some View {
        Button {
            viewModel.didTapJumpForward()
        } label: {
            Image(.forward15)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 24, height: 24)
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
            Image(.loop)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 24, height: 24)
        }
    }

    var zoomToFillButton: some View {
        Button {
            // TODO: Implement zoom to fit functionality
        } label: {  
            Image(.zoomToFill)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 24, height: 24)
        }
    }   

    var lockButton: some View {
        Button {
            // TODO: Implement lock functionality
        } label: {
            Image(.lock)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 24, height: 24)
        }
    }

    var moreBottomButton: some View {
        Button {
            // TODO: Implement more bottom functionality
        } label: {
            Image(.moreBottom)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 24, height: 24) 
        }
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
            ) {}
        )
    }
    .background(.black)
}
