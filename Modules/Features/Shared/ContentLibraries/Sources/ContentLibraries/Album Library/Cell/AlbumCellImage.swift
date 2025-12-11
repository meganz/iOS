import MEGAAppPresentation
import MEGAAssets
import MEGADesignToken
import SwiftUI

struct AlbumCellImage: View {
    let container: any ImageContaining
    let isMediaRevampEnabled: Bool
    
    var body: some View {
        if container.type == .placeholder {
            placeholderBackground
                .aspectRatio(contentMode: .fill)
                .overlay(alignment: .center) {
                    container.image
                        .renderingMode(.template)
                        .resizable()
                        .foregroundStyle(isMediaRevampEnabled ? TokenColors.Icon.primary.swiftUI : TokenColors.Text.disabled.swiftUI)
                        .opacity(isMediaRevampEnabled ? 0.1 : 1.0)
                        .frame(width: placeholderSize.width, height: placeholderSize.height)
                }
        } else {
            thumbnail
        }
    }
    
    @ViewBuilder
    private var placeholderBackground: some View {
        if isMediaRevampEnabled {
            TokenColors.Background.surface1.swiftUI
        } else {
            TokenColors.Background.surface2.swiftUI
        }
    }
    
    private var placeholderSize: CGSize {
        if isMediaRevampEnabled {
            CGSize(width: 100, height: 100)
        } else {
            CGSize(width: 40, height: 40)
        }
    }
    
    private var thumbnail: some View {
        container.image
            .resizable()
            .aspectRatio(contentMode: .fill)
            .sensitive(container)
    }
}

#Preview {
    AlbumCellImage(
        container: ImageContainer(
            image: Image("folder"),
            type: .thumbnail),
        isMediaRevampEnabled: true
    )
}
