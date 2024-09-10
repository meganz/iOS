import MEGADesignToken
import MEGASwiftUI
import SwiftUI

struct LeaveChatButtonView: View {
    private enum Constants {
        static let viewHeight: CGFloat = 44
    }
    
    let text: String
    let action: (() -> Void)

    var body: some View {
        VStack {
            Divider()
            Button {
                action()
            } label: {
                Text(text)
                    .padding(.horizontal)
                    .foregroundColor(TokenColors.Text.error.swiftUI)
            }
            Divider()
        }
        .frame(minHeight: Constants.viewHeight)
        .background()
    }
}
