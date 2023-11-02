import MEGAL10n
import SwiftUI

struct EnableCameraUploadsBannerView: View {
    private enum Constants {
        static let contentHorizontalSpacing: CGFloat = 8
        static let contentVerticalPadding: CGFloat = 12
        static let contentHorizontalPadding: CGFloat = 16
        static let bannerBorderWidth = 0.5
        static let bannerBorderOpacityDarkMode = 0.65
        static let bannerBorderOpacityLightMode = 0.3
        static let chevronFrameWidth = 13.0
        static let chevronFrameHeight = 22.0
    }
    
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .center, spacing: Constants.contentHorizontalSpacing) {
                Image(.cuStatusEnable)
                
                VStack(alignment: .leading) {
                    Text(Strings.Localizable.CameraUploads.Banner.EnableState.title)
                        .font(Font.system(size: 13, weight: .semibold, design: .default))
                    Text(Strings.Localizable.CameraUploads.Banner.EnableState.description)
                        .font(Font.system(size: 11, weight: .regular, design: .default))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
               
                Image(.cuBannerChevron)
                    .frame(width: Constants.chevronFrameWidth,
                           height: Constants.chevronFrameHeight)
            }
            .padding(.vertical, Constants.contentVerticalPadding)
            .padding(.horizontal, Constants.contentHorizontalPadding)
            
            Divider()
                .background(bannerBorderColor)
        }
    }
    
    private var bannerBorderColor: Color {
        colorScheme == .dark ? Color(Colors.General.Gray._545458.color).opacity(Constants.bannerBorderOpacityDarkMode) :
        Color(Colors.General.Gray._3C3C43.color).opacity(Constants.bannerBorderOpacityLightMode)
    }
}

struct EnableCameraUploadsBannerView_Preview: PreviewProvider {
    static var previews: some View {
        
        EnableCameraUploadsBannerView()
        
        if #available(iOS 15.0, *) {
            EnableCameraUploadsBannerView()
                .previewInterfaceOrientation(.landscapeLeft)
        }
    }
}
