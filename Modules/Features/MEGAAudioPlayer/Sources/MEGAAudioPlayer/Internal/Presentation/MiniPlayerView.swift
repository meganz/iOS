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

// MARK: - Loader Throbber

/// 8-dash circular spinner matching the `loader-throbber` Figma component
struct LoaderThrobber: View {
    private let dashCount = 8
    private let dashLength: CGFloat = 5
    private let dashWidth: CGFloat = 2

    /// Tail opacity — the dimmest segment in the ring. Leading dash stays at
    /// 1.0; intermediate dashes interpolate linearly between the two.
    private let tailOpacity: CGFloat = 0.2

    /// One full revolution in seconds. Slower than the default Apple spinner
    /// (~1s) — the dashed look reads as "frantic" at higher speeds.
    private let revolutionDuration: Double = 1.4

    @State private var angle: Angle = .zero

    var body: some View {
        GeometryReader { proxy in
            let size = min(proxy.size.width, proxy.size.height)
            let radius = size / 2 - dashLength / 2

            ZStack {
                ForEach(0..<dashCount, id: \.self) { index in
                    Capsule()
                        .frame(width: dashWidth, height: dashLength)
                        .offset(y: -radius)
                        .rotationEffect(.degrees(Double(index) * (360.0 / Double(dashCount))))
                        .opacity(opacity(forIndex: index))
                }
            }
            .foregroundStyle(TokenColors.Icon.primary.swiftUI)
            .frame(width: size, height: size)
            .rotationEffect(angle)
            // `.linear` repeatForever rotates a full revolution every
            // `revolutionDuration` seconds; setting the destination angle
            // inside `.onAppear` is what kicks the animation off — assigning
            // during init would happen before the view is in the hierarchy
            // and SwiftUI would skip the tween.
            .animation(.linear(duration: revolutionDuration).repeatForever(autoreverses: false), value: angle)
            .onAppear { angle = .degrees(360) }
        }
        .aspectRatio(1, contentMode: .fit)
    }

    /// Linear ramp from `1.0` at the leading dash down to `tailOpacity` at the
    /// trailing one. Computing it inline (vs hard-coded 8 numbers) keeps the
    /// ramp coherent if `dashCount` ever changes.
    private func opacity(forIndex index: Int) -> Double {
        guard dashCount > 1 else { return 1 }
        let progress = Double(index) / Double(dashCount - 1)
        return 1.0 - progress * (1.0 - Double(tailOpacity))
    }
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
