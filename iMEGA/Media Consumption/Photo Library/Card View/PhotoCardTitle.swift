import SwiftUI

struct PhotoCardTitle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .foregroundColor(UIColor.whiteFFFFFF.swiftUI)
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                LinearGradient(colors: [.black000000.opacity(0.3), .black000000.opacity(0)], startPoint: .top, endPoint: .bottom)
            )
    }
}

extension View {
    func photoCardTitle() -> some View {
        modifier(PhotoCardTitle())
    }
}
