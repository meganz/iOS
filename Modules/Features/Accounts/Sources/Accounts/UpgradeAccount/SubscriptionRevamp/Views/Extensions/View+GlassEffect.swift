import MEGADesignToken
import SwiftUI

extension View {
    @ViewBuilder
    func glassCircle() -> some View {
        if #available(iOS 26.0, *) {
            glassEffect(.regular.interactive(), in: Circle())
        } else {
            background(TokenColors.Background.surface1.swiftUI, in: Circle())
        }
    }

    @ViewBuilder
    func glassCapsule() -> some View {
        if #available(iOS 26.0, *) {
            glassEffect(.regular.interactive(), in: Capsule())
        } else {
            background(TokenColors.Background.surface1.swiftUI, in: Capsule())
        }
    }
}
