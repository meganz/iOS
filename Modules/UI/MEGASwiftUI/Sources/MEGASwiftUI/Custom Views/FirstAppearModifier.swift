import SwiftUI

public extension View {
    func onFirstAppear(perform action: (() -> Void)?) -> some View {
        modifier(FirstAppearModifier(action: action))
    }
}

private struct FirstAppearModifier: ViewModifier {
    let action: (() -> Void)?
    @State private var hasAppearedOnce = false

    func body(content: Content) -> some View {
        content.task {
            if !hasAppearedOnce {
                hasAppearedOnce = true
                action?()
            }
        }
    }
}
