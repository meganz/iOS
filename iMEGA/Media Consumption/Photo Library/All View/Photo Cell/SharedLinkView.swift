import MEGADesignToken
import MEGAPresentation
import SwiftUI

struct SharedLinkView: View {
    var body: some View {
        Image(.linksSegmentControler)
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
