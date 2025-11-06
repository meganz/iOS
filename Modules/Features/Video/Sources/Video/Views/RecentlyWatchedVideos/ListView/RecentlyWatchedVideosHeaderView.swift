import MEGADesignToken
import SwiftUI

struct RecentlyWatchedVideosHeaderView: View {
    let text: String
    
    var body: some View {
        Text(text)
            .font(.callout)
            .bold()
            .foregroundStyle(TokenColors.Text.secondary.swiftUI)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview {
    RecentlyWatchedVideosHeaderView(text: "Today")
}

#Preview {
    RecentlyWatchedVideosHeaderView(text: "Today")
        .preferredColorScheme(.dark)
}
