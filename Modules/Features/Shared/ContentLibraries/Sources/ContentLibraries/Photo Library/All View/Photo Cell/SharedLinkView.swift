import MEGAAppPresentation
import MEGAAssets
import MEGADesignToken
import SwiftUI

public struct SharedLinkView: View {
    private let foregroundColor: Color
    private let isMediaRevampEnabled: Bool

    public init(
        foregroundColor: Color,
        isMediaRevampEnabled: Bool = false
    ) {
        self.foregroundColor = foregroundColor
        self.isMediaRevampEnabled = isMediaRevampEnabled
    }
    
    public var body: some View {
        if isMediaRevampEnabled {
            newView
        } else {
            legacyView
        }
    }
    
    private var newView: some View {
        TokenColors.Background.surfaceTransparent.swiftUI
            .aspectRatio(contentMode: .fill)
            .overlay(alignment: .center) {
                MEGAAssets.Image.link02SmallThin
                    .renderingMode(.template)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 16, height: 16)
                    .foregroundStyle(TokenColors.Icon.onColor.swiftUI)
            }
            .frame(width: 20, height: 20)
            .clipShape(RoundedRectangle(cornerRadius: TokenRadius.extraSmall))
    }
    
    private var legacyView: some View {
        MEGAAssets.Image.linksSegmentControler
            .resizable()
            .aspectRatio(contentMode: .fill)
            .frame(width: 15, height: 15)
            .foregroundStyle(
                foregroundColor
            )
    }
}

#Preview {
    SharedLinkView(foregroundColor: .gray)
}

#Preview {
    SharedLinkView(foregroundColor: .white)
        .preferredColorScheme(.dark)
}
