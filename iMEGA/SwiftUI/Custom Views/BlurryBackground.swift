import SwiftUI

@available(iOS 14.0, *)
struct BlurryBackground: ViewModifier {
    let radius: CGFloat
    
    func body(content: Content) -> some View {
        if #available(iOS 15.0, *) {
            content
                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: radius))
        } else {
            content
                .background(BlurryView())
                .cornerRadius(radius)
        }
    }
}

@available(iOS 14.0, *)
extension View {
    func blurryBackground(radius: CGFloat = 0) -> some View {
        modifier(BlurryBackground(radius: radius))
    }
}
