import SwiftUI

struct PhotoCellImage: View {
    let container: ImageContainer
    var aspectRatio: CGFloat?
    
    var body: some View {
        if container.isPlaceholder {
            Color.clear
                .aspectRatio(1, contentMode: .fill)
                .overlay(
                    container.image
                )
        } else {
            thumbnail()
        }
    }
    
    private func thumbnail() -> some View {
        container.image
            .resizable()
            .aspectRatio(aspectRatio, contentMode: .fill)
    }
}
