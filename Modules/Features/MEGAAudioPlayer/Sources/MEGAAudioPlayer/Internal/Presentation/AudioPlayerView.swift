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
                    ArtworkSection()
                        .padding(.leading, TokenSpacing._9)
                    Spacer()
                }
            } else {
                VStack {
                    ArtworkSection()
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
    private let artworkSize = 322.0
    private let placeholderWidth = 183.0
    private let placeholderHeight = 206.0

    var body: some View {
        cover
    }

    private var cover: some View {
        coverPlaceholder
            .frame(width: artworkSize, height: artworkSize)
            .background(Color.white.opacity(0.05))
            .clipShape(RoundedRectangle(cornerRadius: TokenRadius.large))
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
