import SwiftUI
import MEGASwiftUI

struct CardImage: View {
    let container: any ImageContaining
    
    var body: some View {
        if container.isPlaceholder {
            container.image
        } else {
            thumbnail()
        }
    }
    
    private func thumbnail() -> some View {
        container.image
            .resizable()
            .aspectRatio(contentMode: .fill)
            .clipped()
    }
}
