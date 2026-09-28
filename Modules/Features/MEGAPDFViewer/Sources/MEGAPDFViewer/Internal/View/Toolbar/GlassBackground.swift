import SwiftUI

@available(iOS 26.0, *)
struct GlassBackground<S: InsettableShape>: ViewModifier {
    let shape: S

    func body(content: Content) -> some View {
        content.glassEffect(.regular.interactive(), in: shape)
    }
}

@available(iOS 26.0, *)
extension View {
    func glassBackground(in shape: some InsettableShape) -> some View {
        modifier(GlassBackground(shape: shape))
    }
}
