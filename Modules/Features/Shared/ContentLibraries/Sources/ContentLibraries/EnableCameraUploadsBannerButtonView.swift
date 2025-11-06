import MEGAAssets
import MEGADesignToken
import MEGAL10n
import SwiftUI

public struct EnableCameraUploadsBannerButtonView: View {
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
    
    private let onTapHandler: (() -> Void)?
    
    public init(_ onTapHandler: (() -> Void)? = nil) {
        self.onTapHandler = onTapHandler
    }
    
    public var body: some View {
        Button(action: onTapHandler ?? { }, label: content)
            .buttonStyle(.plain)
    }
    
    private func content() -> some View {
        VStack(spacing: 0) {
            HStack(alignment: .center, spacing: Constants.contentHorizontalSpacing) {
                MEGAAssets.Image.enableCameraUploadsBannerIcon
                    .renderingMode(.template)
                    .foregroundColor(TokenColors.Icon.secondary.swiftUI)
                
                VStack(alignment: .leading) {
                    Text(Strings.Localizable.CameraUploads.Banner.EnableState.title)
                        .font(.system(.footnote).bold())
                        .foregroundColor(TokenColors.Text.primary.swiftUI)
                    
                    Text(Strings.Localizable.CameraUploads.Banner.EnableState.description)
                        .font(.caption2)
                        .multilineTextAlignment(.leading)
                        .foregroundColor(TokenColors.Text.secondary.swiftUI)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                MEGAAssets.Image.cuBannerChevronRevamp
                    .renderingMode(.template)
                    .foregroundColor(TokenColors.Icon.secondary.swiftUI)
                    .frame(width: Constants.chevronFrameWidth,
                           height: Constants.chevronFrameHeight)
                
            }
            .padding(.vertical, Constants.contentVerticalPadding)
            .padding(.horizontal, Constants.contentHorizontalPadding)
            
            Divider()
                .background(TokenColors.Border.strong.swiftUI)
        }
        .background(TokenColors.Background.page.swiftUI)
    }
    
    private var bannerBorderColor: Color {
        TokenColors.Border.strong.swiftUI.opacity(colorScheme == .dark ? Constants.bannerBorderOpacityDarkMode : Constants.bannerBorderOpacityLightMode)
    }
}

#Preview("Default") {
    EnableCameraUploadsBannerButtonView()
}

#Preview("Dark Mode") {
    EnableCameraUploadsBannerButtonView()
        .preferredColorScheme(.dark)
}

@available(iOS 17.0, *)
#Preview("Landscape", traits: .landscapeLeft) {
    EnableCameraUploadsBannerButtonView()
}
