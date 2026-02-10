import MEGAAssets
import MEGADesignToken
import MEGASwiftUI
import SwiftUI

struct HomeFloatingButtonViewModifier: ViewModifier {
    let isHidden: Bool
    let onTap: @MainActor () -> Void

    init(isHidden: Bool, onTap: @escaping @MainActor () -> Void) {
        self.isHidden = isHidden
        self.onTap = onTap
    }

    public func body(content: Content) -> some View {
        content
            .overlay(alignment: .bottomTrailing) {
                fabButton
                    .opacity(isHidden ? 0 : 1)
                    .animation(.easeInOut(duration: 0.3), value: isHidden)
            }
    }
    
    private var fabButton: some View {
        RoundedPrimaryImageButton(image: MEGAAssets.Image.plus) { onTap() }
            .padding(TokenSpacing._5)
    }
}

public extension View {
    func floatingButton(
        isHidden: Bool,
        onTap: @escaping @MainActor () -> Void
    ) -> some View {
        modifier(HomeFloatingButtonViewModifier(isHidden: isHidden, onTap: onTap))
    }
}
