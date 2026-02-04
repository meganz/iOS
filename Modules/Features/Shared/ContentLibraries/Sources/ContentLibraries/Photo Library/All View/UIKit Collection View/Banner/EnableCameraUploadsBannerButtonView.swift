import MEGAAssets
import MEGADesignToken
import MEGAL10n
import MEGAUIComponent
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
    private let closeButtonAction: (() -> Void)?
    private let isMediaRevampEnabled: Bool
    
    public init(
        _ onTapHandler: (() -> Void)? = nil,
        closeButtonAction: (() -> Void)? = nil,
        configuration: ContentLibraries.Configuration = ContentLibraries.configuration
    ) {
        self.onTapHandler = onTapHandler
        self.closeButtonAction = closeButtonAction
        isMediaRevampEnabled = configuration.remoteFeatureFlagUseCase.isFeatureFlagEnabled(for: .iosMediaRevamp)
    }
    
    public var body: some View {
        Button(action: onTapHandler ?? { }, label: content)
            .buttonStyle(.plain)
    }
    
    @ViewBuilder
    private func content() -> some View {
        if isMediaRevampEnabled {
            mediaRevampContent
        } else {
            legacyContent
        }
    }
    
    private var mediaRevampContent: some View {
        HStack(alignment: .top, spacing: TokenSpacing._5) {
            HStack(alignment: .top, spacing: TokenSpacing._3) {
                MEGAAssets.Image.enableCameraUploadsBannerIcon
                    .renderingMode(.template)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 24, height: 24)
                    .foregroundStyle(TokenColors.Icon.primary.swiftUI)
                
                VStack(alignment: .leading, spacing: TokenSpacing._3) {
                    Text(Strings.Localizable.automaticallyBackupYourPhotosAndVideosToTheCloudDrive)
                        .font(.subheadline)
                        .foregroundStyle(TokenColors.Text.primary.swiftUI)
                        .fixedSize(horizontal: false, vertical: true)
                    
                    if let onTapHandler {
                        Button(action: onTapHandler) {
                            Text(Strings.Localizable.enableCameraUploadsButton)
                                .font(.callout.bold())
                                .underline(color: TokenColors.Link.primary.swiftUI)
                                .foregroundStyle(TokenColors.Link.primary.swiftUI)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            if let closeButtonAction {
                Button(action: closeButtonAction) {
                    XmarkCloseButton()
                }
            }
        }
        .padding(.horizontal, TokenSpacing._5)
        .padding(.vertical, TokenSpacing._7)
        .background(TokenColors.Background.page.swiftUI)
    }
    
    private var legacyContent: some View {
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
