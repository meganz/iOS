import MEGADesignToken
import SwiftUI

struct QuotaDialogErrorView: View {
    var body: some View {
        VStack {
            Spacer()
            // IOS-12210
            Text("Something went wrong. Please try again later.")
                .font(.callout)
                .multilineTextAlignment(.center)
                .foregroundStyle(TokenColors.Text.secondary.swiftUI)
                .padding(TokenSpacing._5)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(TokenColors.Background.page.swiftUI)
    }
}

#Preview {
    QuotaDialogErrorView()
}
