import MEGADesignToken
import SwiftUI

struct PhotoCellFavoriteBadge: ViewModifier {
    let isFavorite: Bool
    let useLegacyStyle: Bool
    
    func body(content: Content) -> some View {
        content
            .overlay(favoriteOverlay, alignment: .topTrailing)
    }
    
    private var favoriteOverlay: some View {
        ZStack(alignment: .topTrailing) {
            if useLegacyStyle {
                Rectangle()
                    .fill(LinearGradient(gradient: Gradient(colors: [Color.black.opacity(0.3), Color.white.opacity(0.01)]), startPoint: .top, endPoint: .bottom))
                    .alignmentGuide(.top) { d in d[.top] }
                    .frame(height: 40)
            }

            Image(systemName: "heart.fill")
                .resizable()
                .foregroundStyle(TokenColors.Text.onColor.swiftUI)
                .frame(width: 12, height: 11)
                .if(!useLegacyStyle) { view in
                    view.frame(width: 20, height: 20)
                        .background(Color.black.opacity(0.7))
                        .cornerRadius(2)
                }
                .offset(x: -4, y: 4)
        }
        .opacity(isFavorite ? 1 : 0)
    }
}

public extension View {
    func favorite(_ isFavorite: Bool, useLegacyStyle: Bool = false) -> some View {
        modifier(PhotoCellFavoriteBadge(isFavorite: isFavorite, useLegacyStyle: useLegacyStyle))
    }
}
