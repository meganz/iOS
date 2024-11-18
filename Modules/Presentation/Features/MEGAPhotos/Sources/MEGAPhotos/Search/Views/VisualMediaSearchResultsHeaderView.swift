import MEGADesignToken
import SwiftUI

struct VisualMediaSearchResultsHeaderView: View {
    let text: String
    
    var body: some View {
        Text(text)
            .font(.footnote)
            .foregroundStyle(TokenColors.Text.secondary.swiftUI)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}
