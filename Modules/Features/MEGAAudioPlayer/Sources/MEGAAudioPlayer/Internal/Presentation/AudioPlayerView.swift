import MEGAAssets
import MEGADesignToken
import MEGASwiftUI
import SwiftUI
import UIKit

struct AudioPlayerView: View {
    @ObservedObject var vm: AudioPlayerViewModel
    @Environment(\.verticalSizeClass) private var verticalSizeClass

    private var isLandscape: Bool { verticalSizeClass == .compact }

    var body: some View {
        ZStack {
            BackgroundLayer()
                .ignoresSafeArea()

            if isLandscape {
                HStack {
                    ArtworkSection(coverImage: vm.artworkImage, glowColor: vm.glowColor)
                        .padding(.leading, TokenSpacing._9)
                    Spacer()
                }
            } else {
                VStack {
                    ArtworkSection(coverImage: vm.artworkImage, glowColor: vm.glowColor)
                        .padding(.top, TokenSpacing._15)
                    Spacer()
                }
            }
        }
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    vm.dismiss()
                } label: {
                    Image(systemName: "chevron.down")
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                if !vm.isActionsMenuHidden {
                    Button {
                        vm.didTapMore()
                    } label: {
                        Image(systemName: "ellipsis")
                    }
                }
            }
        }
        .preferredColorScheme(.dark)
        .task(id: vm.artworkURLString) {
            await vm.loadArtwork()
        }
    }
}

// MARK: - Background

private struct BackgroundLayer: View {

    var body: some View {
        LinearGradient(
            colors: [
                Color(red: 73 / 255, green: 9 / 255, blue: 0),
                Color(red: 21 / 255, green: 22 / 255, blue: 22 / 255)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

// MARK: - Artwork

private struct ArtworkSection: View {
    let coverImage: UIImage?
    let glowColor: Color?

    private let artworkSize = 322.0
    private let placeholderWidth = 183.0
    private let placeholderHeight = 206.0
    private let glowHeight = 315.0
    private let glowBlurRadius = 125.0

    var body: some View {
        ZStack {
            glow
            cover
        }
    }

    /// color halo behind the artwork . The blur extends rendered pixels ~125pt beyond
    /// the rectangle bounds, so the color halo bleeds out from behind the artwork on all sides.
    /// The `EllipticalGradient` with `center: (0.5, 0.08)` anchors the gradient
    /// near the top, biasing the visible halo upward
    @ViewBuilder
    private var glow: some View {
        if let glowColor {
            EllipticalGradient(
                stops: [
                    .init(color: glowColor, location: 0.00),
                    .init(color: glowColor, location: 1.00)
                ],
                center: UnitPoint(x: 0.5, y: 0.08)
            )
            .frame(width: artworkSize, height: glowHeight)
            .cornerRadius(TokenSpacing._5)
            .blur(radius: glowBlurRadius)
        }
    }

    private var cover: some View {
        coverContent
            .frame(width: artworkSize, height: artworkSize)
            .background(Color.white.opacity(0.05))
            .clipShape(RoundedRectangle(cornerRadius: TokenRadius.large))
    }

    @ViewBuilder
    private var coverContent: some View {
        if let coverImage {
            Image(uiImage: coverImage)
                .resizable()
                .scaledToFill()
        } else {
            coverPlaceholder
        }
    }

    private var coverPlaceholder: some View {
        MEGAAssets.Image.audioIcon
            .resizable()
            .scaledToFit()
            .frame(width: placeholderWidth, height: placeholderHeight)
    }
}

// MARK: - Preview

#Preview("Music — Playing") {
    AudioPlayerView(vm: {
        let vm = AudioPlayerViewModel()
        return vm
    }())
}
