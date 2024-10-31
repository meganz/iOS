import MEGAAssets
import MEGADesignToken
import MEGAPresentation
import SwiftUI

public struct SharedLinkView: View {
    
    public init() { }
    
    public var body: some View {
        MEGAAssetsImageProvider
            .image(named: .linksSegmentControler)
            .resizable()
            .aspectRatio(contentMode: .fill)
            .frame(width: 15, height: 15)
            .foregroundStyle(
                TokenColors.Icon.onColor.swiftUI
            )
    }
}

#Preview {
    SharedLinkView()
}

#Preview {
    SharedLinkView()
        .preferredColorScheme(.dark)
}
