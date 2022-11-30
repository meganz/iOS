import SwiftUI

struct BlurryBackground: ViewModifier {
    let radius: CGFloat
    let singleColorTheme: Bool
    
    init(radius: CGFloat, singleColorTheme: Bool = false) {
        self.radius = radius
        self.singleColorTheme = singleColorTheme
    }
    
    func body(content: Content) -> some View {
        if singleColorTheme {
            content
                .background(BlurryView(singleColorTheme: true))
                .cornerRadius(radius)
        } else if #available(iOS 15.0, *) {
            content
                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: radius))
        } else {
            content
                .background(BlurryView(singleColorTheme: false))
                .cornerRadius(radius)
        }
    }
}

public extension View {
    func blurryBackground(radius: CGFloat = 0, singleColorTheme: Bool = false) -> some View {
        modifier(BlurryBackground(radius: radius, singleColorTheme: singleColorTheme))
    }
}
