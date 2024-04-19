import SwiftUI

struct SensitiveModifier: ViewModifier {
    let isSensitive: Bool
    let radius: CGFloat
    let opaque: Bool
    
    func body(content: Content) -> some View {
        if isSensitive {
            content
                .blur(radius: radius,
                      opaque: opaque)
        } else {
            content
        }
    }
}

public extension View {
    func sensitive(_ isSensitive: Bool,
                   radius: CGFloat = 6.0,
                   opaque: Bool = false) -> some View {
        modifier(SensitiveModifier(isSensitive: isSensitive,
                                   radius: radius,
                                   opaque: opaque))
    }
}
