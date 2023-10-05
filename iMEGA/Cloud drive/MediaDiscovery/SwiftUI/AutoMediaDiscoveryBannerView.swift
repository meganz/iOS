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
        .background(bannerBackgroundColor)
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
                .foregroundColor(closeImageColor)
        }
        .padding(.trailing, Constants.defaultPadding)
    }
    
    private var closeImageColor: Color {
        Color(colorScheme == .dark ? Colors.General.Gray.d1D1D1.color :
                Colors.General.Gray._515151.color)
    }
    
    private var bannerBackgroundColor: Color {
        Color(colorScheme == .dark ? Colors.General.Black._2c2c2e.color :
                Colors.General.White.ffffff.color)
    }
    
    private var bannerBorderColor: Color {
        colorScheme == .dark ? Color(Colors.General.Gray._545458.color).opacity(Constants.bannerBorderOpacityDarkMode) :
        Color(Colors.General.Gray._3C3C43.color).opacity(Constants.bannerBorderOpacityLightMode)
    }
}

struct AutoMediaDiscoveryBannerView_Previews: PreviewProvider {
    static var previews: some View {
        AutoMediaDiscoveryBannerView(showBanner: .constant(true))
        .previewLayout(.sizeThatFits)
    }
}
