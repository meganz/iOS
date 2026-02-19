import SwiftUI

public extension View {
    /// Conditionally ignores the vertical safe area if the device supports iOS 26+ (Liquid Glass)
    @ViewBuilder
    func ignoreVerticalSafeAreaForLiquidGlass() -> some View {
        if #available(iOS 26.0, *) {
            self.ignoresSafeArea(.container, edges: .vertical)
        } else {
            self
        }
    }
}
