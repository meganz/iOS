import SwiftUI

public extension View {
    func onFirstAppear(perform action: (() -> Void)?) -> some View {
        modifier(FirstAppearModifier(action: action))
    }
}

public extension View {
    func onFirstLoad(perform action: @escaping () async -> Void) -> some View {
        modifier(FirstLoadModifier(action: action))
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

private struct FirstLoadModifier: ViewModifier {
    let action: () async -> Void
    @State private var hasLoadedOnce = false
    
    func body(content: Content) -> some View {
        content
            .task {
                guard !hasLoadedOnce else { return }
                hasLoadedOnce.toggle()
                await action()
            }
    }
}
