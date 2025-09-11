import MEGADesignToken
import MEGAL10n
import MEGAPermissions
import MEGAUIComponent
import SwiftUI

public struct PlayerOverlayView: View {
    @StateObject var viewModel: PlayerOverlayViewModel

    enum Constants {
        static let bottomSheetRowHeight: CGFloat = 58
        static let bottomSheetTopPadding: CGFloat = 21
    }

    public var body: some View {
        ZStack {
            if viewModel.isLocked {
                lockOverlayView
            } else {
                backgroundColor
                    .ignoresSafeArea()
                    .contentShape(Rectangle())
                    .overlay(
                        HStack(spacing: 0) {
                            // Left side - backward seek
                            Rectangle()
                                .fill(Color.clear)
                                .contentShape(Rectangle())
                                .onTapGesture(count: 2) {
                                    Task {
                                        await viewModel.handleDoubleTapSeek(isForward: false)
                                    }
                                }
                                .frame(maxWidth: .infinity)

                            // Right side - forward seek
                            Rectangle()
                                .fill(Color.clear)
                                .contentShape(Rectangle())
                                .onTapGesture(count: 2) {
                                    Task {
                                        await viewModel.handleDoubleTapSeek(isForward: true)
                                    }
                                }
                                .frame(maxWidth: .infinity)
                        }
                            .onTapGesture {
                                viewModel.didTapVideoArea()
                            }
                            .onLongPressGesture(
                                minimumDuration: 0.5,
                                perform: {
                                    viewModel.beginHoldToSpeed()
                                },
                                onPressingChanged: { isPressing in
                                    guard !isPressing else { return }
                                    viewModel.endHoldToSpeed()
                                }
                            )
                    )

                if viewModel.isControlsVisible {
                    topToolbar
                    centerPlaybackButtons
                    bottomToolbar
                }

                if viewModel.shouldShowHoldToSpeedChip {
                    holdToSpeedChip
                }

                if viewModel.isDoubleTapSeekActive {
                    GeometryReader { geo in
                        doubleTapSeekChip
                            .padding(
                                .bottom,
                                viewModel.doubleTapSeekChipBottomPadding(
                                    isLandscape: geo.size.width > geo.size.height)
                            )
                    }
                }

                if viewModel.showSnapshotSuccessMessage {
                    snapshotSuccessSnackBar
                }
            }
        }
        .animation(.easeInOut(duration: 0.3), value: viewModel.showSnapshotSuccessMessage)
        .animation(.easeInOut(duration: 0.3), value: viewModel.isControlsVisible)
        .buttonStyle(.plain)
        .task { viewModel.viewWillAppear() }
        .gesture(
            MagnificationGesture()
                .onEnded { scale in
                    viewModel.handlePinchGesture(scale: scale)
                }
        )
        .bottomSheet(
            isPresented: $viewModel.isPlaybackBottomSheetPresented,
            detents: [.fixed(playbackSpeedsBottomSelectionListHeight)],
            showDragIndicator: true,
            cornerRadius: TokenRadius.large
        ) {
            playbackSpeedsSelectionListView
        }
        .bottomSheet(
            isPresented: $viewModel.isBottomMoreSheetPresented,
            detents: [.fixed(bottomMoreSheetHeight)],
            showDragIndicator: true,
            cornerRadius: TokenRadius.large
        ) {
            viewModel.checkToShowPhotoPermissionAlert()
        } content: {
            bottomMoreSheetView
        }
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
        color: Color = TokenColors.Icon.onColor.swiftUI,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Image(name, bundle: .module)
                .renderingMode(.template)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 24, height: 24)
                .foregroundStyle(color)
                .overlay {
                    // This is to increase the tappable area
                    Rectangle()
                        .fill(Color.clear)
                        .contentShape(Rectangle())
                        .frame(width: 44, height: 44)
                }
        }
    }

    private func chipView(content: () -> some View) -> some View {
        content()
            .padding(.horizontal, TokenSpacing._4)
            .padding(.vertical, 6)
            .background(TokenColors.Background.blur.swiftUI)
            .foregroundStyle(TokenColors.Text.onColor.swiftUI)
            .clipShape(Capsule())
    }

    private var holdToSpeedChip: some View {
        chipView {
            HStack(spacing: TokenSpacing._3) {
                Text("2x")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Image(systemName: "forward.fill")

            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
        .padding(.bottom, TokenSpacing._7)
    }

    private var doubleTapSeekChip: some View {
        chipView {
            HStack(spacing: TokenSpacing._3) {
                if viewModel.doubleTapSeekSeconds > 0 {
                    Text(viewModel.doubleTapSeekDisplayText)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    Image(systemName: "forward.fill")
                } else {
                    Image(systemName: "backward.fill")
                    Text(viewModel.doubleTapSeekDisplayText)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }

            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
    }

    private var snapshotSuccessSnackBar: some View {
        GeometryReader { geometry in
            let isLandscape = geometry.size.width > geometry.size.height
            HStack {
                Text(Strings.Localizable.VideoPlayer.Snapshot.SnackBar.title)
                    .font(.footnote)
                    .foregroundColor(TokenColors.Text.inverse.swiftUI)
                Spacer()
            }
            .padding(TokenSpacing._5)
            .frame(height: 50)
            .frame(maxWidth: 360)
            .background(TokenColors.Components.toastBackground.swiftUI)
            .cornerRadius(TokenSpacing._3)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
            .padding(.bottom, isLandscape ? 102 : 164)
        }
        .preferredColorScheme(.dark)
    }
}

// MARK: - Top Toolbar
extension PlayerOverlayView {
    var topToolbar: some View {
        HStack(alignment: .center, spacing: TokenSpacing._5) {
            backButton
            Spacer()
            titleView
            Spacer()
            moreTopButton
        }
        .padding(.horizontal, TokenSpacing._5)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity, alignment: .center)
        .background(TokenColors.Background.blur.swiftUI)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    var backButton: some View {
        controlButton(name: "back", action: viewModel.didTapBack)
    }

    var titleView: some View {
        Text(viewModel.title)
            .font(.headline)
            .fontWeight(.semibold)
            .lineLimit(1)
            .foregroundStyle(TokenColors.Icon.onColor.swiftUI)
    }

    var moreTopButton: some View {
        controlButton(name: "moreTop", action: viewModel.didTapMore)
    }
}

// MARK: - Center Playback Button

extension PlayerOverlayView {
    var centerPlaybackButtons: some View {
        HStack(alignment: .center, spacing: 48) {
            if viewModel.shouldShownJumpButtons {
                jumpBackwardButton
            }
            skipBackwardButton
            playPauseButton
            skipForwardButton
            if viewModel.shouldShownJumpButtons {
                jumpForwardButton
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        .foregroundStyle(TokenColors.Icon.onColor.swiftUI)
    }

    @ViewBuilder var playPauseButton: some View {
        switch viewModel.state {
        case .buffering, .opening:
            loadingSpinner
        case .playing:
            pauseButton
        case .paused, .stopped, .error, .ended:
            playButton
        }
    }

    var loadingSpinner: some View {
        ProgressView()
            .progressViewStyle(CircularProgressViewStyle(tint: .white))
            .scaleEffect(1.5)
            .frame(width: 56, height: 56)
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
        controlButton(name: "backward15") {
            Task {
                await viewModel.didTapJump(by: -15)
            }
        }
    }

    var jumpForwardButton: some View {
        controlButton(name: "forward15") {
            Task {
                await viewModel.didTapJump(by: 15)
            }
        }
    }
}

// MARK: - Bottom Toolbar

extension PlayerOverlayView {
    var bottomToolbar: some View {
        GeometryReader { geometry in
            let isLandscape = geometry.size.width > geometry.size.height
            if isLandscape {
                HStack(alignment: .bottom, spacing: TokenSpacing._7) {
                    timeLineView
                    bottomControls
                        .frame(maxWidth: 264)
                }
                .padding(.horizontal, TokenSpacing._5)
                .padding(.bottom, TokenSpacing._7)
                .frame(maxWidth: .infinity, alignment: .center)
                .background(.clear)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
            } else {
                VStack(spacing: TokenSpacing._7) {
                    timeLineView
                    bottomControls
                }
                .padding(.horizontal, TokenSpacing._5)
                .padding(.bottom, TokenSpacing._10)
                .frame(maxWidth: .infinity, alignment: .center)
                .background(.clear)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
            }
        }
    }

    var timeLineView: some View {
        VStack(alignment: .center, spacing: TokenSpacing._1) {
            currentTimeAndDuration
            seekBar
        }
    }

    private var currentTimeAndDuration: some View {
        HStack {
            Text(viewModel.currentTimeAndDurationString)
                .foregroundStyle(TokenColors.Text.onColor.swiftUI)
                .font(.footnote)
            Spacer()
        }
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
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        viewModel.updateSeekBarDrag(
                            at: value.location,
                            in: geometry.frame(in: .local)
                        )
                    }
                    .onEnded { value in
                        Task {
                            await self.viewModel.endSeekBarDrag(
                                at: value.location,
                                in: geometry.frame(in: .local)
                            )
                        }
                    }
            )
        }
        .frame(height: TokenSpacing._8)
        .contentShape(Rectangle())
    }

    var bottomControls: some View {
        HStack(alignment: .center, spacing: TokenSpacing._1) {
            playbackSpeedButton
            Spacer()
            loopButton
            Spacer()
            rotateButton
            Spacer()
            scalingButton
            Spacer()
            bottomMoreButton
        }
    }

    var playbackSpeedButton: some View {
        Button {
            viewModel.didTapPlaybackSpeed()
        } label: {
            Text(viewModel.currentSpeedString)
                .foregroundStyle(TokenColors.Text.onColor.swiftUI)
                .font(.system(size: 18))
                .frame(minWidth: 24)
                .frame(height: 24)
                .overlay {
                    // This is to increase the tappable area
                    Rectangle()
                        .fill(Color.clear)
                        .contentShape(Rectangle())
                        .frame(width: 44, height: 44)
                }
        }
    }

    var loopButton: some View {
        controlButton(
            name: "loop",
            color: viewModel.isLoopEnabled ?
                TokenColors.Icon.brand.swiftUI :
                TokenColors.Icon.onColor.swiftUI,
            action: viewModel.didTapLoopButton
        )
    }

    var scalingButton: some View {
        controlButton(
            name: viewModel.scalingMode == .fit ? "zoomToFill" : "scaleToFit",
            action: viewModel.didTapScalingButton
        )
    }

    var rotateButton: some View {
        controlButton(name: "rotate", action: viewModel.didTapRotate)
    }
    
    var bottomMoreButton: some View {
        controlButton(name: "moreBottom", action: viewModel.didTapBottomMoreButton)
    }

    private var playbackSpeedsBottomSelectionListHeight: Int {
        PlaybackSpeed.allCases.count * Int(Constants.bottomSheetRowHeight) + Int(Constants.bottomSheetTopPadding)
    }

    private var bottomMoreSheetHeight: Int {
        3 * Int(Constants.bottomSheetRowHeight) + Int(Constants.bottomSheetTopPadding)
    }

    private var playbackSpeedsSelectionListView: some View {
        ScrollView {
            VStack(spacing: .zero) {
                ForEach(PlaybackSpeed.allCases, id: \.rawValue) { playbackSpeed in
                    Button(action: {
                        viewModel.didSelectPlaybackSpeed(playbackSpeed)
                    }, label: {
                        playbackSpeedRowView(playbackSpeed)
                    })
                }
            }
            .padding(.top, Constants.bottomSheetTopPadding)
        }
        .background(
            TokenColors.Background.surface1.swiftUI,
            ignoresSafeAreaEdges: .all
        )
        .preferredColorScheme(.dark)
    }

    private func playbackSpeedRowView(
    _ playbackSpeed: PlaybackSpeed
    ) -> some View {
        HStack(spacing: .zero) {
            Text(playbackSpeed.displayText)
                .font(.body)
                .foregroundStyle(TokenColors.Text.primary.swiftUI)

            Spacer()

            if playbackSpeed == viewModel.currentSpeed {
                Image(systemName: "checkmark")
                    .foregroundStyle(TokenColors.Icon.secondary.swiftUI)
                    .frame(width: 24, height: 24, alignment: .center)
            }
        }
        .frame(height: Constants.bottomSheetRowHeight)
        .padding(.horizontal, TokenSpacing._5)
    }

    private var bottomMoreSheetView: some View {
        VStack(spacing: .zero) {
            bottomMoreSheetRowView(
                icon: "lock",
                title: Strings.Localizable.VideoPlayer.Lock.lockVideoPlayer,
                action: viewModel.didTapLock)
            
            bottomMoreSheetRowView(
                icon: "snapshot",
                title: Strings.Localizable.VideoPlayer.Snapshot.BottomSheet.title
            ) {
                Task {
                    await viewModel.didTapSnapshot()
                }
            }
            
            bottomMoreSheetRowView(
                icon: "pictureInPicture",
                title: Strings.Localizable.VideoPlayer.Pip.BottomSheet.title,
                action: viewModel.didTapPictureInPicture)
        }
        .padding(.top, Constants.bottomSheetTopPadding)
        .background(
            TokenColors.Background.surface1.swiftUI,
            ignoresSafeAreaEdges: .all
        )
        .preferredColorScheme(.dark)
    }

    private func bottomMoreSheetRowView(
        icon: String,
        title: String,
        action: @escaping () -> Void
    ) -> some View {
        Button {
            action()
        } label: {
            HStack(spacing: TokenSpacing._4) {
                Image(icon, bundle: .module)
                    .foregroundStyle(TokenColors.Icon.secondary.swiftUI)
                    .frame(width: 24, height: 24, alignment: .center)

                Text(title)
                    .font(.body)
                    .foregroundStyle(TokenColors.Text.primary.swiftUI)

                Spacer()
            }
            .frame(height: Constants.bottomSheetRowHeight)
            .padding(.horizontal, TokenSpacing._5)
        }
    }
    
    // MARK: - Lock Overlay
    
    private var lockOverlayView: some View {
        ZStack {
            Group {
                if viewModel.isLockOverlayVisible {
                    TokenColors.Background.blur.swiftUI
                } else {
                    Color.clear
                }
            }
            .ignoresSafeArea()
            .contentShape(Rectangle())
            .onTapGesture {
                viewModel.didTapVideoAreaWhileLocked()
            }

            if viewModel.isLockOverlayVisible {
                VStack(spacing: TokenSpacing._5) {
                    Spacer()
                    
                    Button {
                        viewModel.didTapDeactivateLock()
                    } label: {
                        Image("locked", bundle: .module)
                            .font(.system(size: 56))
                            .foregroundStyle(TokenColors.Icon.accent.swiftUI)
                    }
                    .buttonStyle(.plain)

                    VStack(spacing: TokenSpacing._3) {
                        Text(Strings.Localizable.VideoPlayer.Lock.screenLocked)
                            .font(.body)
                            .fontWeight(.semibold)
                            .foregroundStyle(.white)

                        Text(Strings.Localizable.VideoPlayer.Lock.tapIconToUnlock)
                            .font(.subheadline)
                            .foregroundStyle(TokenColors.Text.secondary.swiftUI)
                    }
                    .padding(.bottom, TokenSpacing._13)
                }
            }
        }
        .animation(.easeInOut(duration: 0.3), value: viewModel.isLockOverlayVisible)
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
                ),
                devicePermissionsHandler: DevicePermissionsHandler.makeHandler(),
                saveSnapshotUseCase: SaveSnapshotUseCase(),
                didTapBackAction: {},
                didTapRotateAction: {},
                didTapPictureInPictureAction: {}
            )
        )
    }
    .background(.black)
}
