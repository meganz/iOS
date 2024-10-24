import SwiftUI
import WidgetKit

public struct WidgetAccentViewModifier: ViewModifier {
    public func body(content: Content) -> some View {
        if #available(iOS 18.0, *) {
            content
                .widgetAccentable()
        } else {
            content
        }
    }
}

public extension View {
    func applyWidgetAccent() -> some View {
        modifier(WidgetAccentViewModifier())
    }
}
