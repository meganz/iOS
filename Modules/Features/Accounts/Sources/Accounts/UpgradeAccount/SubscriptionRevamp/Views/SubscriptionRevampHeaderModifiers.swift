import MEGADesignToken
import SwiftUI

extension View {
    /// The bottom fade shared by both page headers, blending the header image into
    /// the page background.
    func subscriptionHeaderBottomFade(height: CGFloat = 120) -> some View {
        overlay(alignment: .bottom) {
            LinearGradient(
                stops: [
                    .init(color: .clear, location: 0),
                    .init(color: TokenColors.Background.page.swiftUI, location: 0.6),
                    .init(color: TokenColors.Background.page.swiftUI, location: 1.0)
                ],
                startPoint: UnitPoint(x: 0.5, y: 0),
                endPoint: UnitPoint(x: 0.5, y: 1)
            )
            .frame(height: height)
        }
    }

    /// Pulls the intro title up into the header so it blends with the image when the
    /// header sits above the content. In the side-by-side layout there is none, so no offset.
    func blendIntoHeader(offset: CGFloat, isSideBySide: Bool) -> some View {
        padding(.top, isSideBySide ? 0 : -offset)
    }
}
