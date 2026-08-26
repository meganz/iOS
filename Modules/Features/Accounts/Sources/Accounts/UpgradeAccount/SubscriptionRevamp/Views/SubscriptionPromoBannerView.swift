import MEGAAssets
import SwiftUI

/// The regular-height promo header image fading into the page background, shared by the promo
/// subscription page and the promotional offer landing dialog.
struct SubscriptionPromoBannerView: View {
    private let height: CGFloat = 280
    private let edgeBlurRadius: CGFloat = 5

    var body: some View {
        Color.clear
            .frame(maxWidth: .infinity)
            .frame(height: height)
            .overlay(alignment: .top) {
                ZStack {
                    bannerImage
                        .blur(radius: edgeBlurRadius)
                        .mask { blurredEdgeMask }
                    bannerImage
                        .mask { sharpBodyMask }
                }
            }
            .clipped()
            .subscriptionHeaderBottomFade()
    }

    private var bannerImage: some View {
        MEGAAssets.Image.promoBannerCentered
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(maxWidth: .infinity)
    }

    private var sharpBodyMask: LinearGradient {
        LinearGradient(
            stops: [
                .init(color: .black, location: 0),
                .init(color: .black, location: 0.94),
                .init(color: .clear, location: 1.0)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    private var blurredEdgeMask: LinearGradient {
        LinearGradient(
            stops: [
                .init(color: .clear, location: 0.82),
                .init(color: .black, location: 0.92),
                .init(color: .black, location: 0.97),
                .init(color: .clear, location: 1.0)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }
}
