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
        .disabled(vm.status == .loading)
    }

    @ViewBuilder
    private var stateIcon: some View {
        switch vm.status {
        case .loading:
            LoaderThrobber()
                .frame(width: Sizes.iconSize, height: Sizes.iconSize)
        case .playing, .buffering:
            Image(uiImage: MEGAAssets.UIImage.miniplayerPause)
                .renderingMode(.template)
                .foregroundStyle(TokenColors.Icon.primary.swiftUI)
        case .paused, .error:
            Image(uiImage: MEGAAssets.UIImage.miniplayerPlay)
                .renderingMode(.template)
                .foregroundStyle(TokenColors.Icon.primary.swiftUI)
        }
    }

    private var details: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(vm.title)
                .font(.system(size: Sizes.titleFontSize, weight: .semibold))
                .lineLimit(1)
                .foregroundStyle(TokenColors.Text.primary.swiftUI)
            Text(vm.artist)
                .font(.system(size: Sizes.artistFontSize, weight: .regular))
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
}

// MARK: - Sizes

private enum Sizes {
    static let pillHeight: CGFloat = 44
    static let iconSize: CGFloat = 24

    /// Horizontal inset between the pill and its container's edges
    static let horizontalMargin: CGFloat = 21

    static let titleFontSize: CGFloat = 16
    static let artistFontSize: CGFloat = 12

    static let surfaceOpacity: CGFloat = 0.67
}

// MARK: - Previews

#Preview("Loading") {
    MiniPlayerView(vm: {
        let vm = MiniPlayerViewModel()
        vm.preview(title: "Novacane", artist: "Frank Ocean", status: .loading)
        return vm
    }())
    .padding()
    .background(Color.orange)
}

#Preview("Playing") {
    MiniPlayerView(vm: {
        let vm = MiniPlayerViewModel()
        vm.preview(title: "Novacane", artist: "Frank Ocean", status: .playing)
        return vm
    }())
    .padding()
    .background(Color.orange)
}

#Preview("Paused") {
    MiniPlayerView(vm: {
        let vm = MiniPlayerViewModel()
        vm.preview(title: "Novacane", artist: "Frank Ocean", status: .paused)
        return vm
    }())
    .padding()
    .background(Color.orange)
}

#Preview("Dark — Playing") {
    MiniPlayerView(vm: {
        let vm = MiniPlayerViewModel()
        vm.preview(title: "Novacane", artist: "Frank Ocean", status: .playing)
        return vm
    }())
    .padding()
    .background(Color.black)
    .preferredColorScheme(.dark)
}
