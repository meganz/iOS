import SwiftUI

struct PhotoCellFavoriteBadge: ViewModifier {
    let isFavorite: Bool
    
    func body(content: Content) -> some View {
        content
            .overlay(favoriteOverlay, alignment: .topTrailing)
    }
    
    @ViewBuilder private var favoriteOverlay: some View {
        if isFavorite {
            ZStack(alignment: .topTrailing) {
                Rectangle()
                    .fill(LinearGradient(gradient: Gradient(colors: [Color.black.opacity(0.3), Color.white.opacity(0.01)]), startPoint: .top, endPoint: .bottom))
                    .alignmentGuide(.top) { d in d[.top] }
                
                Image(systemName: "heart.fill")
                    .resizable()
                    .foregroundColor(Color.white)
                    .offset(x: -5, y: 5)
                    .frame(width: 12, height: 11)
            }
            .frame(height: 40, alignment: .top)
        }
    }
}

public extension View {
    func favorite(_ isFavorite: Bool) -> some View {
        modifier(PhotoCellFavoriteBadge(isFavorite: isFavorite))
    }
}
