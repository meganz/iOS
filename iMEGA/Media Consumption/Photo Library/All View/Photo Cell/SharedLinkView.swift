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
                isDesignTokenEnabled
                ? TokenColors.Icon.onColor.swiftUI
                : MEGAAppColor.White._FFFFFF.color
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
