import MEGAAssets
import MEGADesignToken
import SwiftUI

struct WaitingRoomMessageView: View {
    let title: String
    
    var body: some View {
        Text(title)
            .font(.subheadline)
            .foregroundColor(TokenColors.Text.inverse.swiftUI)
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            .background(TokenColors.Background.inverse.swiftUI)
            .cornerRadius(44)
    }
}

#Preview {
    WaitingRoomMessageView(title: "Wait for host to let you in")
        .padding(20)
        .background(MEGAAssets.Color.black000000)
}
