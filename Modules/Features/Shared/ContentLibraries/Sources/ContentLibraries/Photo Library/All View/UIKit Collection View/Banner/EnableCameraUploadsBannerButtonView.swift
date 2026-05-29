import MEGAAssets
import MEGADesignToken
import MEGAL10n
import MEGAUIComponent
import SwiftUI

public struct EnableCameraUploadsBannerButtonView: View {
    @Environment(\.colorScheme) private var colorScheme
    
    private let onTapHandler: (() -> Void)?
    private let closeButtonAction: (() -> Void)?
    
    public init(
        _ onTapHandler: (() -> Void)? = nil,
        closeButtonAction: (() -> Void)? = nil
    ) {
        self.onTapHandler = onTapHandler
        self.closeButtonAction = closeButtonAction
    }
    
    public var body: some View {
        Button(action: onTapHandler ?? { }, label: content)
            .buttonStyle(.plain)
    }
    
    private func content() -> some View {
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
