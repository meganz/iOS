import MEGAPresentation
import SwiftUI

public struct PhotoCellImage: View {
    let container: any ImageContaining
    var aspectRatio: CGFloat?
    var bgColor: Color
    
    public init(container: any ImageContaining, aspectRatio: CGFloat? = nil, bgColor: Color = .clear) {
        self.container = container
        self.aspectRatio = aspectRatio
        self.bgColor = bgColor
    }
    
    public var body: some View {
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
            .sensitive(container)
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
