import MEGAPresentation
import SwiftUI

public enum SensitiveModifierType {
    case none, blur, opacity
}

struct SensitiveModifier: ViewModifier {
    let type: SensitiveModifierType
    
    func body(content: Content) -> some View {
        switch type {
        case .none:
            content
        case .blur:
            content.blur(radius: 7.0)
        case .opacity:
            content.opacity(0.5)
        }
    }
}

public extension View {
    func sensitive(_ type: SensitiveModifierType) -> some View {
        modifier(SensitiveModifier(type: type))
    }
    
    @ViewBuilder
    func sensitive(_ container: any ImageContaining) -> some View {
        if let container = container as? any SensitiveImageContaining {
            sensitive(container.isSensitive ? .blur : .none)
        } else {
            self
        }
    }
}
