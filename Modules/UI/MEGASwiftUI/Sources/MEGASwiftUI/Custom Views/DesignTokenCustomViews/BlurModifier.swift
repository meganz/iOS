import MEGADesignToken
import SwiftUI

public struct BlurModifier: ViewModifier {
    public func body(content: Content) -> some View {
        background(content: content)
    }
    
    @ViewBuilder
    func background(content: Content) -> some View {
        content.background(Blur(style: .systemUltraThinMaterial).cornerRadius(7, corners: .allCorners))
    }
}

public extension View {
    @ViewBuilder
    func blurBackground() -> some View {
        modifier(BlurModifier())
    }
}
