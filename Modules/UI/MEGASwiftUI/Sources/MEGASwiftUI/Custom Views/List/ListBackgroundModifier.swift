import SwiftUI

@available(iOS 16, *)
struct ListBackgroundModifier: ViewModifier {
    var backgroundColor: Color
    
    func body(content: Content) -> some View {
        content
            .scrollContentBackground(.hidden)
            .background(backgroundColor)
    }
}

public extension View {
    @ViewBuilder
    func listBackgroundColor(_ color: Color) -> some View {
        if #available(iOS 16, *) {
            modifier(ListBackgroundModifier(backgroundColor: color))
        } else {
            background(color)
        }
    }
}
