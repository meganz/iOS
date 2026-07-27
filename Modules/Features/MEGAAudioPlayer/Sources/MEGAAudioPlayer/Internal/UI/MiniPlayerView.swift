import MEGAAssets
import MEGADesignToken
import MEGAInfrastructure
import SwiftUI

/// The pill mini player docked above the tab bar.
struct MiniPlayerView: View {
    @ObservedObject var vm: MiniPlayerViewModel

    @State private var displayIndex = 0

    var body: some View {
        pillBody
            .frame(height: Sizes.pillHeight)
            .contentShape(Capsule())
            .onTapGesture { vm.expand() }
            .padding(.horizontal, Sizes.horizontalMargin)
            .padding(.bottom, Sizes.bottomPadding)
    }

    @ViewBuilder
    private var pillBody: some View {
        if #available(iOS 26.0, *), !ProcessInfo.isRunningIOS26_0Beta {
            pillContent
                .glassEffect(
                    .regular.tint(TokenColors.Background.surface1.swiftUI.opacity(Sizes.surfaceOpacity)),
                    in: Capsule()
                )
        } else {
            pillContent
                .background(legacyPillBackground)
        }
    }

    private var pillContent: some View {
        HStack(spacing: TokenSpacing._3) {
            stateIconButton
            details
            closeButton
        }
        .padding(.horizontal, TokenSpacing._3)
        .padding(.vertical, TokenSpacing._1)
    }

    /// Pre-iOS-26 approximation: `ultraThinMaterial` blur with the surface-1
    /// token tint stacked on top. Lacks real refraction and edge specular but
    /// honours the design tokens for light / dark.
    private var legacyPillBackground: some View {
        ZStack {
            Capsule().fill(.ultraThinMaterial)
            Capsule().fill(TokenColors.Background.surface1.swiftUI.opacity(Sizes.surfaceOpacity))
        }
    }

    // MARK: - Pieces

    private var stateIconButton: some View {
        Button {
            vm.togglePlayPause()
        } label: {
            stateIcon
                .frame(width: Sizes.iconSize, height: Sizes.iconSize)
                .padding(TokenSpacing._3)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(vm.isPreparing)
    }

    @ViewBuilder
    private var stateIcon: some View {
        switch vm.loadingState {
        case .loading, .ready:
            LoaderThrobber()
                .frame(width: Sizes.iconSize, height: Sizes.iconSize)
        case .playing:
            Image(uiImage: MEGAAssets.UIImage.miniplayerPause)
                .renderingMode(.template)
                .foregroundStyle(TokenColors.Icon.primary.swiftUI)
        case .paused:
            Image(uiImage: MEGAAssets.UIImage.miniplayerPlay)
                .renderingMode(.template)
                .foregroundStyle(TokenColors.Icon.primary.swiftUI)
        }
    }

    private var details: some View {
        TabView(selection: $displayIndex) {
            ForEach(Array(vm.tracks.enumerated()), id: \.element.id) { index, track in
                trackLabel(track, index: index)
                    .tag(index)
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        .frame(maxWidth: .infinity)
        .onAppear { displayIndex = vm.currentIndex }
        .onChange(of: displayIndex) { _, newIndex in requestSwitch(to: newIndex) }
        .onChange(of: vm.currentIndex) { _, newIndex in reconcile(to: newIndex) }
    }

    private func trackLabel(_ track: MiniPlayerTrack, index: Int) -> some View {
        let isPlaying = index == vm.currentIndex
        return VStack(alignment: .leading, spacing: 0) {
            Text(isPlaying ? vm.title : track.title)
                .font(.callout.weight(.semibold))
                .lineLimit(1)
                .foregroundStyle(TokenColors.Text.primary.swiftUI)
            if isPlaying {
                Text(vm.artist)
                    .font(.caption)
                    .lineLimit(1)
                    .foregroundStyle(TokenColors.Text.secondary.swiftUI)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Switching tracks

    private func requestSwitch(to newIndex: Int) {
        guard newIndex != vm.currentIndex else { return }
        if newIndex > vm.currentIndex {
            vm.skipToNext()
        } else {
            vm.skipToPrevious()
        }
    }

    private func reconcile(to newIndex: Int) {
        guard displayIndex != newIndex else { return }
        displayIndex = newIndex
    }

    private var closeButton: some View {
        Button {
            vm.close()
        } label: {
            MEGAAssets.Image.x
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .frame(width: Sizes.iconSize, height: Sizes.iconSize)
                .foregroundStyle(TokenColors.Icon.primary.swiftUI)
                .padding(TokenSpacing._3)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Sizes

    enum Sizes {
        static let pillHeight: CGFloat = TokenSpacing._12
        static let iconSize: CGFloat = TokenSpacing._7

        static let horizontalMargin: CGFloat = 21

        static let bottomPadding: CGFloat = TokenSpacing._5

        static let surfaceOpacity: CGFloat = 0.67

        static let reserved: CGFloat = pillHeight + bottomPadding
    }
}

// MARK: - Previews

#Preview("Loading") {
    MiniPlayerView(vm: {
        let vm = MiniPlayerViewModel()
        vm.preview(title: "Novacane", artist: "Frank Ocean", loadingState: .loading, queueTitles: ["Novacane"])
        return vm
    }())
    .padding()
    .background(Color.orange)
}

#Preview("Playing — swipeable") {
    MiniPlayerView(vm: {
        let vm = MiniPlayerViewModel()
        vm.preview(
            title: "Novacane",
            artist: "Frank Ocean",
            loadingState: .playing,
            queueTitles: ["Thinkin Bout You", "Novacane", "Aud.2314"],
            currentIndex: 1
        )
        return vm
    }())
    .padding()
    .background(Color.orange)
}

#Preview("Paused") {
    MiniPlayerView(vm: {
        let vm = MiniPlayerViewModel()
        vm.preview(title: "Novacane", artist: "Frank Ocean", loadingState: .paused, queueTitles: ["Novacane"])
        return vm
    }())
    .padding()
    .background(Color.orange)
}

#Preview("Dark — Playing") {
    MiniPlayerView(vm: {
        let vm = MiniPlayerViewModel()
        vm.preview(title: "Novacane", artist: "Frank Ocean", loadingState: .playing, queueTitles: ["Novacane"])
        return vm
    }())
    .padding()
    .background(Color.black)
    .preferredColorScheme(.dark)
}
