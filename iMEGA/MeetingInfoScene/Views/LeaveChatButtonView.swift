import SwiftUI

struct LeaveChatButtonView: View {
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
                    .foregroundColor(Color(UIColor.mnz_redF30C14()))
            }
            Divider()
        }
        .frame(minHeight: 44)
    }
}
