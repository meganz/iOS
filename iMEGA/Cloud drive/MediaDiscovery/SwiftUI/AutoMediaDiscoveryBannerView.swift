import MEGADesignToken
import MEGAL10n
import SwiftUI

struct AutoMediaDiscoveryBannerView: View {
    @Binding var showBanner: Bool
    var onDismiss: (() -> Void)?
    
    @Environment(\.colorScheme) private var colorScheme
    
    private enum Constants {
        static let descriptionTextVerticalPadding: CGFloat = 14
        static let defaultPadding: CGFloat = 16
        static let bannerBorderWidth = 0.5
        static let bannerBorderOpacityDarkMode = 0.65
        static let bannerBorderOpacityLightMode = 0.3
    }
    
    var body: some View {
        HStack(spacing: .zero) {
            bannerDescription
            closeButton
        }
        .background(TokenColors.Background.page.swiftUI)
        .border(bannerBorderColor,
                width: Constants.bannerBorderWidth)
    }
    
    private var bannerDescription: some View {
        Text(Strings.Localizable.Photos.MediaDiscovery.AutoMediaDiscoveryBanner.title)
            .font(Font.system(size: 12, weight: .regular, design: Font.Design.default))
            .padding(.vertical, Constants.descriptionTextVerticalPadding)
            .padding(.horizontal, Constants.defaultPadding)
            .frame(maxWidth: .infinity)
    }
    
    private var closeButton: some View {
        Button {
            withAnimation {
                showBanner = false
                onDismiss?()
            }
        } label: {
            Image(systemName: "xmark.circle.fill")
                .foregroundStyle(TokenColors.Icon.secondary.swiftUI)
        }
        .padding(.trailing, Constants.defaultPadding)
    }
    
    private var bannerBorderColor: Color {
        TokenColors.Border.strong.swiftUI.opacity(colorScheme == .dark ? Constants.bannerBorderOpacityDarkMode : Constants.bannerBorderOpacityLightMode)
    }
}

@available(iOS 17.0, *)
#Preview(traits: .sizeThatFitsLayout) {
    AutoMediaDiscoveryBannerView(showBanner: .constant(true))
}
