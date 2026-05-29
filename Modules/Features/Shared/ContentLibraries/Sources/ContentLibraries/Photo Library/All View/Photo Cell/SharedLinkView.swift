import MEGAAppPresentation
import MEGAAssets
import MEGADesignToken
import SwiftUI

public struct SharedLinkView: View {
    private let foregroundColor: Color

    public init(foregroundColor: Color) {
        self.foregroundColor = foregroundColor
    }
    
    public var body: some View {
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
}

#Preview {
    SharedLinkView(foregroundColor: .gray)
}

#Preview {
    SharedLinkView(foregroundColor: .white)
        .preferredColorScheme(.dark)
}
