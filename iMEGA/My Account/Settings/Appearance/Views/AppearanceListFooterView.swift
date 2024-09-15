import MEGADesignToken
import SwiftUI

struct AppearanceListFooterWithLinkView: View {
    
    let message: String
    let linkMessage: String
    let linkUrl: URL
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(message)
                .foregroundColor(TokenColors.Text.primary.swiftUI)
            Link(destination: linkUrl) {
                Text(linkMessage)
                    .foregroundStyle(TokenColors.Link.primary.swiftUI)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .font(.footnote)
    }
}

#Preview {
    AppearanceListFooterWithLinkView(
        message: "Folders that contain only images and videos will open in media discovery view by default.",
        linkMessage: "Learn more about mega",
        linkUrl: URL(string: "https://www.mega.io")!)
    .previewDevice(.none)
}
