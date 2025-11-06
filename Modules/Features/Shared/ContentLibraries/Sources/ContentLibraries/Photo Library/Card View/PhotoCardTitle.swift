import MEGADesignToken
import SwiftUI

struct PhotoCardTitle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .foregroundColor(.white)
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                LinearGradient(colors: [.black, .black.opacity(0.3), .black.opacity(0)], startPoint: .top, endPoint: .bottom)
            )
    }
}

extension View {
    func photoCardTitle() -> some View {
        modifier(PhotoCardTitle())
    }
}
