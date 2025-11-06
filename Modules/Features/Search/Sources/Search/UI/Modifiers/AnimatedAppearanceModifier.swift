import SwiftUI

struct AnimatedAppearanceModifier: ViewModifier {
    var isContentLoaded: Bool
    let duration: Double

    func body(content: Content) -> some View {
        content
            .opacity(isContentLoaded ? 1 : 0)
            .animation(.linear(duration: duration), value: !isContentLoaded)
    }
}

extension View {
    
    /// Animate the appearance of a view, to be used for situation where we want asynchronously load the content of a view
    /// - Parameters:
    ///   - isContentLoaded: A `Binding` value to determine when/whether to perform the animated transition.
    ///     - If isContentLoaded goes from false -> true, the view will appear with a fading animation.
    ///     - If isContentLoaded is true, the view will appear without any animation
    ///   - duration: The duration of the animation, defaults to 0.1 second
    /// - Returns: The to-be-animated view
    func animatedAppearance(isContentLoaded: Bool, duration: Double = 0.1) -> some View {
        modifier(AnimatedAppearanceModifier(isContentLoaded: isContentLoaded, duration: duration))
    }
}
