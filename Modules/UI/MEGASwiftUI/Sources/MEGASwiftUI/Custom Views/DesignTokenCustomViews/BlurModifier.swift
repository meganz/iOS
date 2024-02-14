import MEGADesignToken
import SwiftUI

public struct BlurModifier: ViewModifier {
    private let isDesignTokenEnabled: Bool
    private let backgroundColor: Color
    
    public init(isDesignTokenEnabled: Bool, backgroundColor: Color) {
        self.isDesignTokenEnabled = isDesignTokenEnabled
        self.backgroundColor = backgroundColor
    }
    
    public func body(content: Content) -> some View {
        background(content: content)
    }
    
    @ViewBuilder
    func background(content: Content) -> some View {
        if isDesignTokenEnabled {
            content.background(Blur(style: .systemUltraThinMaterial).cornerRadius(7, corners: .allCorners))
        } else {
            content.background(backgroundColor.cornerRadius(7, corners: .allCorners))
        }
    }
}

public extension View {
    @ViewBuilder
    func blurBackground(_ isDesignTokenEnabled: Bool, color: Color) -> some View {
        modifier(BlurModifier(isDesignTokenEnabled: isDesignTokenEnabled, backgroundColor: color))
    }
}
