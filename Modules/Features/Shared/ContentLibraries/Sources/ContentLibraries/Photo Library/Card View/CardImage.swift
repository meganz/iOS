import MEGAAppPresentation
import SwiftUI

struct CardImage: View {
    let container: any ImageContaining
    
    var body: some View {
        if container.type == .placeholder {
            container.image
        } else {
            thumbnail()
        }
    }
    
    private func thumbnail() -> some View {
        container.image
            .resizable()
            .aspectRatio(contentMode: .fill)
            .sensitive(container)
            .clipped()
    }
}
