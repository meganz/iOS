import SwiftUI

struct Shimmer: ViewModifier {
    let animation = Animation.linear(duration: 1.5).repeatForever(autoreverses: false)
    let scaleEffect: CGFloat

    @State private var phase: CGFloat = 0

    init(scaleEffect: CGFloat) {
        self.scaleEffect = scaleEffect
    }

    func body(content: Content) -> some View {
        content
            .modifier(
                AnimatedMask(
                    scaleEffect: scaleEffect,
                    phase: phase
                ).animation(animation)
            )
            .onAppear { phase = 0.8 }
    }

    struct AnimatedMask: AnimatableModifier {
        let scaleEffect: CGFloat
        var phase: CGFloat

        var animatableData: CGFloat {
            get { phase }
            set { phase = newValue }
        }

        func body(content: Content) -> some View {
            content
                .mask(GradientMask(phase: phase).scaleEffect(scaleEffect))
        }
    }

    struct GradientMask: View {
        let phase: CGFloat
        let centerColor = Color.black
        let edgeColor = Color.black.opacity(0.7)

        @Environment(\.layoutDirection)
        private var layoutDirection

        var body: some View {
            LinearGradient(
                gradient: Gradient(stops: [
                    .init(color: edgeColor, location: phase),
                    .init(color: centerColor, location: phase + 0.1),
                    .init(color: edgeColor, location: phase + 0.2)
                ]),
                startPoint: .leading,
                endPoint: .trailing
            )
        }
    }
}

extension View {
    /// Applies a shimmer effect to a view when active.
    ///
    /// - Parameters:
    ///   - active: A boolean value indicating whether the shimmer effect should be active. Default is true.
    ///   - scaleEffect: The scale effect to be applied to the shimmer, determining its width. Default is 5.
    /// - Returns: A view with the shimmer effect applied if active, otherwise the original view.
    @ViewBuilder
    public func shimmering(
        active: Bool = true,
        scaleEffect: CGFloat = 5
    ) -> some View {
        if active {
            modifier(Shimmer(scaleEffect: scaleEffect))
                .foregroundColor(Color.primary.opacity(0.1))
                .redacted(reason: .placeholder)
        } else {
            self
        }
    }
}
