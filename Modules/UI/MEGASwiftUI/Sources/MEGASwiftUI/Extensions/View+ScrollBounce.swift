import SwiftUI

public extension View {
    /// If iOS 16.4 is available, this var adds a view modifier to enable or disable view scrolling based on content size
    @ViewBuilder var scrollBounceBasedOnSize: some View {
        if #available(iOS 16.4, *) {
            self.scrollBounceBehavior(.basedOnSize)
        } else {
            self
        }
    }
}
