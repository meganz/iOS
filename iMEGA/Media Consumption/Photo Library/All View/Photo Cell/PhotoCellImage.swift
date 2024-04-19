import MEGASwiftUI
import SwiftUI

struct PhotoCellImage: View {
    let container: any ImageContaining
    var aspectRatio: CGFloat?
    var bgColor = Color.clear
    var isSensitive = false
    
    var body: some View {
        if container.type == .placeholder {
            bgColor
                .aspectRatio(contentMode: .fill)
                .overlay(
                    container.image
                )
                .clipped()
        } else {
            thumbnail()
        }
    }
    
    private func thumbnail() -> some View {
        container.image
            .resizable()
            .aspectRatio(aspectRatio, contentMode: .fill)
            .sensitive(isSensitive)
    }
}

#Preview {
    PhotoCellImage(
        container: ImageContainer(
            image: Image(systemName: "square"),
            type: .thumbnail
        )
    )
}
