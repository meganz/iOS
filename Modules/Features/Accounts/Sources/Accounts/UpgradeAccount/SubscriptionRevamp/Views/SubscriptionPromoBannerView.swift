import MEGAAssets
import SwiftUI

/// The regular-height promo header image fading into the page background, shared by the promo
/// subscription page and the promotional offer landing dialog.
struct SubscriptionPromoBannerView: View {
    private let height: CGFloat = 280

    var body: some View {
        Color.clear
            .frame(maxWidth: .infinity)
            .frame(height: height)
            .overlay(alignment: .top) {
                MEGAAssets.Image.promoBannerCentered
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: .infinity)
            }
            .clipped()
            .subscriptionHeaderBottomFade()
    }
}
