import SwiftUI

struct DetermineViewSizeModifier: ViewModifier {
    
    let onChangeHandler: @Sendable (CGSize) -> Void
    
    func body(content: Content) -> some View {
        content
            .frame(in: .named("DetermineViewSizeModifier"))
            .onPreferenceChange(FramePreferenceKey.self) {
                onChangeHandler($0.size)
            }
    }
}

public extension View {
    
    /// Fetches the view size  once it has rendered
    /// - Parameter onChangeHandler: Handler to monitor view size changes
    /// - Returns: A modified view that will monitor and report the view size
    func determineViewSize(onChangeHandler: @escaping @Sendable (CGSize) -> Void) -> some View {
        modifier(DetermineViewSizeModifier(onChangeHandler: onChangeHandler))
    }
}
