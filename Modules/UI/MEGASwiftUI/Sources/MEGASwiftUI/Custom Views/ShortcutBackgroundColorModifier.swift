import SwiftUI
import WidgetKit

public struct ShortcutBackgroundColorModifier: ViewModifier {
    let topBackgroundColor: Color
    let bottomBackgroundColor: Color
    let renderMode: WidgetRenderingMode
    
    public func body(content: Content) -> some View {
        if #available(iOS 18.0, *), renderMode == .accented {
            content
                .applyWidgetAccent()
        } else {
            content
                .background(LinearGradient(gradient: Gradient(colors: [topBackgroundColor, bottomBackgroundColor]), startPoint: .top, endPoint: .bottom))
        }
    }
}

public extension View {
    func shortcutBackgroundColor(topBackgroundColor: Color, bottomBackgroundColor: Color, renderMode: WidgetRenderingMode) -> some View {
        modifier(ShortcutBackgroundColorModifier(topBackgroundColor: topBackgroundColor,
                                                 bottomBackgroundColor: bottomBackgroundColor,
                                                 renderMode: renderMode))
    }
}
