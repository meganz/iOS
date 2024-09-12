import MEGADesignToken
import SwiftUI

struct ErrorView: View {
    let error: String
    
    var body: some View {
        Text(error)
            .font(.footnote)
            .foregroundStyle(TokenColors.Text.error.swiftUI)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal)
    }
}
