import MEGAAppPresentation
import MEGADesignToken
import SwiftUI

struct AlbumCellImage: View {
    let container: any ImageContaining
    
    var body: some View {
        if container.type == .placeholder {
            TokenColors.Background.surface2.swiftUI
                .aspectRatio(contentMode: .fill)
                .overlay(alignment: .center) {
                    container.image
                        .resizable()
                        .renderingMode(.template)
                        .foregroundStyle(TokenColors.Text.disabled.swiftUI)
                        .frame(width: 40, height: 40)
                }
        } else {
            thumbnail()
        }
    }
    
    private func thumbnail() -> some View {
        container.image
            .resizable()
            .aspectRatio(contentMode: .fill)
            .sensitive(container)
    }
}

#Preview {
    AlbumCellImage(container: ImageContainer(
        image: Image("folder"),
        type: .thumbnail)
    )
}
