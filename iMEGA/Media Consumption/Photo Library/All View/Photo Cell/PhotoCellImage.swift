import SwiftUI

struct PhotoCellImage: View {
    let container: ImageContainer
    
    var body: some View {
        if container.isPlaceholder {
            Color.clear
                .aspectRatio(1, contentMode: .fill)
                .overlay(
                    container.image
                )
        } else {
            if let overlay = container.overlay {
                thumbnail()
                    .overlay(overlay)
            } else {
                thumbnail()
            }
        }
    }
    
    private func thumbnail() -> some View {
        container.image
            .resizable()
            .aspectRatio(1, contentMode: .fill)
    }
}
