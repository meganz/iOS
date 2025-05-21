import MEGAAssets
import MEGADesignToken
import SwiftUI

struct WaitingRoomUserAvatarView: View {
    let avatar: Image

    var body: some View {
        avatar
            .resizable()
            .scaledToFill()
            .frame(width: 80, height: 80)
            .clipShape(Circle())
            .padding(2)
            .overlay(
                Circle()
                    .stroke(
                        MEGAAssets.Color.whiteFFFFFF.opacity(0.3),
                        lineWidth: 4
                    )
            )
    }
}

@available(iOS 17.0, *)
#Preview(traits: .sizeThatFitsLayout) {
    WaitingRoomUserAvatarView(avatar: Image(Color.red, CGSize(width: 100, height: 100)))
        .padding(20)
        .background(MEGAAssets.Color.black000000)
}
