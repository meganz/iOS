import SwiftUI

struct MiniPlayerAwareModifier: ViewModifier {
    @EnvironmentObject var miniPlayerVisibility: MiniPlayerVisibility
    
    func body(content: Content) -> some View {
        content
            .padding(.bottom, miniPlayerVisibility.height)
    }
}

public extension View {
    func miniPlayerAware() -> some View {
        modifier(MiniPlayerAwareModifier())
    }
}
