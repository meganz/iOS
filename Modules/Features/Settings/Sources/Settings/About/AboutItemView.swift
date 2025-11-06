import MEGADesignToken
import MEGASwiftUI
import SwiftUI

struct AboutItemView: View {
    let title: String
    let subtitle: String
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(title)
                .font(.body)
            Text(subtitle)
                .font(.callout)
                .foregroundColor(TokenColors.Text.secondary.swiftUI)
        }
        .separator()
        .background()
    }
}
