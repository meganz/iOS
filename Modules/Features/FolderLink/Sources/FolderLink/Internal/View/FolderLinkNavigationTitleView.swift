import MEGADesignToken
import SwiftUI

struct FolderLinkNavigationTitleView: View {
    let title: String
    let subtitle: String?
    
    var body: some View {
        VStack {
            Text(title)
                .font(.headline)
                .foregroundStyle(TokenColors.Text.primary.swiftUI)
                .lineLimit(1)
            if let subtitle {
                Text(subtitle)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(TokenColors.Text.secondary.swiftUI)
                    .lineLimit(1)
            }
        }
    }
}
