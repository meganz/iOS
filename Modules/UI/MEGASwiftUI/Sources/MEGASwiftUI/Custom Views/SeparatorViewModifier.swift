import SwiftUI

struct SeparatorViewModifier: ViewModifier {
    var separatorOffSet: CGFloat
    var separatorColor: Color
    
    func body(content: Content) -> some View {
        VStack(spacing: 0) {
            content
            
            separatorColor
                .frame(height: 0.3)
                .offset(x: separatorOffSet)
        }
    }
}

public extension View {
    ///  Applies a bottom separator view like in tableview cell rows based on provided offset and color.
    /// - Parameter offset: Separator offset from the x origin
    /// - Parameter color: Color of separator view
    /// - Returns: A modified view that will add a separator at the bottom of the content view.
    func separatorView(offset: CGFloat, color: Color) -> some View {
        modifier(SeparatorViewModifier(separatorOffSet: offset, separatorColor: color))
    }
}
