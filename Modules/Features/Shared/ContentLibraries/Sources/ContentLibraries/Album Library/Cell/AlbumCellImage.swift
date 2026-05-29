import MEGAAppPresentation
import MEGAAssets
import MEGADesignToken
import SwiftUI

struct AlbumCellImage: View {
    let container: any ImageContaining
    
    var body: some View {
        if container.type == .placeholder {
            TokenColors.Background.surface1.swiftUI
                .aspectRatio(contentMode: .fill)
                .overlay(alignment: .center) {
                    container.image
                        .renderingMode(.template)
                        .resizable()
                        .foregroundStyle(TokenColors.Icon.primary.swiftUI)
                        .opacity(0.1)
                        .frame(width: 100, height: 100)
                }
        } else {
            thumbnail
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
            type: .thumbnail)
    )
}
