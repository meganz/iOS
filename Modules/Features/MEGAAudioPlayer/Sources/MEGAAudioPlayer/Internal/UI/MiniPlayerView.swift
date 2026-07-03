import MEGAAssets
import MEGADesignToken
import MEGAInfrastructure
import SwiftUI

/// The pill mini player docked above the tab bar.
struct MiniPlayerView: View {
    @ObservedObject var vm: MiniPlayerViewModel

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
        VStack(alignment: .leading, spacing: 0) {
            Text(vm.title)
                .font(.callout.weight(.semibold))
                .lineLimit(1)
                .foregroundStyle(TokenColors.Text.primary.swiftUI)
            Text(vm.artist)
                .font(.caption)
                .lineLimit(1)
                .foregroundStyle(TokenColors.Text.secondary.swiftUI)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
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
        vm.preview(title: "Novacane", artist: "Frank Ocean", loadingState: .loading)
        return vm
    }())
    .padding()
    .background(Color.orange)
}

#Preview("Playing") {
    MiniPlayerView(vm: {
        let vm = MiniPlayerViewModel()
        vm.preview(title: "Novacane", artist: "Frank Ocean", loadingState: .playing)
        return vm
    }())
    .padding()
    .background(Color.orange)
}

#Preview("Paused") {
    MiniPlayerView(vm: {
        let vm = MiniPlayerViewModel()
        vm.preview(title: "Novacane", artist: "Frank Ocean", loadingState: .paused)
        return vm
    }())
    .padding()
    .background(Color.orange)
}

#Preview("Dark — Playing") {
    MiniPlayerView(vm: {
        let vm = MiniPlayerViewModel()
        vm.preview(title: "Novacane", artist: "Frank Ocean", loadingState: .playing)
        return vm
    }())
    .padding()
    .background(Color.black)
    .preferredColorScheme(.dark)
}
