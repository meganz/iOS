import MEGAAssets
import MEGADesignToken
import MEGASwiftUI
import SwiftUI

struct EmptySearchView: View {
    let description: String
    
    var body: some View {
        ContentUnavailableView {
            Image(uiImage: MEGAAssets.UIImage.glassSearch)
        } description: {
            Text(description)
                .font(.footnote)
                .foregroundStyle(TokenColors.Text.secondary.swiftUI)
        }
        .frame(maxHeight: .infinity)
    }
}

#Preview {
    EmptySearchView(description: "Test")
}
