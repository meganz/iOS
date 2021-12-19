import SwiftUI

@available(iOS 14.0, *)
struct CardImage: View {
    let container: ImageContainer
    
    var body: some View {
        if container.isPlaceholder {
            container.image
        } else {
            container.image
                .resizable()
                .aspectRatio(contentMode: .fill)
                .clipped()
        }
    }
}
