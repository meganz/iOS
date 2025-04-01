import MEGAAppPresentation
import MEGAAssets
import SwiftUI

public struct SharedLinkView: View {
    private let foregroundColor: Color

    public init(foregroundColor: Color) {
        self.foregroundColor = foregroundColor
    }
    
    public var body: some View {
        MEGAAssetsImageProvider
            .image(named: .linksSegmentControler)
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
